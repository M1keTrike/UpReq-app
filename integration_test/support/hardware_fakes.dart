import 'dart:typed_data';

import 'package:riverpod/misc.dart' show Override;
import 'package:up_req/features/recordings/data/just_audio_player.dart';
import 'package:up_req/features/recordings/data/record_audio_recorder.dart';
import 'package:up_req/features/recordings/data/wav_writer.dart';
import 'package:up_req/features/recordings/domain/contracts/wav_sink.dart';
import 'package:up_req/features/transcription/data/model_repository_impl.dart';
import 'package:up_req/features/transcription/data/whisper_transcriber.dart';

import '../../test/support/fake_audio_playback.dart';
import '../../test/support/fake_audio_recorder.dart';
import '../../test/support/fake_model_repository.dart';
import '../../test/support/fake_transcriber.dart';

/// Escritor WAV en memoria para las pruebas de integración del incremento 2:
/// `WavFileSink` real resuelve rutas con `path_provider`, que no existe en
/// este arnés sin un plugin nativo. No reproduce el formato binario, solo
/// las duraciones que `StopRecording`/`RecoverInterrupted` necesitan —el
/// contenido del audio en sí es responsabilidad de `wav_header_test.dart` y
/// de la validación en dispositivo físico (V1).
class FakeWavSink implements WavSink {
  final List<Uint8List> appended = [];
  int durationMsToReturn = 1000;

  @override
  Future<void> open(String relativePath, {int sampleRate = 16000, int channels = 1}) async {}

  @override
  Future<void> append(Uint8List pcmFrames) async => appended.add(pcmFrames);

  @override
  Future<int> closeAndFinalize() async => durationMsToReturn;

  @override
  Future<int> repairExisting(String relativePath, {int sampleRate = 16000, int channels = 1}) async =>
      durationMsToReturn;

  @override
  Future<void> reopenForAppend(String relativePath, {int sampleRate = 16000, int channels = 1}) async {}
}

/// Dobla todo el hardware/red del incremento 2 (micrófono, escritor WAV,
/// transcriptor, modelo, reproductor) para que las pruebas de integración
/// recorran la app real de punta a punta sin tocar plugins nativos ni la
/// red — mismo principio que T026 aplicó a las pruebas unitarias, extendido
/// aquí a las de integración. Los dobles individuales (`FakeAudioRecorder`,
/// `FakeTranscriber`, `FakeModelRepository`, `FakeAudioPlayback`) ya existen
/// en `test/support/`; esta función solo los cablea como overrides de
/// Riverpod para `pumpTestApp`.
List<Override> hardwareOverrides({
  FakeAudioRecorder? audioRecorder,
  FakeWavSink? wavSink,
  FakeTranscriber? transcriber,
  FakeModelRepository? modelRepository,
  FakeAudioPlayback? audioPlayback,
}) {
  return [
    audioRecorderProvider.overrideWithValue(audioRecorder ?? FakeAudioRecorder()),
    wavSinkProvider.overrideWithValue(wavSink ?? FakeWavSink()),
    transcriberProvider.overrideWithValue(transcriber ?? FakeTranscriber()),
    modelRepositoryProvider.overrideWithValue(modelRepository ?? FakeModelRepository()),
    audioPlaybackProvider.overrideWithValue(audioPlayback ?? FakeAudioPlayback()),
  ];
}
