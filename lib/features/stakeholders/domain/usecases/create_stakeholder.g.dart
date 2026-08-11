// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_stakeholder.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(createStakeholder)
final createStakeholderProvider = CreateStakeholderProvider._();

final class CreateStakeholderProvider
    extends
        $FunctionalProvider<
          CreateStakeholder,
          CreateStakeholder,
          CreateStakeholder
        >
    with $Provider<CreateStakeholder> {
  CreateStakeholderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createStakeholderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createStakeholderHash();

  @$internal
  @override
  $ProviderElement<CreateStakeholder> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CreateStakeholder create(Ref ref) {
    return createStakeholder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateStakeholder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateStakeholder>(value),
    );
  }
}

String _$createStakeholderHash() => r'34ff1ce853863053acb010439b76f34861c0e7c5';
