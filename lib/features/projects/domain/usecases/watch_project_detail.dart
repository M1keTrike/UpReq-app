import 'package:up_req/core/domain/combine_latest.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';

import '../entities/project.dart';
import '../entities/project_counters.dart';
import '../entities/project_detail.dart';
import '../project_repository.dart';

final class WatchProjectDetail {
  const WatchProjectDetail(this._repository);

  final ProjectRepository _repository;

  /// Si el proyecto no existe (o ya no), el stream emite `NotFoundFailure`
  /// como error en vez de un valor: no hay estado "vacío" para el detalle de
  /// un proyecto, es un `AsyncError` (ui-contracts.md, pantalla 3).
  Stream<ProjectDetail> call(ProjectId id) {
    return combineLatest2<Project?, ProjectCounters, ProjectDetail>(
      _repository.watchById(id),
      _repository.watchCounters(id),
      (project, counters) {
        if (project == null) {
          throw NotFoundFailure('No se encontró el proyecto $id.');
        }
        return ProjectDetail(project: project, counters: counters);
      },
    );
  }
}
