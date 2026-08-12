import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart' as pkg;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/contracts/audio_playback.dart';

part 'just_audio_player.g.dart';

/// Único importador de `package:just_audio` en todo el árbol (T090).
/// Resuelve la ruta relativa contra el sandbox de la app con el mismo
/// criterio que `WavFileSink` (T038): la base guarda rutas relativas, nunca
/// absolutas.
class JustAudioPlayback implements AudioPlayback {
  final _player = pkg.AudioPlayer();

  @override
  Future<void> load(String relativePath) async {
    final absolutePath = await _resolveAbsolutePath(relativePath);
    await _player.setFilePath(absolutePath);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Stream<Duration> get position => _player.positionStream;

  @override
  Future<void> dispose() => _player.dispose();

  Future<String> _resolveAbsolutePath(String relativePath) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}${Platform.pathSeparator}'
        '${relativePath.replaceAll('/', Platform.pathSeparator)}';
  }
}

/// `autoDispose` (por defecto), a diferencia de `AudioRecorder`: el
/// reproductor solo necesita vivir mientras la pantalla de detalle de
/// grabación está abierta, no sobrevivir a la navegación.
@riverpod
AudioPlayback audioPlayback(Ref ref) {
  final playback = JustAudioPlayback();
  ref.onDispose(() {
    unawaited(playback.dispose());
  });
  return playback;
}
