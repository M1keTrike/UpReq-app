import 'dart:typed_data';

import 'package:record/record.dart' as pkg;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/contracts/audio_recorder.dart';

part 'record_audio_recorder.g.dart';

/// Único importador de `package:record` en todo el árbol (verificado por
/// tool/check_import_boundaries.dart). PCM16 16 kHz mono, con
/// `audioInterruption` en su valor por defecto (`pause`): ante una llamada
/// entrante el grabador se pausa solo y no reanuda por su cuenta
/// (research.md, decisión 5), que es exactamente lo que la app necesita
/// para distinguir una pausa impuesta de una pedida.
class RecordAudioRecorder implements AudioRecorder {
  final _recorder = pkg.AudioRecorder();

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<Stream<Uint8List>> start() {
    return _recorder.startStream(
      const pkg.RecordConfig(
        encoder: pkg.AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );
  }

  @override
  Future<void> stop() => _recorder.stop();

  @override
  Stream<RecorderState> get states => _recorder.onStateChanged().map(_toDomain);

  RecorderState _toDomain(pkg.RecordState state) {
    return switch (state) {
      pkg.RecordState.record => RecorderState.recording,
      pkg.RecordState.pause => RecorderState.paused,
      pkg.RecordState.stop => RecorderState.stopped,
    };
  }
}

/// `keepAlive`: el grabador de hardware es un recurso único que debe
/// sobrevivir a la navegación entre pantallas, igual que la conexión a la
/// base de datos.
@Riverpod(keepAlive: true)
AudioRecorder audioRecorder(Ref ref) => RecordAudioRecorder();
