// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_form_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `sessionFormProvider(projectId, sessionId)` de ui-contracts.md, pantalla
/// 5. Al fallar la validación de una escritura, este estado no se toca: es
/// lo que conserva lo escrito (FR-022).

@ProviderFor(SessionForm)
final sessionFormProvider = SessionFormFamily._();

/// `sessionFormProvider(projectId, sessionId)` de ui-contracts.md, pantalla
/// 5. Al fallar la validación de una escritura, este estado no se toca: es
/// lo que conserva lo escrito (FR-022).
final class SessionFormProvider
    extends $AsyncNotifierProvider<SessionForm, SessionFormState> {
  /// `sessionFormProvider(projectId, sessionId)` de ui-contracts.md, pantalla
  /// 5. Al fallar la validación de una escritura, este estado no se toca: es
  /// lo que conserva lo escrito (FR-022).
  SessionFormProvider._({
    required SessionFormFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'sessionFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionFormHash();

  @override
  String toString() {
    return r'sessionFormProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  SessionForm create() => SessionForm();

  @override
  bool operator ==(Object other) {
    return other is SessionFormProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionFormHash() => r'43d2999ce447dbc6b1a979c87e8ad0d053e74a35';

/// `sessionFormProvider(projectId, sessionId)` de ui-contracts.md, pantalla
/// 5. Al fallar la validación de una escritura, este estado no se toca: es
/// lo que conserva lo escrito (FR-022).

final class SessionFormFamily extends $Family
    with
        $ClassFamilyOverride<
          SessionForm,
          AsyncValue<SessionFormState>,
          SessionFormState,
          FutureOr<SessionFormState>,
          (String, String?)
        > {
  SessionFormFamily._()
    : super(
        retry: null,
        name: r'sessionFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// `sessionFormProvider(projectId, sessionId)` de ui-contracts.md, pantalla
  /// 5. Al fallar la validación de una escritura, este estado no se toca: es
  /// lo que conserva lo escrito (FR-022).

  SessionFormProvider call(String projectId, String? sessionId) =>
      SessionFormProvider._(argument: (projectId, sessionId), from: this);

  @override
  String toString() => r'sessionFormProvider';
}

/// `sessionFormProvider(projectId, sessionId)` de ui-contracts.md, pantalla
/// 5. Al fallar la validación de una escritura, este estado no se toca: es
/// lo que conserva lo escrito (FR-022).

abstract class _$SessionForm extends $AsyncNotifier<SessionFormState> {
  late final _$args = ref.$arg as (String, String?);
  String get projectId => _$args.$1;
  String? get sessionId => _$args.$2;

  FutureOr<SessionFormState> build(String projectId, String? sessionId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<SessionFormState>, SessionFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SessionFormState>, SessionFormState>,
              AsyncValue<SessionFormState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

/// Alimenta el selector de participantes con `watchSelectableByProject`, de
/// modo que estructuralmente no puede ofrecer interesados inactivos ni de
/// otro proyecto (FR-009, ui-contracts.md pantalla 5).

@ProviderFor(selectableStakeholders)
final selectableStakeholdersProvider = SelectableStakeholdersFamily._();

/// Alimenta el selector de participantes con `watchSelectableByProject`, de
/// modo que estructuralmente no puede ofrecer interesados inactivos ni de
/// otro proyecto (FR-009, ui-contracts.md pantalla 5).

final class SelectableStakeholdersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Stakeholder>>,
          List<Stakeholder>,
          Stream<List<Stakeholder>>
        >
    with
        $FutureModifier<List<Stakeholder>>,
        $StreamProvider<List<Stakeholder>> {
  /// Alimenta el selector de participantes con `watchSelectableByProject`, de
  /// modo que estructuralmente no puede ofrecer interesados inactivos ni de
  /// otro proyecto (FR-009, ui-contracts.md pantalla 5).
  SelectableStakeholdersProvider._({
    required SelectableStakeholdersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'selectableStakeholdersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$selectableStakeholdersHash();

  @override
  String toString() {
    return r'selectableStakeholdersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Stakeholder>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Stakeholder>> create(Ref ref) {
    final argument = this.argument as String;
    return selectableStakeholders(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SelectableStakeholdersProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$selectableStakeholdersHash() =>
    r'ae0af4440b899b59366e9d84a054a0705f5d0799';

/// Alimenta el selector de participantes con `watchSelectableByProject`, de
/// modo que estructuralmente no puede ofrecer interesados inactivos ni de
/// otro proyecto (FR-009, ui-contracts.md pantalla 5).

final class SelectableStakeholdersFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Stakeholder>>, String> {
  SelectableStakeholdersFamily._()
    : super(
        retry: null,
        name: r'selectableStakeholdersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Alimenta el selector de participantes con `watchSelectableByProject`, de
  /// modo que estructuralmente no puede ofrecer interesados inactivos ni de
  /// otro proyecto (FR-009, ui-contracts.md pantalla 5).

  SelectableStakeholdersProvider call(String projectId) =>
      SelectableStakeholdersProvider._(argument: projectId, from: this);

  @override
  String toString() => r'selectableStakeholdersProvider';
}
