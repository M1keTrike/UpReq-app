// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcript_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `transcriptViewProvider(recordingId)`.

@ProviderFor(transcriptView)
final transcriptViewProvider = TranscriptViewFamily._();

/// `transcriptViewProvider(recordingId)`.

final class TranscriptViewProvider
    extends
        $FunctionalProvider<
          AsyncValue<TranscriptView>,
          TranscriptView,
          Stream<TranscriptView>
        >
    with $FutureModifier<TranscriptView>, $StreamProvider<TranscriptView> {
  /// `transcriptViewProvider(recordingId)`.
  TranscriptViewProvider._({
    required TranscriptViewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'transcriptViewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transcriptViewHash();

  @override
  String toString() {
    return r'transcriptViewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<TranscriptView> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<TranscriptView> create(Ref ref) {
    final argument = this.argument as String;
    return transcriptView(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TranscriptViewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transcriptViewHash() => r'3a0bb4ac344658ab850cdeb5706f6b48104e7d23';

/// `transcriptViewProvider(recordingId)`.

final class TranscriptViewFamily extends $Family
    with $FunctionalFamilyOverride<Stream<TranscriptView>, String> {
  TranscriptViewFamily._()
    : super(
        retry: null,
        name: r'transcriptViewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// `transcriptViewProvider(recordingId)`.

  TranscriptViewProvider call(String recordingId) =>
      TranscriptViewProvider._(argument: recordingId, from: this);

  @override
  String toString() => r'transcriptViewProvider';
}
