import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/script_point_repository_impl.dart';
import '../script_point_repository.dart';

part 'reorder_script_point.g.dart';

final class ReorderScriptPoint {
  const ReorderScriptPoint(this._repository, this._statusReader);

  final ScriptPointRepository _repository;
  final ProjectStatusReader _statusReader;

  /// Preserva el invariante `0..n-1` (data-model.md): `to` debe caer dentro
  /// del rango vivo actual de la sesión. Sin marca de tiempo propia: el
  /// contrato de `move` no lleva `at` (reordenar no es una edición de
  /// contenido, así que no bumpea `updated_at`).
  Future<Result<void>> call(SessionId session, ScriptPointId id, int from, int to) async {
    final current = await _repository.findById(id);
    if (current == null) {
      return Err(NotFoundFailure('No se encontró el punto de guion $id.'));
    }
    if (!await _statusReader.isActive(current.projectId)) {
      return Err(ProjectClosedFailure('El proyecto ${current.projectId} está cerrado.'));
    }

    final points = await _repository.watchBySession(session).first;
    final n = points.length;
    if (from < 0 || from >= n || to < 0 || to >= n) {
      return const Err(ValidationFailure('La posición de destino no es válida.'));
    }

    await _repository.move(session, id, from, to);
    return const Ok(null);
  }
}

@riverpod
ReorderScriptPoint reorderScriptPoint(Ref ref) {
  return ReorderScriptPoint(
    ref.watch(scriptPointRepositoryProvider),
    ref.watch(projectStatusReaderProvider),
  );
}
