import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';

import '../domain/entities/project.dart';
import '../domain/project_repository.dart';

class ProjectStatusReaderImpl implements ProjectStatusReader {
  const ProjectStatusReaderImpl(this._repository);

  final ProjectRepository _repository;

  @override
  Future<bool> isActive(ProjectId id) async {
    final project = await _repository.findById(id);
    return project?.status == ProjectStatus.active;
  }
}
