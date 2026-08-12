import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:whisper_ggml/whisper_ggml.dart' as pkg;

import '../domain/contracts/transcriber.dart';

part 'whisper_transcriber.g.dart';

/// Único importador de `package:whisper_ggml` en todo el árbol (verificado
/// por tool/check_import_boundaries.dart). `lang` fijo en `'es'` (Principio
/// II); `withSegments: true` solo en la pasada definitiva, que es la que
/// produce evidencia.
class WhisperTranscriber implements Transcriber {
  final _controller = pkg.WhisperController();

  @override
  Future<List<RawSegment>> transcribeFile({
    required String relativePath,
    required TranscriptionModel model,
    String? initialPrompt,
  }) async {
    final absolutePath = await _resolveAbsolutePath(relativePath);
    final result = await _controller.transcribe(
      model: _toWhisperModel(model),
      audioPath: absolutePath,
      lang: 'es',
      initialPrompt: initialPrompt,
      withSegments: true,
    );

    if (result == null) {
      throw Exception('whisper_ggml no devolvió transcripción para $relativePath.');
    }

    final segments = result.transcription.segments;
    if (segments == null || segments.isEmpty) {
      return [
        RawSegment(fromMs: 0, toMs: 0, text: result.transcription.text),
      ];
    }

    return [
      for (final segment in segments)
        RawSegment(
          fromMs: segment.fromTs.inMilliseconds,
          toMs: segment.toTs.inMilliseconds,
          text: segment.text,
        ),
    ];
  }

  @override
  Future<LiveTranscription> transcribeLive({
    required Stream<Uint8List> pcm16,
    required TranscriptionModel model,
    String? initialPrompt,
  }) async {
    final session = await _controller.transcribeLive(
      model: _toWhisperModel(model),
      pcm16Stream: pcm16,
      lang: 'es',
      initialPrompt: initialPrompt,
    );
    return _WhisperLiveTranscription(session);
  }

  pkg.WhisperModel _toWhisperModel(TranscriptionModel model) {
    return switch (model) {
      TranscriptionModel.base => pkg.WhisperModel.base,
      TranscriptionModel.small => pkg.WhisperModel.small,
    };
  }

  Future<String> _resolveAbsolutePath(String relativePath) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}${Platform.pathSeparator}'
        '${relativePath.replaceAll('/', Platform.pathSeparator)}';
  }
}

class _WhisperLiveTranscription implements LiveTranscription {
  _WhisperLiveTranscription(this._session);

  final pkg.WhisperLiveSession _session;

  @override
  Stream<String> get partials => _session.partials;

  @override
  Future<void> stop() => _session.stop();
}

@Riverpod(keepAlive: true)
Transcriber transcriber(Ref ref) => WhisperTranscriber();
