// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'just_audio_player.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `autoDispose` (por defecto), a diferencia de `AudioRecorder`: el
/// reproductor solo necesita vivir mientras la pantalla de detalle de
/// grabación está abierta, no sobrevivir a la navegación.

@ProviderFor(audioPlayback)
final audioPlaybackProvider = AudioPlaybackProvider._();

/// `autoDispose` (por defecto), a diferencia de `AudioRecorder`: el
/// reproductor solo necesita vivir mientras la pantalla de detalle de
/// grabación está abierta, no sobrevivir a la navegación.

final class AudioPlaybackProvider
    extends $FunctionalProvider<AudioPlayback, AudioPlayback, AudioPlayback>
    with $Provider<AudioPlayback> {
  /// `autoDispose` (por defecto), a diferencia de `AudioRecorder`: el
  /// reproductor solo necesita vivir mientras la pantalla de detalle de
  /// grabación está abierta, no sobrevivir a la navegación.
  AudioPlaybackProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'audioPlaybackProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$audioPlaybackHash();

  @$internal
  @override
  $ProviderElement<AudioPlayback> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AudioPlayback create(Ref ref) {
    return audioPlayback(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AudioPlayback value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AudioPlayback>(value),
    );
  }
}

String _$audioPlaybackHash() => r'4de113ccb5258965b8f9bb4848be42ef5058d102';
