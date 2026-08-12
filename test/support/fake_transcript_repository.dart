import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/transcription/domain/contracts/transcript_repository.dart';
import 'package:up_req/features/transcription/domain/entities/transcript.dart';
import 'package:up_req/features/transcription/domain/entities/transcript_segment.dart';

/// Doble en memoria, indexado por (`recordingId`, `pass`) igual que el
/// índice único real `transcripts_one_per_pass`.
class FakeTranscriptRepository implements TranscriptRepository {
  final Map<String, Transcript> _byId = {};
  final Map<String, List<TranscriptSegment>> _segmentsByTranscript = {};

  @override
  Stream<Transcript?> watchByRecordingAndPass(RecordingId id, TranscriptPass pass) {
    final match = _byId.values.where(
      (t) => t.recordingId == id && t.pass == pass,
    );
    return Stream.value(match.isEmpty ? null : match.single);
  }

  @override
  Stream<List<TranscriptSegment>> watchSegments(TranscriptId id) {
    final segments = List<TranscriptSegment>.from(_segmentsByTranscript[id.value] ?? const [])
      ..sort((a, b) => a.position.compareTo(b.position));
    return Stream.value(segments);
  }

  @override
  Future<TranscriptSegment?> findSegmentById(SegmentId id) async {
    for (final segments in _segmentsByTranscript.values) {
      for (final segment in segments) {
        if (segment.id == id) return segment;
      }
    }
    return null;
  }

  @override
  Future<List<Transcript>> findPending() async {
    return _byId.values.where((t) => t.status == TranscriptStatus.pending).toList();
  }

  @override
  Future<void> upsert(Transcript transcript) async {
    _byId[transcript.id.value] = transcript;
  }

  @override
  Future<void> replaceSegments(TranscriptId id, List<TranscriptSegment> segments) async {
    _segmentsByTranscript[id.value] = List.of(segments);
  }

  @override
  Future<void> softDeleteByRecording(RecordingId id, DateTime at) async {
    _byId.removeWhere((_, t) => t.recordingId == id);
  }

  Transcript? findById(TranscriptId id) => _byId[id.value];
}
