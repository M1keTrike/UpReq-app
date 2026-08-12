import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:up_req/core/widgets/async_scaffold_body.dart';

import 'glossary_list_provider.dart';
import 'glossary_mutations.dart';

class GlossaryListScreen extends ConsumerWidget {
  const GlossaryListScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(glossaryListProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('Glosario')),
      floatingActionButton: state.value?.isReadOnly ?? true
          ? null
          : FloatingActionButton(
              onPressed: () => context.go('/projects/$projectId/glossary/new'),
              tooltip: 'Nuevo término',
              child: const Icon(Icons.add),
            ),
      body: AsyncScaffoldBody<GlossaryListState>(
        value: state,
        isEmpty: (data) => data.terms.isEmpty,
        empty: (context) => const Center(
          child: Text('Todavía no hay términos. Crea el primero con el botón +.'),
        ),
        data: (context, data) => ListView.builder(
          itemCount: data.terms.length,
          itemBuilder: (context, index) {
            final term = data.terms[index];
            return ListTile(
              title: Text(term.term),
              subtitle: term.definition == null || term.definition!.isEmpty
                  ? null
                  : Text(term.definition!, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => context.go('/projects/$projectId/glossary/${term.id.value}/edit'),
              trailing: data.isReadOnly
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Eliminar',
                      onPressed: () => runDeleteGlossaryTerm(ref, term.id),
                    ),
            );
          },
        ),
      ),
    );
  }
}
