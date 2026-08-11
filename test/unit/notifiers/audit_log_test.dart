import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/audit_log/data/audit_repository_impl.dart';
import 'package:up_req/features/audit_log/domain/audit_repository.dart';
import 'package:up_req/features/audit_log/domain/entities/audit_entry.dart';
import 'package:up_req/features/audit_log/presentation/audit_log_provider.dart';

import '../../support/test_container.dart';

class _FakeAuditRepository implements AuditRepository {
  List<AuditEntry> entries = [];

  @override
  Stream<List<AuditEntry>> watchByProject(ProjectId id) => Stream.value(entries);
}

void main() {
  test('expone los asientos del proyecto a través de un único provider', () async {
    final at = DateTime.utc(2026, 1, 1);
    final repository = _FakeAuditRepository()
      ..entries = [
        AuditEntry(
          id: const AuditEntryId('entry-1'),
          projectId: const ProjectId('p1'),
          operation: AuditOperation.stakeholderDeactivated,
          entityType: AuditEntityType.stakeholder,
          entityId: 's1',
          entityLabel: 'Ana',
          occurredAt: at,
          createdAt: at,
          updatedAt: at,
        ),
      ];

    final container = buildTestContainer(
      overrides: [auditRepositoryProvider.overrideWithValue(repository)],
    );
    container.listen(auditLogProvider('p1'), (_, _) {});

    final state = await container.read(auditLogProvider('p1').future);

    expect(state.entries.map((e) => e.entityLabel), ['Ana']);
  });

  test('el estado vacío no lleva ningún asiento', () async {
    final repository = _FakeAuditRepository();

    final container = buildTestContainer(
      overrides: [auditRepositoryProvider.overrideWithValue(repository)],
    );
    container.listen(auditLogProvider('p1'), (_, _) {});

    final state = await container.read(auditLogProvider('p1').future);

    expect(state.entries, isEmpty);
  });
}
