import 'dart:async';

import 'package:up_req/features/recordings/domain/contracts/audio_playback.dart';

/// Doble controlable desde la prueba: nunca abre un reproductor real (T026).
class FakeAudioPlayback implements AudioPlayback {
  String? loadedPath;
  bool playing = false;
  Duration lastSeek = Duration.zero;
  bool disposed = false;

  final _positionController = StreamController<Duration>.broadcast();
  final _completedController = StreamController<void>.broadcast();

  /// Si se fija, `play()` no resuelve hasta que la prueba complete este
  /// `Completer` — simula que `just_audio.play()` no se resuelve hasta que
  /// la reproducción se pausa o termina (comportamiento real del paquete).
  Completer<void>? playGate;

  @override
  Future<void> load(String relativePath) async {
    loadedPath = relativePath;
  }

  @override
  Future<void> play() async {
    playing = true;
    final gate = playGate;
    if (gate != null) await gate.future;
  }

  @override
  Future<void> pause() async {
    playing = false;
  }

  @override
  Future<void> seek(Duration position) async {
    lastSeek = position;
    _positionController.add(position);
  }

  @override
  Stream<Duration> get position => _positionController.stream;

  @override
  Stream<void> get completed => _completedController.stream;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _positionController.close();
    await _completedController.close();
  }

  /// Simula el avance de la reproducción.
  void emitPosition(Duration position) => _positionController.add(position);

  /// Simula que la pista llegó sola al final.
  void emitCompleted() => _completedController.add(null);
}
