// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_recording.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deleteRecording)
final deleteRecordingProvider = DeleteRecordingProvider._();

final class DeleteRecordingProvider
    extends
        $FunctionalProvider<DeleteRecording, DeleteRecording, DeleteRecording>
    with $Provider<DeleteRecording> {
  DeleteRecordingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteRecordingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteRecordingHash();

  @$internal
  @override
  $ProviderElement<DeleteRecording> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeleteRecording create(Ref ref) {
    return deleteRecording(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteRecording value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteRecording>(value),
    );
  }
}

String _$deleteRecordingHash() => r'3b6642a6da12fdafa339449770933e3c063356c7';
