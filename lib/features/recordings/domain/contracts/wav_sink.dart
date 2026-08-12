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
}
