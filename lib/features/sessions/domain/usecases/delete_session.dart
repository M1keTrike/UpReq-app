import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/session_repository_impl.dart';
import '../session_repository.dart';

part 'delete_session.g.dart';

final class DeleteSession {
  const DeleteSession(this._repository, this._statusReader, this._clock);

  final SessionRepository _repository;
  final ProjectStatusReader _statusReader;
  final Clock _clock;

  /// Asienta **un** `sessionDeleted`; los puntos de guion conservan su fila
  /// y desaparecen por visibilidad transitiva (invariante I9).
  Future<Result<void>> call(SessionId id) async {
    final current = await _repository.findById(id);
    if (current == null) {
      return Err(NotFoundFailure('No se encontró la sesión $id.'));
    }
    if (!await _statusReader.isActive(current.projectId)) {
      return Err(ProjectClosedFailure('El proyecto ${current.projectId} está cerrado.'));
    }

    await _repository.softDelete(id, _clock.now());
    return const Ok(null);
  }
}

@riverpod
DeleteSession deleteSession(Ref ref) {
  return DeleteSession(
    ref.watch(sessionRepositoryProvider),
    ref.watch(projectStatusReaderProvider),
    ref.watch(clockProvider),
  );
}
