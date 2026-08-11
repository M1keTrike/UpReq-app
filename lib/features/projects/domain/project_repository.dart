import 'package:up_req/core/domain/ids.dart';

import 'entities/project.dart';
import 'entities/project_counters.dart';

abstract interface class ProjectRepository {
  Stream<List<Project>> watchByStatus(ProjectStatus status);
  Stream<Project?> watchById(ProjectId id);
  Stream<ProjectCounters> watchCounters(ProjectId id);
  Future<Project?> findById(ProjectId id);
  Future<void> insert(Project project);
  Future<void> update(Project project);

  /// Cambia `status` y asienta bitácora en la MISMA transacción.
  /// FR-004, FR-004b, FR-015.
  Future<void> setStatus(ProjectId id, ProjectStatus status, DateTime at);
}
