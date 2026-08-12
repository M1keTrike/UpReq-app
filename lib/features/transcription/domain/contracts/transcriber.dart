import 'dart:typed_data';

/// Transcripción en el dispositivo. Implementado en data/ sobre
/// `whisper_ggml`, único importador. SIEMPRE se dobla en pruebas: ninguna
/// prueba carga un modelo Whisper (regla de Calidad de la constitución).
abstract interface class Transcriber {
  /// Pasada definitiva sobre un archivo ya cerrado. Produce segmentos con
  /// ventana temporal. FR-013.
  Future<List<RawSegment>> transcribeFile({
    required String relativePath,
    required TranscriptionModel model,
    String? initialPrompt, // el glosario del proyecto, FR-014
  });

  /// Pasada en vivo sobre el flujo de captura. FR-012.
  Future<LiveTranscription> transcribeLive({
    required Stream<Uint8List> pcm16,
    required TranscriptionModel model,
    String? initialPrompt,
  });
}

class RawSegment {
  const RawSegment({required this.fromMs, required this.toMs, required this.text});

  final int fromMs;
  final int toMs;
  final String text;
}

abstract interface class LiveTranscription {
  Stream<String> get partials;
  Future<void> stop();
}

enum TranscriptionModel { base, small }
