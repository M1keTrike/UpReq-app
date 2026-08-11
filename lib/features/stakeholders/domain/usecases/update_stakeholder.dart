import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/stakeholder_repository_impl.dart';
import '../entities/stakeholder.dart';
import '../entities/stakeholder_draft.dart';
import '../stakeholder_repository.dart';

part 'update_stakeholder.g.dart';

final class UpdateStakeholder {
  const UpdateStakeholder(this._repository, this._statusReader, this._clock);

  final StakeholderRepository _repository;
  final ProjectStatusReader _statusReader;
  final Clock _clock;

  Future<Result<void>> call(StakeholderId id, StakeholderDraft draft) async {
    final failure = draft.validate();
    if (failure != null) return Err(failure);

    final current = await _repository.findById(id);
    if (current == null) {
      return Err(NotFoundFailure('No se encontró el interesado $id.'));
    }
    if (!await _statusReader.isActive(current.projectId)) {
      return Err(ProjectClosedFailure('El proyecto ${current.projectId} está cerrado.'));
    }

    final updated = Stakeholder(
      id: current.id,
      projectId: current.projectId,
      name: draft.name.trim(),
      role: draft.role,
      area: draft.area,
      influence: draft.influence,
      notes: draft.notes,
      status: current.status,
      createdAt: current.createdAt,
      updatedAt: _clock.now(),
    );

    await _repository.update(updated);
    return const Ok(null);
  }
}

@riverpod
UpdateStakeholder updateStakeholder(Ref ref) {
  return UpdateStakeholder(
    ref.watch(stakeholderRepositoryProvider),
    ref.watch(projectStatusReaderProvider),
    ref.watch(clockProvider),
  );
}
