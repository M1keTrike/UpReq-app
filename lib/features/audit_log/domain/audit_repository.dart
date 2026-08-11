import 'package:up_req/core/domain/ids.dart';

import 'entities/audit_entry.dart';

/// Solo lectura. Ninguna operación de escritura: los asientos los inserta
/// cada repositorio de US1-US5 dentro de su propia transacción (decisión 7
/// de research.md).
abstract interface class AuditRepository {
  /// Del más reciente al más antiguo. FR-015a.
  Stream<List<AuditEntry>> watchByProject(ProjectId id);
}
