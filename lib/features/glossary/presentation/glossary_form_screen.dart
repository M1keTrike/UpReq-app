import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/widgets/async_scaffold_body.dart';

import '../domain/entities/glossary_term_draft.dart';
import 'glossary_form_provider.dart';
import 'glossary_mutations.dart';

class GlossaryFormScreen extends ConsumerStatefulWidget {
  const GlossaryFormScreen({required this.projectId, required this.termId, super.key});

  final String projectId;

  /// `null` en modo creación.
  final String? termId;

  @override
  ConsumerState<GlossaryFormScreen> createState() => _GlossaryFormScreenState();
}

class _GlossaryFormScreenState extends ConsumerState<GlossaryFormScreen> {
  final _termController = TextEditingController();
  final _definitionController = TextEditingController();
  final _notesController = TextEditingController();
  var _initialized = false;

  bool get _isEditing => widget.termId != null;

  @override
  void dispose() {
    _termController.dispose();
    _definitionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final draft = GlossaryTermDraft(
      term: _termController.text,
      definition: _definitionController.text.trim().isEmpty ? null : _definitionController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    try {
      if (_isEditing) {
        await runSaveGlossaryTerm(ref, GlossaryTermId(widget.termId!), draft);
      } else {
        await runCreateGlossaryTerm(ref, ProjectId(widget.projectId), draft);
      }
      if (mounted) context.pop();
    } catch (_) {
      // El estado de la Mutation (MutationError) ya refleja el fallo; el
      // formulario conserva lo escrito (FR-022).
    }
  }

  @override
  Widget build(BuildContext context) {
    final formAsync = ref.watch(glossaryFormProvider(widget.projectId, widget.termId));
    final mutationState = _isEditing ? ref.watch(saveGlossaryTerm) : ref.watch(createGlossaryTerm);
    final isPending = mutationState is MutationPending;
    final error = mutationState is MutationError ? mutationState.error : null;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar término' : 'Nuevo término')),
      body: AsyncScaffoldBody<GlossaryFormState>(
        value: formAsync,
        isEmpty: (_) => false,
        empty: (_) => const SizedBox.shrink(),
        data: (context, data) {
          if (!_initialized) {
            _termController.text = data.term;
            _definitionController.text = data.definition ?? '';
            _notesController.text = data.notes ?? '';
            _initialized = true;
          }

          final fieldsEnabled = !data.isReadOnly;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                TextField(
                  controller: _termController,
                  enabled: fieldsEnabled,
                  decoration: InputDecoration(
                    labelText: 'Término',
                    errorText: error == null
                        ? null
                        : error is Failure
                            ? error.message
                            : error.toString(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _definitionController,
                  enabled: fieldsEnabled,
                  decoration: const InputDecoration(labelText: 'Definición'),
                  maxLines: 4,
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
