import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/recordings/domain/entities/recording.dart';
import 'package:up_req/features/transcription/domain/contracts/transcriber.dart';
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
  test(
    'una sesión con dos grabaciones produce dos transcripciones independientes, '
    'cada una con sus propios segmentos (FR-003a)',
    () async {
      final at = DateTime.utc(2026, 1, 1);
      const sessionId = SessionId('session-1');
      const projectId = ProjectId('project-1');
      const recordingA = RecordingId('recording-a');
      const recordingB = RecordingId('recording-b');

      final recordingRepository = FakeRecordingRepository();
      await recordingRepository.insert(
        Recording(
          id: recordingA,
          sessionId: sessionId,
          projectId: projectId,
          filePath: 'recordings/recording-a.wav',
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
      await recordingRepository.insert(
        Recording(
          id: recordingB,
          sessionId: sessionId,
          projectId: projectId,
          filePath: 'recordings/recording-b.wav',
          status: RecordingStatus.stopped,
          durationMs: 7000,
          sampleRate: 16000,
          channels: 1,
          startedAt: at,
          stoppedAt: at,
          createdAt: at,
          updatedAt: at,
        ),
      );

      final transcriptRepository = FakeTranscriptRepository();
      final modelRepository = FakeModelRepository()..available.add(TranscriptionModel.small);
      final transcriber = FakeTranscriber();
      final idGenerator = _SequentialIdGenerator();

      RunFinalPass build() {
        return RunFinalPass(
          recordingRepository,
          transcriptRepository,
          modelRepository,
          transcriber,
          FakeGlossaryRepository(),
          const BuildInitialPrompt(),
          idGenerator,
          Clock.fixed(at),
        );
      }

      transcriber.segmentsToReturn = const [
        RawSegment(fromMs: 0, toMs: 1000, text: 'primera grabación'),
      ];
      final resultA = await build()(recordingA);

      transcriber.segmentsToReturn = const [
        RawSegment(fromMs: 0, toMs: 500, text: 'segunda grabación, primer segmento'),
        RawSegment(fromMs: 500, toMs: 1200, text: 'segunda grabación, segundo segmento'),
      ];
      final resultB = await build()(recordingB);

      expect(resultA, isA<Ok<TranscriptId>>());
      expect(resultB, isA<Ok<TranscriptId>>());
      final idA = (resultA as Ok<TranscriptId>).value;
      final idB = (resultB as Ok<TranscriptId>).value;
      expect(idA, isNot(idB));

      final transcriptA = transcriptRepository.findById(idA)!;
      final transcriptB = transcriptRepository.findById(idB)!;
      expect(transcriptA.recordingId, recordingA);
      expect(transcriptB.recordingId, recordingB);
      expect(transcriptA.text, 'primera grabación');
      expect(transcriptB.text, 'segunda grabación, primer segmento segunda grabación, segundo segmento');

      final segmentsA = await transcriptRepository.watchSegments(idA).first;
      final segmentsB = await transcriptRepository.watchSegments(idB).first;
      expect(segmentsA, hasLength(1));
      expect(segmentsB, hasLength(2));
      expect(segmentsA.every((s) => s.recordingId == recordingA), isTrue);
      expect(segmentsB.every((s) => s.recordingId == recordingB), isTrue);
      // Las marcas de tiempo de B no contaminan a A: cada una arranca en 0
      // relativa a SU propia grabación.
      expect(segmentsA.first.fromMs, 0);
      expect(segmentsB.first.fromMs, 0);
    },
  );
}
