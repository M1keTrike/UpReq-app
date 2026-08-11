import 'package:up_req/core/domain/ids.dart';

import 'entities/elicitation_session.dart';
import 'entities/session_detail.dart';

abstract interface class SessionRepository {
  /// Solo vivas, del proyecto (FR-018).
  Stream<List<ElicitationSession>> watchByProject(ProjectId id);

  /// Sesión + participantes + contadores en un único stream (FR-013).
  Stream<SessionDetail?> watchDetail(SessionId id);

  Future<ElicitationSession?> findById(SessionId id);

  /// Inserta sesión y participantes en una transacción. FR-009.
  Future<void> insert(ElicitationSession session, List<StakeholderId> participantIds);

  /// Reemplaza cabecera y participantes en una transacción. Rechazada por
  /// dominio (`SessionHeaderFrozenFailure`) si la sesión está cerrada.
  Future<void> updateHeader(ElicitationSession session, List<StakeholderId> participantIds);

  /// Permitido con la sesión cerrada (FR-008b, invariante I7).
  Future<void> updateNotes(SessionId id, String? notes, DateTime at);

  /// Sella `closed_at` al pasar a `closed`.
  Future<void> setStatus(SessionId id, SessionStatus status, DateTime at);

  /// Marca `deleted_at` y asienta bitácora en la misma transacción.
  /// FR-014a, FR-015. NO toca los puntos de guion: conservan su fila y su
  /// `deleted_at` nulo, y dejan de verse por la condición sobre la sesión en
  /// `alive()`. Escribe UN solo asiento `sessionDeleted`, nunca uno por
  /// punto (invariante I9).
  Future<void> softDelete(SessionId id, DateTime at);
}
