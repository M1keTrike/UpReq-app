import '../contracts/transcriber.dart';

/// Estado del modelo en la pantalla de ajustes (ui-contracts.md, pantalla
/// 5). No se persiste en ninguna tabla: `notDownloaded`/`available` derivan
/// de si el archivo existe en disco (`ModelRepository.isAvailable`);
/// `downloading`/`failed` son puramente de sesión, mientras dura una
/// descarga activa (`model_download_notifier.dart`).
enum ModelStatus { notDownloaded, downloading, available, failed }

/// Entrada de la lista de modelos de la pantalla de ajustes. Inmutable.
final class ModelEntry {
  const ModelEntry({
    required this.model,
    required this.label,
    required this.status,
    this.progress,
    this.sizeBytes,
  });

  final TranscriptionModel model;

  /// "En vivo" | "Definitiva".
  final String label;
  final ModelStatus status;

  /// 0..1; nulo si el servidor no informa `Content-Length` o si no hay
  /// descarga en curso. Nunca se inventa un porcentaje (T099).
  final double? progress;
  final int? sizeBytes;

  @override
  bool operator ==(Object other) =>
      other is ModelEntry &&
      other.model == model &&
      other.label == label &&
      other.status == status &&
      other.progress == progress &&
      other.sizeBytes == sizeBytes;

  @override
  int get hashCode => Object.hash(model, label, status, progress, sizeBytes);

  @override
  String toString() => 'ModelEntry($model, $status, progress: $progress)';
}
