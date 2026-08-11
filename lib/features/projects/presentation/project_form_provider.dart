import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';

import '../data/project_repository_impl.dart';

part 'project_form_provider.g.dart';

final class ProjectFormState {
  const ProjectFormState({
    required this.name,
    this.client,
    this.description,
    this.projectId,
  });

  final String name;
  final String? client;
  final String? description;

  /// `null` en modo creación (`/projects/new`).
  final ProjectId? projectId;

  bool get isEditing => projectId != null;

  ProjectFormState copyWith({String? name, String? client, String? description}) {
    return ProjectFormState(
      name: name ?? this.name,
      client: client ?? this.client,
      description: description ?? this.description,
      projectId: projectId,
    );
  }
}

/// `projectFormProvider(projectId)` de ui-contracts.md, pantalla 2. Al fallar
/// la validación de una escritura, este estado no se toca: es lo que
/// conserva lo escrito (FR-022).
@riverpod
class ProjectForm extends _$ProjectForm {
  @override
  Future<ProjectFormState> build(String? projectId) async {
    if (projectId == null) {
      return const ProjectFormState(name: '');
    }

    final repository = ref.watch(projectRepositoryProvider);
    final project = await repository.findById(ProjectId(projectId));
    if (project == null) {
      throw NotFoundFailure('No se encontró el proyecto $projectId.');
    }

    return ProjectFormState(
      name: project.name,
      client: project.client,
      description: project.description,
      projectId: project.id,
    );
  }

  void updateName(String name) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(name: name));
  }

  void updateClient(String? client) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(client: client));
  }

  void updateDescription(String? description) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(description: description));
  }
}
