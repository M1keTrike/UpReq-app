import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/contracts/model_repository.dart';
import '../domain/contracts/transcriber.dart';
import '../domain/usecases/download_model.dart';

part 'model_download_notifier.g.dart';

/// Progreso de descarga por modelo, observado por `modelSettingsProvider`
/// (ui-contracts.md: "`progress` ... se observa por stream del
/// repositorio, no por la mutación"). `keepAlive`: si el analista sale de
/// ajustes a media descarga —`small` pesa cientos de MB (research.md)— la
/// descarga no debe morir por eso, mismo criterio que
/// `ActiveCaptureNotifier`.
@Riverpod(keepAlive: true)
class ModelDownloadNotifier extends _$ModelDownloadNotifier {
  final _subscriptions = <TranscriptionModel, StreamSubscription<DownloadProgress>>{};

  @override
  Map<TranscriptionModel, DownloadProgress> build() {
    ref.onDispose(() {
      for (final subscription in _subscriptions.values) {
        subscription.cancel();
      }
    });
    return const {};
  }

  /// No hace nada si ya hay una descarga en curso para [model]: evita una
  /// segunda suscripción concurrente al mismo `download()`.
  void start(TranscriptionModel model) {
    if (_subscriptions.containsKey(model)) return;
    final downloadModel = ref.read(downloadModelProvider);
    _subscriptions[model] = downloadModel(model).listen(
      (progress) => state = {...state, model: progress},
      onDone: () => _subscriptions.remove(model),
    );
  }
}
