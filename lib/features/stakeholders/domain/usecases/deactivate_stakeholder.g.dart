// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deactivate_stakeholder.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deactivateStakeholder)
final deactivateStakeholderProvider = DeactivateStakeholderProvider._();

final class DeactivateStakeholderProvider
    extends
        $FunctionalProvider<
          DeactivateStakeholder,
          DeactivateStakeholder,
          DeactivateStakeholder
        >
    with $Provider<DeactivateStakeholder> {
  DeactivateStakeholderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deactivateStakeholderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deactivateStakeholderHash();

  @$internal
  @override
  $ProviderElement<DeactivateStakeholder> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeactivateStakeholder create(Ref ref) {
    return deactivateStakeholder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeactivateStakeholder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeactivateStakeholder>(value),
    );
  }
}

String _$deactivateStakeholderHash() =>
    r'db8f3d5b111ff9fccb2cca0bd80b782cd66d83a1';
