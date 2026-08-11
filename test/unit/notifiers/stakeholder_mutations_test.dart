import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/features/stakeholders/data/stakeholder_repository_impl.dart';
import 'package:up_req/features/stakeholders/domain/entities/stakeholder.dart';
import 'package:up_req/features/stakeholders/domain/entities/stakeholder_draft.dart';
import 'package:up_req/features/stakeholders/domain/stakeholder_repository.dart';
import 'package:up_req/features/stakeholders/presentation/stakeholder_mutations.dart';

import '../../support/test_container.dart';

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
  @override
  Future<bool> isActive(ProjectId id) async => true;
}

void main() {
  final at = DateTime.utc(2026, 1, 1);
  const projectId = ProjectId('p1');
  late _FakeStakeholderRepository repository;

  setUp(() => repository = _FakeStakeholderRepository());

  test('runCreateStakeholder y runSaveStakeholder pasan por sus providers', () async {
    final container = buildTestContainer(
      overrides: [
        stakeholderRepositoryProvider.overrideWithValue(repository),
        projectStatusReaderProvider.overrideWithValue(_FakeProjectStatusReader()),
      ],
      fixedNow: at,
    );

    final id = await runCreateStakeholder(container, projectId, const StakeholderDraft(name: 'Ana'));
    expect(repository.store[id.value]!.name, 'Ana');

    await runSaveStakeholder(container, id, const StakeholderDraft(name: 'Ana María'));
    expect(repository.store[id.value]!.name, 'Ana María');
  });

  test('runDeactivateStakeholder pasa por su provider', () async {
    repository.store['s1'] = Stakeholder(
      id: const StakeholderId('s1'),
      projectId: projectId,
      name: 'Ana',
      influence: InfluenceLevel.medium,
      status: StakeholderStatus.active,
      createdAt: at,
      updatedAt: at,
    );
    final container = buildTestContainer(
      overrides: [
        stakeholderRepositoryProvider.overrideWithValue(repository),
        projectStatusReaderProvider.overrideWithValue(_FakeProjectStatusReader()),
      ],
      fixedNow: at,
    );

    await runDeactivateStakeholder(container, const StakeholderId('s1'));

    expect(repository.store['s1']!.status, StakeholderStatus.inactive);
  });
}
