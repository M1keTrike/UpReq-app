import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/contracts/model_repository.dart';
import '../domain/contracts/transcriber.dart';
import 'model_download_client.dart';
import 'whisper_transcriber.dart';

part 'model_repository_impl.g.dart';

/// Disponibilidad y descarga del modelo (T102). **Reemplaza** el
/// `UnavailableModelRepository` placeholder que T079/T080 (US4) dejaron en
/// este mismo archivo. La disponibilidad se resuelve comprobando en disco
/// la misma ruta que usaría `whisper_ggml` (`whisperModelPath`,
/// `whisper_transcriber.dart`): es la barrera de research.md, conflicto C3
/// — todo camino hacia `Transcriber` pasa antes por aquí, y nunca se llama
/// a `WhisperController.downloadModel()`.
class ModelRepositoryImpl implements ModelRepository {
  ModelRepositoryImpl(this._downloadClient, {Future<String> Function(TranscriptionModel model)? resolvePath})
      : _resolvePath = resolvePath ?? whisperModelPath;

  final ModelDownloadClient _downloadClient;
  final Future<String> Function(TranscriptionModel model) _resolvePath;

  @override
  Future<bool> isAvailable(TranscriptionModel model) async {
    final path = await _resolvePath(model);
    return File(path).existsSync();
  }

  @override
  Stream<DownloadProgress> download(TranscriptionModel model) => _downloadClient.download(model);

  @override
  Future<void> cancelDownload(TranscriptionModel model) async {
    _downloadClient.cancel(model);
  }
}

@Riverpod(keepAlive: true)
ModelRepository modelRepository(Ref ref) => ModelRepositoryImpl(ModelDownloadClient());
