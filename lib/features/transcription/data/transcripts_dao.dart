import 'package:drift/drift.dart';
import 'package:up_req/core/database/app_database.dart';
import 'package:up_req/core/database/tables/transcript_segments.dart';
import 'package:up_req/core/database/tables/transcripts.dart';

part 'transcripts_dao.g.dart';

@DriftAccessor(tables: [Transcripts, TranscriptSegments])
class TranscriptsDao extends DatabaseAccessor<AppDatabase> with _$TranscriptsDaoMixin {
  TranscriptsDao(super.db);

  /// Invariante T1: como máximo un `transcript` no borrado por par
  /// (`recording_id`, `pass`), garantizado por el índice único
  /// `transcripts_one_per_pass`.
  Stream<Transcript?> watchByRecordingAndPass(String recordingId, String pass) {
    final query = select(transcripts)
      ..where((t) => t.recordingId.equals(recordingId) & t.pass.equals(pass) & t.deletedAt.isNull());
    return query.watchSingleOrNull();
  }

  Stream<List<TranscriptSegment>> watchSegments(String transcriptId) {
    final query = select(transcriptSegments)
      ..where((s) => s.transcriptId.equals(transcriptId) & s.deletedAt.isNull())
      ..orderBy([(s) => OrderingTerm(expression: s.position)]);
    return query.watch();
  }

  Future<TranscriptSegment?> findSegmentById(String id) {
    final query = select(transcriptSegments)
      ..where((s) => s.id.equals(id) & s.deletedAt.isNull());
    return query.getSingleOrNull();
  }

  /// Cola de FR-016.
  Future<List<Transcript>> findPending() {
    final query = select(transcripts)
      ..where((t) => t.status.equals('pending') & t.deletedAt.isNull());
    return query.get();
  }

  Future<void> upsertTranscript(TranscriptsCompanion companion) {
    return into(transcripts).insertOnConflictUpdate(companion);
  }

  /// Reemplaza los segmentos de una transcripción en una sola transacción:
  /// los anteriores se retiran físicamente porque son artefactos de una
  /// pasada de procesamiento todavía no cerrada, no evidencia ya expuesta al
  /// analista (FR-023 no exige bitácora para segmentos).
  Future<void> replaceSegments(String transcriptId, List<TranscriptSegmentsCompanion> segments) async {
    await transaction(() async {
      await (delete(transcriptSegments)..where((s) => s.transcriptId.equals(transcriptId))).go();
      if (segments.isNotEmpty) {
        await batch((b) => b.insertAll(transcriptSegments, segments));
      }
    });
  }
}
