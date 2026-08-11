import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/widgets/async_scaffold_body.dart';

import 'script_point_list.dart';
import 'script_point_mutations.dart';
import 'session_detail_provider.dart';
import 'session_status_control.dart';

/// Detalle de sesión y guion (ui-contracts.md, pantalla 6): cabecera con
/// control de estado, participantes, contadores del guion y la lista de
/// puntos. `isEmpty` se deja siempre en `false` (patrón de
/// `ProjectDetailScreen`): la sesión siempre existe si llegamos aquí, así
/// que el guion vacío es un estado dentro de la vista de datos, no un
/// cuarto estado genérico sin contexto de sesión.
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({required this.projectId, required this.sessionId, super.key});

  final String projectId;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionDetailProvider(sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesión'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: () => context.go('/projects/$projectId/sessions/$sessionId/edit'),
          ),
        ],
      ),
      body: AsyncScaffoldBody<SessionDetailState>(
        value: state,
        isEmpty: (_) => false,
        empty: (_) => const SizedBox.shrink(),
        data: (context, data) => _SessionDetailView(sessionId: sessionId, state: data),
      ),
    );
  }
}

class _SessionDetailView extends ConsumerStatefulWidget {
  const _SessionDetailView({required this.sessionId, required this.state});

  final String sessionId;
  final SessionDetailState state;

  @override
  ConsumerState<_SessionDetailView> createState() => _SessionDetailViewState();
}

class _SessionDetailViewState extends ConsumerState<_SessionDetailView> {
  final _newPointController = TextEditingController();

  @override
  void dispose() {
    _newPointController.dispose();
    super.dispose();
  }

  Future<void> _addPoint() async {
    final text = _newPointController.text.trim();
    if (text.isEmpty) return;
    try {
      await runAddScriptPoint(ref, SessionId(widget.sessionId), text);
      _newPointController.clear();
    } catch (_) {
      // El estado de la Mutation (MutationError) ya refleja el fallo.
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.state;
    final session = data.session;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(session.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (!data.isReadOnly) SessionStatusControl(sessionId: session.id, status: session.status),
        const SizedBox(height: 12),
        Text('Participantes: ${data.participantIds.length}'),
        Text(
          'Guion: ${data.counters.pending} pendientes · '
          '${data.counters.covered} cubiertos · ${data.counters.skipped} omitidos',
        ),
        const Divider(height: 32),
        Text('Guion', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (data.points.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Todavía no hay puntos en el guion. Agrega el primero abajo.'),
          )
        else
          ScriptPointList(
            sessionId: session.id,
            points: data.points,
            isReadOnly: data.isReadOnly,
          ),
        if (!data.isReadOnly) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newPointController,
                  decoration: const InputDecoration(labelText: 'Nuevo punto del guion'),
                  onSubmitted: (_) => _addPoint(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Agregar punto',
                onPressed: _addPoint,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
