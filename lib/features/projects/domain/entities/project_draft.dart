import 'package:up_req/core/domain/failures.dart';

/// Objeto de valor con los campos editables de un proyecto y sus reglas de
/// validación (data-model.md, "Reglas de validación por formulario").
final class ProjectDraft {
  const ProjectDraft({required this.name, this.client, this.description});

  final String name;
  final String? client;
  final String? description;

  /// `null` si es válido; el fallo describible al usuario en caso contrario.
  /// La validación falla antes de tocar la base de datos (FR-022).
  ValidationFailure? validate() {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const ValidationFailure('El nombre del proyecto es obligatorio.');
    }
    if (trimmedName.length > 120) {
      return const ValidationFailure(
        'El nombre del proyecto no puede superar los 120 caracteres.',
      );
    }
    if ((client?.length ?? 0) > 120) {
      return const ValidationFailure(
        'El cliente no puede superar los 120 caracteres.',
      );
    }
    if ((description?.length ?? 0) > 500) {
      return const ValidationFailure(
        'La descripción no puede superar los 500 caracteres.',
      );
    }
    return null;
  }
}
