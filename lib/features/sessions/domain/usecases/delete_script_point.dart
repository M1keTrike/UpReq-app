import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/script_point_repository_impl.dart';
import '../script_point_repository.dart';

part 'delete_script_point.g.dart';

final class DeleteScriptPoint {
  const DeleteScriptPoint(this._repository, this._statusReader, this._clock);

  final ScriptPointRepository _repository;
  final ProjectStatusReader _statusReader;
  final Clock _clock;

  /// Compacta posiciones y asienta **un** `scriptPointDeleted`, todo en la
  /// transacción del repositorio (T089).
  Future<Result<void>> call(ScriptPointId id) async {
    final current = await _repository.findById(id);
    if (current == null) {
      return Err(NotFoundFailure('No se encontró el punto de guion $id.'));
    }
    if (!await _statusReader.isActive(current.projectId)) {
      return Err(ProjectClosedFailure('El proyecto ${current.projectId} está cerrado.'));
    }

    await _repository.softDelete(id, _clock.now());
    return const Ok(null);
  }
}

@riverpod
DeleteScriptPoint deleteScriptPoint(Ref ref) {
  return DeleteScriptPoint(
    ref.watch(scriptPointRepositoryProvider),
    ref.watch(projectStatusReaderProvider),
    ref.watch(clockProvider),
  );
}
