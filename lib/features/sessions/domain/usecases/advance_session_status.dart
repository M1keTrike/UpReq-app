import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/session_repository_impl.dart';
import '../entities/elicitation_session.dart';
import '../session_repository.dart';
import '../session_transition.dart';

part 'advance_session_status.g.dart';

final class AdvanceSessionStatus {
  const AdvanceSessionStatus(this._repository, this._statusReader, this._clock);

  final SessionRepository _repository;
  final ProjectStatusReader _statusReader;
  final Clock _clock;

  /// Usa `transitionSession` para la validación exhaustiva de FR-008a;
  /// `setStatus` sella `closed_at` al cerrar.
  Future<Result<void>> call(SessionId id, SessionStatus to) async {
    final current = await _repository.findById(id);
    if (current == null) {
      return Err(NotFoundFailure('No se encontró la sesión $id.'));
    }
    if (!await _statusReader.isActive(current.projectId)) {
      return Err(ProjectClosedFailure('El proyecto ${current.projectId} está cerrado.'));
    }

    final transition = transitionSession(current.status, to);
    if (transition is Err<SessionStatus>) {
      return Err(transition.failure);
    }

    await _repository.setStatus(id, to, _clock.now());
    return const Ok(null);
  }
}

@riverpod
AdvanceSessionStatus advanceSessionStatus(Ref ref) {
  return AdvanceSessionStatus(
    ref.watch(sessionRepositoryProvider),
    ref.watch(projectStatusReaderProvider),
    ref.watch(clockProvider),
  );
}
