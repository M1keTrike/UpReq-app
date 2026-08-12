import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/model_repository_impl.dart';
import '../contracts/model_repository.dart';
import '../contracts/transcriber.dart';
import 'process_pending_transcripts.dart';

part 'download_model.g.dart';

/// FR-020: descarga iniciada manualmente desde ajustes, con progreso real.
/// Al completar dispara `ProcessPendingTranscripts`: es lo que resuelve la
/// cola de FR-016 sin que el analista tenga que volver a cerrar cada sesión.
final class DownloadModel {
  const DownloadModel(this._repository, this._processPending);

  final ModelRepository _repository;
  final ProcessPendingTranscripts _processPending;

  Stream<DownloadProgress> call(TranscriptionModel model) async* {
    await for (final progress in _repository.download(model)) {
      yield progress;
      if (progress.state == DownloadState.done) {
        await _processPending();
      }
    }
  }
}

// keepAlive: se lee desde ModelDownloadNotifier (presentation, keepAlive) —
// la descarga debe sobrevivir a la navegación fuera de ajustes.
@Riverpod(keepAlive: true)
DownloadModel downloadModel(Ref ref) {
  return DownloadModel(ref.watch(modelRepositoryProvider), ref.watch(processPendingTranscriptsProvider));
}
