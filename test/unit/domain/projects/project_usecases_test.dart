import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/projects/domain/entities/project.dart';
import 'package:up_req/features/projects/domain/entities/project_counters.dart';
import 'package:up_req/features/projects/domain/entities/project_draft.dart';
import 'package:up_req/features/projects/domain/project_repository.dart';
import 'package:up_req/features/projects/domain/usecases/close_project.dart';
import 'package:up_req/features/projects/domain/usecases/create_project.dart';
import 'package:up_req/features/projects/domain/usecases/reopen_project.dart';
import 'package:up_req/features/projects/domain/usecases/update_project.dart';

class _FakeProjectRepository implements ProjectRepository {
  final Map<String, Project> store = {};

  @override
  Future<void> insert(Project project) async {
    store[project.id.value] = project;
  }

  @override
  Future<void> update(Project project) async {
    store[project.id.value] = project;
  }

  @override
  Future<Project?> findById(ProjectId id) async => store[id.value];

  @override
  Future<void> setStatus(ProjectId id, ProjectStatus status, DateTime at) async {
    final current = store[id.value]!;
    store[id.value] = current.copyWith(status: status, updatedAt: at);
  }

  @override
  Stream<List<Project>> watchByStatus(ProjectStatus status) =>
      Stream.value(store.values.where((p) => p.status == status).toList());

  @override
  Stream<Project?> watchById(ProjectId id) => Stream.value(store[id.value]);

  @override
  Stream<ProjectCounters> watchCounters(ProjectId id) =>
      Stream.value(const ProjectCounters(stakeholders: 0, sessions: 0, glossaryTerms: 0));
}

void main() {
  final at = DateTime.utc(2026, 1, 1);
  late _FakeProjectRepository repository;

  setUp(() {
    repository = _FakeProjectRepository();
  });

  group('CreateProject', () {
    test('rechaza un nombre vacío', () async {
      final useCase = CreateProject(
        repository,
        Clock.fixed(at),
        _FixedIdGenerator('project-1'),
      );

      final result = await useCase(const ProjectDraft(name: '   '));

      expect(result, isA<Err<ProjectId>>());
      expect((result as Err<ProjectId>).failure, isA<ValidationFailure>());
      expect(repository.store, isEmpty);
    });

    test('crea el proyecto activo con el nombre recortado', () async {
      final useCase = CreateProject(
        repository,
        Clock.fixed(at),
        _FixedIdGenerator('project-1'),
      );

      final result = await useCase(const ProjectDraft(name: '  Mi proyecto  '));

      expect(result, isA<Ok<ProjectId>>());
      final id = (result as Ok<ProjectId>).value;
      final saved = repository.store[id.value]!;
      expect(saved.name, 'Mi proyecto');
      expect(saved.status, ProjectStatus.active);
      expect(saved.createdAt, at);
      expect(saved.updatedAt, at);
    });
  });

  group('UpdateProject', () {
    test('devuelve ProjectClosedFailure sobre un proyecto cerrado', () async {
      repository.store['project-1'] = Project(
        id: const ProjectId('project-1'),
        name: 'Original',
        status: ProjectStatus.closed,
        createdAt: at,
        updatedAt: at,
      );
      final useCase = UpdateProject(repository, Clock.fixed(at));

      final result = await useCase(
        const ProjectId('project-1'),
        const ProjectDraft(name: 'Nuevo nombre'),
      );

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ProjectClosedFailure>());
      expect(repository.store['project-1']!.name, 'Original');
    });

    test('rechaza un nombre vacío sin tocar el repositorio', () async {
      repository.store['project-1'] = Project(
        id: const ProjectId('project-1'),
        name: 'Original',
        status: ProjectStatus.active,
        createdAt: at,
        updatedAt: at,
      );
      final useCase = UpdateProject(repository, Clock.fixed(at));

      final result = await useCase(const ProjectId('project-1'), const ProjectDraft(name: ''));

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ValidationFailure>());
      expect(repository.store['project-1']!.name, 'Original');
    });
  });

  group('Transición active ↔ closed', () {
    test('CloseProject pasa de active a closed', () async {
      repository.store['project-1'] = Project(
        id: const ProjectId('project-1'),
        name: 'Proyecto',
        status: ProjectStatus.active,
        createdAt: at,
        updatedAt: at,
      );
      final useCase = CloseProject(repository, Clock.fixed(at));

      final result = await useCase(const ProjectId('project-1'));

      expect(result, isA<Ok<void>>());
      expect(repository.store['project-1']!.status, ProjectStatus.closed);
    });

    test('CloseProject sobre un proyecto ya cerrado devuelve ProjectClosedFailure', () async {
      repository.store['project-1'] = Project(
        id: const ProjectId('project-1'),
        name: 'Proyecto',
        status: ProjectStatus.closed,
        createdAt: at,
        updatedAt: at,
      );
      final useCase = CloseProject(repository, Clock.fixed(at));

      final result = await useCase(const ProjectId('project-1'));

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ProjectClosedFailure>());
    });

    test('ReopenProject pasa de closed a active', () async {
      repository.store['project-1'] = Project(
        id: const ProjectId('project-1'),
        name: 'Proyecto',
        status: ProjectStatus.closed,
        createdAt: at,
        updatedAt: at,
      );
      final useCase = ReopenProject(repository, Clock.fixed(at));

      final result = await useCase(const ProjectId('project-1'));

      expect(result, isA<Ok<void>>());
      expect(repository.store['project-1']!.status, ProjectStatus.active);
    });
  });
}

class _FixedIdGenerator implements IdGenerator {
  _FixedIdGenerator(this._id);

  final String _id;

  @override
  String generate() => _id;
}
