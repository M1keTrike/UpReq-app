import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/project_repository_impl.dart';
import '../domain/entities/project.dart';
import '../domain/usecases/watch_active_projects.dart';
import '../domain/usecases/watch_closed_projects.dart';

part 'project_list_provider.g.dart';

enum ProjectFilter { active, closed }

final class ProjectListState {
  const ProjectListState({required this.projects, required this.filter});

  final List<Project> projects;
  final ProjectFilter filter;
}

/// Filtro activos/cerrados de la lista. Provider separado, pequeño y con
/// estado propio, para que `projectListProvider` pueda reaccionar a su
/// cambio sin mezclar el control del filtro con la carga de datos.
@riverpod
class ProjectListFilterNotifier extends _$ProjectListFilterNotifier {
  @override
  ProjectFilter build() => ProjectFilter.active;

  void set(ProjectFilter filter) => state = filter;
}

/// Único provider que consume la pantalla de lista (ui-contracts.md,
/// pantalla 1): un solo `AsyncValue<ProjectListState>`.
@riverpod
Stream<ProjectListState> projectList(Ref ref) {
  final filter = ref.watch(projectListFilterProvider);
  final repository = ref.watch(projectRepositoryProvider);

  final projects = filter == ProjectFilter.active
      ? WatchActiveProjects(repository)()
      : WatchClosedProjects(repository)();

  return projects.map((list) => ProjectListState(projects: list, filter: filter));
}
