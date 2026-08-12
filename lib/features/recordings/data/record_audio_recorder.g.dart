// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_audio_recorder.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `keepAlive`: el grabador de hardware es un recurso único que debe
/// sobrevivir a la navegación entre pantallas, igual que la conexión a la
/// base de datos.

@ProviderFor(audioRecorder)
final audioRecorderProvider = AudioRecorderProvider._();

/// `keepAlive`: el grabador de hardware es un recurso único que debe
/// sobrevivir a la navegación entre pantallas, igual que la conexión a la
/// base de datos.

final class AudioRecorderProvider
    extends $FunctionalProvider<AudioRecorder, AudioRecorder, AudioRecorder>
    with $Provider<AudioRecorder> {
  /// `keepAlive`: el grabador de hardware es un recurso único que debe
  /// sobrevivir a la navegación entre pantallas, igual que la conexión a la
  /// base de datos.
  AudioRecorderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'audioRecorderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$audioRecorderHash();

  @$internal
  @override
  $ProviderElement<AudioRecorder> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AudioRecorder create(Ref ref) {
    return audioRecorder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AudioRecorder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AudioRecorder>(value),
    );
  }
}

String _$audioRecorderHash() => r'ae6421892785a921bda2d7aadaa483c207720331';
