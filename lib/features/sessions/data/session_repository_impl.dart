import 'package:drift/drift.dart' as drift;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/database/app_database.dart' as db;
import 'package:up_req/core/database/database_provider.dart';
import 'package:up_req/core/domain/combine_latest.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';

import '../domain/entities/elicitation_session.dart' as domain;
import '../domain/entities/session_counters.dart' as domain;
import '../domain/entities/session_detail.dart' as domain;
import '../domain/session_repository.dart';
import 'sessions_dao.dart';

part 'session_repository_impl.g.dart';

class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl(this._db, this._dao, this._idGenerator);

  final db.AppDatabase _db;
  final SessionsDao _dao;
  final IdGenerator _idGenerator;

  @override
  Stream<List<domain.ElicitationSession>> watchByProject(ProjectId id) {
    return _dao.watchByProject(id.value).map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Stream<domain.SessionDetail?> watchDetail(SessionId id) {
    final sessionAndParticipants = combineLatest2<db.Session?, List<String>, (db.Session?, List<String>)>(
      _dao.watchById(id.value),
      _dao.watchParticipantIds(id.value),
      (session, participantIds) => (session, participantIds),
    );

    return combineLatest2<(db.Session?, List<String>), domain.SessionCounters, domain.SessionDetail?>(
      sessionAndParticipants,
      _dao.watchCounters(id.value),
      (sessionAndParticipantIds, counters) {
        final (session, participantIds) = sessionAndParticipantIds;
        if (session == null) return null;
        return domain.SessionDetail(
          session: _toDomain(session),
          participantIds: participantIds.map(StakeholderId.new).toList(),
          counters: counters,
        );
      },
    );
  }

  @override
  Future<domain.ElicitationSession?> findById(SessionId id) async {
    final row = await _dao.findById(id.value);
    return row == null ? null : _toDomain(row);
  }

  /// Inserta sesión y participantes en una transacción. FR-009.
  @override
  Future<void> insert(domain.ElicitationSession session, List<StakeholderId> participantIds) async {
    await _db.transaction(() async {
      await _dao.insertSession(
        db.SessionsCompanion.insert(
          id: session.id.value,
          projectId: session.projectId.value,
          title: session.title,
          scheduledAt: session.scheduledAt,
          technique: session.technique.name,
          location: drift.Value(session.location),
          status: drift.Value(session.status.name),
          notes: drift.Value(session.notes),
          closedAt: const drift.Value(null),
          deletedAt: const drift.Value(null),
          createdAt: session.createdAt,
          updatedAt: session.updatedAt,
        ),
      );
      await _dao.insertParticipants(_participantCompanions(session, participantIds, session.createdAt));
    });
  }

  /// Reemplaza cabecera y participantes en una transacción.
  @override
  Future<void> updateHeader(
    domain.ElicitationSession session,
    List<StakeholderId> participantIds,
  ) async {
    await _db.transaction(() async {
      await _dao.updateSession(
        session.id.value,
        db.SessionsCompanion(
          title: drift.Value(session.title),
          scheduledAt: drift.Value(session.scheduledAt),
          technique: drift.Value(session.technique.name),
          location: drift.Value(session.location),
          updatedAt: drift.Value(session.updatedAt),
        ),
      );
      await _dao.deleteParticipants(session.id.value);
      await _dao.insertParticipants(_participantCompanions(session, participantIds, session.updatedAt));
    });
  }

  @override
  Future<void> updateNotes(SessionId id, String? notes, DateTime at) {
    return _dao.updateSession(
      id.value,
      db.SessionsCompanion(notes: drift.Value(notes), updatedAt: drift.Value(at)),
    );
  }

  /// Sella `closed_at` al pasar a `closed`. Sin asiento de bitácora: el
  /// catálogo de FR-015 no incluye cambios de estado de sesión, solo su
  /// eliminación.
  @override
  Future<void> setStatus(SessionId id, domain.SessionStatus status, DateTime at) {
    return _dao.updateSession(
      id.value,
      db.SessionsCompanion(
        status: drift.Value(status.name),
        updatedAt: drift.Value(at),
        closedAt: status == domain.SessionStatus.closed
            ? drift.Value(at)
            : const drift.Value.absent(),
      ),
    );
  }

  /// Marca `deleted_at` y asienta bitácora en la misma transacción,
  /// copiando en `entity_label` el título de la sesión (patrón de T041). NO
  /// toca `script_points`: conservan su fila y su `deleted_at` nulo
  /// (invariante I9).
  @override
  Future<void> softDelete(SessionId id, DateTime at) async {
    await _db.transaction(() async {
      final current = await _dao.findById(id.value);
      if (current == null) return;

      await _dao.updateSession(
        id.value,
        db.SessionsCompanion(deletedAt: drift.Value(at), updatedAt: drift.Value(at)),
      );

      await _db.into(_db.auditEntries).insert(
            db.AuditEntriesCompanion.insert(
              id: _idGenerator.generate(),
              projectId: current.projectId,
              operation: 'sessionDeleted',
              entityType: 'session',
              entityId: id.value,
              entityLabel: drift.Value(current.title),
              occurredAt: at,
              createdAt: at,
              updatedAt: at,
            ),
          );
    });
  }

  List<db.SessionParticipantsCompanion> _participantCompanions(
    domain.ElicitationSession session,
    List<StakeholderId> participantIds,
    DateTime at,
  ) {
    return [
      for (final participantId in participantIds)
        db.SessionParticipantsCompanion.insert(
          sessionId: session.id.value,
          stakeholderId: participantId.value,
          projectId: session.projectId.value,
          createdAt: at,
        ),
    ];
  }

  domain.ElicitationSession _toDomain(db.Session row) {
    return domain.ElicitationSession(
      id: SessionId(row.id),
      projectId: ProjectId(row.projectId),
      title: row.title,
      scheduledAt: row.scheduledAt,
      technique: domain.SessionTechnique.values.byName(row.technique),
      location: row.location,
      status: domain.SessionStatus.values.byName(row.status),
      notes: row.notes,
      closedAt: row.closedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

@Riverpod(keepAlive: true)
SessionRepository sessionRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  return SessionRepositoryImpl(
    database,
    SessionsDao(database),
    ref.watch(idGeneratorProvider),
  );
}
