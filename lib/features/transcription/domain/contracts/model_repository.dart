import 'transcriber.dart';

/// Disponibilidad y descarga del modelo. Implementado en data/ sobre `dio`,
/// ÚNICO importador de `dio` en todo el árbol, verificado por puerta de CI.
abstract interface class ModelRepository {
  /// Comprueba que el archivo del modelo existe en disco.
  /// Es la barrera que impide que el paquete dispare su descarga automática,
  /// prohibida por la constitución (research.md, conflicto C3). Todo camino
  /// hacia `Transcriber` pasa por aquí primero.
  Future<bool> isAvailable(TranscriptionModel model);

  /// Descarga iniciada manualmente desde ajustes. Emite progreso real.
  /// Escribe a `.part` y renombra de forma atómica al completar, de modo que
  /// una descarga interrumpida nunca deja un modelo utilizable. FR-020, FR-022.
  Stream<DownloadProgress> download(TranscriptionModel model);

  Future<void> cancelDownload(TranscriptionModel model);
}

class DownloadProgress {
  const DownloadProgress({required this.receivedBytes, this.totalBytes, required this.state});

  final int receivedBytes;
  final int? totalBytes; // nulo si el servidor no informa longitud
  final DownloadState state;
}

enum DownloadState { idle, downloading, done, failed, cancelled }
