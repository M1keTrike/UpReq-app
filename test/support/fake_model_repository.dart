import 'dart:async';

import 'package:up_req/features/transcription/domain/contracts/model_repository.dart';
import 'package:up_req/features/transcription/domain/contracts/transcriber.dart';

/// Doble controlable desde la prueba: nunca abre una conexión de red real
/// (T026). `available` empieza en vacío: todo modelo falta hasta que la
/// prueba lo declare disponible, que es el estado por defecto real de una
/// instalación nueva.
class FakeModelRepository implements ModelRepository {
  final Set<TranscriptionModel> available = {};
  final List<DownloadProgress> progressToEmit = [];
  bool cancelled = false;
  TranscriptionModel? lastCancelledModel;

  @override
  Future<bool> isAvailable(TranscriptionModel model) async => available.contains(model);

  @override
  Stream<DownloadProgress> download(TranscriptionModel model) {
    return Stream.fromIterable(progressToEmit).map((p) {
      if (p.state == DownloadState.done) available.add(model);
      return p;
    });
  }

  @override
  Future<void> cancelDownload(TranscriptionModel model) async {
    cancelled = true;
    lastCancelledModel = model;
  }
}
