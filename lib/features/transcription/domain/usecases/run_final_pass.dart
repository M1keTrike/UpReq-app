import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/glossary/data/glossary_repository_impl.dart';
import 'package:up_req/features/glossary/domain/glossary_repository.dart';
import 'package:up_req/features/recordings/data/recording_repository_impl.dart';
import 'package:up_req/features/recordings/domain/contracts/recording_repository.dart';

import '../../data/model_repository_impl.dart';
import '../../data/transcript_repository_impl.dart';
import '../../data/whisper_transcriber.dart';
import '../contracts/model_repository.dart';
import '../contracts/transcriber.dart';
import '../contracts/transcript_repository.dart';
import '../entities/transcript.dart';
import '../segment_mapping.dart';
import 'build_initial_prompt.dart';

part 'run_final_pass.g.dart';

/// Pasada definitiva al cerrar la sesión (FR-013). **Comprueba
/// `ModelRepository.isAvailable` antes de tocar el transcriptor**: si falta
/// el modelo, deja el `Transcript` en `pending` y termina en `Ok`, no en
/// `Err` (FR-016) — es la barrera que impide que `whisper_ggml` dispare su
/// descarga automática (research.md, conflicto C3).
final class RunFinalPass {
  const RunFinalPass(
    this._recordingRepository,
    this._transcriptRepository,
    this._modelRepository,
    this._transcriber,
    this._glossaryRepository,
    this._buildInitialPrompt,
    this._idGenerator,
    this._clock,
  );

  final RecordingRepository _recordingRepository;
  final TranscriptRepository _transcriptRepository;
  final ModelRepository _modelRepository;
  final Transcriber _transcriber;
  final GlossaryRepository _glossaryRepository;
  final BuildInitialPrompt _buildInitialPrompt;
  final IdGenerator _idGenerator;
  final Clock _clock;

  static const _model = TranscriptionModel.small;

  Future<Result<TranscriptId>> call(RecordingId recordingId) async {
    final recording = await _recordingRepository.findById(recordingId);
    if (recording == null) {
      return Err(NotFoundFailure('No se encontró la grabación $recordingId.'));
    }

    final existing = await _transcriptRepository
        .watchByRecordingAndPass(recordingId, TranscriptPass.finalPass)
        .first;
    final id = existing?.id ?? TranscriptId(_idGenerator.generate());
    final now = _clock.now();

    if (!await _modelRepository.isAvailable(_model)) {
      await _transcriptRepository.upsert(
        Transcript(
          id: id,
          recordingId: recordingId,
          sessionId: recording.sessionId,
          projectId: recording.projectId,
          pass: TranscriptPass.finalPass,
          status: TranscriptStatus.pending,
          modelId: _model,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
      );
      return Ok(id);
    }

    await _transcriptRepository.upsert(
      Transcript(
        id: id,
        recordingId: recordingId,
        sessionId: recording.sessionId,
        projectId: recording.projectId,
        pass: TranscriptPass.finalPass,
        status: TranscriptStatus.processing,
        modelId: _model,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );

    final terms = await _glossaryRepository.watchByProject(recording.projectId).first;
    final initialPrompt = _buildInitialPrompt(terms);

    try {
      final raw = await _transcriber.transcribeFile(
        relativePath: recording.filePath,
        model: _model,
        initialPrompt: initialPrompt.isEmpty ? null : initialPrompt,
      );

      final segmentIds = [for (var i = 0; i < raw.length; i++) SegmentId(_idGenerator.generate())];
      final completedAt = _clock.now();
      final segments = mapRawSegments(
        raw: raw,
        ids: segmentIds,
        transcriptId: id,
        recordingId: recordingId,
        sessionId: recording.sessionId,
        projectId: recording.projectId,
        now: completedAt,
      );

      await _transcriptRepository.replaceSegments(id, segments);
      await _transcriptRepository.upsert(
        Transcript(
          id: id,
          recordingId: recordingId,
          sessionId: recording.sessionId,
          projectId: recording.projectId,
          pass: TranscriptPass.finalPass,
          status: TranscriptStatus.done,
          modelId: _model,
          text: raw.map((s) => s.text).join(' '),
          completedAt: completedAt,
          createdAt: existing?.createdAt ?? now,
          updatedAt: completedAt,
        ),
      );
      return Ok(id);
    } catch (error) {
      await _transcriptRepository.upsert(
        Transcript(
          id: id,
          recordingId: recordingId,
          sessionId: recording.sessionId,
          projectId: recording.projectId,
          pass: TranscriptPass.finalPass,
          status: TranscriptStatus.failed,
          modelId: _model,
          failureReason: error.toString(),
          createdAt: existing?.createdAt ?? now,
          updatedAt: _clock.now(),
        ),
      );
      return Err(TranscriptionFailure('La transcripción falló: $error'));
    }
  }
}

@riverpod
RunFinalPass runFinalPass(Ref ref) {
  return RunFinalPass(
    ref.watch(recordingRepositoryProvider),
    ref.watch(transcriptRepositoryProvider),
    ref.watch(modelRepositoryProvider),
    ref.watch(transcriberProvider),
    ref.watch(glossaryRepositoryProvider),
    ref.watch(buildInitialPromptProvider),
    ref.watch(idGeneratorProvider),
    ref.watch(clockProvider),
  );
}
