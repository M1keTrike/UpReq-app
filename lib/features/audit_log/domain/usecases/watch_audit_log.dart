import 'package:up_req/core/domain/ids.dart';

import '../audit_repository.dart';
import '../entities/audit_entry.dart';

final class WatchAuditLog {
  const WatchAuditLog(this._repository);

  final AuditRepository _repository;

  Stream<List<AuditEntry>> call(ProjectId projectId) => _repository.watchByProject(projectId);
}
