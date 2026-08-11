import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/projects/domain/entities/project.dart';
import 'package:up_req/features/projects/domain/entities/project_counters.dart';
import 'package:up_req/features/projects/domain/project_repository.dart';
import 'package:up_req/features/projects/domain/usecases/watch_project_detail.dart';

class _FakeProjectRepository implements ProjectRepository {
  Project? project;
  ProjectCounters counters = const ProjectCounters(stakeholders: 0, sessions: 0, glossaryTerms: 0);

  @override
  Stream<Project?> watchById(ProjectId id) => Stream.value(project);

  @override
  Stream<ProjectCounters> watchCounters(ProjectId id) => Stream.value(counters);

  @override
  Stream<List<Project>> watchByStatus(ProjectStatus status) => throw UnimplementedError();

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
  final at = DateTime.utc(2026, 1, 1);

  test('combina proyecto y contadores en un solo valor', () async {
    final repository = _FakeProjectRepository()
      ..project = Project(
        id: const ProjectId('p1'),
        name: 'Proyecto',
        status: ProjectStatus.active,
        createdAt: at,
        updatedAt: at,
      )
      ..counters = const ProjectCounters(stakeholders: 2, sessions: 1, glossaryTerms: 4);

    final detail = await WatchProjectDetail(repository)(const ProjectId('p1')).first;

    expect(detail.project.name, 'Proyecto');
    expect(detail.counters.stakeholders, 2);
  });

  test('emite NotFoundFailure como error si el proyecto no existe', () async {
    final repository = _FakeProjectRepository();

    final stream = WatchProjectDetail(repository)(const ProjectId('missing'));

    await expectLater(stream, emitsError(isA<NotFoundFailure>()));
  });
}
