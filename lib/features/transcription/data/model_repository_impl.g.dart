// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(modelRepository)
final modelRepositoryProvider = ModelRepositoryProvider._();

final class ModelRepositoryProvider
    extends
        $FunctionalProvider<ModelRepository, ModelRepository, ModelRepository>
    with $Provider<ModelRepository> {
  ModelRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelRepositoryHash();

  @$internal
  @override
  $ProviderElement<ModelRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ModelRepository create(Ref ref) {
    return modelRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ModelRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ModelRepository>(value),
    );
  }
}

String _$modelRepositoryHash() => r'8de7f2807752e426f21f3cd86ec2d10321fd098a';
