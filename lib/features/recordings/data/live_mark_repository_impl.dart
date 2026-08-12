import 'package:drift/drift.dart' as drift;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/database/app_database.dart' as db;
import 'package:up_req/core/database/database_provider.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';

import '../domain/contracts/live_mark_repository.dart';
import '../domain/entities/live_mark.dart' as domain;
import 'live_marks_dao.dart';

part 'live_mark_repository_impl.g.dart';

class LiveMarkRepositoryImpl implements LiveMarkRepository {
  LiveMarkRepositoryImpl(this._db, this._dao, this._idGenerator);

  final db.AppDatabase _db;
  final LiveMarksDao _dao;
  final IdGenerator _idGenerator;

  @override
  Stream<List<domain.LiveMark>> watchByRecording(RecordingId id) {
    return _dao.watchByRecording(id.value).map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<void> insert(domain.LiveMark mark) {
    return _dao.insertMark(
      db.LiveMarksCompanion.insert(
        id: mark.id.value,
        recordingId: mark.recordingId.value,
        sessionId: mark.sessionId.value,
        projectId: mark.projectId.value,
        kind: mark.kind.name,
        atMs: mark.atMs,
        createdAt: mark.createdAt,
        updatedAt: mark.updatedAt,
      ),
    );
  }

  @override
  Future<void> updateKind(LiveMarkId id, domain.LiveMarkKind kind, DateTime at) {
    return _dao.updateMark(
      id.value,
      db.LiveMarksCompanion(kind: drift.Value(kind.name), updatedAt: drift.Value(at)),
    );
  }

  @override
  Future<void> softDelete(LiveMarkId id, DateTime at) async {
    await _db.transaction(() async {
      final current = await _dao.findById(id.value);
      if (current == null) return;

      await _dao.updateMark(
        id.value,
        db.LiveMarksCompanion(deletedAt: drift.Value(at), updatedAt: drift.Value(at)),
      );

      await _db.into(_db.auditEntries).insert(
            db.AuditEntriesCompanion.insert(
              id: _idGenerator.generate(),
              projectId: current.projectId,
              operation: 'liveMarkDeleted',
              entityType: 'liveMark',
              entityId: id.value,
              entityLabel: drift.Value(current.kind),
              occurredAt: at,
              createdAt: at,
              updatedAt: at,
            ),
          );
    });
  }

  domain.LiveMark _toDomain(db.LiveMark row) {
    return domain.LiveMark(
      id: LiveMarkId(row.id),
      recordingId: RecordingId(row.recordingId),
      sessionId: SessionId(row.sessionId),
      projectId: ProjectId(row.projectId),
      kind: domain.LiveMarkKind.values.byName(row.kind),
      atMs: row.atMs,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

@Riverpod(keepAlive: true)
LiveMarkRepository liveMarkRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  return LiveMarkRepositoryImpl(database, LiveMarksDao(database), ref.watch(idGeneratorProvider));
}
