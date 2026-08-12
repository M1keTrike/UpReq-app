import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:up_req/core/widgets/async_scaffold_body.dart';

import '../domain/entities/elicitation_session.dart';
import 'session_list_provider.dart';
import 'session_mutations.dart';

class SessionListScreen extends ConsumerWidget {
  const SessionListScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionListProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('Sesiones')),
      floatingActionButton: state.value?.isReadOnly ?? true
          ? null
          : FloatingActionButton(
              onPressed: () => context.go('/projects/$projectId/sessions/new'),
              tooltip: 'Nueva sesión',
              child: const Icon(Icons.add),
            ),
      body: AsyncScaffoldBody<SessionListState>(
        value: state,
        isEmpty: (data) => data.sessions.isEmpty,
        empty: (context) => const Center(
          child: Text('Todavía no hay sesiones. Crea la primera con el botón +.'),
        ),
        data: (context, data) => ListView.builder(
          itemCount: data.sessions.length,
          itemBuilder: (context, index) {
            final session = data.sessions[index];
            return ListTile(
              title: Text(session.title),
              subtitle: Text('${_statusLabel(session.status)} · ${_techniqueLabel(session.technique)}'),
              onTap: () =>
                  context.go('/projects/$projectId/sessions/${session.id.value}'),
              trailing: data.isReadOnly
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Eliminar',
                      onPressed: () => runDeleteSession(ref, session.id),
                    ),
            );
          },
        ),
      ),
    );
  }

  static String _statusLabel(SessionStatus status) => switch (status) {
        SessionStatus.planned => 'Planeada',
        SessionStatus.inProgress => 'En curso',
        SessionStatus.closed => 'Cerrada',
      };

  static String _techniqueLabel(SessionTechnique technique) => switch (technique) {
        SessionTechnique.openInterview => 'Entrevista abierta',
        SessionTechnique.structuredInterview => 'Entrevista estructurada',
        SessionTechnique.workshop => 'Taller',
        SessionTechnique.observation => 'Observación',
        SessionTechnique.documentReview => 'Revisión documental',
      };
}
