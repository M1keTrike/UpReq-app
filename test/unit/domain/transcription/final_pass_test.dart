import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/recordings/domain/entities/recording.dart';
import 'package:up_req/features/transcription/domain/contracts/transcriber.dart';
import 'package:up_req/features/transcription/domain/entities/transcript.dart';
import 'package:up_req/features/transcription/domain/usecases/build_initial_prompt.dart';
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
  const recordingId = RecordingId('recording-1');

  late FakeRecordingRepository recordingRepository;
  late FakeTranscriptRepository transcriptRepository;
  late FakeModelRepository modelRepository;
  late FakeTranscriber transcriber;
  late FakeGlossaryRepository glossaryRepository;

  RunFinalPass build({Clock? clock}) {
    return RunFinalPass(
      recordingRepository,
      transcriptRepository,
      modelRepository,
      transcriber,
      glossaryRepository,
      const BuildInitialPrompt(),
      _SequentialIdGenerator(),
      clock ?? Clock.fixed(at),
    );
  }

  setUp(() async {
    recordingRepository = FakeRecordingRepository();
    transcriptRepository = FakeTranscriptRepository();
    modelRepository = FakeModelRepository();
    transcriber = FakeTranscriber();
    glossaryRepository = FakeGlossaryRepository();

    await recordingRepository.insert(
      Recording(
        id: recordingId,
        sessionId: sessionId,
        projectId: projectId,
        filePath: 'recordings/recording-1.wav',
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
  });

  test('sin modelo disponible devuelve Ok con el Transcript en pending (FR-016)', () async {
    final useCase = build();
    final result = await useCase(recordingId);

    expect(result, isA<Ok<TranscriptId>>());
    final id = (result as Ok<TranscriptId>).value;
    final stored = transcriptRepository.findById(id)!;
    expect(stored.status, TranscriptStatus.pending);
    expect(transcriber.lastRelativePath, isNull, reason: 'el transcriptor no debe invocarse');
  });

  test('con modelo disponible pasa a processing y termina en done con segmentos', () async {
    modelRepository.available.add(TranscriptionModel.small);
    transcriber.segmentsToReturn = const [
      RawSegment(fromMs: 0, toMs: 1000, text: 'Hola'),
      RawSegment(fromMs: 1000, toMs: 2500, text: 'buenas tardes'),
    ];

    final useCase = build();
    final result = await useCase(recordingId);

    expect(result, isA<Ok<TranscriptId>>());
    final id = (result as Ok<TranscriptId>).value;
    final stored = transcriptRepository.findById(id)!;
    expect(stored.status, TranscriptStatus.done);
    expect(stored.text, 'Hola buenas tardes');
    expect(stored.completedAt, isNotNull);
    expect(transcriber.lastRelativePath, 'recordings/recording-1.wav');
    expect(transcriber.lastModel, TranscriptionModel.small);
  });

  test('un fallo del transcriptor deja failed con failure_reason', () async {
    modelRepository.available.add(TranscriptionModel.small);
    transcriber.errorToThrow = Exception('motor nativo caído');

    final useCase = build();
    final result = await useCase(recordingId);

    expect(result, isA<Err<TranscriptId>>());
    final stored = transcriptRepository.findById(const TranscriptId('id-0'))!;
    expect(stored.status, TranscriptStatus.failed);
    expect(stored.failureReason, isNotNull);
  });
}
