import 'package:drift/drift.dart' as drift;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/database/app_database.dart' as db;
import 'package:up_req/core/database/database_provider.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';

import '../domain/entities/script_point.dart' as domain;
import '../domain/script_point_repository.dart';
import 'script_points_dao.dart';

part 'script_point_repository_impl.g.dart';

class ScriptPointRepositoryImpl implements ScriptPointRepository {
  ScriptPointRepositoryImpl(this._db, this._dao, this._idGenerator);

  final db.AppDatabase _db;
  final ScriptPointsDao _dao;
  final IdGenerator _idGenerator;

  @override
  Stream<List<domain.ScriptPoint>> watchBySession(SessionId id) {
    return _dao.watchBySession(id.value).map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<domain.ScriptPoint?> findById(ScriptPointId id) async {
    final row = await _dao.findById(id.value);
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> append(domain.ScriptPoint point) {
    return _dao.insertPoint(
      db.ScriptPointsCompanion.insert(
        id: point.id.value,
        sessionId: point.sessionId.value,
        projectId: point.projectId.value,
        body: point.text,
        status: drift.Value(point.status.name),
        position: point.position,
        deletedAt: const drift.Value(null),
        createdAt: point.createdAt,
        updatedAt: point.updatedAt,
      ),
    );
  }

  @override
  Future<void> updateText(ScriptPointId id, String text, DateTime at) {
    return _dao.updatePoint(
      id.value,
      db.ScriptPointsCompanion(body: drift.Value(text), updatedAt: drift.Value(at)),
    );
  }

  @override
  Future<void> setStatus(ScriptPointId id, domain.ScriptPointStatus status, DateTime at) {
    return _dao.updatePoint(
      id.value,
      db.ScriptPointsCompanion(status: drift.Value(status.name), updatedAt: drift.Value(at)),
    );
  }

  @override
  Future<void> move(SessionId session, ScriptPointId id, int from, int to) {
    return _dao.movePosition(session.value, id.value, from, to);
  }

  /// Marca `deleted_at`, compacta posiciones y asienta bitácora, todo en una
  /// transacción, copiando en `entity_label` el texto del punto (patrón de
  /// T041, T057, T075).
  @override
  Future<void> softDelete(ScriptPointId id, DateTime at) async {
    await _db.transaction(() async {
      final current = await _dao.findById(id.value);
      if (current == null) return;

      await _dao.updatePoint(
        id.value,
        db.ScriptPointsCompanion(deletedAt: drift.Value(at), updatedAt: drift.Value(at)),
      );

      await _dao.compactPositionsAfter(current.sessionId, current.position);

      await _db.into(_db.auditEntries).insert(
            db.AuditEntriesCompanion.insert(
              id: _idGenerator.generate(),
              projectId: current.projectId,
              operation: 'scriptPointDeleted',
              entityType: 'scriptPoint',
              entityId: id.value,
              entityLabel: drift.Value(current.body),
              occurredAt: at,
              createdAt: at,
              updatedAt: at,
            ),
          );
    });
  }

  domain.ScriptPoint _toDomain(db.ScriptPoint row) {
    return domain.ScriptPoint(
      id: ScriptPointId(row.id),
      sessionId: SessionId(row.sessionId),
      projectId: ProjectId(row.projectId),
      text: row.body,
      status: domain.ScriptPointStatus.values.byName(row.status),
      position: row.position,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

@Riverpod(keepAlive: true)
ScriptPointRepository scriptPointRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  return ScriptPointRepositoryImpl(
    database,
    ScriptPointsDao(database),
    ref.watch(idGeneratorProvider),
  );
}
