import 'package:drift/drift.dart';
import 'package:up_req/core/database/app_database.dart';
import 'package:up_req/core/database/tables/projects.dart';
import 'package:up_req/features/projects/domain/entities/project_counters.dart' as domain;

part 'projects_dao.g.dart';

@DriftAccessor(tables: [Projects])
class ProjectsDao extends DatabaseAccessor<AppDatabase> with _$ProjectsDaoMixin {
  ProjectsDao(super.db);

  /// Único helper de filtrado por estado: toda consulta de lista pasa por
  /// aquí (data-model.md, "Aislamiento por proyecto").
  Stream<List<Project>> watchByStatus(String status) {
    return (select(projects)
          ..where((p) => p.status.equals(status))
          ..orderBy([(p) => OrderingTerm(expression: p.name)]))
        .watch();
  }

  Stream<Project?> watchById(String id) {
    return (select(projects)..where((p) => p.id.equals(id))).watchSingleOrNull();
  }

  Future<Project?> findById(String id) {
    return (select(projects)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertProject(ProjectsCompanion companion) => into(projects).insert(companion);

  Future<void> updateProject(String id, ProjectsCompanion companion) {
    return (update(projects)..where((p) => p.id.equals(id))).write(companion);
  }

  /// COUNT en SQL, nunca contando en Dart (FR-013). Una sola consulta con
  /// subconsultas correlacionadas para no multiplicar streams.
  Stream<domain.ProjectCounters> watchCounters(String projectId) {
    final query = customSelect(
      'SELECT '
      "(SELECT COUNT(*) FROM stakeholders WHERE project_id = ? AND status = 'active') AS stakeholders, "
      '(SELECT COUNT(*) FROM sessions WHERE project_id = ? AND deleted_at IS NULL) AS sessions, '
      '(SELECT COUNT(*) FROM glossary_terms WHERE project_id = ? AND deleted_at IS NULL) AS glossary_terms',
      variables: [
        Variable.withString(projectId),
        Variable.withString(projectId),
        Variable.withString(projectId),
      ],
      readsFrom: {
        attachedDatabase.stakeholders,
        attachedDatabase.sessions,
        attachedDatabase.glossaryTerms,
      },
    );
    return query.watchSingle().map(
          (row) => domain.ProjectCounters(
            stakeholders: row.read<int>('stakeholders'),
            sessions: row.read<int>('sessions'),
            glossaryTerms: row.read<int>('glossary_terms'),
          ),
        );
  }
}
