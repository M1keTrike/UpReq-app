import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/database/app_database.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/stakeholders/data/stakeholder_repository_impl.dart';
import 'package:up_req/features/stakeholders/data/stakeholders_dao.dart';

import '../support/seed.dart';
import '../support/test_container.dart';
import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  late StakeholderRepositoryImpl repository;

  setUp(() {
    db = openTestDatabase();
    repository = StakeholderRepositoryImpl(
      db,
      StakeholdersDao(db),
      SequentialIdGenerator(prefix: 'audit'),
    );
  });

  tearDown(() => db.close());

  test('desactivar conserva la fila y asienta bitácora', () async {
    final at = DateTime.utc(2026, 1, 1);
    await db.into(db.projects).insert(seedProject(at: at, id: 'project-1'));
    await db.into(db.stakeholders).insert(
          seedStakeholder(at: at, projectId: 'project-1', id: 's1', name: 'Ana'),
        );

    await repository.deactivate(const StakeholderId('s1'), at.add(const Duration(days: 1)));

    final rows = await db.select(db.stakeholders).get();
    expect(rows, hasLength(1));
    expect(rows.single.status, 'inactive');

    final auditRows = await db.select(db.auditEntries).get();
    expect(auditRows, hasLength(1));
    expect(auditRows.single.operation, 'stakeholderDeactivated');
    expect(auditRows.single.entityLabel, 'Ana');
  });

  test('updated_at cambia en toda escritura (FR-016)', () async {
    final created = DateTime.utc(2026, 1, 1);
    await db.into(db.projects).insert(seedProject(at: created, id: 'project-1'));
    await db.into(db.stakeholders).insert(seedStakeholder(at: created, projectId: 'project-1', id: 's1'));

    final updateAt = created.add(const Duration(days: 1));
    await repository.deactivate(const StakeholderId('s1'), updateAt);

    final row = (await db.select(db.stakeholders).get()).single;
    expect(row.createdAt, created);
    expect(row.updatedAt, updateAt);
  });

  test('invariante I4: nunca devuelve interesados de otro proyecto', () async {
    final at = DateTime.utc(2026, 1, 1);
    await db.into(db.projects).insert(seedProject(at: at, id: 'project-1'));
    await db.into(db.projects).insert(seedProject(at: at, id: 'project-2', name: 'Otro proyecto'));

    await db.into(db.stakeholders).insert(
          seedStakeholder(at: at, projectId: 'project-1', id: 's1', name: 'De uno'),
        );
    await db.into(db.stakeholders).insert(
          seedStakeholder(at: at, projectId: 'project-2', id: 's2', name: 'De dos'),
        );

    final ofProjectOne = await repository.watchByProject(const ProjectId('project-1')).first;

    expect(ofProjectOne.map((s) => s.name), ['De uno']);
  });
}
