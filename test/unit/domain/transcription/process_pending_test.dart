import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/recordings/domain/entities/recording.dart';
import 'package:up_req/features/transcription/domain/contracts/transcriber.dart';
import 'package:up_req/features/transcription/domain/entities/transcript.dart';
import 'package:up_req/features/transcription/domain/usecases/build_initial_prompt.dart';
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
  const sessionId = SessionId('session-1');
  const projectId = ProjectId('project-1');

  test('recorre findPending() y lanza la pasada definitiva de cada uno', () async {
    final recordingRepository = FakeRecordingRepository();
    final transcriptRepository = FakeTranscriptRepository();
    final modelRepository = FakeModelRepository()..available.add(TranscriptionModel.small);
    final transcriber = FakeTranscriber()
      ..segmentsToReturn = const [RawSegment(fromMs: 0, toMs: 1000, text: 'Hola')];

    for (final id in ['recording-1', 'recording-2']) {
      await recordingRepository.insert(
        Recording(
          id: RecordingId(id),
          sessionId: sessionId,
          projectId: projectId,
          filePath: 'recordings/$id.wav',
          status: RecordingStatus.stopped,
          durationMs: 5000,
          sampleRate: 16000,
          channels: 1,
          startedAt: at,
          stoppedAt: at,
          createdAt: at,
          updatedAt: at,
        ),
      );
      await transcriptRepository.upsert(
        Transcript(
          id: TranscriptId('transcript-$id'),
          recordingId: RecordingId(id),
          sessionId: sessionId,
          projectId: projectId,
          pass: TranscriptPass.finalPass,
          status: TranscriptStatus.pending,
          modelId: TranscriptionModel.small,
          createdAt: at,
          updatedAt: at,
        ),
      );
    }

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
    final useCase = ProcessPendingTranscripts(transcriptRepository, runFinalPass);

    final result = await useCase();

    expect(result, isA<Ok<int>>());
    expect((result as Ok<int>).value, 2);
    expect(
      transcriptRepository.findById(const TranscriptId('transcript-recording-1'))!.status,
      TranscriptStatus.done,
    );
    expect(
      transcriptRepository.findById(const TranscriptId('transcript-recording-2'))!.status,
      TranscriptStatus.done,
    );
  });

  test('sin pendientes, no invoca la pasada definitiva y devuelve 0', () async {
    final transcriptRepository = FakeTranscriptRepository();
    final runFinalPass = RunFinalPass(
      FakeRecordingRepository(),
      transcriptRepository,
      FakeModelRepository(),
      FakeTranscriber(),
      FakeGlossaryRepository(),
      const BuildInitialPrompt(),
      _SequentialIdGenerator(),
      Clock.fixed(at),
    );
    final useCase = ProcessPendingTranscripts(transcriptRepository, runFinalPass);

    final result = await useCase();

    expect(result, isA<Ok<int>>());
    expect((result as Ok<int>).value, 0);
  });
}
