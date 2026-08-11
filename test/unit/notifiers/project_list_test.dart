import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/projects/data/project_repository_impl.dart';
import 'package:up_req/features/projects/domain/entities/project.dart';
import 'package:up_req/features/projects/domain/entities/project_counters.dart';
import 'package:up_req/features/projects/domain/project_repository.dart';
import 'package:up_req/features/projects/presentation/project_list_provider.dart';

import '../../support/test_container.dart';

class _FakeProjectRepository implements ProjectRepository {
  List<Project> active = [];
  List<Project> closed = [];

  @override
  Stream<List<Project>> watchByStatus(ProjectStatus status) {
    return Stream.value(status == ProjectStatus.active ? active : closed);
  }

  @override
  Stream<Project?> watchById(ProjectId id) => throw UnimplementedError();

  @override
  Stream<ProjectCounters> watchCounters(ProjectId id) => throw UnimplementedError();

  @override
  Future<Project?> findById(ProjectId id) => throw UnimplementedError();

  @override
  Future<void> insert(Project project) => throw UnimplementedError();

  @override
  Future<void> update(Project project) => throw UnimplementedError();

  @override
  Future<void> setStatus(ProjectId id, ProjectStatus status, DateTime at) =>
      throw UnimplementedError();
}

void main() {
  test('cambia entre proyectos activos y cerrados según el filtro', () async {
    final at = DateTime.utc(2026, 1, 1);
    final repository = _FakeProjectRepository()
      ..active = [
        Project(
          id: const ProjectId('p1'),
          name: 'Activo',
          status: ProjectStatus.active,
          createdAt: at,
          updatedAt: at,
        ),
      ]
      ..closed = [
        Project(
          id: const ProjectId('p2'),
          name: 'Cerrado',
          status: ProjectStatus.closed,
          createdAt: at,
          updatedAt: at,
        ),
      ];

    final container = buildTestContainer(
      overrides: [projectRepositoryProvider.overrideWithValue(repository)],
    );
    // autoDispose por defecto: sin un listener activo, el provider se
    // destruiría entre la carga y la lectura de `.future`.
    container.listen(projectListProvider, (_, _) {});

    final active = await container.read(projectListProvider.future);
    expect(active.filter, ProjectFilter.active);
    expect(active.projects.map((p) => p.name), ['Activo']);

    container.read(projectListFilterProvider.notifier).set(ProjectFilter.closed);

    final closed = await container.read(projectListProvider.future);
    expect(closed.filter, ProjectFilter.closed);
    expect(closed.projects.map((p) => p.name), ['Cerrado']);
  });
}
