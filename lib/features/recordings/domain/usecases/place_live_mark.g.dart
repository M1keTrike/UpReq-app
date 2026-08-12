// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_live_mark.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(placeLiveMark)
final placeLiveMarkProvider = PlaceLiveMarkProvider._();

final class PlaceLiveMarkProvider
    extends $FunctionalProvider<PlaceLiveMark, PlaceLiveMark, PlaceLiveMark>
    with $Provider<PlaceLiveMark> {
  PlaceLiveMarkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placeLiveMarkProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placeLiveMarkHash();

  @$internal
  @override
  $ProviderElement<PlaceLiveMark> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlaceLiveMark create(Ref ref) {
    return placeLiveMark(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaceLiveMark value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaceLiveMark>(value),
    );
  }
}

String _$placeLiveMarkHash() => r'5b1c5eacff0acb3d915c30de47b307556fbe4bd9';
