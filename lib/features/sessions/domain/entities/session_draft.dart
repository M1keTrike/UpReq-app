import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';

import 'elicitation_session.dart';

/// Campos editables de la cabecera de una sesión y sus participantes
/// (data-model.md, "Reglas de validación por formulario"). La comprobación
/// de que todos los participantes pertenecen al mismo proyecto no vive aquí
/// porque requiere consultar otro repositorio; la hacen los casos de uso
/// `CreateSession` y `UpdateSessionHeader` (invariante I8).
final class SessionDraft {
  const SessionDraft({
    required this.title,
    required this.scheduledAt,
    required this.technique,
    required this.participantIds,
    this.location,
    this.notes,
  });

  final String title;
  final DateTime scheduledAt;
  final SessionTechnique technique;
  final String? location;
  final String? notes;
  final List<StakeholderId> participantIds;

  /// `null` si es válido; el fallo describible al usuario en caso contrario.
  /// La validación falla antes de tocar la base de datos (FR-022).
  ValidationFailure? validate() {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return const ValidationFailure('El título de la sesión es obligatorio.');
    }
    if (trimmedTitle.length > 160) {
      return const ValidationFailure(
        'El título de la sesión no puede superar los 160 caracteres.',
      );
    }
    if ((location?.length ?? 0) > 160) {
      return const ValidationFailure('El lugar no puede superar los 160 caracteres.');
    }
    if (participantIds.isEmpty) {
      return const ValidationFailure(
        'La sesión debe tener al menos un participante.',
      );
    }
    return null;
  }
}
