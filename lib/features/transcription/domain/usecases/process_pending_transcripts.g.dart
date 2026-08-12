// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'process_pending_transcripts.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(processPendingTranscripts)
final processPendingTranscriptsProvider = ProcessPendingTranscriptsProvider._();

final class ProcessPendingTranscriptsProvider
    extends
        $FunctionalProvider<
          ProcessPendingTranscripts,
          ProcessPendingTranscripts,
          ProcessPendingTranscripts
        >
    with $Provider<ProcessPendingTranscripts> {
  ProcessPendingTranscriptsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'processPendingTranscriptsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$processPendingTranscriptsHash();

  @$internal
  @override
  $ProviderElement<ProcessPendingTranscripts> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProcessPendingTranscripts create(Ref ref) {
    return processPendingTranscripts(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProcessPendingTranscripts value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProcessPendingTranscripts>(value),
    );
  }
}

String _$processPendingTranscriptsHash() =>
    r'7e8a6c46829b7454f1625820e2874b1b571eeb76';
