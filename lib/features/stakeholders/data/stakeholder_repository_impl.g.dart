// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stakeholder_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(stakeholderRepository)
final stakeholderRepositoryProvider = StakeholderRepositoryProvider._();

final class StakeholderRepositoryProvider
    extends
        $FunctionalProvider<
          StakeholderRepository,
          StakeholderRepository,
          StakeholderRepository
        >
    with $Provider<StakeholderRepository> {
  StakeholderRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stakeholderRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stakeholderRepositoryHash();

  @$internal
  @override
  $ProviderElement<StakeholderRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StakeholderRepository create(Ref ref) {
    return stakeholderRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StakeholderRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StakeholderRepository>(value),
    );
  }
}

String _$stakeholderRepositoryHash() =>
    r'47c790d525e27160051dc7dfbfff8db572929099';
