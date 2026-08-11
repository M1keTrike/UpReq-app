import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/project_repository_impl.dart';
import '../entities/project.dart';
import '../entities/project_draft.dart';
import '../project_repository.dart';

part 'update_project.g.dart';

final class UpdateProject {
  const UpdateProject(this._repository, this._clock);

  final ProjectRepository _repository;
  final Clock _clock;

  Future<Result<void>> call(ProjectId id, ProjectDraft draft) async {
    final failure = draft.validate();
    if (failure != null) return Err(failure);

    final current = await _repository.findById(id);
    if (current == null) {
      return Err(NotFoundFailure('No se encontró el proyecto $id.'));
    }
    if (current.status == ProjectStatus.closed) {
      return Err(ProjectClosedFailure('El proyecto $id está cerrado.'));
    }

    // Reemplazo completo desde el draft, no `copyWith`: `client`/
    // `description` pueden pasar a `null` a propósito (el usuario vació el
    // campo), y `copyWith` con `?? valorAnterior` no distingue "sin cambio"
    // de "borrado".
    final updated = Project(
      id: current.id,
      name: draft.name.trim(),
      client: draft.client,
      description: draft.description,
      status: current.status,
      createdAt: current.createdAt,
      updatedAt: _clock.now(),
    );

    await _repository.update(updated);
    return const Ok(null);
  }
}

@riverpod
UpdateProject updateProject(Ref ref) {
  return UpdateProject(ref.watch(projectRepositoryProvider), ref.watch(clockProvider));
}
