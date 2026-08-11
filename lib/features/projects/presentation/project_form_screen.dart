import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/widgets/async_scaffold_body.dart';

import '../domain/entities/project_draft.dart';
import 'project_form_provider.dart';
import 'project_mutations.dart';

class ProjectFormScreen extends ConsumerStatefulWidget {
  const ProjectFormScreen({required this.projectId, super.key});

  /// `null` en modo creación (`/projects/new`).
  final String? projectId;

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _nameController = TextEditingController();
  final _clientController = TextEditingController();
  final _descriptionController = TextEditingController();
  var _initialized = false;

  bool get _isEditing => widget.projectId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _clientController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final draft = ProjectDraft(
      name: _nameController.text,
      client: _clientController.text.trim().isEmpty ? null : _clientController.text.trim(),
      description:
          _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
    );

    try {
      if (_isEditing) {
        await runSaveProject(ref, ProjectId(widget.projectId!), draft);
        if (mounted) context.pop();
      } else {
        final id = await runCreateProject(ref, draft);
        if (mounted) context.go('/projects/${id.value}');
      }
    } catch (_) {
      // El estado de la Mutation (MutationError) ya refleja el fallo; el
      // formulario conserva lo escrito (FR-022), no hay nada más que hacer.
    }
  }

  @override
  Widget build(BuildContext context) {
    final formAsync = ref.watch(projectFormProvider(widget.projectId));
    final mutationState = _isEditing ? ref.watch(saveProject) : ref.watch(createProject);
    final isPending = mutationState is MutationPending;
    final error = mutationState is MutationError ? mutationState.error : null;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar proyecto' : 'Nuevo proyecto')),
      body: AsyncScaffoldBody<ProjectFormState>(
        value: formAsync,
        isEmpty: (_) => false,
        empty: (_) => const SizedBox.shrink(),
        data: (context, data) {
          if (!_initialized) {
            _nameController.text = data.name;
            _clientController.text = data.client ?? '';
            _descriptionController.text = data.description ?? '';
            _initialized = true;
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    errorText: error == null
                        ? null
                        : error is Failure
                            ? error.message
                            : error.toString(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _clientController,
                  decoration: const InputDecoration(labelText: 'Cliente'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isPending ? null : _onSave,
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
}
