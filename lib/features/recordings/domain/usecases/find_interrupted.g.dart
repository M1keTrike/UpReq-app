// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'find_interrupted.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(findInterrupted)
final findInterruptedProvider = FindInterruptedProvider._();

final class FindInterruptedProvider
    extends
        $FunctionalProvider<FindInterrupted, FindInterrupted, FindInterrupted>
    with $Provider<FindInterrupted> {
  FindInterruptedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'findInterruptedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$findInterruptedHash();

  @$internal
  @override
  $ProviderElement<FindInterrupted> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FindInterrupted create(Ref ref) {
    return findInterrupted(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FindInterrupted value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FindInterrupted>(value),
    );
  }
}

String _$findInterruptedHash() => r'c5ba9d85bdeed42b3bf12d2efaae961327aa106f';
