import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/transcription/domain/entities/transcript_segment.dart';

void main() {
  final at = DateTime.utc(2026, 1, 1);

  TranscriptSegment build({String text = 'Hola'}) {
    return TranscriptSegment(
      id: const SegmentId('segment-1'),
      transcriptId: const TranscriptId('transcript-1'),
      recordingId: const RecordingId('recording-1'),
      sessionId: const SessionId('session-1'),
      projectId: const ProjectId('project-1'),
      fromMs: 0,
      toMs: 1000,
      position: 0,
      text: text,
      createdAt: at,
      updatedAt: at,
    );
  }

  test('dos segmentos con los mismos campos son iguales y comparten hashCode', () {
    final a = build();
    final b = build();

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('difieren si el texto difiere', () {
    expect(build(), isNot(build(text: 'Adiós')));
  });

  test('toString incluye id, posición y ventana temporal', () {
    expect(build().toString(), 'TranscriptSegment(segment-1, 0, 0ms-1000ms)');
  });
}
