import 'package:up_req/core/domain/ids.dart';

import '../entities/elicitation_session.dart';
import '../session_repository.dart';

final class WatchSessions {
  const WatchSessions(this._repository);

  final SessionRepository _repository;

  Stream<List<ElicitationSession>> call(ProjectId projectId) =>
      _repository.watchByProject(projectId);
}
