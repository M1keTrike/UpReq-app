import 'package:up_req/core/domain/ids.dart';

import '../entities/stakeholder.dart';
import '../stakeholder_repository.dart';

final class WatchStakeholders {
  const WatchStakeholders(this._repository);

  final StakeholderRepository _repository;

  Stream<List<Stakeholder>> call(ProjectId projectId) =>
      _repository.watchByProject(projectId);
}
