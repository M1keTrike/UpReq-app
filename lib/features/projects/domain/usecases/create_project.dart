import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/project_repository_impl.dart';
import '../entities/project.dart';
import '../entities/project_draft.dart';
import '../project_repository.dart';

part 'create_project.g.dart';

final class CreateProject {
  const CreateProject(this._repository, this._clock, this._idGenerator);

  final ProjectRepository _repository;
  final Clock _clock;
  final IdGenerator _idGenerator;

  Future<Result<ProjectId>> call(ProjectDraft draft) async {
    final failure = draft.validate();
    if (failure != null) return Err(failure);

    final now = _clock.now();
    final project = Project(
      id: ProjectId(_idGenerator.generate()),
      name: draft.name.trim(),
      client: draft.client,
      description: draft.description,
      status: ProjectStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.insert(project);
    return Ok(project.id);
  }
}

@riverpod
CreateProject createProject(Ref ref) {
  return CreateProject(
    ref.watch(projectRepositoryProvider),
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
  );
}
