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

/// FR-019: el segmento que contiene la posición actual del reproductor, o
/// `null` fuera de todos. `activeSegmentProvider(transcriptId)`.

@ProviderFor(activeSegment)
final activeSegmentProvider = ActiveSegmentFamily._();

/// FR-019: el segmento que contiene la posición actual del reproductor, o
/// `null` fuera de todos. `activeSegmentProvider(transcriptId)`.

final class ActiveSegmentProvider
    extends
        $FunctionalProvider<
          AsyncValue<SegmentId?>,
          SegmentId?,
          Stream<SegmentId?>
        >
    with $FutureModifier<SegmentId?>, $StreamProvider<SegmentId?> {
  /// FR-019: el segmento que contiene la posición actual del reproductor, o
  /// `null` fuera de todos. `activeSegmentProvider(transcriptId)`.
  ActiveSegmentProvider._({
    required ActiveSegmentFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activeSegmentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeSegmentHash();

  @override
  String toString() {
    return r'activeSegmentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<SegmentId?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<SegmentId?> create(Ref ref) {
    final argument = this.argument as String;
    return activeSegment(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveSegmentProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeSegmentHash() => r'12f1b9039f6d63c3dade074e1842264182c68698';

/// FR-019: el segmento que contiene la posición actual del reproductor, o
/// `null` fuera de todos. `activeSegmentProvider(transcriptId)`.

final class ActiveSegmentFamily extends $Family
    with $FunctionalFamilyOverride<Stream<SegmentId?>, String> {
  ActiveSegmentFamily._()
    : super(
        retry: null,
        name: r'activeSegmentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// FR-019: el segmento que contiene la posición actual del reproductor, o
  /// `null` fuera de todos. `activeSegmentProvider(transcriptId)`.

  ActiveSegmentProvider call(String transcriptId) =>
      ActiveSegmentProvider._(argument: transcriptId, from: this);

  @override
  String toString() => r'activeSegmentProvider';
}
