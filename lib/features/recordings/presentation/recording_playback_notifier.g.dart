// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_playback_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Carga el archivo de la grabación y sigue la posición de reproducción
/// (FR-017, FR-018, FR-019). `autoDispose`, a diferencia de
/// `ActiveCaptureNotifier`: el reproductor solo necesita vivir mientras la
/// pantalla de detalle está abierta, no sobrevivir a la navegación.

@ProviderFor(RecordingPlaybackNotifier)
final recordingPlaybackProvider = RecordingPlaybackNotifierFamily._();

/// Carga el archivo de la grabación y sigue la posición de reproducción
/// (FR-017, FR-018, FR-019). `autoDispose`, a diferencia de
/// `ActiveCaptureNotifier`: el reproductor solo necesita vivir mientras la
/// pantalla de detalle está abierta, no sobrevivir a la navegación.
final class RecordingPlaybackNotifierProvider
    extends $NotifierProvider<RecordingPlaybackNotifier, PlaybackState> {
  /// Carga el archivo de la grabación y sigue la posición de reproducción
  /// (FR-017, FR-018, FR-019). `autoDispose`, a diferencia de
  /// `ActiveCaptureNotifier`: el reproductor solo necesita vivir mientras la
  /// pantalla de detalle está abierta, no sobrevivir a la navegación.
  RecordingPlaybackNotifierProvider._({
    required RecordingPlaybackNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'recordingPlaybackProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recordingPlaybackNotifierHash();

  @override
  String toString() {
    return r'recordingPlaybackProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RecordingPlaybackNotifier create() => RecordingPlaybackNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaybackState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaybackState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RecordingPlaybackNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recordingPlaybackNotifierHash() =>
    r'0413d421583e75cc92c8c028b3a131d14395c477';

/// Carga el archivo de la grabación y sigue la posición de reproducción
/// (FR-017, FR-018, FR-019). `autoDispose`, a diferencia de
/// `ActiveCaptureNotifier`: el reproductor solo necesita vivir mientras la
/// pantalla de detalle está abierta, no sobrevivir a la navegación.

final class RecordingPlaybackNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          RecordingPlaybackNotifier,
          PlaybackState,
          PlaybackState,
          PlaybackState,
          String
        > {
  RecordingPlaybackNotifierFamily._()
    : super(
        retry: null,
        name: r'recordingPlaybackProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Carga el archivo de la grabación y sigue la posición de reproducción
  /// (FR-017, FR-018, FR-019). `autoDispose`, a diferencia de
  /// `ActiveCaptureNotifier`: el reproductor solo necesita vivir mientras la
  /// pantalla de detalle está abierta, no sobrevivir a la navegación.

  RecordingPlaybackNotifierProvider call(String recordingId) =>
      RecordingPlaybackNotifierProvider._(argument: recordingId, from: this);

  @override
  String toString() => r'recordingPlaybackProvider';
}

/// Carga el archivo de la grabación y sigue la posición de reproducción
/// (FR-017, FR-018, FR-019). `autoDispose`, a diferencia de
/// `ActiveCaptureNotifier`: el reproductor solo necesita vivir mientras la
/// pantalla de detalle está abierta, no sobrevivir a la navegación.

abstract class _$RecordingPlaybackNotifier extends $Notifier<PlaybackState> {
  late final _$args = ref.$arg as String;
  String get recordingId => _$args;

  PlaybackState build(String recordingId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PlaybackState, PlaybackState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlaybackState, PlaybackState>,
              PlaybackState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
