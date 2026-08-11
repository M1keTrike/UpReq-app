import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/stakeholder_repository_impl.dart';
import '../entities/stakeholder.dart';
import '../entities/stakeholder_draft.dart';
import '../stakeholder_repository.dart';

part 'create_stakeholder.g.dart';

final class CreateStakeholder {
  const CreateStakeholder(
    this._repository,
    this._statusReader,
    this._clock,
    this._idGenerator,
  );

  final StakeholderRepository _repository;
  final ProjectStatusReader _statusReader;
  final Clock _clock;
  final IdGenerator _idGenerator;

  Future<Result<StakeholderId>> call(ProjectId projectId, StakeholderDraft draft) async {
    final failure = draft.validate();
    if (failure != null) return Err(failure);

    if (!await _statusReader.isActive(projectId)) {
      return Err(ProjectClosedFailure('El proyecto $projectId está cerrado.'));
    }

    final now = _clock.now();
    final stakeholder = Stakeholder(
      id: StakeholderId(_idGenerator.generate()),
      projectId: projectId,
      name: draft.name.trim(),
      role: draft.role,
      area: draft.area,
      influence: draft.influence,
      notes: draft.notes,
      status: StakeholderStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.insert(stakeholder);
    return Ok(stakeholder.id);
  }
}

@riverpod
CreateStakeholder createStakeholder(Ref ref) {
  return CreateStakeholder(
    ref.watch(stakeholderRepositoryProvider),
    ref.watch(projectStatusReaderProvider),
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
  );
}
