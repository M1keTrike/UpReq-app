import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/recordings/domain/usecases/seek_to_segment.dart';
import 'package:up_req/features/transcription/domain/contracts/transcriber.dart';
import 'package:up_req/features/transcription/domain/entities/transcript.dart';
import 'package:up_req/features/transcription/domain/entities/transcript_segment.dart';

import '../../../support/fake_audio_playback.dart';
import '../../../support/fake_transcript_repository.dart';

final _at = DateTime.utc(2026, 1, 1);
const _recordingId = RecordingId('recording-1');
const _transcriptId = TranscriptId('transcript-1');

void main() {
  group('SeekToSegment', () {
    test('resuelve from_ms del segmento y salta a esa posición', () async {
      final transcriptRepository = FakeTranscriptRepository();
      await transcriptRepository.upsert(
        Transcript(
          id: _transcriptId,
          recordingId: _recordingId,
          sessionId: const SessionId('session-1'),
          projectId: const ProjectId('project-1'),
          pass: TranscriptPass.finalPass,
          status: TranscriptStatus.done,
          modelId: TranscriptionModel.small,
          completedAt: _at,
          createdAt: _at,
          updatedAt: _at,
        ),
      );
      await transcriptRepository.replaceSegments(_transcriptId, [
        TranscriptSegment(
          id: const SegmentId('segment-1'),
          transcriptId: _transcriptId,
          recordingId: _recordingId,
          sessionId: const SessionId('session-1'),
          projectId: const ProjectId('project-1'),
          fromMs: 4200,
          toMs: 5300,
          position: 0,
          text: 'Hola',
          createdAt: _at,
          updatedAt: _at,
        ),
      ]);
      final playback = FakeAudioPlayback();

      final useCase = SeekToSegment(transcriptRepository, playback);
      final result = await useCase(const SegmentId('segment-1'));

      expect(result, isA<Ok<void>>());
      expect(playback.lastSeek, const Duration(milliseconds: 4200));
    });

    test('rechaza con NotFoundFailure si el segmento no existe', () async {
      final useCase = SeekToSegment(FakeTranscriptRepository(), FakeAudioPlayback());

      final result = await useCase(const SegmentId('missing'));

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<NotFoundFailure>());
    });
  });
}
