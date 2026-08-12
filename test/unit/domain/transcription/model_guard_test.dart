import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/recordings/domain/entities/recording.dart';
import 'package:up_req/features/transcription/domain/entities/transcript.dart';
import 'package:up_req/features/transcription/domain/usecases/build_initial_prompt.dart';
import 'package:up_req/features/transcription/domain/usecases/run_final_pass.dart';

import '../../../support/fake_glossary_repository.dart';
import '../../../support/fake_model_repository.dart';
import '../../../support/fake_recording_repository.dart';
import '../../../support/fake_transcriber.dart';
import '../../../support/fake_transcript_repository.dart';

class _FixedIdGenerator implements IdGenerator {
  _FixedIdGenerator(this._id);
  final String _id;
  @override
  String generate() => _id;
}

/// Materializa el conflicto C3 de plan.md: `Transcriber` no debe invocarse
/// jamás mientras `ModelRepository.isAvailable` devuelva `false`, porque esa
/// llamada es exactamente la que dispararía la descarga implícita y
/// prohibida de `whisper_ggml`.
void main() {
  test('Transcriber no se invoca nunca cuando el modelo no está disponible', () async {
    final at = DateTime.utc(2026, 1, 1);
    const recordingId = RecordingId('recording-1');

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
    final modelRepository = FakeModelRepository(); // vacío: ningún modelo disponible
    final transcriber = FakeTranscriber();

    final useCase = RunFinalPass(
      recordingRepository,
      transcriptRepository,
      modelRepository,
      transcriber,
      FakeGlossaryRepository(),
      const BuildInitialPrompt(),
      _FixedIdGenerator('transcript-1'),
      Clock.fixed(at),
    );

    final result = await useCase(recordingId);

    expect(result, isA<Ok<TranscriptId>>());
    expect(transcriber.lastRelativePath, isNull);
    expect(transcriber.lastModel, isNull);
    expect(transcriber.lastInitialPrompt, isNull);
    expect(
      transcriptRepository.findById(const TranscriptId('transcript-1'))!.status,
      TranscriptStatus.pending,
    );
  });
}
