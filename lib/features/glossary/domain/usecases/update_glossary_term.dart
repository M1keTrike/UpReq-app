import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/glossary_repository_impl.dart';
import '../entities/glossary_term.dart';
import '../entities/glossary_term_draft.dart';
import '../glossary_repository.dart';
import '../term_sort_key.dart';

part 'update_glossary_term.g.dart';

final class UpdateGlossaryTerm {
  const UpdateGlossaryTerm(this._repository, this._statusReader, this._clock);

  final GlossaryRepository _repository;
  final ProjectStatusReader _statusReader;
  final Clock _clock;

  Future<Result<void>> call(GlossaryTermId id, GlossaryTermDraft draft) async {
    final failure = draft.validate();
    if (failure != null) return Err(failure);

    final current = await _repository.findById(id);
    if (current == null) {
      return Err(NotFoundFailure('No se encontró el término $id.'));
    }
    if (!await _statusReader.isActive(current.projectId)) {
      return Err(ProjectClosedFailure('El proyecto ${current.projectId} está cerrado.'));
    }

    final term = draft.term.trim();
    final updated = GlossaryTerm(
      id: current.id,
      projectId: current.projectId,
      term: term,
      termSortKey: computeTermSortKey(term),
      definition: draft.definition,
      notes: draft.notes,
      createdAt: current.createdAt,
      updatedAt: _clock.now(),
    );

    await _repository.update(updated);
    return const Ok(null);
  }
}

@riverpod
UpdateGlossaryTerm updateGlossaryTerm(Ref ref) {
  return UpdateGlossaryTerm(
    ref.watch(glossaryRepositoryProvider),
    ref.watch(projectStatusReaderProvider),
    ref.watch(clockProvider),
  );
}
