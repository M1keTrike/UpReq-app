import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/session_status_reader.dart';

import '../domain/entities/elicitation_session.dart';
import '../domain/session_repository.dart';

class SessionStatusReaderImpl implements SessionStatusReader {
  const SessionStatusReaderImpl(this._repository);

  final SessionRepository _repository;

  @override
  Future<SessionSnapshot?> find(SessionId id) async {
    final session = await _repository.findById(id);
    if (session == null) return null;
    return SessionSnapshot(
      projectId: session.projectId,
      isInProgress: session.status == SessionStatus.inProgress,
    );
  }

  @override
  Stream<SessionSnapshot?> watch(SessionId id) {
    return _repository.watchDetail(id).map((detail) {
      if (detail == null) return null;
      return SessionSnapshot(
        projectId: detail.session.projectId,
        isInProgress: detail.session.status == SessionStatus.inProgress,
      );
    });
  }
}
