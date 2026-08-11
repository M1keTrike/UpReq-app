import 'package:drift/drift.dart';
import 'package:up_req/core/database/app_database.dart';
import 'package:up_req/core/database/tables/glossary_terms.dart';

part 'glossary_dao.g.dart';

@DriftAccessor(tables: [GlossaryTerms])
class GlossaryDao extends DatabaseAccessor<AppDatabase> with _$GlossaryDaoMixin {
  GlossaryDao(super.db);

  /// Vivos del proyecto, ordenados por `term_sort_key` en SQL (nunca en
  /// Dart). Único helper de filtrado por proyecto (data-model.md,
  /// "Aislamiento por proyecto", invariante I4).
  Stream<List<GlossaryTerm>> watchByProject(String projectId) {
    return (select(glossaryTerms)
          ..where((t) => t.projectId.equals(projectId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.termSortKey)]))
        .watch();
  }

  Future<GlossaryTerm?> findById(String id) {
    return (select(glossaryTerms)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertTerm(GlossaryTermsCompanion companion) => into(glossaryTerms).insert(companion);

  Future<void> updateTerm(String id, GlossaryTermsCompanion companion) {
    return (update(glossaryTerms)..where((t) => t.id.equals(id))).write(companion);
  }
}
