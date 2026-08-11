import 'package:up_req/core/domain/ids.dart';

import '../entities/glossary_term.dart';
import '../glossary_repository.dart';

final class WatchGlossary {
  const WatchGlossary(this._repository);

  final GlossaryRepository _repository;

  Stream<List<GlossaryTerm>> call(ProjectId projectId) => _repository.watchByProject(projectId);
}
