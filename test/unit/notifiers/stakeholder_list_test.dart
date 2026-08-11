import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/stakeholders/data/stakeholder_repository_impl.dart';
import 'package:up_req/features/stakeholders/domain/entities/stakeholder.dart';
import 'package:up_req/features/stakeholders/domain/stakeholder_repository.dart';
import 'package:up_req/features/stakeholders/presentation/stakeholder_list_provider.dart';

import '../../support/test_container.dart';

class _FakeStakeholderRepository implements StakeholderRepository {
  List<Stakeholder> stakeholders = [];

  @override
  Stream<List<Stakeholder>> watchByProject(ProjectId id) => Stream.value(stakeholders);

  @override
  Stream<List<Stakeholder>> watchSelectableByProject(ProjectId id) => throw UnimplementedError();

  @override
  Future<Stakeholder?> findById(StakeholderId id) => throw UnimplementedError();

  @override
  Future<void> insert(Stakeholder stakeholder) => throw UnimplementedError();

  @override
  Future<void> update(Stakeholder stakeholder) => throw UnimplementedError();

  @override
  Future<void> deactivate(StakeholderId id, DateTime at) => throw UnimplementedError();
}

void main() {
  test('expone los interesados del proyecto a través de un único provider', () async {
    final at = DateTime.utc(2026, 1, 1);
    final repository = _FakeStakeholderRepository()
      ..stakeholders = [
        Stakeholder(
          id: const StakeholderId('s1'),
          projectId: const ProjectId('p1'),
          name: 'Ana',
          influence: InfluenceLevel.high,
          status: StakeholderStatus.active,
          createdAt: at,
          updatedAt: at,
        ),
      ];

    final container = buildTestContainer(
      overrides: [stakeholderRepositoryProvider.overrideWithValue(repository)],
    );
    container.listen(stakeholderListProvider('p1'), (_, _) {});

    final state = await container.read(stakeholderListProvider('p1').future);

    expect(state.stakeholders.map((s) => s.name), ['Ana']);
  });
}
