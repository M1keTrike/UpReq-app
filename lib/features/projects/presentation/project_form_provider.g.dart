// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_form_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `projectFormProvider(projectId)` de ui-contracts.md, pantalla 2. Al fallar
/// la validación de una escritura, este estado no se toca: es lo que
/// conserva lo escrito (FR-022).

@ProviderFor(ProjectForm)
final projectFormProvider = ProjectFormFamily._();

/// `projectFormProvider(projectId)` de ui-contracts.md, pantalla 2. Al fallar
/// la validación de una escritura, este estado no se toca: es lo que
/// conserva lo escrito (FR-022).
final class ProjectFormProvider
    extends $AsyncNotifierProvider<ProjectForm, ProjectFormState> {
  /// `projectFormProvider(projectId)` de ui-contracts.md, pantalla 2. Al fallar
  /// la validación de una escritura, este estado no se toca: es lo que
  /// conserva lo escrito (FR-022).
  ProjectFormProvider._({
    required ProjectFormFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'projectFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$projectFormHash();

  @override
  String toString() {
    return r'projectFormProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProjectForm create() => ProjectForm();

  @override
  bool operator ==(Object other) {
    return other is ProjectFormProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$projectFormHash() => r'3a85c307eec902f7f596ac60167cdb455fd7c5fc';

/// `projectFormProvider(projectId)` de ui-contracts.md, pantalla 2. Al fallar
/// la validación de una escritura, este estado no se toca: es lo que
/// conserva lo escrito (FR-022).

final class ProjectFormFamily extends $Family
    with
        $ClassFamilyOverride<
          ProjectForm,
          AsyncValue<ProjectFormState>,
          ProjectFormState,
          FutureOr<ProjectFormState>,
          String?
        > {
  ProjectFormFamily._()
    : super(
        retry: null,
        name: r'projectFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// `projectFormProvider(projectId)` de ui-contracts.md, pantalla 2. Al fallar
  /// la validación de una escritura, este estado no se toca: es lo que
  /// conserva lo escrito (FR-022).

  ProjectFormProvider call(String? projectId) =>
      ProjectFormProvider._(argument: projectId, from: this);

  @override
  String toString() => r'projectFormProvider';
}

/// `projectFormProvider(projectId)` de ui-contracts.md, pantalla 2. Al fallar
/// la validación de una escritura, este estado no se toca: es lo que
/// conserva lo escrito (FR-022).

abstract class _$ProjectForm extends $AsyncNotifier<ProjectFormState> {
  late final _$args = ref.$arg as String?;
  String? get projectId => _$args;

  FutureOr<ProjectFormState> build(String? projectId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ProjectFormState>, ProjectFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ProjectFormState>, ProjectFormState>,
              AsyncValue<ProjectFormState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
