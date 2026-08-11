import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:up_req/core/widgets/async_scaffold_body.dart';

import '../domain/entities/stakeholder.dart';
import 'stakeholder_list_provider.dart';
import 'stakeholder_mutations.dart';

class StakeholderListScreen extends ConsumerWidget {
  const StakeholderListScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stakeholderListProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('Interesados')),
      floatingActionButton: state.value?.isReadOnly ?? false
          ? null
          : FloatingActionButton(
              onPressed: () => context.go('/projects/$projectId/stakeholders/new'),
              tooltip: 'Nuevo interesado',
              child: const Icon(Icons.add),
            ),
      body: AsyncScaffoldBody<StakeholderListState>(
        value: state,
        isEmpty: (data) => data.stakeholders.isEmpty,
        empty: (context) => const Center(
          child: Text('Todavía no hay interesados. Crea el primero con el botón +.'),
        ),
        data: (context, data) => ListView.builder(
          itemCount: data.stakeholders.length,
          itemBuilder: (context, index) {
            final stakeholder = data.stakeholders[index];
            final isInactive = stakeholder.status == StakeholderStatus.inactive;
            return ListTile(
              title: Text(
                stakeholder.name,
                style: isInactive ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
              ),
              subtitle: Text(
                isInactive ? 'Inactivo · ${stakeholder.influence.name}' : stakeholder.influence.name,
              ),
              onTap: () =>
                  context.go('/projects/$projectId/stakeholders/${stakeholder.id.value}/edit'),
              trailing: isInactive || data.isReadOnly
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.person_off_outlined),
                      tooltip: 'Desactivar',
                      onPressed: () => runDeactivateStakeholder(ref, stakeholder.id),
                    ),
            );
          },
        ),
      ),
    );
  }
}
