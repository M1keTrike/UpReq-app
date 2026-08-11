import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';

import '../entities/session_detail.dart';
import '../session_repository.dart';

final class WatchSessionDetail {
  const WatchSessionDetail(this._repository);

  final SessionRepository _repository;

  /// Si la sesión no existe (o ya no), el stream emite `NotFoundFailure`
  /// como error en vez de un valor, igual que `WatchProjectDetail`.
  Stream<SessionDetail> call(SessionId id) {
    return _repository.watchDetail(id).map((detail) {
      if (detail == null) {
        throw NotFoundFailure('No se encontró la sesión $id.');
      }
      return detail;
    });
  }
}
