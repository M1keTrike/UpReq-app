import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/widgets/async_scaffold_body.dart';

import '../domain/entities/elicitation_session.dart';
import '../domain/entities/session_draft.dart';
import 'session_form_provider.dart';
import 'session_mutations.dart';
import 'session_status_control.dart';

class SessionFormScreen extends ConsumerStatefulWidget {
  const SessionFormScreen({required this.projectId, required this.sessionId, super.key});

  final String projectId;

  /// `null` en modo creación.
  final String? sessionId;

  @override
  ConsumerState<SessionFormScreen> createState() => _SessionFormScreenState();
}

class _SessionFormScreenState extends ConsumerState<SessionFormScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  var _initialized = false;

  bool get _isEditing => widget.sessionId != null;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _onSave(SessionFormState data) async {
    final draft = SessionDraft(
      title: _titleController.text,
      scheduledAt: data.scheduledAt,
      technique: data.technique,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      participantIds: data.participantIds,
    );

    try {
      if (_isEditing) {
        await runSaveSession(ref, SessionId(widget.sessionId!), draft);
        if (mounted) context.pop();
      } else {
        await runCreateSession(ref, data.projectId, draft);
        if (mounted) context.go('/projects/${widget.projectId}/sessions');
      }
    } catch (_) {
      // El estado de la Mutation (MutationError) ya refleja el fallo; el
      // formulario conserva lo escrito (FR-022).
    }
  }

  Future<void> _pickScheduledAt(SessionFormState data) async {
    final date = await showDatePicker(
      context: context,
      initialDate: data.scheduledAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(data.scheduledAt),
    );
    if (time == null) return;
    ref
        .read(sessionFormProvider(widget.projectId, widget.sessionId).notifier)
        .updateScheduledAt(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    final formAsync = ref.watch(sessionFormProvider(widget.projectId, widget.sessionId));
    final selectableAsync = ref.watch(selectableStakeholdersProvider(widget.projectId));
    final mutationState = _isEditing ? ref.watch(saveSession) : ref.watch(createSession);
    final isPending = mutationState is MutationPending;
    final error = mutationState is MutationError ? mutationState.error : null;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar sesión' : 'Nueva sesión')),
      body: AsyncScaffoldBody<SessionFormState>(
        value: formAsync,
        isEmpty: (_) => false,
        empty: (_) => const SizedBox.shrink(),
        data: (context, data) {
          if (!_initialized) {
            _titleController.text = data.title;
            _locationController.text = data.location ?? '';
            _notesController.text = data.notes ?? '';
            _initialized = true;
          }

          final fieldsEnabled = !data.isReadOnly;
          final headerEnabled = fieldsEnabled && !data.isHeaderFrozen;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                if (_isEditing && fieldsEnabled) ...[
                  SessionStatusControl(sessionId: data.sessionId!, status: data.status),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _titleController,
                  enabled: headerEnabled,
                  decoration: InputDecoration(
                    labelText: 'Título',
                    errorText: error == null
                        ? null
                        : error is Failure
                            ? error.message
                            : error.toString(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha y hora'),
                  subtitle: Text(_formatDateTime(data.scheduledAt)),
                  onTap: headerEnabled ? () => _pickScheduledAt(data) : null,
                  enabled: headerEnabled,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SessionTechnique>(
                  initialValue: data.technique,
                  decoration: const InputDecoration(labelText: 'Técnica'),
                  items: [
                    for (final technique in SessionTechnique.values)
                      DropdownMenuItem(value: technique, child: Text(_techniqueLabel(technique))),
                  ],
                  onChanged: headerEnabled
                      ? (technique) {
                          if (technique == null) return;
                          ref
                              .read(sessionFormProvider(widget.projectId, widget.sessionId).notifier)
                              .updateTechnique(technique);
                        }
                      : null,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationController,
                  enabled: headerEnabled,
                  decoration: const InputDecoration(labelText: 'Lugar'),
                ),
                const SizedBox(height: 16),
                Text('Participantes', style: Theme.of(context).textTheme.titleMedium),
                selectableAsync.when(
                  data: (stakeholders) => Column(
                    children: [
                      for (final stakeholder in stakeholders)
                        CheckboxListTile(
                          title: Text(stakeholder.name),
                          value: data.participantIds.contains(stakeholder.id),
                          onChanged: headerEnabled
                              ? (_) => ref
                                  .read(sessionFormProvider(widget.projectId, widget.sessionId).notifier)
                                  .toggleParticipant(stakeholder.id)
                              : null,
                        ),
                    ],
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                  error: (error, _) => Text('No se pudieron cargar los interesados: $error'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  enabled: fieldsEnabled,
                  decoration: const InputDecoration(labelText: 'Notas'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                if (fieldsEnabled)
                  FilledButton(
                    onPressed: isPending ? null : () => _onSave(data),
                    child: isPending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} ${two(value.hour)}:${two(value.minute)}';
  }

  static String _techniqueLabel(SessionTechnique technique) => switch (technique) {
        SessionTechnique.openInterview => 'Entrevista abierta',
        SessionTechnique.structuredInterview => 'Entrevista estructurada',
        SessionTechnique.workshop => 'Taller',
        SessionTechnique.observation => 'Observación',
        SessionTechnique.documentReview => 'Revisión documental',
      };
}
