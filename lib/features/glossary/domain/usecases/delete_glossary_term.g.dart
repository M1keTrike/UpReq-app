// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_glossary_term.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deleteGlossaryTerm)
final deleteGlossaryTermProvider = DeleteGlossaryTermProvider._();

final class DeleteGlossaryTermProvider
    extends
        $FunctionalProvider<
          DeleteGlossaryTerm,
          DeleteGlossaryTerm,
          DeleteGlossaryTerm
        >
    with $Provider<DeleteGlossaryTerm> {
  DeleteGlossaryTermProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteGlossaryTermProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteGlossaryTermHash();

  @$internal
  @override
  $ProviderElement<DeleteGlossaryTerm> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeleteGlossaryTerm create(Ref ref) {
    return deleteGlossaryTerm(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteGlossaryTerm value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteGlossaryTerm>(value),
    );
  }
}

String _$deleteGlossaryTermHash() =>
    r'5baed246422aab3788e62eca1ee0ef253196f711';
