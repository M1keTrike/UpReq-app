import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/project_repository_impl.dart';
import '../entities/project.dart';
import '../project_repository.dart';

part 'close_project.g.dart';

final class CloseProject {
  const CloseProject(this._repository, this._clock);

  final ProjectRepository _repository;
  final Clock _clock;

  Future<Result<void>> call(ProjectId id) async {
    final current = await _repository.findById(id);
    if (current == null) {
      return Err(NotFoundFailure('No se encontró el proyecto $id.'));
    }
    if (current.status == ProjectStatus.closed) {
      return Err(ProjectClosedFailure('El proyecto $id ya está cerrado.'));
    }

    await _repository.setStatus(id, ProjectStatus.closed, _clock.now());
    return const Ok(null);
  }
}

@riverpod
CloseProject closeProject(Ref ref) {
  return CloseProject(ref.watch(projectRepositoryProvider), ref.watch(clockProvider));
}
