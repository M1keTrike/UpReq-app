import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/ids.dart';

import '../data/just_audio_player.dart';
import '../domain/usecases/load_recording_for_playback.dart';

part 'recording_playback_notifier.g.dart';

/// Estado de reproducción del detalle de grabación (ui-contracts.md,
/// pantalla 3). `isPlaying` no lo expone `AudioPlayback`: solo este
/// notifier pide `play()`/`pause()`, así que es el único que necesita
/// llevar la cuenta.
final class PlaybackState {
  const PlaybackState({required this.isPlaying, required this.position});

  final bool isPlaying;
  final Duration position;

  PlaybackState copyWith({bool? isPlaying, Duration? position}) {
    return PlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
    );
  }
}

/// Carga el archivo de la grabación y sigue la posición de reproducción
/// (FR-017, FR-018, FR-019). `autoDispose`, a diferencia de
/// `ActiveCaptureNotifier`: el reproductor solo necesita vivir mientras la
/// pantalla de detalle está abierta, no sobrevivir a la navegación.
@riverpod
class RecordingPlaybackNotifier extends _$RecordingPlaybackNotifier {
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<void>? _completedSubscription;

  @override
  PlaybackState build(String recordingId) {
    // `audioPlaybackProvider` es autoDispose: sin este `watch`, nada lo
    // mantiene vivo entre el `ref.read` de `_load` y el de `play()`, y
    // Riverpod lo destruye (cierra el `AudioPlayer`) apenas termina de
    // crearse. `play()` entonces opera sobre un reproductor nuevo sin
    // archivo cargado y no suena nada.
    ref.watch(audioPlaybackProvider);
    ref.onDispose(() {
      _positionSubscription?.cancel();
      _completedSubscription?.cancel();
    });
    unawaited(_load(recordingId));
    return const PlaybackState(isPlaying: false, position: Duration.zero);
  }

  Future<void> _load(String recordingId) async {
    await ref.read(loadRecordingForPlaybackProvider)(RecordingId(recordingId));
    final playback = ref.read(audioPlaybackProvider);
    _positionSubscription = playback.position.listen((position) {
      state = state.copyWith(position: position);
    });
    // Al llegar sola al final, `just_audio` deja la posición en el punto
    // final y no reinicia por su cuenta: sin este rebobinado, tocar
    // "reproducir" de nuevo no suena nada. Hay que pausar **antes** de
    // rebobinar: `just_audio` conserva internamente "reproduciendo=true"
    // tras terminar solo (a diferencia de una pausa pedida por el
    // usuario), así que un `seek` sin pausar antes reanuda la
    // reproducción sola desde el segundo 0.
    _completedSubscription = playback.completed.listen((_) async {
      await playback.pause();
      await playback.seek(Duration.zero);
      state = state.copyWith(isPlaying: false, position: Duration.zero);
    });
  }

  Future<void> play() async {
    state = state.copyWith(isPlaying: true);
    await ref.read(audioPlaybackProvider).play();
  }

  Future<void> pause() async {
    await ref.read(audioPlaybackProvider).pause();
    state = state.copyWith(isPlaying: false);
  }
}
