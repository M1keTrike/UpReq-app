import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/session_repository_impl.dart';
import '../session_repository.dart';

part 'update_session_notes.g.dart';

final class UpdateSessionNotes {
  const UpdateSessionNotes(this._repository, this._statusReader, this._clock);

  final SessionRepository _repository;
  final ProjectStatusReader _statusReader;
  final Clock _clock;

  /// Permitido aunque la sesión esté cerrada (FR-008b, invariante I7): a
  /// diferencia de `UpdateSessionHeader`, no comprueba `status`.
  Future<Result<void>> call(SessionId id, String? notes) async {
    final current = await _repository.findById(id);
    if (current == null) {
      return Err(NotFoundFailure('No se encontró la sesión $id.'));
    }
    if (!await _statusReader.isActive(current.projectId)) {
      return Err(ProjectClosedFailure('El proyecto ${current.projectId} está cerrado.'));
    }

    await _repository.updateNotes(id, notes, _clock.now());
    return const Ok(null);
  }
}

@riverpod
UpdateSessionNotes updateSessionNotes(Ref ref) {
  return UpdateSessionNotes(
    ref.watch(sessionRepositoryProvider),
    ref.watch(projectStatusReaderProvider),
    ref.watch(clockProvider),
  );
}
