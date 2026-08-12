// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'load_recording_for_playback.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(loadRecordingForPlayback)
final loadRecordingForPlaybackProvider = LoadRecordingForPlaybackProvider._();

final class LoadRecordingForPlaybackProvider
    extends
        $FunctionalProvider<
          LoadRecordingForPlayback,
          LoadRecordingForPlayback,
          LoadRecordingForPlayback
        >
    with $Provider<LoadRecordingForPlayback> {
  LoadRecordingForPlaybackProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loadRecordingForPlaybackProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loadRecordingForPlaybackHash();

  @$internal
  @override
  $ProviderElement<LoadRecordingForPlayback> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LoadRecordingForPlayback create(Ref ref) {
    return loadRecordingForPlayback(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoadRecordingForPlayback value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoadRecordingForPlayback>(value),
    );
  }
}

String _$loadRecordingForPlaybackHash() =>
    r'0f5142494c5301c8453d10b00ab34c49b86f2b9c';
