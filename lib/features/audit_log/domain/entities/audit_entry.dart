import 'package:up_req/core/domain/ids.dart';

/// Catálogo de operaciones de data-model.md. Este incremento no asienta ni
/// altas ni ediciones: solo cierre, desactivación, eliminación y reapertura.
enum AuditOperation {
  projectClosed,
  projectReopened,
  stakeholderDeactivated,
  sessionDeleted,
  scriptPointDeleted,
  glossaryTermDeleted,
}

enum AuditEntityType { project, stakeholder, session, scriptPoint, glossaryTerm }

/// Asiento de bitácora (FR-015, FR-015a). Inmutable y de solo lectura: esta
/// historia no expone ninguna operación de escritura, los asientos los
/// escriben US1 a US5 dentro de sus propias transacciones (decisión 7 de
/// research.md).
final class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.projectId,
    required this.operation,
    required this.entityType,
    required this.entityId,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    this.entityLabel,
  });

  final AuditEntryId id;
  final ProjectId projectId;
  final AuditOperation operation;
  final AuditEntityType entityType;
  final String entityId;
  final String? entityLabel;
  final DateTime occurredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      other is AuditEntry &&
      other.id == id &&
      other.projectId == projectId &&
      other.operation == operation &&
      other.entityType == entityType &&
      other.entityId == entityId &&
      other.entityLabel == entityLabel &&
      other.occurredAt == occurredAt &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        projectId,
        operation,
        entityType,
        entityId,
        entityLabel,
        occurredAt,
        createdAt,
        updatedAt,
      );

  @override
  String toString() => 'AuditEntry($id, $operation, $entityType, $entityId)';
}
