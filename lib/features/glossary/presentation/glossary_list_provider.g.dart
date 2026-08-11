// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glossary_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Único provider que consume la pantalla de lista de glosario
/// (ui-contracts.md, pantalla 7).

@ProviderFor(glossaryList)
final glossaryListProvider = GlossaryListFamily._();

/// Único provider que consume la pantalla de lista de glosario
/// (ui-contracts.md, pantalla 7).

final class GlossaryListProvider
    extends
        $FunctionalProvider<
          AsyncValue<GlossaryListState>,
          GlossaryListState,
          Stream<GlossaryListState>
        >
    with
        $FutureModifier<GlossaryListState>,
        $StreamProvider<GlossaryListState> {
  /// Único provider que consume la pantalla de lista de glosario
  /// (ui-contracts.md, pantalla 7).
  GlossaryListProvider._({
    required GlossaryListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'glossaryListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$glossaryListHash();

  @override
  String toString() {
    return r'glossaryListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<GlossaryListState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<GlossaryListState> create(Ref ref) {
    final argument = this.argument as String;
    return glossaryList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GlossaryListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$glossaryListHash() => r'8f4efc88eb92f840f64a2cce067bb87c799b19af';

/// Único provider que consume la pantalla de lista de glosario
/// (ui-contracts.md, pantalla 7).

final class GlossaryListFamily extends $Family
    with $FunctionalFamilyOverride<Stream<GlossaryListState>, String> {
  GlossaryListFamily._()
    : super(
        retry: null,
        name: r'glossaryListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Único provider que consume la pantalla de lista de glosario
  /// (ui-contracts.md, pantalla 7).

  GlossaryListProvider call(String projectId) =>
      GlossaryListProvider._(argument: projectId, from: this);

  @override
  String toString() => r'glossaryListProvider';
}
