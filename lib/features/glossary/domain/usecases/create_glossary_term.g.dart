// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_glossary_term.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(createGlossaryTerm)
final createGlossaryTermProvider = CreateGlossaryTermProvider._();

final class CreateGlossaryTermProvider
    extends
        $FunctionalProvider<
          CreateGlossaryTerm,
          CreateGlossaryTerm,
          CreateGlossaryTerm
        >
    with $Provider<CreateGlossaryTerm> {
  CreateGlossaryTermProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createGlossaryTermProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createGlossaryTermHash();

  @$internal
  @override
  $ProviderElement<CreateGlossaryTerm> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CreateGlossaryTerm create(Ref ref) {
    return createGlossaryTerm(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateGlossaryTerm value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateGlossaryTerm>(value),
    );
  }
}

String _$createGlossaryTermHash() =>
    r'b37a885bc99976089711629395d6d3bda0effcf7';
