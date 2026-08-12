// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'start_recording.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(startRecording)
final startRecordingProvider = StartRecordingProvider._();

final class StartRecordingProvider
    extends $FunctionalProvider<StartRecording, StartRecording, StartRecording>
    with $Provider<StartRecording> {
  StartRecordingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startRecordingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startRecordingHash();

  @$internal
  @override
  $ProviderElement<StartRecording> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StartRecording create(Ref ref) {
    return startRecording(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StartRecording value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StartRecording>(value),
    );
  }
}

String _$startRecordingHash() => r'd537a6ec9150d94c29e532e483fbe72ed5ff1be0';
