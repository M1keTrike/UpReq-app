import 'dart:typed_data';

/// Captura de audio. Implementado en data/ sobre `record`, único importador
/// (verificado por tool/check_import_boundaries.dart).
abstract interface class AudioRecorder {
  /// Permiso de micrófono. FR-004.
  Future<bool> hasPermission();

  /// Abre el micrófono y devuelve el flujo PCM16 crudo, 16 kHz mono.
  /// El llamador lo bifurca: escritor WAV y pasada en vivo (research.md, 4).
  Future<Stream<Uint8List>> start();

  Future<void> stop();

  /// Emite cada cambio de estado del grabador, incluidas las pausas que
  /// **impone el sistema** (llamada entrante). El notifier distingue las
  /// suyas de las impuestas y marca `interrupted` solo en el segundo caso.
  /// FR-010.
  Stream<RecorderState> get states;
}

enum RecorderState { recording, paused, stopped }
