/// Reproducción. Implementado en data/ sobre `just_audio`, único importador.
abstract interface class AudioPlayback {
  Future<void> load(String relativePath);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position); // FR-018
  Stream<Duration> get position; // FR-019, resaltado del segmento activo
  Future<void> dispose();
}
