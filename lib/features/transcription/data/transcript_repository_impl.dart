import 'package:drift/drift.dart' as drift;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/database/app_database.dart' as db;
import 'package:up_req/core/database/database_provider.dart';
import 'package:up_req/core/domain/ids.dart';

import '../domain/contracts/transcriber.dart';
import '../domain/contracts/transcript_repository.dart';
import '../domain/entities/transcript.dart' as domain;
import '../domain/entities/transcript_segment.dart' as domain;
import 'transcripts_dao.dart';

part 'transcript_repository_impl.g.dart';

class TranscriptRepositoryImpl implements TranscriptRepository {
  TranscriptRepositoryImpl(this._db, this._dao);

  final db.AppDatabase _db;
  final TranscriptsDao _dao;

  @override
  Stream<domain.Transcript?> watchByRecordingAndPass(RecordingId id, domain.TranscriptPass pass) {
    return _dao
        .watchByRecordingAndPass(id.value, pass.dbValue)
        .map((row) => row == null ? null : _toDomain(row));
  }

  @override
  Stream<List<domain.TranscriptSegment>> watchSegments(TranscriptId id) {
    return _dao.watchSegments(id.value).map((rows) => rows.map(_segmentToDomain).toList());
  }

  @override
  Future<domain.TranscriptSegment?> findSegmentById(SegmentId id) async {
    final row = await _dao.findSegmentById(id.value);
    return row == null ? null : _segmentToDomain(row);
  }

  @override
  Future<List<domain.Transcript>> findPending() async {
    final rows = await _dao.findPending();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<void> upsert(domain.Transcript transcript) {
    return _dao.upsertTranscript(
      db.TranscriptsCompanion.insert(
        id: transcript.id.value,
        recordingId: transcript.recordingId.value,
        sessionId: transcript.sessionId.value,
        projectId: transcript.projectId.value,
        pass: transcript.pass.dbValue,
        status: drift.Value(transcript.status.name),
        modelId: transcript.modelId.name,
        body: drift.Value(transcript.text),
        failureReason: drift.Value(transcript.failureReason),
        completedAt: drift.Value(transcript.completedAt),
        createdAt: transcript.createdAt,
        updatedAt: transcript.updatedAt,
      ),
    );
  }

  @override
  Future<void> replaceSegments(TranscriptId id, List<domain.TranscriptSegment> segments) {
    return _dao.replaceSegments(
      id.value,
      [
        for (final segment in segments)
          db.TranscriptSegmentsCompanion.insert(
            id: segment.id.value,
            transcriptId: segment.transcriptId.value,
            recordingId: segment.recordingId.value,
            sessionId: segment.sessionId.value,
            projectId: segment.projectId.value,
            fromMs: segment.fromMs,
            toMs: segment.toMs,
            position: segment.position,
            body: segment.text,
            createdAt: segment.createdAt,
            updatedAt: segment.updatedAt,
          ),
      ],
    );
  }

  /// Ver domain/contracts/transcript_repository.dart: invocado únicamente
  /// desde `RecordingRepositoryImpl.softDelete`, que hoy hace la cascada
  /// directamente sobre las tablas de drift dentro de su propia transacción
  /// (T039). Este método existe para completar el contrato declarado en
  /// domain-contracts.md.
  @override
  Future<void> softDeleteByRecording(RecordingId id, DateTime at) async {
    await _db.transaction(() async {
      await (_db.update(_db.transcripts)
            ..where((t) => t.recordingId.equals(id.value) & t.deletedAt.isNull()))
          .write(db.TranscriptsCompanion(deletedAt: drift.Value(at), updatedAt: drift.Value(at)));

      await (_db.update(_db.transcriptSegments)
            ..where((s) => s.recordingId.equals(id.value) & s.deletedAt.isNull()))
          .write(
            db.TranscriptSegmentsCompanion(deletedAt: drift.Value(at), updatedAt: drift.Value(at)),
          );
    });
  }

  domain.Transcript _toDomain(db.Transcript row) {
    return domain.Transcript(
      id: TranscriptId(row.id),
      recordingId: RecordingId(row.recordingId),
      sessionId: SessionId(row.sessionId),
      projectId: ProjectId(row.projectId),
      pass: domain.TranscriptPass.fromDbValue(row.pass),
      status: domain.TranscriptStatus.values.byName(row.status),
      modelId: TranscriptionModel.values.byName(row.modelId),
      text: row.body,
      failureReason: row.failureReason,
      completedAt: row.completedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  domain.TranscriptSegment _segmentToDomain(db.TranscriptSegment row) {
    return domain.TranscriptSegment(
      id: SegmentId(row.id),
      transcriptId: TranscriptId(row.transcriptId),
      recordingId: RecordingId(row.recordingId),
      sessionId: SessionId(row.sessionId),
      projectId: ProjectId(row.projectId),
      fromMs: row.fromMs,
      toMs: row.toMs,
      position: row.position,
      text: row.body,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

@Riverpod(keepAlive: true)
TranscriptRepository transcriptRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  return TranscriptRepositoryImpl(database, TranscriptsDao(database));
}
