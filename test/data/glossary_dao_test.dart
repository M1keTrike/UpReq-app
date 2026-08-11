import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/database/app_database.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/glossary/data/glossary_dao.dart';
import 'package:up_req/features/glossary/data/glossary_repository_impl.dart';

import '../support/seed.dart';
import '../support/test_container.dart';
import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  late GlossaryRepositoryImpl repository;

  setUp(() {
    db = openTestDatabase();
    repository = GlossaryRepositoryImpl(
      db,
      GlossaryDao(db),
      SequentialIdGenerator(prefix: 'audit'),
    );
  });

  tearDown(() => db.close());

  test('el orden por term_sort_key ignora mayúsculas y acentos', () async {
    final at = DateTime.utc(2026, 1, 1);
    await db.into(db.projects).insert(seedProject(at: at, id: 'project-1'));
    await db.into(db.glossaryTerms).insert(
          seedGlossaryTerm(
            at: at,
            projectId: 'project-1',
            id: 't-zeta',
            term: 'Zeta',
            termSortKey: 'zeta',
          ),
        );
    await db.into(db.glossaryTerms).insert(
          seedGlossaryTerm(
            at: at,
            projectId: 'project-1',
            id: 't-abaco-tilde',
            term: 'Ábaco',
            termSortKey: 'abaco',
          ),
        );
    await db.into(db.glossaryTerms).insert(
          seedGlossaryTerm(
            at: at,
            projectId: 'project-1',
            id: 't-abaco',
            term: 'abaco',
            termSortKey: 'abaco',
          ),
        );

    final terms = await repository.watchByProject(const ProjectId('project-1')).first;

    expect(terms.map((t) => t.id.value).toList(), [
      't-abaco-tilde',
      't-abaco',
      't-zeta',
    ]);
  });

  test('eliminación lógica conserva la fila y asienta bitácora', () async {
    final at = DateTime.utc(2026, 1, 1);
    await db.into(db.projects).insert(seedProject(at: at, id: 'project-1'));
    await db.into(db.glossaryTerms).insert(
          seedGlossaryTerm(at: at, projectId: 'project-1', id: 't1', term: 'Requisito'),
        );

    await repository.softDelete(const GlossaryTermId('t1'), at.add(const Duration(days: 1)));

    final rows = await db.select(db.glossaryTerms).get();
    expect(rows, hasLength(1));
    expect(rows.single.deletedAt, isNotNull);

    final auditRows = await db.select(db.auditEntries).get();
    expect(auditRows, hasLength(1));
    expect(auditRows.single.operation, 'glossaryTermDeleted');
    expect(auditRows.single.entityType, 'glossaryTerm');
    expect(auditRows.single.entityLabel, 'Requisito');

    final alive = await repository.watchByProject(const ProjectId('project-1')).first;
    expect(alive, isEmpty);
  });

  test('updated_at cambia en toda escritura (FR-016)', () async {
    final created = DateTime.utc(2026, 1, 1);
    await db.into(db.projects).insert(seedProject(at: created, id: 'project-1'));
    await db.into(db.glossaryTerms).insert(
          seedGlossaryTerm(at: created, projectId: 'project-1', id: 't1'),
        );

    final updateAt = created.add(const Duration(days: 1));
    await repository.softDelete(const GlossaryTermId('t1'), updateAt);

    final row = (await db.select(db.glossaryTerms).get()).single;
    expect(row.createdAt, created);
    expect(row.updatedAt, updateAt);
  });

  test('invariante I4: nunca devuelve términos de otro proyecto', () async {
    final at = DateTime.utc(2026, 1, 1);
    await db.into(db.projects).insert(seedProject(at: at, id: 'project-1'));
    await db.into(db.projects).insert(seedProject(at: at, id: 'project-2', name: 'Otro proyecto'));

    await db.into(db.glossaryTerms).insert(
          seedGlossaryTerm(at: at, projectId: 'project-1', id: 't1', term: 'De uno'),
        );
    await db.into(db.glossaryTerms).insert(
          seedGlossaryTerm(at: at, projectId: 'project-2', id: 't2', term: 'De dos'),
        );

    final ofProjectOne = await repository.watchByProject(const ProjectId('project-1')).first;

    expect(ofProjectOne.map((t) => t.term), ['De uno']);
  });
}
