// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stakeholder_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Único provider que consume la pantalla de lista de interesados
/// (ui-contracts.md, pantalla 4).

@ProviderFor(stakeholderList)
final stakeholderListProvider = StakeholderListFamily._();

/// Único provider que consume la pantalla de lista de interesados
/// (ui-contracts.md, pantalla 4).

final class StakeholderListProvider
    extends
        $FunctionalProvider<
          AsyncValue<StakeholderListState>,
          StakeholderListState,
          Stream<StakeholderListState>
        >
    with
        $FutureModifier<StakeholderListState>,
        $StreamProvider<StakeholderListState> {
  /// Único provider que consume la pantalla de lista de interesados
  /// (ui-contracts.md, pantalla 4).
  StakeholderListProvider._({
    required StakeholderListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'stakeholderListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$stakeholderListHash();

  @override
  String toString() {
    return r'stakeholderListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<StakeholderListState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<StakeholderListState> create(Ref ref) {
    final argument = this.argument as String;
    return stakeholderList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StakeholderListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stakeholderListHash() => r'92c2ac6563a79693963deab4fc45558ef57caa2a';

/// Único provider que consume la pantalla de lista de interesados
/// (ui-contracts.md, pantalla 4).

final class StakeholderListFamily extends $Family
    with $FunctionalFamilyOverride<Stream<StakeholderListState>, String> {
  StakeholderListFamily._()
    : super(
        retry: null,
        name: r'stakeholderListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Único provider que consume la pantalla de lista de interesados
  /// (ui-contracts.md, pantalla 4).

  StakeholderListProvider call(String projectId) =>
      StakeholderListProvider._(argument: projectId, from: this);

  @override
  String toString() => r'stakeholderListProvider';
}
