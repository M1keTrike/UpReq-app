import 'package:up_req/core/domain/ids.dart';

import 'entities/glossary_term.dart';

abstract interface class GlossaryRepository {
  /// Vivos, ordenados por `term_sort_key`. FR-012. El orden se resuelve
  /// siempre en SQL, nunca en Dart.
  Stream<List<GlossaryTerm>> watchByProject(ProjectId id);

  Future<GlossaryTerm?> findById(GlossaryTermId id);
  Future<void> insert(GlossaryTerm term);
  Future<void> update(GlossaryTerm term);

  /// Marca `deleted_at` y asienta bitácora `glossaryTermDeleted` en la misma
  /// transacción, copiando en `entity_label` el término. FR-014a, FR-015.
  Future<void> softDelete(GlossaryTermId id, DateTime at);
}
