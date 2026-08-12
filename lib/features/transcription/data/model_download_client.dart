import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart' as pkg;

import '../domain/contracts/model_repository.dart';
import '../domain/contracts/transcriber.dart';
import 'whisper_transcriber.dart';

/// Cliente de descarga del modelo GGML. ÚNICO importador de `package:dio`
/// en todo el árbol, verificado por tool/check_no_network_deps.dart.
///
/// Descarga a `<ruta>.part` y renombra de forma atómica al completar.
/// `deleteOnError` (activo por defecto en `Dio.download`) ya borra el
/// `.part` tanto en un fallo de red como en una cancelación — lo verifica
/// dio internamente sobre la propia escritura a disco, no algo que este
/// cliente deba reimplementar — así que una descarga cancelada o fallida
/// nunca deja un modelo a medias, y reintentar simplemente empieza de cero
/// sobre el mismo `.part` (FR-022).
///
/// [resolvePath] y [resolveUrl] son inyectables (por defecto
/// [whisperModelPath] y [whisperModelDownloadUrl]) para que las pruebas
/// puedan apuntar a un directorio temporal sin tocar `path_provider` ni la
/// red real.
class ModelDownloadClient {
  ModelDownloadClient({
    pkg.Dio? dio,
    Future<String> Function(TranscriptionModel model)? resolvePath,
    Uri Function(TranscriptionModel model)? resolveUrl,
  })  : _dio = dio ?? pkg.Dio(),
        _resolvePath = resolvePath ?? whisperModelPath,
        _resolveUrl = resolveUrl ?? whisperModelDownloadUrl;

  final pkg.Dio _dio;
  final Future<String> Function(TranscriptionModel model) _resolvePath;
  final Uri Function(TranscriptionModel model) _resolveUrl;
  final _cancelTokens = <TranscriptionModel, pkg.CancelToken>{};

  Stream<DownloadProgress> download(TranscriptionModel model) {
    final controller = StreamController<DownloadProgress>();
    unawaited(_run(model, controller));
    return controller.stream;
  }

  Future<void> _run(TranscriptionModel model, StreamController<DownloadProgress> controller) async {
    final destinationPath = await _resolvePath(model);
    final partPath = '$destinationPath.part';
    final cancelToken = pkg.CancelToken();
    _cancelTokens[model] = cancelToken;

    controller.add(const DownloadProgress(receivedBytes: 0, state: DownloadState.downloading));
    try {
      await _dio.downloadUri(
        _resolveUrl(model),
        partPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          controller.add(
            DownloadProgress(
              receivedBytes: received,
              totalBytes: total > 0 ? total : null,
              state: DownloadState.downloading,
            ),
          );
        },
      );
      await File(partPath).rename(destinationPath);
      final finalSize = await File(destinationPath).length();
      controller.add(DownloadProgress(receivedBytes: finalSize, totalBytes: finalSize, state: DownloadState.done));
    } on pkg.DioException catch (error) {
      final cancelled = error.type == pkg.DioExceptionType.cancel;
      controller.add(
        DownloadProgress(
          receivedBytes: 0,
          state: cancelled ? DownloadState.cancelled : DownloadState.failed,
        ),
      );
    } finally {
      _cancelTokens.remove(model);
      await controller.close();
    }
  }

  /// FR-022: cancela la descarga en curso de [model], si la hay. Es un
  /// no-op si ya terminó o nunca empezó.
  void cancel(TranscriptionModel model) {
    _cancelTokens[model]?.cancel();
  }
}
