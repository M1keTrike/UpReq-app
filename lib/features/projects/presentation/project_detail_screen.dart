import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:up_req/core/widgets/async_scaffold_body.dart';

import 'project_detail_provider.dart';
import 'project_mutations.dart';

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectDetailProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('Proyecto')),
      body: AsyncScaffoldBody<ProjectDetailState>(
        value: state,
        isEmpty: (_) => false,
        empty: (_) => const SizedBox.shrink(),
        data: (context, data) => _ProjectDetailView(projectId: projectId, state: data),
      ),
    );
  }
}

class _ProjectDetailView extends ConsumerWidget {
  const _ProjectDetailView({required this.projectId, required this.state});

  final String projectId;
  final ProjectDetailState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = state.project;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(project.name, style: Theme.of(context).textTheme.headlineSmall),
        if (project.client != null) Text(project.client!),
        if (project.description != null) ...[
          const SizedBox(height: 8),
          Text(project.description!),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            if (!state.isReadOnly)
              OutlinedButton(
                onPressed: () => context.go('/projects/$projectId/edit'),
                child: const Text('Editar'),
              ),
            OutlinedButton(
              onPressed: () => state.isReadOnly
                  ? runReopenProject(ref, project.id)
                  : runCloseProject(ref, project.id),
              child: Text(state.isReadOnly ? 'Reabrir' : 'Cerrar'),
            ),
          ],
        ),
        const Divider(height: 32),
        ListTile(
          title: const Text('Interesados'),
          trailing: Text('${state.counters.stakeholders}'),
          onTap: () => context.go('/projects/$projectId/stakeholders'),
        ),
        ListTile(
          title: const Text('Sesiones'),
          trailing: Text('${state.counters.sessions}'),
          onTap: () => context.go('/projects/$projectId/sessions'),
        ),
        ListTile(
          title: const Text('Glosario'),
          trailing: Text('${state.counters.glossaryTerms}'),
          onTap: () => context.go('/projects/$projectId/glossary'),
        ),
        ListTile(
          title: const Text('Bitácora'),
          onTap: () => context.go('/projects/$projectId/audit'),
        ),
      ],
    );
  }
}
