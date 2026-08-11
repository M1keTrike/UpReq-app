import '../entities/project.dart';
import '../project_repository.dart';

final class WatchClosedProjects {
  const WatchClosedProjects(this._repository);

  final ProjectRepository _repository;

  Stream<List<Project>> call() => _repository.watchByStatus(ProjectStatus.closed);
}
