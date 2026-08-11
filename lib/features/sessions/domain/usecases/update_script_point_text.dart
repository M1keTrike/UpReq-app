import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/script_point_repository_impl.dart';
import '../script_point_repository.dart';

part 'update_script_point_text.g.dart';

final class UpdateScriptPointText {
  const UpdateScriptPointText(this._repository, this._statusReader, this._clock);

  final ScriptPointRepository _repository;
  final ProjectStatusReader _statusReader;
  final Clock _clock;

  /// Permitido con la sesión cerrada (FR-011): solo la cabecera de la
  /// sesión se congela al cerrar (invariante I7), el guion no.
  Future<Result<void>> call(ScriptPointId id, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const Err(ValidationFailure('El texto del punto es obligatorio.'));
    }
    if (trimmed.length > 500) {
      return const Err(
        ValidationFailure('El texto del punto no puede superar los 500 caracteres.'),
      );
    }

    final current = await _repository.findById(id);
    if (current == null) {
      return Err(NotFoundFailure('No se encontró el punto de guion $id.'));
    }
    if (!await _statusReader.isActive(current.projectId)) {
      return Err(ProjectClosedFailure('El proyecto ${current.projectId} está cerrado.'));
    }

    await _repository.updateText(id, trimmed, _clock.now());
    return const Ok(null);
  }
}

@riverpod
UpdateScriptPointText updateScriptPointText(Ref ref) {
  return UpdateScriptPointText(
    ref.watch(scriptPointRepositoryProvider),
    ref.watch(projectStatusReaderProvider),
    ref.watch(clockProvider),
  );
}
