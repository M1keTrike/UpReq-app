// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_model_status.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(watchModelStatus)
final watchModelStatusProvider = WatchModelStatusProvider._();

final class WatchModelStatusProvider
    extends
        $FunctionalProvider<
          WatchModelStatus,
          WatchModelStatus,
          WatchModelStatus
        >
    with $Provider<WatchModelStatus> {
  WatchModelStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchModelStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchModelStatusHash();

  @$internal
  @override
  $ProviderElement<WatchModelStatus> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchModelStatus create(Ref ref) {
    return watchModelStatus(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchModelStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchModelStatus>(value),
    );
  }
}

String _$watchModelStatusHash() => r'd128996aedd3e96c153fb04c167b56fc30f39af1';
