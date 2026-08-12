/// Reparación de una cabecera WAV que quedó sin parchear por un cierre
/// inesperado. FUNCIÓN PURA sobre los tamaños: no abre micrófono ni depende
/// de plataforma, y por eso se prueba sin grabar nada (research.md, decisión
/// 4). Es lo que hace recuperable una grabación interrumpida (FR-010).
class WavHeaderRepair {
  const WavHeaderRepair._();

  static const _headerBytes = 44;
  static const _bitsPerSample = 16;

  /// Dados el tamaño real del archivo y el formato con que se grabó, devuelve
  /// los dos valores que deben escribirse en la cabecera y la duración
  /// resultante. Una trama incompleta al final (bytes sobrantes que no
  /// completan una muestra) se descarta: no es audio reproducible.
  static WavRepairPlan plan({
    required int fileLengthBytes,
    required int sampleRate,
    required int channels,
  }) {
    final blockAlign = channels * (_bitsPerSample ~/ 8);
    final rawDataBytes = fileLengthBytes > _headerBytes ? fileLengthBytes - _headerBytes : 0;
    final completeFrames = blockAlign > 0 ? rawDataBytes ~/ blockAlign : 0;
    final dataChunkSize = completeFrames * blockAlign;
    final riffChunkSize = 36 + dataChunkSize;
    final durationMs = sampleRate > 0 ? (completeFrames * 1000) ~/ sampleRate : 0;

    return WavRepairPlan(
      riffChunkSize: riffChunkSize,
      dataChunkSize: dataChunkSize,
      durationMs: durationMs,
    );
  }
}

class WavRepairPlan {
  const WavRepairPlan({
    required this.riffChunkSize,
    required this.dataChunkSize,
    required this.durationMs,
  });

  /// Offset 4 de la cabecera RIFF.
  final int riffChunkSize;

  /// Offset 40 de la cabecera RIFF.
  final int dataChunkSize;

  final int durationMs;
}
