import 'package:drift/drift.dart';
import 'package:up_req/core/database/app_database.dart';
import 'package:up_req/core/database/tables/audit_entries.dart';

part 'audit_dao.g.dart';

@DriftAccessor(tables: [AuditEntries])
class AuditDao extends DatabaseAccessor<AppDatabase> with _$AuditDaoMixin {
  AuditDao(super.db);

  /// Asientos del proyecto, del más reciente al más antiguo (FR-015a). Único
  /// helper de filtrado por proyecto (data-model.md, "Aislamiento por
  /// proyecto", invariante I4).
  Stream<List<AuditEntry>> watchByProject(String projectId) {
    return (select(auditEntries)
          ..where((a) => a.projectId.equals(projectId))
          ..orderBy([(a) => OrderingTerm(expression: a.occurredAt, mode: OrderingMode.desc)]))
        .watch();
  }
}
