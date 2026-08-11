import 'package:drift/drift.dart' as drift;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/database/app_database.dart' as db;
import 'package:up_req/core/database/database_provider.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';

import '../domain/entities/glossary_term.dart' as domain;
import '../domain/glossary_repository.dart';
import 'glossary_dao.dart';

part 'glossary_repository_impl.g.dart';

class GlossaryRepositoryImpl implements GlossaryRepository {
  GlossaryRepositoryImpl(this._db, this._dao, this._idGenerator);

  final db.AppDatabase _db;
  final GlossaryDao _dao;
  final IdGenerator _idGenerator;

  @override
  Stream<List<domain.GlossaryTerm>> watchByProject(ProjectId id) {
    return _dao.watchByProject(id.value).map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<domain.GlossaryTerm?> findById(GlossaryTermId id) async {
    final row = await _dao.findById(id.value);
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> insert(domain.GlossaryTerm term) {
    return _dao.insertTerm(
      db.GlossaryTermsCompanion.insert(
        id: term.id.value,
        projectId: term.projectId.value,
        term: term.term,
        definition: drift.Value(term.definition),
        notes: drift.Value(term.notes),
        termSortKey: term.termSortKey,
        createdAt: term.createdAt,
        updatedAt: term.updatedAt,
      ),
    );
  }

  @override
  Future<void> update(domain.GlossaryTerm term) {
    return _dao.updateTerm(
      term.id.value,
      db.GlossaryTermsCompanion(
        term: drift.Value(term.term),
        definition: drift.Value(term.definition),
        notes: drift.Value(term.notes),
        termSortKey: drift.Value(term.termSortKey),
        updatedAt: drift.Value(term.updatedAt),
      ),
    );
  }

  /// Marca `deleted_at` y asienta bitácora en la misma transacción,
  /// copiando en `entity_label` el término (patrón de T041).
  @override
  Future<void> softDelete(GlossaryTermId id, DateTime at) async {
    await _db.transaction(() async {
      final current = await _dao.findById(id.value);
      if (current == null) return;

      await _dao.updateTerm(
        id.value,
        db.GlossaryTermsCompanion(deletedAt: drift.Value(at), updatedAt: drift.Value(at)),
      );

      await _db.into(_db.auditEntries).insert(
            db.AuditEntriesCompanion.insert(
              id: _idGenerator.generate(),
              projectId: current.projectId,
              operation: 'glossaryTermDeleted',
              entityType: 'glossaryTerm',
              entityId: id.value,
              entityLabel: drift.Value(current.term),
              occurredAt: at,
              createdAt: at,
              updatedAt: at,
            ),
          );
    });
  }

  domain.GlossaryTerm _toDomain(db.GlossaryTerm row) {
    return domain.GlossaryTerm(
      id: GlossaryTermId(row.id),
      projectId: ProjectId(row.projectId),
      term: row.term,
      definition: row.definition,
      notes: row.notes,
      termSortKey: row.termSortKey,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

@Riverpod(keepAlive: true)
GlossaryRepository glossaryRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  return GlossaryRepositoryImpl(
    database,
    GlossaryDao(database),
    ref.watch(idGeneratorProvider),
  );
}
