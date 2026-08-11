import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';

import '../data/glossary_repository_impl.dart';

part 'glossary_form_provider.g.dart';

final class GlossaryFormState {
  const GlossaryFormState({
    required this.projectId,
    this.termId,
    this.term = '',
    this.definition,
    this.notes,
    this.isReadOnly = false,
  });

  final ProjectId projectId;

  /// `null` en modo creación.
  final GlossaryTermId? termId;
  final String term;
  final String? definition;
  final String? notes;

  /// Deriva de `ProjectStatusReader.isActive` (FR-004a): con el proyecto
  /// cerrado, el formulario se muestra en solo lectura.
  final bool isReadOnly;

  bool get isEditing => termId != null;

  GlossaryFormState copyWith({
    String? term,
    String? definition,
    String? notes,
  }) {
    return GlossaryFormState(
      projectId: projectId,
      termId: termId,
      term: term ?? this.term,
      definition: definition ?? this.definition,
      notes: notes ?? this.notes,
      isReadOnly: isReadOnly,
    );
  }
}

@riverpod
class GlossaryForm extends _$GlossaryForm {
  @override
  Future<GlossaryFormState> build(String projectId, String? termId) async {
    final statusReader = ref.watch(projectStatusReaderProvider);

    if (termId == null) {
      final isActive = await statusReader.isActive(ProjectId(projectId));
      return GlossaryFormState(projectId: ProjectId(projectId), isReadOnly: !isActive);
    }

    final repository = ref.watch(glossaryRepositoryProvider);
    final term = await repository.findById(GlossaryTermId(termId));
    if (term == null) {
      throw NotFoundFailure('No se encontró el término $termId.');
    }
    final isActive = await statusReader.isActive(term.projectId);

    return GlossaryFormState(
      projectId: term.projectId,
      termId: term.id,
      term: term.term,
      definition: term.definition,
      notes: term.notes,
      isReadOnly: !isActive,
    );
  }

  void updateTerm(String term) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(term: term));
  }

  void updateDefinition(String? definition) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(definition: definition));
  }

  void updateNotes(String? notes) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(notes: notes));
  }
}
