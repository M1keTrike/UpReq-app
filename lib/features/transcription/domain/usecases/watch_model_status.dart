import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/model_repository_impl.dart';
import '../contracts/model_repository.dart';
import '../contracts/transcriber.dart';
import '../entities/model_entry.dart';

part 'watch_model_status.g.dart';

/// FR-020: disponibilidad de cada modelo para la pantalla de ajustes.
/// Snapshot único por llamada: `ModelRepository.isAvailable` comprueba un
/// archivo en disco y no es reactivo por sí solo. `modelSettingsProvider`
/// vuelve a invocar este caso de uso cada vez que el notifier de descarga
/// cambia de estado, que es el único evento que puede alterar la
/// disponibilidad.
final class WatchModelStatus {
  const WatchModelStatus(this._repository);

  final ModelRepository _repository;

  Stream<Map<TranscriptionModel, ModelStatus>> call() async* {
    final result = <TranscriptionModel, ModelStatus>{};
    for (final model in TranscriptionModel.values) {
      result[model] = await _repository.isAvailable(model) ? ModelStatus.available : ModelStatus.notDownloaded;
    }
    yield result;
  }
}

@riverpod
WatchModelStatus watchModelStatus(Ref ref) => WatchModelStatus(ref.watch(modelRepositoryProvider));
