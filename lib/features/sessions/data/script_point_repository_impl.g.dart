// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'script_point_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(scriptPointRepository)
final scriptPointRepositoryProvider = ScriptPointRepositoryProvider._();

final class ScriptPointRepositoryProvider
    extends
        $FunctionalProvider<
          ScriptPointRepository,
          ScriptPointRepository,
          ScriptPointRepository
        >
    with $Provider<ScriptPointRepository> {
  ScriptPointRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scriptPointRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scriptPointRepositoryHash();

  @$internal
  @override
  $ProviderElement<ScriptPointRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ScriptPointRepository create(Ref ref) {
    return scriptPointRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScriptPointRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScriptPointRepository>(value),
    );
  }
}

String _$scriptPointRepositoryHash() =>
    r'b9e90d47ad4bd97aef14105c0655849380205164';
