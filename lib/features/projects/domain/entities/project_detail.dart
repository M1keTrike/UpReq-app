import 'project.dart';
import 'project_counters.dart';

/// Proyecto y sus contadores en un único agregado (FR-013): un solo stream
/// combinado, para no multiplicar las re-consultas que provoca la
/// invalidación por tabla de drift (decisión 9 de research.md).
final class ProjectDetail {
  const ProjectDetail({required this.project, required this.counters});

  final Project project;
  final ProjectCounters counters;
}
