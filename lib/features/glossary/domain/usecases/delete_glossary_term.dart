import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/glossary_repository_impl.dart';
import '../glossary_repository.dart';

part 'delete_glossary_term.g.dart';

final class DeleteGlossaryTerm {
  const DeleteGlossaryTerm(this._repository, this._statusReader, this._clock);

  final GlossaryRepository _repository;
  final ProjectStatusReader _statusReader;
  final Clock _clock;

  /// Asienta `glossaryTermDeleted`. FR-014a.
  Future<Result<void>> call(GlossaryTermId id) async {
    final current = await _repository.findById(id);
    if (current == null) {
      return Err(NotFoundFailure('No se encontró el término $id.'));
    }
    if (!await _statusReader.isActive(current.projectId)) {
      return Err(ProjectClosedFailure('El proyecto ${current.projectId} está cerrado.'));
    }

    await _repository.softDelete(id, _clock.now());
    return const Ok(null);
  }
}

@riverpod
DeleteGlossaryTerm deleteGlossaryTerm(Ref ref) {
  return DeleteGlossaryTerm(
    ref.watch(glossaryRepositoryProvider),
    ref.watch(projectStatusReaderProvider),
    ref.watch(clockProvider),
  );
}
