import 'package:drift/drift.dart' as drift;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/database/app_database.dart' as db;
import 'package:up_req/core/database/database_provider.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';

import '../domain/contracts/recording_repository.dart';
import '../domain/entities/recording.dart' as domain;
import 'recordings_dao.dart';

part 'recording_repository_impl.g.dart';

class RecordingRepositoryImpl implements RecordingRepository {
  RecordingRepositoryImpl(this._db, this._dao, this._idGenerator);

  final db.AppDatabase _db;
  final RecordingsDao _dao;
  final IdGenerator _idGenerator;

  @override
  Stream<List<domain.Recording>> watchBySession(SessionId id) {
    return _dao.watchBySession(id.value).map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Stream<domain.Recording?> watchActive() {
    return _dao.watchActive().map((row) => row == null ? null : _toDomain(row));
  }

  @override
  Stream<domain.Recording?> watchById(RecordingId id) {
    return _dao.watchById(id.value).map((row) => row == null ? null : _toDomain(row));
  }

  @override
  Future<domain.Recording?> findInterrupted() async {
    final row = await _dao.findInterrupted();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<domain.Recording?> findById(RecordingId id) async {
    final row = await _dao.findById(id.value);
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> insert(domain.Recording recording) {
    return _dao.insertRecording(
      db.RecordingsCompanion.insert(
        id: recording.id.value,
        sessionId: recording.sessionId.value,
        projectId: recording.projectId.value,
        filePath: recording.filePath,
        status: drift.Value(recording.status.name),
        durationMs: drift.Value(recording.durationMs),
        sampleRate: drift.Value(recording.sampleRate),
        channels: drift.Value(recording.channels),
        startedAt: recording.startedAt,
        stoppedAt: drift.Value(recording.stoppedAt),
        createdAt: recording.createdAt,
        updatedAt: recording.updatedAt,
      ),
    );
  }

  @override
  Future<void> updateStatus(RecordingId id, domain.RecordingStatus status, DateTime at) {
    return _dao.updateRecording(
      id.value,
      db.RecordingsCompanion(status: drift.Value(status.name), updatedAt: drift.Value(at)),
    );
  }

  @override
  Future<void> setStopped(RecordingId id, int durationMs, DateTime at) {
    return _dao.updateRecording(
      id.value,
      db.RecordingsCompanion(
        status: const drift.Value('stopped'),
        durationMs: drift.Value(durationMs),
        stoppedAt: drift.Value(at),
        updatedAt: drift.Value(at),
      ),
    );
  }

  /// Baja lógica + asiento `recordingDeleted`, y cascada que retira marcas,
  /// transcripciones y segmentos de esta grabación SIN asientos propios
  /// (FR-023), todo en una única transacción.
  @override
  Future<void> softDelete(RecordingId id, DateTime at) async {
    await _db.transaction(() async {
      final current = await _dao.findById(id.value);
      if (current == null) return;

      await _dao.updateRecording(
        id.value,
        db.RecordingsCompanion(deletedAt: drift.Value(at), updatedAt: drift.Value(at)),
      );

      await (_db.update(_db.liveMarks)
            ..where((m) => m.recordingId.equals(id.value) & m.deletedAt.isNull()))
          .write(db.LiveMarksCompanion(deletedAt: drift.Value(at), updatedAt: drift.Value(at)));

      await (_db.update(_db.transcripts)
            ..where((t) => t.recordingId.equals(id.value) & t.deletedAt.isNull()))
          .write(db.TranscriptsCompanion(deletedAt: drift.Value(at), updatedAt: drift.Value(at)));

      await (_db.update(_db.transcriptSegments)
            ..where((s) => s.recordingId.equals(id.value) & s.deletedAt.isNull()))
          .write(
            db.TranscriptSegmentsCompanion(deletedAt: drift.Value(at), updatedAt: drift.Value(at)),
          );

      await _db.into(_db.auditEntries).insert(
            db.AuditEntriesCompanion.insert(
              id: _idGenerator.generate(),
              projectId: current.projectId,
              operation: 'recordingDeleted',
              entityType: 'recording',
              entityId: id.value,
              entityLabel: drift.Value(current.filePath),
              occurredAt: at,
              createdAt: at,
              updatedAt: at,
            ),
          );
    });
  }

  domain.Recording _toDomain(db.Recording row) {
    return domain.Recording(
      id: RecordingId(row.id),
      sessionId: SessionId(row.sessionId),
      projectId: ProjectId(row.projectId),
      filePath: row.filePath,
      status: domain.RecordingStatus.values.byName(row.status),
      durationMs: row.durationMs,
      sampleRate: row.sampleRate,
      channels: row.channels,
      startedAt: row.startedAt,
      stoppedAt: row.stoppedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

@Riverpod(keepAlive: true)
RecordingRepository recordingRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  return RecordingRepositoryImpl(
    database,
    RecordingsDao(database),
    ref.watch(idGeneratorProvider),
  );
}
