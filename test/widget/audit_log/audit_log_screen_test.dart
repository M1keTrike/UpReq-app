import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/audit_log/domain/entities/audit_entry.dart';
import 'package:up_req/features/audit_log/presentation/audit_log_provider.dart';
import 'package:up_req/features/audit_log/presentation/audit_log_screen.dart';

Future<void> _pump(WidgetTester tester, Override override) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [override],
      child: const MaterialApp(home: AuditLogScreen(projectId: 'p1')),
    ),
  );
}

void main() {
  testWidgets('cargando: muestra el indicador de progreso', (tester) async {
    await _pump(
      tester,
      auditLogProvider('p1').overrideWith((ref) => const Stream<AuditLogState>.empty()),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('con datos: muestra los asientos', (tester) async {
    final at = DateTime.utc(2026, 1, 1);
    await _pump(
      tester,
      auditLogProvider('p1').overrideWith(
        (ref) => Stream.value(
          AuditLogState(
            entries: [
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
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana'), findsOneWidget);
  });

  testWidgets(
    'vacía: NO invita a crear nada, explica que aún no hay operaciones (excepción a FR-020)',
    (tester) async {
      await _pump(
        tester,
        auditLogProvider('p1').overrideWith((ref) => Stream.value(const AuditLogState(entries: []))),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Todavía no se ha registrado ninguna operación'), findsOneWidget);
      expect(find.textContaining('Crea el primero'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    },
  );

  testWidgets('con error: muestra un mensaje de error', (tester) async {
    await _pump(
      tester,
      auditLogProvider('p1').overrideWith((ref) => Stream<AuditLogState>.error(Exception('boom'))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Ha ocurrido un error'), findsOneWidget);
  });
}
