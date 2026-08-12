import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/transcription/domain/contracts/transcriber.dart';
import 'package:up_req/features/transcription/domain/segment_mapping.dart';

void main() {
  final at = DateTime.utc(2026, 1, 1);

  test('position es contigua 0..n-1 y from_ms/to_ms pasan tal cual (S1, S2)', () {
    final raw = [
      const RawSegment(fromMs: 0, toMs: 1200, text: 'Hola'),
      const RawSegment(fromMs: 1200, toMs: 2500, text: 'buenas tardes'),
      const RawSegment(fromMs: 2500, toMs: 4000, text: 'gracias por venir'),
    ];

    final segments = mapRawSegments(
      raw: raw,
      ids: const [SegmentId('seg-0'), SegmentId('seg-1'), SegmentId('seg-2')],
      transcriptId: const TranscriptId('transcript-1'),
      recordingId: const RecordingId('recording-1'),
      sessionId: const SessionId('session-1'),
      projectId: const ProjectId('project-1'),
      now: at,
    );

    expect(segments.map((s) => s.position), [0, 1, 2]);
    for (var i = 0; i < segments.length; i++) {
      expect(segments[i].fromMs, raw[i].fromMs);
      expect(segments[i].toMs, raw[i].toMs);
      expect(segments[i].text, raw[i].text);
      expect(segments[i].fromMs, lessThan(segments[i].toMs));
    }
  });

  test('sin solapes: cada segmento termina donde empieza el siguiente o antes', () {
    final raw = [
      const RawSegment(fromMs: 0, toMs: 1000, text: 'a'),
      const RawSegment(fromMs: 1000, toMs: 2000, text: 'b'),
    ];

    final segments = mapRawSegments(
      raw: raw,
      ids: const [SegmentId('seg-0'), SegmentId('seg-1')],
      transcriptId: const TranscriptId('transcript-1'),
      recordingId: const RecordingId('recording-1'),
      sessionId: const SessionId('session-1'),
      projectId: const ProjectId('project-1'),
      now: at,
    );

    expect(segments[0].toMs, lessThanOrEqualTo(segments[1].fromMs));
  });

  test('lista vacía produce lista vacía', () {
    final segments = mapRawSegments(
      raw: const [],
      ids: const [],
      transcriptId: const TranscriptId('transcript-1'),
      recordingId: const RecordingId('recording-1'),
      sessionId: const SessionId('session-1'),
      projectId: const ProjectId('project-1'),
      now: at,
    );

    expect(segments, isEmpty);
  });
}
