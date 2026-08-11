import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/stakeholder_repository_impl.dart';
import '../stakeholder_repository.dart';

part 'deactivate_stakeholder.g.dart';

final class DeactivateStakeholder {
  const DeactivateStakeholder(this._repository, this._statusReader, this._clock);

  final StakeholderRepository _repository;
  final ProjectStatusReader _statusReader;
  final Clock _clock;

  Future<Result<void>> call(StakeholderId id) async {
    final current = await _repository.findById(id);
    if (current == null) {
      return Err(NotFoundFailure('No se encontró el interesado $id.'));
    }
    if (!await _statusReader.isActive(current.projectId)) {
      return Err(ProjectClosedFailure('El proyecto ${current.projectId} está cerrado.'));
    }

    await _repository.deactivate(id, _clock.now());
    return const Ok(null);
  }
}

@riverpod
DeactivateStakeholder deactivateStakeholder(Ref ref) {
  return DeactivateStakeholder(
    ref.watch(stakeholderRepositoryProvider),
    ref.watch(projectStatusReaderProvider),
    ref.watch(clockProvider),
  );
}
