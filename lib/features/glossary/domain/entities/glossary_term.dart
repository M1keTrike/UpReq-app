import 'package:up_req/core/domain/ids.dart';

/// Término del glosario de un proyecto (FR-012). Inmutable. `termSortKey` se
/// calcula a partir de `term` (ver `domain/term_sort_key.dart`) y se
/// recalcula en cada escritura.
final class GlossaryTerm {
  const GlossaryTerm({
    required this.id,
    required this.projectId,
    required this.term,
    required this.termSortKey,
    required this.createdAt,
    required this.updatedAt,
    this.definition,
    this.notes,
  });

  final GlossaryTermId id;
  final ProjectId projectId;
  final String term;
  final String? definition;
  final String? notes;
  final String termSortKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      other is GlossaryTerm &&
      other.id == id &&
      other.projectId == projectId &&
      other.term == term &&
      other.definition == definition &&
      other.notes == notes &&
      other.termSortKey == termSortKey &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        projectId,
        term,
        definition,
        notes,
        termSortKey,
        createdAt,
        updatedAt,
      );

  @override
  String toString() => 'GlossaryTerm($id, $term)';
}
