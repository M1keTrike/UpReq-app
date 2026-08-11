import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/database/app_database.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/projects/data/project_repository_impl.dart';
import 'package:up_req/features/projects/data/projects_dao.dart';
import 'package:up_req/features/projects/domain/entities/project.dart' as domain;

import '../support/seed.dart';
import '../support/test_container.dart';
import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  late ProjectRepositoryImpl repository;

  setUp(() {
    db = openTestDatabase();
    repository = ProjectRepositoryImpl(db, ProjectsDao(db), SequentialIdGenerator(prefix: 'audit'));
  });

  tearDown(() => db.close());

  test('cerrar un proyecto no borra filas y asienta bitácora en la misma transacción', () async {
    final at = DateTime.utc(2026, 1, 1);
    await db.into(db.projects).insert(seedProject(at: at, id: 'project-1', name: 'Proyecto'));

    await repository.setStatus(
      const ProjectId('project-1'),
      domain.ProjectStatus.closed,
      at.add(const Duration(days: 1)),
    );

    final rows = await db.select(db.projects).get();
    expect(rows, hasLength(1));
    expect(rows.single.status, 'closed');

    final auditRows = await db.select(db.auditEntries).get();
    expect(auditRows, hasLength(1));
    expect(auditRows.single.operation, 'projectClosed');
    expect(auditRows.single.entityType, 'project');
    expect(auditRows.single.entityId, 'project-1');
    expect(auditRows.single.entityLabel, 'Proyecto');
  });

  test('updated_at cambia en toda escritura y created_at nunca', () async {
    final created = DateTime.utc(2026, 1, 1);
    await db.into(db.projects).insert(seedProject(at: created, id: 'project-1'));

    final updateAt = created.add(const Duration(days: 1));
    await repository.setStatus(const ProjectId('project-1'), domain.ProjectStatus.closed, updateAt);

    final row = (await db.select(db.projects).get()).single;
    expect(row.createdAt, created);
    expect(row.updatedAt, updateAt);
  });

  test('ProjectCounters cuenta correctamente tras altas y bajas lógicas', () async {
    final at = DateTime.utc(2026, 1, 1);
    await db.into(db.projects).insert(seedProject(at: at, id: 'project-1'));

    await db.into(db.stakeholders).insert(
          seedStakeholder(at: at, projectId: 'project-1', id: 's1', status: 'active'),
        );
    await db.into(db.stakeholders).insert(
          seedStakeholder(at: at, projectId: 'project-1', id: 's2', status: 'active'),
        );
    await db.into(db.stakeholders).insert(
          seedStakeholder(at: at, projectId: 'project-1', id: 's3', status: 'inactive'),
        );

    await db.into(db.sessions).insert(seedSession(at: at, projectId: 'project-1', id: 'sess1'));
    await db.into(db.sessions).insert(seedSession(at: at, projectId: 'project-1', id: 'sess2'));
    await db.into(db.sessions).insert(
          seedSession(at: at, projectId: 'project-1', id: 'sess3', deletedAt: at),
        );

    await db.into(db.glossaryTerms).insert(seedGlossaryTerm(at: at, projectId: 'project-1', id: 'g1'));
    await db.into(db.glossaryTerms).insert(
          seedGlossaryTerm(at: at, projectId: 'project-1', id: 'g2', deletedAt: at),
        );

    final counters = await repository.watchCounters(const ProjectId('project-1')).first;
    expect(counters.stakeholders, 2);
    expect(counters.sessions, 2);
    expect(counters.glossaryTerms, 1);
  });

  test('entity_label conserva el nombre del proyecto al momento del asiento', () async {
    final at = DateTime.utc(2026, 1, 1);
    await db.into(db.projects).insert(seedProject(at: at, id: 'project-1', name: 'Nombre original'));

    // Cierra con el nombre original.
    await repository.setStatus(
      const ProjectId('project-1'),
      domain.ProjectStatus.closed,
      at.add(const Duration(days: 1)),
    );
    // Reabre.
    await repository.setStatus(
      const ProjectId('project-1'),
      domain.ProjectStatus.active,
      at.add(const Duration(days: 2)),
    );
    // Renombra tras reabrir.
    await repository.update(
      domain.Project(
        id: const ProjectId('project-1'),
        name: 'Nombre nuevo',
        status: domain.ProjectStatus.active,
        createdAt: at,
        updatedAt: at.add(const Duration(days: 3)),
      ),
    );
    // Cierra de nuevo con el nombre nuevo.
    await repository.setStatus(
      const ProjectId('project-1'),
      domain.ProjectStatus.closed,
      at.add(const Duration(days: 4)),
    );

    final auditRows = await (db.select(db.auditEntries)
          ..orderBy([(a) => drift.OrderingTerm(expression: a.occurredAt)]))
        .get();

    expect(auditRows, hasLength(3));
    expect(auditRows[0].operation, 'projectClosed');
    expect(auditRows[0].entityLabel, 'Nombre original');
    expect(auditRows[2].operation, 'projectClosed');
    expect(auditRows[2].entityLabel, 'Nombre nuevo');
  });
}
