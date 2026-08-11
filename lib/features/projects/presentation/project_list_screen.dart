import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:up_req/core/widgets/async_scaffold_body.dart';

import '../domain/entities/project.dart';
import 'project_list_provider.dart';
import 'project_mutations.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyectos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<ProjectFilter>(
              segments: const [
                ButtonSegment(value: ProjectFilter.active, label: Text('Activos')),
                ButtonSegment(value: ProjectFilter.closed, label: Text('Cerrados')),
              ],
              selected: {ref.watch(projectListFilterProvider)},
              onSelectionChanged: (selection) => ref
                  .read(projectListFilterProvider.notifier)
                  .set(selection.first),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/projects/new'),
        tooltip: 'Nuevo proyecto',
        child: const Icon(Icons.add),
      ),
      body: AsyncScaffoldBody<ProjectListState>(
        value: state,
        isEmpty: (data) => data.projects.isEmpty,
        empty: (context) => _EmptyList(
          filter: state.value?.filter ?? ProjectFilter.active,
        ),
        data: (context, data) => _ProjectListView(projects: data.projects),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.filter});

  final ProjectFilter filter;

  @override
  Widget build(BuildContext context) {
    final message = filter == ProjectFilter.active
        ? 'Todavía no hay proyectos. Crea el primero con el botón +.'
        : 'No hay proyectos cerrados.';
    return Center(child: Text(message));
  }
}

class _ProjectListView extends ConsumerWidget {
  const _ProjectListView({required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return ListTile(
          title: Text(project.name),
          subtitle: project.client != null ? Text(project.client!) : null,
          onTap: () => context.go('/projects/${project.id.value}'),
          trailing: IconButton(
            icon: Icon(project.status == ProjectStatus.active ? Icons.lock_outline : Icons.lock_open),
            tooltip: project.status == ProjectStatus.active ? 'Cerrar' : 'Reabrir',
            onPressed: () => project.status == ProjectStatus.active
                ? runCloseProject(ref, project.id)
                : runReopenProject(ref, project.id),
          ),
        );
      },
    );
  }
}
