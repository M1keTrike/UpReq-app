import 'package:riverpod/experimental/mutation.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';

import '../domain/entities/project_draft.dart';
import '../domain/usecases/close_project.dart';
import '../domain/usecases/create_project.dart';
import '../domain/usecases/reopen_project.dart';
import '../domain/usecases/update_project.dart';

/// Toda escritura de la feature como `Mutation<T>` observable
/// (ui-contracts.md, "Contrato de escritura"). Prohibido derivar el
/// progreso de una escritura de una bandera `isLoading`/`hasError` en el
/// estado de pantalla: el estado de la mutación (`MutationIdle`,
/// `MutationPending`, `MutationError`, `MutationSuccess`) es la única fuente
/// de verdad sobre su progreso.
final createProject = Mutation<ProjectId>();
final saveProject = Mutation<void>();
final closeProject = Mutation<void>();
final reopenProject = Mutation<void>();

Future<ProjectId> runCreateProject(MutationTarget target, ProjectDraft draft) {
  return createProject.run(target, (tsx) async {
    final result = await tsx.get(createProjectProvider)(draft);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  });
}

Future<void> runSaveProject(MutationTarget target, ProjectId id, ProjectDraft draft) {
  return saveProject.run(target, (tsx) async {
    final result = await tsx.get(updateProjectProvider)(id, draft);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => throw failure,
    };
  });
}

Future<void> runCloseProject(MutationTarget target, ProjectId id) {
  return closeProject.run(target, (tsx) async {
    final result = await tsx.get(closeProjectProvider)(id);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => throw failure,
    };
  });
}

Future<void> runReopenProject(MutationTarget target, ProjectId id) {
  return reopenProject.run(target, (tsx) async {
    final result = await tsx.get(reopenProjectProvider)(id);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => throw failure,
    };
  });
}
