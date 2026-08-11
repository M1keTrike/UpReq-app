import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/widgets/async_scaffold_body.dart';

import '../domain/entities/stakeholder.dart';
import '../domain/entities/stakeholder_draft.dart';
import 'stakeholder_form_provider.dart';
import 'stakeholder_mutations.dart';

class StakeholderFormScreen extends ConsumerStatefulWidget {
  const StakeholderFormScreen({required this.projectId, required this.stakeholderId, super.key});

  final String projectId;

  /// `null` en modo creación.
  final String? stakeholderId;

  @override
  ConsumerState<StakeholderFormScreen> createState() => _StakeholderFormScreenState();
}

class _StakeholderFormScreenState extends ConsumerState<StakeholderFormScreen> {
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _areaController = TextEditingController();
  final _notesController = TextEditingController();
  var _initialized = false;

  bool get _isEditing => widget.stakeholderId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _areaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _onSave(InfluenceLevel influence) async {
    final draft = StakeholderDraft(
      name: _nameController.text,
      influence: influence,
      role: _roleController.text.trim().isEmpty ? null : _roleController.text.trim(),
      area: _areaController.text.trim().isEmpty ? null : _areaController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    try {
      if (_isEditing) {
        await runSaveStakeholder(ref, StakeholderId(widget.stakeholderId!), draft);
      } else {
        await runCreateStakeholder(ref, ProjectId(widget.projectId), draft);
      }
      if (mounted) context.pop();
    } catch (_) {
      // El estado de la Mutation (MutationError) ya refleja el fallo; el
      // formulario conserva lo escrito (FR-022).
    }
  }

  @override
  Widget build(BuildContext context) {
    final formAsync = ref.watch(stakeholderFormProvider(widget.projectId, widget.stakeholderId));
    final mutationState = _isEditing ? ref.watch(saveStakeholder) : ref.watch(createStakeholder);
    final isPending = mutationState is MutationPending;
    final error = mutationState is MutationError ? mutationState.error : null;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar interesado' : 'Nuevo interesado')),
      body: AsyncScaffoldBody<StakeholderFormState>(
        value: formAsync,
        isEmpty: (_) => false,
        empty: (_) => const SizedBox.shrink(),
        data: (context, data) {
          if (!_initialized) {
            _nameController.text = data.name;
            _roleController.text = data.role ?? '';
            _areaController.text = data.area ?? '';
            _notesController.text = data.notes ?? '';
            _initialized = true;
          }

          final fieldsEnabled = !data.isReadOnly;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                TextField(
                  controller: _nameController,
                  enabled: fieldsEnabled,
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
                  controller: _roleController,
                  enabled: fieldsEnabled,
                  decoration: const InputDecoration(labelText: 'Rol'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _areaController,
                  enabled: fieldsEnabled,
                  decoration: const InputDecoration(labelText: 'Área'),
                ),
                const SizedBox(height: 12),
                SegmentedButton<InfluenceLevel>(
                  segments: const [
                    ButtonSegment(value: InfluenceLevel.high, label: Text('Alta')),
                    ButtonSegment(value: InfluenceLevel.medium, label: Text('Media')),
                    ButtonSegment(value: InfluenceLevel.low, label: Text('Baja')),
                  ],
                  selected: {data.influence},
                  onSelectionChanged: fieldsEnabled
                      ? (selection) => ref
                          .read(stakeholderFormProvider(widget.projectId, widget.stakeholderId).notifier)
                          .updateInfluence(selection.first)
                      : null,
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
                    onPressed: isPending ? null : () => _onSave(data.influence),
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
