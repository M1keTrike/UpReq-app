import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/stakeholders/data/stakeholder_repository_impl.dart';
import 'package:up_req/features/stakeholders/domain/stakeholder_repository.dart';

import '../../data/session_repository_impl.dart';
import '../entities/elicitation_session.dart';
import '../entities/session_draft.dart';
import '../session_repository.dart';

part 'update_session_header.g.dart';

final class UpdateSessionHeader {
  const UpdateSessionHeader(
    this._repository,
    this._stakeholderRepository,
    this._statusReader,
    this._clock,
  );

  final SessionRepository _repository;
  final StakeholderRepository _stakeholderRepository;
  final ProjectStatusReader _statusReader;
  final Clock _clock;

  /// Rechazada con `SessionHeaderFrozenFailure` si la sesión está cerrada
  /// (FR-008b, invariante I7); las notas y el guion siguen siendo editables
  /// por otros casos de uso.
  Future<Result<void>> call(SessionId id, SessionDraft draft) async {
    final failure = draft.validate();
    if (failure != null) return Err(failure);

    final current = await _repository.findById(id);
    if (current == null) {
      return Err(NotFoundFailure('No se encontró la sesión $id.'));
    }
    if (!await _statusReader.isActive(current.projectId)) {
      return Err(ProjectClosedFailure('El proyecto ${current.projectId} está cerrado.'));
    }
    if (current.status == SessionStatus.closed) {
      return Err(
        SessionHeaderFrozenFailure(
          'La cabecera de la sesión $id está congelada porque está cerrada.',
        ),
      );
    }

    for (final participantId in draft.participantIds) {
      final stakeholder = await _stakeholderRepository.findById(participantId);
      if (stakeholder == null || stakeholder.projectId != current.projectId) {
        return Err(
          CrossProjectReferenceFailure(
            'El interesado $participantId no pertenece al proyecto ${current.projectId}.',
          ),
        );
      }
    }

    // Reemplazo completo de los campos de cabecera desde el draft, no
    // `copyWith`: `location` puede pasar a `null` a propósito (el usuario
    // vació el campo), y `copyWith` con `?? valorAnterior` no distingue "sin
    // cambio" de "borrado" (patrón de UpdateProject).
    final updated = ElicitationSession(
      id: current.id,
      projectId: current.projectId,
      title: draft.title.trim(),
      scheduledAt: draft.scheduledAt,
      technique: draft.technique,
      location: draft.location,
      status: current.status,
      notes: current.notes,
      closedAt: current.closedAt,
      createdAt: current.createdAt,
      updatedAt: _clock.now(),
    );

    await _repository.updateHeader(updated, draft.participantIds);
    return const Ok(null);
  }
}

@riverpod
UpdateSessionHeader updateSessionHeader(Ref ref) {
  return UpdateSessionHeader(
    ref.watch(sessionRepositoryProvider),
    ref.watch(stakeholderRepositoryProvider),
    ref.watch(projectStatusReaderProvider),
    ref.watch(clockProvider),
  );
}
