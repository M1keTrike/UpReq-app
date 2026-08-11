import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/database/app_database.dart' as db;
import 'package:up_req/core/database/database_provider.dart';
import 'package:up_req/core/domain/ids.dart';

import '../domain/audit_repository.dart';
import '../domain/entities/audit_entry.dart' as domain;
import 'audit_dao.dart';

part 'audit_repository_impl.g.dart';

/// Solo lectura: sin transacción de escritura alguna, a diferencia de las
/// cinco implementaciones que escriben asientos (patrón de T041). Esta
/// historia únicamente proyecta filas ya insertadas por US1-US5.
class AuditRepositoryImpl implements AuditRepository {
  AuditRepositoryImpl(this._dao);

  final AuditDao _dao;

  @override
  Stream<List<domain.AuditEntry>> watchByProject(ProjectId id) {
    return _dao.watchByProject(id.value).map((rows) => rows.map(_toDomain).toList());
  }

  domain.AuditEntry _toDomain(db.AuditEntry row) {
    return domain.AuditEntry(
      id: AuditEntryId(row.id),
      projectId: ProjectId(row.projectId),
      operation: domain.AuditOperation.values.byName(row.operation),
      entityType: domain.AuditEntityType.values.byName(row.entityType),
      entityId: row.entityId,
      entityLabel: row.entityLabel,
      occurredAt: row.occurredAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

@Riverpod(keepAlive: true)
AuditRepository auditRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  return AuditRepositoryImpl(AuditDao(database));
}
