import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';

import '../data/stakeholder_repository_impl.dart';
import '../domain/entities/stakeholder.dart';

part 'stakeholder_form_provider.g.dart';

final class StakeholderFormState {
  const StakeholderFormState({
    required this.projectId,
    this.stakeholderId,
    this.name = '',
    this.role,
    this.area,
    this.influence = InfluenceLevel.medium,
    this.notes,
    this.isReadOnly = false,
  });

  final ProjectId projectId;

  /// `null` en modo creación.
  final StakeholderId? stakeholderId;
  final String name;
  final String? role;
  final String? area;
  final InfluenceLevel influence;
  final String? notes;

  /// Deriva de `ProjectStatusReader.isActive` (FR-004a): con el proyecto
  /// cerrado, el formulario se muestra en solo lectura.
  final bool isReadOnly;

  bool get isEditing => stakeholderId != null;

  StakeholderFormState copyWith({
    String? name,
    String? role,
    String? area,
    InfluenceLevel? influence,
    String? notes,
  }) {
    return StakeholderFormState(
      projectId: projectId,
      stakeholderId: stakeholderId,
      name: name ?? this.name,
      role: role ?? this.role,
      area: area ?? this.area,
      influence: influence ?? this.influence,
      notes: notes ?? this.notes,
      isReadOnly: isReadOnly,
    );
  }
}

@riverpod
class StakeholderForm extends _$StakeholderForm {
  @override
  Future<StakeholderFormState> build(String projectId, String? stakeholderId) async {
    final statusReader = ref.watch(projectStatusReaderProvider);

    if (stakeholderId == null) {
      final isActive = await statusReader.isActive(ProjectId(projectId));
      return StakeholderFormState(projectId: ProjectId(projectId), isReadOnly: !isActive);
    }

    final repository = ref.watch(stakeholderRepositoryProvider);
    final stakeholder = await repository.findById(StakeholderId(stakeholderId));
    if (stakeholder == null) {
      throw NotFoundFailure('No se encontró el interesado $stakeholderId.');
    }
    final isActive = await statusReader.isActive(stakeholder.projectId);

    return StakeholderFormState(
      projectId: stakeholder.projectId,
      stakeholderId: stakeholder.id,
      name: stakeholder.name,
      role: stakeholder.role,
      area: stakeholder.area,
      influence: stakeholder.influence,
      notes: stakeholder.notes,
      isReadOnly: !isActive,
    );
  }

  void updateName(String name) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(name: name));
  }

  void updateRole(String? role) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(role: role));
  }

  void updateArea(String? area) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(area: area));
  }

  void updateInfluence(InfluenceLevel influence) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(influence: influence));
  }

  void updateNotes(String? notes) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(notes: notes));
  }
}
