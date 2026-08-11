import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/audit_log/domain/entities/audit_entry.dart';

void main() {
  final at = DateTime.utc(2026, 1, 1);

  test('== y hashCode comparan por valor', () {
    AuditEntry build({AuditOperation operation = AuditOperation.projectClosed}) => AuditEntry(
          id: const AuditEntryId('a1'),
          projectId: const ProjectId('p1'),
          operation: operation,
          entityType: AuditEntityType.project,
          entityId: 'p1',
          entityLabel: 'Proyecto Uno',
          occurredAt: at,
          createdAt: at,
          updatedAt: at,
        );

    final a = build();
    final b = build();
    final c = build(operation: AuditOperation.projectReopened);

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a, isNot(equals(c)));
    expect(a, isNot(equals(Object())));
    expect(a.toString(), contains('projectClosed'));
  });
}
