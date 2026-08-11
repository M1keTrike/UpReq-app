import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/result.dart';

import 'entities/elicitation_session.dart';

/// Función pura que concentra FR-008a en un único punto probable de forma
/// exhaustiva: avance en un solo sentido, sin retroceso ni reapertura.
///
/// ```text
/// planned → inProgress | closed      válida
/// inProgress → closed                válida
/// cualquier retroceso o auto-transición   InvalidSessionTransitionFailure
/// ```
Result<SessionStatus> transitionSession(SessionStatus from, SessionStatus to) {
  return switch ((from, to)) {
    (SessionStatus.planned, SessionStatus.inProgress) => const Ok(SessionStatus.inProgress),
    (SessionStatus.planned, SessionStatus.closed) => const Ok(SessionStatus.closed),
    (SessionStatus.inProgress, SessionStatus.closed) => const Ok(SessionStatus.closed),
    (SessionStatus.planned, SessionStatus.planned) ||
    (SessionStatus.inProgress, SessionStatus.planned) ||
    (SessionStatus.inProgress, SessionStatus.inProgress) ||
    (SessionStatus.closed, SessionStatus.planned) ||
    (SessionStatus.closed, SessionStatus.inProgress) ||
    (SessionStatus.closed, SessionStatus.closed) =>
      Err(
        InvalidSessionTransitionFailure(
          'No se puede pasar de ${from.name} a ${to.name}.',
        ),
      ),
  };
}
