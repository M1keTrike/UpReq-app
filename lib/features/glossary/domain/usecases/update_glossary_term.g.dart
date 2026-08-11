// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_glossary_term.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(updateGlossaryTerm)
final updateGlossaryTermProvider = UpdateGlossaryTermProvider._();

final class UpdateGlossaryTermProvider
    extends
        $FunctionalProvider<
          UpdateGlossaryTerm,
          UpdateGlossaryTerm,
          UpdateGlossaryTerm
        >
    with $Provider<UpdateGlossaryTerm> {
  UpdateGlossaryTermProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateGlossaryTermProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateGlossaryTermHash();

  @$internal
  @override
  $ProviderElement<UpdateGlossaryTerm> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UpdateGlossaryTerm create(Ref ref) {
    return updateGlossaryTerm(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateGlossaryTerm value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateGlossaryTerm>(value),
    );
  }
}

String _$updateGlossaryTermHash() =>
    r'3d55ed61ce9b223f58797eb0e88fb170b4b09e2f';
