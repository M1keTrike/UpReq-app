// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glossary_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(glossaryRepository)
final glossaryRepositoryProvider = GlossaryRepositoryProvider._();

final class GlossaryRepositoryProvider
    extends
        $FunctionalProvider<
          GlossaryRepository,
          GlossaryRepository,
          GlossaryRepository
        >
    with $Provider<GlossaryRepository> {
  GlossaryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'glossaryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$glossaryRepositoryHash();

  @$internal
  @override
  $ProviderElement<GlossaryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GlossaryRepository create(Ref ref) {
    return glossaryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlossaryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GlossaryRepository>(value),
    );
  }
}

String _$glossaryRepositoryHash() =>
    r'cce7331fca4e5a634a24dd8b6d5ab01c82e16c06';
