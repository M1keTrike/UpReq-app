import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/ids.dart';

import '../data/project_repository_impl.dart';
import '../domain/entities/project.dart';
import '../domain/entities/project_counters.dart';
import '../domain/usecases/watch_project_detail.dart';

part 'project_detail_provider.g.dart';

final class ProjectDetailState {
  const ProjectDetailState({required this.project, required this.counters});

  final Project project;
  final ProjectCounters counters;

  /// Deriva de `status == closed` y oculta toda acción de escritura de las
  /// pantallas hijas (FR-004a). La ocultación es comodidad; la garantía está
  /// en dominio (ui-contracts.md, pantalla 3).
  bool get isReadOnly => project.status == ProjectStatus.closed;
}

@riverpod
Stream<ProjectDetailState> projectDetail(Ref ref, String projectId) {
  final repository = ref.watch(projectRepositoryProvider);
  return WatchProjectDetail(repository)(ProjectId(projectId)).map(
        (detail) => ProjectDetailState(project: detail.project, counters: detail.counters),
      );
}
