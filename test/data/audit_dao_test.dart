import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/database/app_database.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/audit_log/data/audit_dao.dart';
import 'package:up_req/features/audit_log/data/audit_repository_impl.dart';

import '../support/seed.dart';
import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  late AuditRepositoryImpl repository;

  setUp(() {
    db = openTestDatabase();
    repository = AuditRepositoryImpl(AuditDao(db));
  });

  tearDown(() => db.close());

  test('orden del más reciente al más antiguo (FR-015a)', () async {
    final base = DateTime.utc(2026, 1, 1);
    await db.into(db.projects).insert(seedProject(at: base, id: 'project-1'));

    await db.into(db.auditEntries).insert(
          seedAuditEntry(
            at: base,
            projectId: 'project-1',
            operation: 'projectClosed',
            entityType: 'project',
            entityId: 'project-1',
            id: 'entry-oldest',
          ),
        );
    await db.into(db.auditEntries).insert(
          seedAuditEntry(
            at: base.add(const Duration(days: 2)),
            projectId: 'project-1',
            operation: 'projectReopened',
            entityType: 'project',
            entityId: 'project-1',
            id: 'entry-newest',
          ),
        );
    await db.into(db.auditEntries).insert(
          seedAuditEntry(
            at: base.add(const Duration(days: 1)),
            projectId: 'project-1',
            operation: 'stakeholderDeactivated',
            entityType: 'stakeholder',
            entityId: 'stakeholder-1',
            id: 'entry-middle',
          ),
        );

    final entries = await repository.watchByProject(const ProjectId('project-1')).first;

    expect(entries.map((e) => e.id.value).toList(), [
      'entry-newest',
      'entry-middle',
      'entry-oldest',
    ]);
  });

  test('invariante I4: filtrado estricto por proyecto, sin contaminación cruzada', () async {
    final at = DateTime.utc(2026, 1, 1);
    await db.into(db.projects).insert(seedProject(at: at, id: 'project-1'));
    await db.into(db.projects).insert(seedProject(at: at, id: 'project-2', name: 'Otro proyecto'));

    await db.into(db.auditEntries).insert(
          seedAuditEntry(
            at: at,
            projectId: 'project-1',
            operation: 'projectClosed',
            entityType: 'project',
            entityId: 'project-1',
            id: 'entry-p1',
          ),
        );
    await db.into(db.auditEntries).insert(
          seedAuditEntry(
            at: at,
            projectId: 'project-2',
            operation: 'projectClosed',
            entityType: 'project',
            entityId: 'project-2',
            id: 'entry-p2',
          ),
        );

    final ofProjectOne = await repository.watchByProject(const ProjectId('project-1')).first;
    final ofProjectTwo = await repository.watchByProject(const ProjectId('project-2')).first;

    expect(ofProjectOne.map((e) => e.id.value).toList(), ['entry-p1']);
    expect(ofProjectTwo.map((e) => e.id.value).toList(), ['entry-p2']);
  });

  test('mapea operation, entityType y entityLabel al dominio', () async {
    final at = DateTime.utc(2026, 1, 1);
    await db.into(db.projects).insert(seedProject(at: at, id: 'project-1'));
    await db.into(db.auditEntries).insert(
          seedAuditEntry(
            at: at,
            projectId: 'project-1',
            operation: 'glossaryTermDeleted',
            entityType: 'glossaryTerm',
            entityId: 'term-1',
            id: 'entry-1',
            entityLabel: 'Requisito',
          ),
        );

    final entries = await repository.watchByProject(const ProjectId('project-1')).first;

    expect(entries, hasLength(1));
    final entry = entries.single;
    expect(entry.operation.name, 'glossaryTermDeleted');
    expect(entry.entityType.name, 'glossaryTerm');
    expect(entry.entityId, 'term-1');
    expect(entry.entityLabel, 'Requisito');
  });
}
