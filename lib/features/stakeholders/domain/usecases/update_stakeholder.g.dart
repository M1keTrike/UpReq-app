// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_stakeholder.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(updateStakeholder)
final updateStakeholderProvider = UpdateStakeholderProvider._();

final class UpdateStakeholderProvider
    extends
        $FunctionalProvider<
          UpdateStakeholder,
          UpdateStakeholder,
          UpdateStakeholder
        >
    with $Provider<UpdateStakeholder> {
  UpdateStakeholderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateStakeholderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateStakeholderHash();

  @$internal
  @override
  $ProviderElement<UpdateStakeholder> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UpdateStakeholder create(Ref ref) {
    return updateStakeholder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateStakeholder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateStakeholder>(value),
    );
  }
}

String _$updateStakeholderHash() => r'290b1a92103369789975d845c4aa7c4a5b3e7ea2';
