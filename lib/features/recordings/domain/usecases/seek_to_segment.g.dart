// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seek_to_segment.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(seekToSegment)
final seekToSegmentProvider = SeekToSegmentProvider._();

final class SeekToSegmentProvider
    extends $FunctionalProvider<SeekToSegment, SeekToSegment, SeekToSegment>
    with $Provider<SeekToSegment> {
  SeekToSegmentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seekToSegmentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seekToSegmentHash();

  @$internal
  @override
  $ProviderElement<SeekToSegment> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SeekToSegment create(Ref ref) {
    return seekToSegment(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SeekToSegment value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SeekToSegment>(value),
    );
  }
}

String _$seekToSegmentHash() => r'38a3c3eea1f5ab1e731e047811d9cf598e13957f';
