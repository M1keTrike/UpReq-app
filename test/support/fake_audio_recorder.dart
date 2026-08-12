import 'dart:async';
import 'dart:typed_data';

import 'package:up_req/features/recordings/domain/contracts/audio_recorder.dart';

/// Doble controlable desde la prueba: nunca abre el micrófono. Garantiza
/// T026 — ninguna prueba de este incremento toca hardware real.
class FakeAudioRecorder implements AudioRecorder {
  bool permissionGranted = true;
  bool started = false;
  final pcmController = StreamController<Uint8List>.broadcast();
  final statesController = StreamController<RecorderState>.broadcast();

  @override
  Future<bool> hasPermission() async => permissionGranted;

  @override
  Future<Stream<Uint8List>> start() async {
    started = true;
    statesController.add(RecorderState.recording);
    return pcmController.stream;
  }

  @override
  Future<void> stop() async {
    started = false;
    // Simula la transición transitoria real de `record`: pasar por `paused`
    // antes de `stopped` al detener. El notifier debe distinguir esto de una
    // interrupción real vía `_ownPause` (research.md, decisión 5).
    statesController.add(RecorderState.paused);
    statesController.add(RecorderState.stopped);
  }

  @override
  Stream<RecorderState> get states => statesController.stream;

  /// Simula una trama PCM entrante.
  void emitFrame(Uint8List frame) => pcmController.add(frame);

  /// Simula una pausa que la app pidió (no debe interpretarse como
  /// interrupción por el notifier).
  void emitOwnPause() => statesController.add(RecorderState.paused);

  /// Simula una pausa impuesta por el sistema (llamada entrante): el
  /// notifier debe distinguirla de la anterior y marcar `interrupted`.
  void emitSystemPause() => statesController.add(RecorderState.paused);

  Future<void> dispose() async {
    await pcmController.close();
    await statesController.close();
  }
}
