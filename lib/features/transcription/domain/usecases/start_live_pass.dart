import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/glossary/data/glossary_repository_impl.dart';
import 'package:up_req/features/glossary/domain/entities/glossary_term.dart';
import 'package:up_req/features/glossary/domain/glossary_repository.dart';
import 'package:up_req/features/recordings/data/recording_repository_impl.dart';
import 'package:up_req/features/recordings/domain/contracts/recording_repository.dart';

import '../../data/model_repository_impl.dart';
import '../../data/whisper_transcriber.dart';
import '../contracts/model_repository.dart';
import '../contracts/transcriber.dart';
import 'build_initial_prompt.dart';

part 'start_live_pass.g.dart';

/// Pasada en vivo (FR-012). **Comprueba `ModelRepository.isAvailable`
/// primero**, igual que `RunFinalPass`: si falta el modelo `base`, devuelve
/// `ModelUnavailableFailure` y el llamador simplemente omite la pasada en
/// vivo — a diferencia de la definitiva, esto NO impide grabar (FR-012 no
/// depende de la transcripción).
final class StartLivePass {
  const StartLivePass(
    this._recordingRepository,
    this._modelRepository,
    this._transcriber,
    this._glossaryRepository,
    this._buildInitialPrompt,
  );

  final RecordingRepository _recordingRepository;
  final ModelRepository _modelRepository;
  final Transcriber _transcriber;
  final GlossaryRepository _glossaryRepository;
  final BuildInitialPrompt _buildInitialPrompt;

  static const _model = TranscriptionModel.base;

  Future<Result<LiveTranscription>> call(RecordingId recordingId, Stream<Uint8List> pcm16) async {
    if (!await _modelRepository.isAvailable(_model)) {
      return Err(
        ModelUnavailableFailure('El modelo base no está disponible; la pasada en vivo se omite.'),
      );
    }

    final recording = await _recordingRepository.findById(recordingId);
    final terms = recording == null
        ? const <GlossaryTerm>[]
        : await _glossaryRepository.watchByProject(recording.projectId).first;
    final initialPrompt = _buildInitialPrompt(terms);

    final session = await _transcriber.transcribeLive(
      pcm16: pcm16,
      model: _model,
      initialPrompt: initialPrompt.isEmpty ? null : initialPrompt,
    );
    return Ok(session);
  }
}

// keepAlive: se lee desde ActiveCaptureNotifier (T040/T083), que también es
// keepAlive. Ver start_recording.dart.
@Riverpod(keepAlive: true)
StartLivePass startLivePass(Ref ref) {
  return StartLivePass(
    ref.watch(recordingRepositoryProvider),
    ref.watch(modelRepositoryProvider),
    ref.watch(transcriberProvider),
    ref.watch(glossaryRepositoryProvider),
    ref.watch(buildInitialPromptProvider),
  );
}
