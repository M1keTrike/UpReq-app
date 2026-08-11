import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/projects/data/project_repository_impl.dart';
import 'package:up_req/features/projects/domain/entities/project.dart';
import 'package:up_req/features/projects/domain/entities/project_counters.dart';
import 'package:up_req/features/projects/domain/entities/project_draft.dart';
import 'package:up_req/features/projects/domain/project_repository.dart';
import 'package:up_req/features/projects/presentation/project_mutations.dart';

import '../../support/test_container.dart';

class _FakeProjectRepository implements ProjectRepository {
  final Map<String, Project> store = {};

  @override
  Future<void> insert(Project project) async => store[project.id.value] = project;

  @override
  Future<void> update(Project project) async => store[project.id.value] = project;

  @override
  Future<Project?> findById(ProjectId id) async => store[id.value];

  @override
  Future<void> setStatus(ProjectId id, ProjectStatus status, DateTime at) async {
    final current = store[id.value]!;
    store[id.value] = current.copyWith(status: status, updatedAt: at);
  }

  @override
  Stream<List<Project>> watchByStatus(ProjectStatus status) => throw UnimplementedError();

  @override
  Stream<Project?> watchById(ProjectId id) => throw UnimplementedError();

  @override
  Stream<ProjectCounters> watchCounters(ProjectId id) => throw UnimplementedError();
}

void main() {
  final at = DateTime.utc(2026, 1, 1);
  late _FakeProjectRepository repository;

  setUp(() => repository = _FakeProjectRepository());

  test('runSaveProject actualiza el proyecto vía el provider del caso de uso', () async {
    repository.store['p1'] = Project(
      id: const ProjectId('p1'),
      name: 'Original',
      status: ProjectStatus.active,
      createdAt: at,
      updatedAt: at,
    );
    final container = buildTestContainer(
      overrides: [projectRepositoryProvider.overrideWithValue(repository)],
      fixedNow: at,
    );

    await runSaveProject(container, const ProjectId('p1'), const ProjectDraft(name: 'Nuevo'));

    expect(repository.store['p1']!.name, 'Nuevo');
  });

  test('runCloseProject y runReopenProject transicionan el estado vía sus providers', () async {
    repository.store['p1'] = Project(
      id: const ProjectId('p1'),
      name: 'Proyecto',
      status: ProjectStatus.active,
      createdAt: at,
      updatedAt: at,
    );
    final container = buildTestContainer(
      overrides: [projectRepositoryProvider.overrideWithValue(repository)],
      fixedNow: at,
    );

    await runCloseProject(container, const ProjectId('p1'));
    expect(repository.store['p1']!.status, ProjectStatus.closed);

    await runReopenProject(container, const ProjectId('p1'));
    expect(repository.store['p1']!.status, ProjectStatus.active);
  });
}
