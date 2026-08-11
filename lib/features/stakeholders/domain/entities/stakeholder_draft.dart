import 'package:up_req/core/domain/failures.dart';

import 'stakeholder.dart';

/// Campos editables de un interesado (data-model.md, "Reglas de validación
/// por formulario"). `influence` es obligatoria pero con valor por defecto
/// `medium`, así que el formulario nunca la deja sin elegir.
final class StakeholderDraft {
  const StakeholderDraft({
    required this.name,
    this.influence = InfluenceLevel.medium,
    this.role,
    this.area,
    this.notes,
  });

  final String name;
  final String? role;
  final String? area;
  final InfluenceLevel influence;
  final String? notes;

  ValidationFailure? validate() {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const ValidationFailure('El nombre del interesado es obligatorio.');
    }
    if (trimmedName.length > 120) {
      return const ValidationFailure(
        'El nombre del interesado no puede superar los 120 caracteres.',
      );
    }
    if ((role?.length ?? 0) > 120) {
      return const ValidationFailure('El rol no puede superar los 120 caracteres.');
    }
    if ((area?.length ?? 0) > 120) {
      return const ValidationFailure('El área no puede superar los 120 caracteres.');
    }
    return null;
  }
}
