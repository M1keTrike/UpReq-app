import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/recordings/domain/usecases/watch_active_segment.dart';
import 'package:up_req/features/transcription/domain/contracts/transcriber.dart';
import 'package:up_req/features/transcription/domain/entities/transcript.dart';
import 'package:up_req/features/transcription/domain/entities/transcript_segment.dart';

import '../../../support/fake_audio_playback.dart';
import '../../../support/fake_transcript_repository.dart';

final _at = DateTime.utc(2026, 1, 1);
const _recordingId = RecordingId('recording-1');
const _transcriptId = TranscriptId('transcript-1');

void main() {
  test('cruza la posición del reproductor con las ventanas y devuelve null fuera de todo segmento', () async {
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
        fromMs: 0,
        toMs: 2000,
        position: 0,
        text: 'Hola',
        createdAt: _at,
        updatedAt: _at,
      ),
      TranscriptSegment(
        id: const SegmentId('segment-2'),
        transcriptId: _transcriptId,
        recordingId: _recordingId,
        sessionId: const SessionId('session-1'),
        projectId: const ProjectId('project-1'),
        fromMs: 2000,
        toMs: 4000,
        position: 1,
        text: 'Adiós',
        createdAt: _at,
        updatedAt: _at,
      ),
    ]);
    final playback = FakeAudioPlayback();

    final useCase = WatchActiveSegment(transcriptRepository, playback);
    final values = <SegmentId?>[];
    final subscription = useCase(_transcriptId).listen(values.add);

    playback.emitPosition(const Duration(milliseconds: 500));
    await Future<void>.delayed(Duration.zero);
    playback.emitPosition(const Duration(milliseconds: 2500));
    await Future<void>.delayed(Duration.zero);
    playback.emitPosition(const Duration(milliseconds: 5000));
    await Future<void>.delayed(Duration.zero);

    await subscription.cancel();

    expect(values, [
      const SegmentId('segment-1'),
      const SegmentId('segment-2'),
      null,
    ]);
  });
}
