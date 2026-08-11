import 'package:drift/drift.dart';
import 'package:up_req/core/database/app_database.dart';
import 'package:up_req/core/database/tables/sessions.dart';
import 'package:up_req/features/sessions/domain/entities/session_counters.dart' as domain;

part 'sessions_dao.g.dart';

@DriftAccessor(tables: [Sessions, SessionParticipants])
class SessionsDao extends DatabaseAccessor<AppDatabase> with _$SessionsDaoMixin {
  SessionsDao(super.db);

  /// Solo vivas, del proyecto. Único helper de filtrado (data-model.md,
  /// "Aislamiento por proyecto", invariante I4).
  Stream<List<Session>> watchByProject(String projectId) {
    return (select(sessions)
          ..where((s) => s.projectId.equals(projectId) & s.deletedAt.isNull())
          ..orderBy([(s) => OrderingTerm(expression: s.scheduledAt)]))
        .watch();
  }

  Stream<Session?> watchById(String id) {
    return (select(sessions)..where((s) => s.id.equals(id))).watchSingleOrNull();
  }

  Future<Session?> findById(String id) {
    return (select(sessions)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertSession(SessionsCompanion companion) => into(sessions).insert(companion);

  Future<void> updateSession(String id, SessionsCompanion companion) {
    return (update(sessions)..where((s) => s.id.equals(id))).write(companion);
  }

  /// IDs de interesado participantes de la sesión. Sin `deleted_at`: quitar
  /// un participante es una edición de la sesión, no una baja (data-model.md).
  Stream<List<String>> watchParticipantIds(String sessionId) {
    final query = select(sessionParticipants)..where((p) => p.sessionId.equals(sessionId));
    return query.watch().map((rows) => rows.map((r) => r.stakeholderId).toList());
  }

  Future<void> insertParticipants(List<SessionParticipantsCompanion> companions) {
    if (companions.isEmpty) return Future.value();
    return batch((b) => b.insertAll(sessionParticipants, companions));
  }

  Future<void> deleteParticipants(String sessionId) {
    return (delete(sessionParticipants)..where((p) => p.sessionId.equals(sessionId))).go();
  }

  /// COUNT en SQL agrupado por estado, nunca contando en Dart (FR-013).
  Stream<domain.SessionCounters> watchCounters(String sessionId) {
    final query = customSelect(
      'SELECT '
      "(SELECT COUNT(*) FROM script_points WHERE session_id = ? AND status = 'pending' AND deleted_at IS NULL) AS pending, "
      "(SELECT COUNT(*) FROM script_points WHERE session_id = ? AND status = 'covered' AND deleted_at IS NULL) AS covered, "
      "(SELECT COUNT(*) FROM script_points WHERE session_id = ? AND status = 'skipped' AND deleted_at IS NULL) AS skipped",
      variables: [
        Variable.withString(sessionId),
        Variable.withString(sessionId),
        Variable.withString(sessionId),
      ],
      readsFrom: {attachedDatabase.scriptPoints},
    );
    return query.watchSingle().map(
          (row) => domain.SessionCounters(
            pending: row.read<int>('pending'),
            covered: row.read<int>('covered'),
            skipped: row.read<int>('skipped'),
          ),
        );
  }
}
