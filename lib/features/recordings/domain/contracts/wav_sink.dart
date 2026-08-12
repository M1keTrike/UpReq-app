import 'dart:typed_data';

/// Escritura incremental del archivo WAV. La pieza que hace recuperable una
/// grabación interrumpida (research.md, decisión 4).
abstract interface class WavSink {
  /// Escribe la cabecera RIFF con los dos campos de tamaño en cero y deja el
  /// archivo listo para anexar.
  Future<void> open(String relativePath, {int sampleRate = 16000, int channels = 1});

  Future<void> append(Uint8List pcmFrames);

  /// Vuelve atrás y parchea los dos campos de tamaño con los valores reales.
  /// Devuelve la duración resultante en milisegundos.
  Future<int> closeAndFinalize();

  /// Repara la cabecera de un archivo que quedó SIN cerrar por un cierre
  /// inesperado del proceso (FR-010): recalcula los tamaños desde el
  /// tamaño real en disco y los parchea, sin haberlo abierto antes con
  /// `open()`. Devuelve la duración resultante en milisegundos.
  Future<int> repairExisting(String relativePath, {int sampleRate = 16000, int channels = 1});

  /// Reabre un archivo ya reparado para seguir anexando tramas nuevas al
  /// final, sin truncarlo (FR-011, reanudar una grabación interrumpida): el
  /// archivo ya contiene audio real y debe conservarse íntegro.
  Future<void> reopenForAppend(String relativePath, {int sampleRate = 16000, int channels = 1});
}
