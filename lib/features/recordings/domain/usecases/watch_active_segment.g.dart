// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_active_segment.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(watchActiveSegment)
final watchActiveSegmentProvider = WatchActiveSegmentProvider._();

final class WatchActiveSegmentProvider
    extends
        $FunctionalProvider<
          WatchActiveSegment,
          WatchActiveSegment,
          WatchActiveSegment
        >
    with $Provider<WatchActiveSegment> {
  WatchActiveSegmentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchActiveSegmentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchActiveSegmentHash();

  @$internal
  @override
  $ProviderElement<WatchActiveSegment> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WatchActiveSegment create(Ref ref) {
    return watchActiveSegment(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchActiveSegment value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchActiveSegment>(value),
    );
  }
}

String _$watchActiveSegmentHash() =>
    r'2c2cc811b87b3b66621ff1f19bd7c83618ee5728';
