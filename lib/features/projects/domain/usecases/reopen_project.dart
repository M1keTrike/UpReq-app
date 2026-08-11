import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/project_repository_impl.dart';
import '../entities/project.dart';
import '../project_repository.dart';

part 'reopen_project.g.dart';

final class ReopenProject {
  const ReopenProject(this._repository, this._clock);

  final ProjectRepository _repository;
  final Clock _clock;

  Future<Result<void>> call(ProjectId id) async {
    final current = await _repository.findById(id);
    if (current == null) {
      return Err(NotFoundFailure('No se encontró el proyecto $id.'));
    }
    if (current.status == ProjectStatus.active) {
      // Ya está activo: no hay nada que reabrir. Idempotente a propósito, sin
      // escritura ni asiento de bitácora nuevo.
      return const Ok(null);
    }

    await _repository.setStatus(id, ProjectStatus.active, _clock.now());
    return const Ok(null);
  }
}

@riverpod
ReopenProject reopenProject(Ref ref) {
  return ReopenProject(ref.watch(projectRepositoryProvider), ref.watch(clockProvider));
}
