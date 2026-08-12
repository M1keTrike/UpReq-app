// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stop_recording.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(stopRecording)
final stopRecordingProvider = StopRecordingProvider._();

final class StopRecordingProvider
    extends $FunctionalProvider<StopRecording, StopRecording, StopRecording>
    with $Provider<StopRecording> {
  StopRecordingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stopRecordingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stopRecordingHash();

  @$internal
  @override
  $ProviderElement<StopRecording> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StopRecording create(Ref ref) {
    return stopRecording(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StopRecording value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StopRecording>(value),
    );
  }
}

String _$stopRecordingHash() => r'eaca235c534c896b39af6a6cf8ab4e52f11bd807';
