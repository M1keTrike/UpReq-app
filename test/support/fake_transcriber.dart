import 'dart:async';
import 'dart:typed_data';

import 'package:up_req/features/transcription/domain/contracts/transcriber.dart';

/// Doble controlable desde la prueba: nunca carga un modelo Whisper (T026).
class FakeTranscriber implements Transcriber {
  List<RawSegment> segmentsToReturn = const [];
  Object? errorToThrow;
  String? lastInitialPrompt;
  TranscriptionModel? lastModel;
  String? lastRelativePath;

  final _liveController = StreamController<String>.broadcast();
  late final _liveSession = _FakeLiveTranscription(_liveController.stream);

  @override
  Future<List<RawSegment>> transcribeFile({
    required String relativePath,
    required TranscriptionModel model,
    String? initialPrompt,
  }) async {
    lastRelativePath = relativePath;
    lastModel = model;
    lastInitialPrompt = initialPrompt;
    if (errorToThrow != null) throw errorToThrow!;
    return segmentsToReturn;
  }

  @override
  Future<LiveTranscription> transcribeLive({
    required Stream<Uint8List> pcm16,
    required TranscriptionModel model,
    String? initialPrompt,
  }) async {
    lastModel = model;
    lastInitialPrompt = initialPrompt;
    return _liveSession;
  }

  /// Simula una línea parcial de la pasada en vivo.
  void emitPartial(String text) => _liveController.add(text);

  bool get liveStopped => _liveSession.stopped;

  Future<void> dispose() async {
    await _liveController.close();
  }
}

class _FakeLiveTranscription implements LiveTranscription {
  _FakeLiveTranscription(this.partials);

  @override
  final Stream<String> partials;

  bool stopped = false;

  @override
  Future<void> stop() async {
    stopped = true;
  }
}
