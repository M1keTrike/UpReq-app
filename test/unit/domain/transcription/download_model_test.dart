import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/recordings/domain/entities/recording.dart';
import 'package:up_req/features/transcription/domain/contracts/model_repository.dart';
import 'package:up_req/features/transcription/domain/contracts/transcriber.dart';
import 'package:up_req/features/transcription/domain/entities/transcript.dart';
import 'package:up_req/features/transcription/domain/usecases/build_initial_prompt.dart';
import 'package:up_req/features/transcription/domain/usecases/download_model.dart';
import 'package:up_req/features/transcription/domain/usecases/process_pending_transcripts.dart';
import 'package:up_req/features/transcription/domain/usecases/run_final_pass.dart';

import '../../../support/fake_glossary_repository.dart';
import '../../../support/fake_model_repository.dart';
import '../../../support/fake_recording_repository.dart';
import '../../../support/fake_transcriber.dart';
import '../../../support/fake_transcript_repository.dart';

class _SequentialIdGenerator implements IdGenerator {
  int _next = 0;
  @override
  String generate() => 'id-${_next++}';
}

void main() {
  final at = DateTime.utc(2026, 1, 1);
  const recordingId = RecordingId('recording-1');
  const transcriptId = TranscriptId('transcript-1');

  test('emite progreso, y al completar dispara ProcessPendingTranscripts', () async {
    final recordingRepository = FakeRecordingRepository()
      ..store['recording-1'] = Recording(
        id: recordingId,
        sessionId: const SessionId('session-1'),
        projectId: const ProjectId('project-1'),
        filePath: 'recordings/recording-1.wav',
        status: RecordingStatus.stopped,
        durationMs: 5000,
        sampleRate: 16000,
        channels: 1,
        startedAt: at,
        stoppedAt: at,
        createdAt: at,
        updatedAt: at,
      );
    final transcriptRepository = FakeTranscriptRepository();
    await transcriptRepository.upsert(
      Transcript(
        id: transcriptId,
        recordingId: recordingId,
        sessionId: const SessionId('session-1'),
        projectId: const ProjectId('project-1'),
        pass: TranscriptPass.finalPass,
        status: TranscriptStatus.pending,
        modelId: TranscriptionModel.small,
        createdAt: at,
        updatedAt: at,
      ),
    );
    final transcriber = FakeTranscriber()
      ..segmentsToReturn = const [RawSegment(fromMs: 0, toMs: 1000, text: 'Hola')];

    final modelRepository = FakeModelRepository()
      ..progressToEmit.addAll(const [
        DownloadProgress(receivedBytes: 50, totalBytes: 100, state: DownloadState.downloading),
        DownloadProgress(receivedBytes: 100, totalBytes: 100, state: DownloadState.done),
      ]);

    final runFinalPass = RunFinalPass(
      recordingRepository,
      transcriptRepository,
      modelRepository,
      transcriber,
      FakeGlossaryRepository(),
      const BuildInitialPrompt(),
      _SequentialIdGenerator(),
      Clock.fixed(at),
    );
    final processPending = ProcessPendingTranscripts(transcriptRepository, runFinalPass);
    final useCase = DownloadModel(modelRepository, processPending);

    final emitted = await useCase(TranscriptionModel.small).toList();

    expect(emitted.map((p) => p.state), [DownloadState.downloading, DownloadState.done]);
    // ProcessPendingTranscripts corrió tras el `done`: la transcripción que
    // estaba pending ahora refleja el resultado de la pasada definitiva.
    expect(transcriptRepository.findById(transcriptId)!.status, TranscriptStatus.done);
    expect(transcriber.lastRelativePath, 'recordings/recording-1.wav');
  });
}
