import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/contracts/model_repository.dart';
import '../domain/contracts/transcriber.dart';

part 'model_repository_impl.g.dart';

/// PLACEHOLDER TEMPORAL: T102 (US6, Fase 8) reemplaza esta clase por la
/// implementación real sobre `dio`, resolviendo la ruta con
/// `WhisperController.getPath(model)`. Hasta entonces ningún modelo está
/// disponible nunca, así que `RunFinalPass` (US4) dejará toda transcripción
/// en `pending` (FR-016) en vez de fallar o lanzar — es exactamente el
/// comportamiento correcto de un incremento donde US4 está completa y US6
/// todavía no, y mantiene intacta la barrera del modelo (research.md,
/// conflicto C3): `Transcriber` sigue sin invocarse jamás desde aquí.
class UnavailableModelRepository implements ModelRepository {
  @override
  Future<bool> isAvailable(TranscriptionModel model) async => false;

  @override
  Stream<DownloadProgress> download(TranscriptionModel model) {
    return Stream.value(
      const DownloadProgress(receivedBytes: 0, state: DownloadState.failed),
    );
  }

  @override
  Future<void> cancelDownload(TranscriptionModel model) async {}
}

@Riverpod(keepAlive: true)
ModelRepository modelRepository(Ref ref) => UnavailableModelRepository();
