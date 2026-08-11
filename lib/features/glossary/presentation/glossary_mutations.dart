import 'package:riverpod/experimental/mutation.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';

import '../domain/entities/glossary_term_draft.dart';
import '../domain/usecases/create_glossary_term.dart';
import '../domain/usecases/delete_glossary_term.dart';
import '../domain/usecases/update_glossary_term.dart';

final createGlossaryTerm = Mutation<GlossaryTermId>();
final saveGlossaryTerm = Mutation<void>();
final deleteGlossaryTerm = Mutation<void>();

Future<GlossaryTermId> runCreateGlossaryTerm(
  MutationTarget target,
  ProjectId projectId,
  GlossaryTermDraft draft,
) {
  return createGlossaryTerm.run(target, (tsx) async {
    final result = await tsx.get(createGlossaryTermProvider)(projectId, draft);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  });
}

Future<void> runSaveGlossaryTerm(
  MutationTarget target,
  GlossaryTermId id,
  GlossaryTermDraft draft,
) {
  return saveGlossaryTerm.run(target, (tsx) async {
    final result = await tsx.get(updateGlossaryTermProvider)(id, draft);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => throw failure,
    };
  });
}

Future<void> runDeleteGlossaryTerm(MutationTarget target, GlossaryTermId id) {
  return deleteGlossaryTerm.run(target, (tsx) async {
    final result = await tsx.get(deleteGlossaryTermProvider)(id);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => throw failure,
    };
  });
}
