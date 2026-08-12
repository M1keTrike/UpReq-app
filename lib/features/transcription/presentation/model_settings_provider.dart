import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/transcript_repository_impl.dart';
import '../domain/contracts/model_repository.dart';
import '../domain/contracts/transcriber.dart';
import '../domain/entities/model_entry.dart';
import '../domain/usecases/watch_model_status.dart';
import 'model_download_notifier.dart';

part 'model_settings_provider.g.dart';

const _modelLabels = {
  TranscriptionModel.base: 'En vivo',
  TranscriptionModel.small: 'Definitiva',
};

/// `modelSettingsProvider` de ui-contracts.md, pantalla 5.
final class ModelSettingsState {
  const ModelSettingsState({required this.models, required this.pendingTranscripts});

  final List<ModelEntry> models;

  /// Transcripciones esperando modelo (FR-016). Llegar a cero tras una
  /// descarga es la confirmación de que `ProcessPendingTranscripts` corrió.
  final int pendingTranscripts;
}

@riverpod
Stream<ModelSettingsState> modelSettings(Ref ref) {
  final watchModelStatus = ref.watch(watchModelStatusProvider);
  final transcriptRepository = ref.watch(transcriptRepositoryProvider);
  // Snapshot deliberado del notifier de descarga, igual que
  // `sessionCaptureProvider` con `activeCaptureProvider`: cuando el
  // progreso cambia, esta función se reejecuta entera y el stream combinado
  // se resuscribe con el valor fresco.
  final downloads = ref.watch(modelDownloadProvider);

  return watchModelStatus().asyncMap((availability) async {
    final pending = await transcriptRepository.findPending();
    return ModelSettingsState(
      models: [
        for (final model in TranscriptionModel.values)
          _toEntry(model, availability[model] ?? ModelStatus.notDownloaded, downloads[model]),
      ],
      pendingTranscripts: pending.length,
    );
  });
}

ModelEntry _toEntry(TranscriptionModel model, ModelStatus baseStatus, DownloadProgress? progress) {
  final status = switch (progress?.state) {
    DownloadState.downloading => ModelStatus.downloading,
    DownloadState.failed => ModelStatus.failed,
    _ => baseStatus,
  };
  final total = progress?.totalBytes;
  // Sin Content-Length el servidor no informa `total`: progreso nulo, nunca
  // un porcentaje inventado (T099).
  final ratio = status == ModelStatus.downloading && total != null && total > 0
      ? progress!.receivedBytes / total
      : null;
  return ModelEntry(model: model, label: _modelLabels[model]!, status: status, progress: ratio, sizeBytes: total);
}
