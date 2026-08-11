// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Filtro activos/cerrados de la lista. Provider separado, pequeño y con
/// estado propio, para que `projectListProvider` pueda reaccionar a su
/// cambio sin mezclar el control del filtro con la carga de datos.

@ProviderFor(ProjectListFilterNotifier)
final projectListFilterProvider = ProjectListFilterNotifierProvider._();

/// Filtro activos/cerrados de la lista. Provider separado, pequeño y con
/// estado propio, para que `projectListProvider` pueda reaccionar a su
/// cambio sin mezclar el control del filtro con la carga de datos.
final class ProjectListFilterNotifierProvider
    extends $NotifierProvider<ProjectListFilterNotifier, ProjectFilter> {
  /// Filtro activos/cerrados de la lista. Provider separado, pequeño y con
  /// estado propio, para que `projectListProvider` pueda reaccionar a su
  /// cambio sin mezclar el control del filtro con la carga de datos.
  ProjectListFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectListFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectListFilterNotifierHash();

  @$internal
  @override
  ProjectListFilterNotifier create() => ProjectListFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProjectFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProjectFilter>(value),
    );
  }
}

String _$projectListFilterNotifierHash() =>
    r'ef67e3739e71e9b4e7ca53d49696c0eba8687c4f';

/// Filtro activos/cerrados de la lista. Provider separado, pequeño y con
/// estado propio, para que `projectListProvider` pueda reaccionar a su
/// cambio sin mezclar el control del filtro con la carga de datos.

abstract class _$ProjectListFilterNotifier extends $Notifier<ProjectFilter> {
  ProjectFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ProjectFilter, ProjectFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProjectFilter, ProjectFilter>,
              ProjectFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Único provider que consume la pantalla de lista (ui-contracts.md,
/// pantalla 1): un solo `AsyncValue<ProjectListState>`.

@ProviderFor(projectList)
final projectListProvider = ProjectListProvider._();

/// Único provider que consume la pantalla de lista (ui-contracts.md,
/// pantalla 1): un solo `AsyncValue<ProjectListState>`.

final class ProjectListProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProjectListState>,
          ProjectListState,
          Stream<ProjectListState>
        >
    with $FutureModifier<ProjectListState>, $StreamProvider<ProjectListState> {
  /// Único provider que consume la pantalla de lista (ui-contracts.md,
  /// pantalla 1): un solo `AsyncValue<ProjectListState>`.
  ProjectListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectListHash();

  @$internal
  @override
  $StreamProviderElement<ProjectListState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ProjectListState> create(Ref ref) {
    return projectList(ref);
  }
}

String _$projectListHash() => r'c9daf88fc4d03b3546a9a8a8b0b214fbb6f90f91';
