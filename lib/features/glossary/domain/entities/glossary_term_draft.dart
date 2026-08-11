import 'package:up_req/core/domain/failures.dart';

/// Campos editables de un término del glosario (data-model.md, "Reglas de
/// validación por formulario"). `term` es la única obligatoria.
final class GlossaryTermDraft {
  const GlossaryTermDraft({
    required this.term,
    this.definition,
    this.notes,
  });

  final String term;
  final String? definition;
  final String? notes;

  ValidationFailure? validate() {
    final trimmedTerm = term.trim();
    if (trimmedTerm.isEmpty) {
      return const ValidationFailure('El término es obligatorio.');
    }
    if (trimmedTerm.length > 120) {
      return const ValidationFailure('El término no puede superar los 120 caracteres.');
    }
    if ((definition?.length ?? 0) > 2000) {
      return const ValidationFailure('La definición no puede superar los 2000 caracteres.');
    }
    return null;
  }
}
