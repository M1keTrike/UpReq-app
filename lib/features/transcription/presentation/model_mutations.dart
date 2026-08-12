import 'package:riverpod/experimental/mutation.dart';
import 'package:up_req/core/domain/result.dart';

import '../domain/contracts/transcriber.dart';
import '../domain/usecases/cancel_model_download.dart';
import 'model_download_notifier.dart';

final downloadModel = Mutation<void>();
final cancelModelDownload = Mutation<void>();

/// El progreso no vive en el estado de esta `Mutation`: es dato del dominio,
/// observado por `modelSettingsProvider` vía `ModelDownloadNotifier`
/// (ui-contracts.md). Aquí solo se dispara el arranque.
Future<void> runDownloadModel(MutationTarget target, TranscriptionModel model) {
  return downloadModel.run(target, (tsx) async {
    tsx.get(modelDownloadProvider.notifier).start(model);
  });
}

Future<void> runCancelModelDownload(MutationTarget target, TranscriptionModel model) {
  return cancelModelDownload.run(target, (tsx) async {
    final result = await tsx.get(cancelModelDownloadProvider)(model);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => throw failure,
    };
  });
}
