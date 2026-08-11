import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:up_req/core/widgets/async_scaffold_body.dart';

import 'audit_log_provider.dart';

/// Pantalla de solo lectura (ui-contracts.md, pantalla 8). No expone ningún
/// `Mutation`: a diferencia del resto de listas de la aplicación, aquí no hay
/// botón flotante ni acciones de escritura por fila.
class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(auditLogProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('Bitácora')),
      body: AsyncScaffoldBody<AuditLogState>(
        value: state,
        isEmpty: (data) => data.entries.isEmpty,
        // Excepción declarada a FR-020: la bitácora no tiene nada que crear,
        // así que el estado vacío explica la ausencia de operaciones en vez
        // de invitar a una acción.
        empty: (context) => const Center(
          child: Text('Todavía no se ha registrado ninguna operación en la bitácora.'),
        ),
        data: (context, data) => ListView.builder(
          itemCount: data.entries.length,
          itemBuilder: (context, index) {
            final entry = data.entries[index];
            return ListTile(
              title: Text(entry.entityLabel ?? entry.operation.name),
              subtitle: Text('${entry.operation.name} · ${entry.occurredAt}'),
            );
          },
        ),
      ),
    );
  }
}
