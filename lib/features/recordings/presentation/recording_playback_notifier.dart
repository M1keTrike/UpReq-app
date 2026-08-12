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

  @override
  PlaybackState build(String recordingId) {
    ref.onDispose(() => _positionSubscription?.cancel());
    unawaited(_load(recordingId));
    return const PlaybackState(isPlaying: false, position: Duration.zero);
  }

  Future<void> _load(String recordingId) async {
    await ref.read(loadRecordingForPlaybackProvider)(RecordingId(recordingId));
    _positionSubscription = ref.read(audioPlaybackProvider).position.listen((position) {
      state = state.copyWith(position: position);
    });
  }

  Future<void> play() async {
    await ref.read(audioPlaybackProvider).play();
    state = state.copyWith(isPlaying: true);
  }

  Future<void> pause() async {
    await ref.read(audioPlaybackProvider).pause();
    state = state.copyWith(isPlaying: false);
  }
}
