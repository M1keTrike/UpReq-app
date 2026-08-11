import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/glossary_repository_impl.dart';
import '../entities/glossary_term.dart';
import '../entities/glossary_term_draft.dart';
import '../glossary_repository.dart';
import '../term_sort_key.dart';

part 'create_glossary_term.g.dart';

final class CreateGlossaryTerm {
  const CreateGlossaryTerm(
    this._repository,
    this._statusReader,
    this._clock,
    this._idGenerator,
  );

  final GlossaryRepository _repository;
  final ProjectStatusReader _statusReader;
  final Clock _clock;
  final IdGenerator _idGenerator;

  Future<Result<GlossaryTermId>> call(ProjectId projectId, GlossaryTermDraft draft) async {
    final failure = draft.validate();
    if (failure != null) return Err(failure);

    if (!await _statusReader.isActive(projectId)) {
      return Err(ProjectClosedFailure('El proyecto $projectId está cerrado.'));
    }

    final now = _clock.now();
    final term = draft.term.trim();
    final glossaryTerm = GlossaryTerm(
      id: GlossaryTermId(_idGenerator.generate()),
      projectId: projectId,
      term: term,
      termSortKey: computeTermSortKey(term),
      definition: draft.definition,
      notes: draft.notes,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.insert(glossaryTerm);
    return Ok(glossaryTerm.id);
  }
}

@riverpod
CreateGlossaryTerm createGlossaryTerm(Ref ref) {
  return CreateGlossaryTerm(
    ref.watch(glossaryRepositoryProvider),
    ref.watch(projectStatusReaderProvider),
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
  );
}
