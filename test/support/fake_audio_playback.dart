import 'dart:async';

import 'package:up_req/features/recordings/domain/contracts/audio_playback.dart';

/// Doble controlable desde la prueba: nunca abre un reproductor real (T026).
class FakeAudioPlayback implements AudioPlayback {
  String? loadedPath;
  bool playing = false;
  Duration lastSeek = Duration.zero;
  bool disposed = false;

  final _positionController = StreamController<Duration>.broadcast();

  @override
  Future<void> load(String relativePath) async {
    loadedPath = relativePath;
  }

  @override
  Future<void> play() async {
    playing = true;
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
  Future<void> dispose() async {
    disposed = true;
    await _positionController.close();
  }

  /// Simula el avance de la reproducción.
  void emitPosition(Duration position) => _positionController.add(position);
}
