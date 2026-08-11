import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/stakeholders/domain/entities/stakeholder.dart';
import 'package:up_req/features/stakeholders/domain/entities/stakeholder_draft.dart';
import 'package:up_req/features/stakeholders/domain/stakeholder_repository.dart';
import 'package:up_req/features/stakeholders/domain/usecases/create_stakeholder.dart';
import 'package:up_req/features/stakeholders/domain/usecases/deactivate_stakeholder.dart';
import 'package:up_req/features/stakeholders/domain/usecases/update_stakeholder.dart';

class _FakeStakeholderRepository implements StakeholderRepository {
  final Map<String, Stakeholder> store = {};

  @override
  Future<void> insert(Stakeholder stakeholder) async => store[stakeholder.id.value] = stakeholder;

  @override
  Future<void> update(Stakeholder stakeholder) async => store[stakeholder.id.value] = stakeholder;

  @override
  Future<Stakeholder?> findById(StakeholderId id) async => store[id.value];

  @override
  Future<void> deactivate(StakeholderId id, DateTime at) async {
    final current = store[id.value]!;
    store[id.value] = Stakeholder(
      id: current.id,
      projectId: current.projectId,
      name: current.name,
      influence: current.influence,
      status: StakeholderStatus.inactive,
      createdAt: current.createdAt,
      updatedAt: at,
      role: current.role,
      area: current.area,
      notes: current.notes,
    );
  }

  @override
  Stream<List<Stakeholder>> watchByProject(ProjectId id) => throw UnimplementedError();

  @override
  Stream<List<Stakeholder>> watchSelectableByProject(ProjectId id) => throw UnimplementedError();
}

class _FakeProjectStatusReader implements ProjectStatusReader {
  _FakeProjectStatusReader({this.active = true});

  final bool active;

  @override
  Future<bool> isActive(ProjectId id) async => active;
}

class _FixedIdGenerator implements IdGenerator {
  _FixedIdGenerator(this._id);

  final String _id;

  @override
  String generate() => _id;
}

void main() {
  final at = DateTime.utc(2026, 1, 1);
  const projectId = ProjectId('project-1');
  late _FakeStakeholderRepository repository;

  setUp(() => repository = _FakeStakeholderRepository());

  group('CreateStakeholder', () {
    test('rechaza un nombre vacío', () async {
      final useCase = CreateStakeholder(
        repository,
        _FakeProjectStatusReader(),
        Clock.fixed(at),
        _FixedIdGenerator('s1'),
      );

      final result = await useCase(projectId, const StakeholderDraft(name: '  '));

      expect(result, isA<Err<StakeholderId>>());
      expect((result as Err<StakeholderId>).failure, isA<ValidationFailure>());
    });

    test('usa medium como influencia por defecto', () async {
      final useCase = CreateStakeholder(
        repository,
        _FakeProjectStatusReader(),
        Clock.fixed(at),
        _FixedIdGenerator('s1'),
      );

      final result = await useCase(projectId, const StakeholderDraft(name: 'Ana'));

      expect(result, isA<Ok<StakeholderId>>());
      expect(repository.store['s1']!.influence, InfluenceLevel.medium);
    });

    test('rechaza con ProjectClosedFailure si el proyecto está cerrado', () async {
      final useCase = CreateStakeholder(
        repository,
        _FakeProjectStatusReader(active: false),
        Clock.fixed(at),
        _FixedIdGenerator('s1'),
      );

      final result = await useCase(projectId, const StakeholderDraft(name: 'Ana'));

      expect(result, isA<Err<StakeholderId>>());
      expect((result as Err<StakeholderId>).failure, isA<ProjectClosedFailure>());
      expect(repository.store, isEmpty);
    });
  });

  group('UpdateStakeholder', () {
    test('rechaza con ProjectClosedFailure si el proyecto está cerrado', () async {
      repository.store['s1'] = Stakeholder(
        id: const StakeholderId('s1'),
        projectId: projectId,
        name: 'Original',
        influence: InfluenceLevel.medium,
        status: StakeholderStatus.active,
        createdAt: at,
        updatedAt: at,
      );
      final useCase = UpdateStakeholder(
        repository,
        _FakeProjectStatusReader(active: false),
        Clock.fixed(at),
      );

      final result = await useCase(const StakeholderId('s1'), const StakeholderDraft(name: 'Nuevo'));

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ProjectClosedFailure>());
      expect(repository.store['s1']!.name, 'Original');
    });
  });

  group('DeactivateStakeholder', () {
    test('desactiva un interesado del proyecto activo', () async {
      repository.store['s1'] = Stakeholder(
        id: const StakeholderId('s1'),
        projectId: projectId,
        name: 'Ana',
        influence: InfluenceLevel.medium,
        status: StakeholderStatus.active,
        createdAt: at,
        updatedAt: at,
      );
      final useCase = DeactivateStakeholder(repository, _FakeProjectStatusReader(), Clock.fixed(at));

      final result = await useCase(const StakeholderId('s1'));

      expect(result, isA<Ok<void>>());
      expect(repository.store['s1']!.status, StakeholderStatus.inactive);
    });

    test('rechaza con ProjectClosedFailure si el proyecto está cerrado', () async {
      repository.store['s1'] = Stakeholder(
        id: const StakeholderId('s1'),
        projectId: projectId,
        name: 'Ana',
        influence: InfluenceLevel.medium,
        status: StakeholderStatus.active,
        createdAt: at,
        updatedAt: at,
      );
      final useCase = DeactivateStakeholder(
        repository,
        _FakeProjectStatusReader(active: false),
        Clock.fixed(at),
      );

      final result = await useCase(const StakeholderId('s1'));

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ProjectClosedFailure>());
    });
  });
}
