/// Reproducción. Implementado en data/ sobre `just_audio`, único importador.
abstract interface class AudioPlayback {
  Future<void> load(String relativePath);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position); // FR-018
  Stream<Duration> get position; // FR-019, resaltado del segmento activo
  /// Emite cuando la reproducción llega sola al final del audio (a
  /// diferencia de una pausa pedida por el usuario), para que quien escuche
  /// pueda rebobinar y dejar la pista lista para repetirse.
  Stream<void> get completed;
  Future<void> dispose();
}
