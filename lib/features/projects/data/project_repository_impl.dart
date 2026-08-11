import 'package:drift/drift.dart' as drift;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/database/app_database.dart' as db;
import 'package:up_req/core/database/database_provider.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';

import '../domain/entities/project.dart' as domain;
import '../domain/entities/project_counters.dart';
import '../domain/project_repository.dart';
import 'projects_dao.dart';

part 'project_repository_impl.g.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  ProjectRepositoryImpl(this._db, this._dao, this._idGenerator);

  final db.AppDatabase _db;
  final ProjectsDao _dao;
  final IdGenerator _idGenerator;

  @override
  Stream<List<domain.Project>> watchByStatus(domain.ProjectStatus status) {
    return _dao.watchByStatus(_statusToDb(status)).map(
          (rows) => rows.map(_toDomain).toList(),
        );
  }

  @override
  Stream<domain.Project?> watchById(ProjectId id) {
    return _dao.watchById(id.value).map((row) => row == null ? null : _toDomain(row));
  }

  @override
  Stream<ProjectCounters> watchCounters(ProjectId id) => _dao.watchCounters(id.value);

  @override
  Future<domain.Project?> findById(ProjectId id) async {
    final row = await _dao.findById(id.value);
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> insert(domain.Project project) {
    return _dao.insertProject(
      db.ProjectsCompanion.insert(
        id: project.id.value,
        name: project.name,
        client: drift.Value(project.client),
        description: drift.Value(project.description),
        status: drift.Value(_statusToDb(project.status)),
        createdAt: project.createdAt,
        updatedAt: project.updatedAt,
      ),
    );
  }

  @override
  Future<void> update(domain.Project project) {
    return _dao.updateProject(
      project.id.value,
      db.ProjectsCompanion(
        name: drift.Value(project.name),
        client: drift.Value(project.client),
        description: drift.Value(project.description),
        updatedAt: drift.Value(project.updatedAt),
      ),
    );
  }

  /// Cambia `status` y asienta bitácora en la MISMA transacción, copiando en
  /// `entity_label` el nombre del proyecto en ese momento. Este es el patrón
  /// que siguen las cinco implementaciones que escriben asientos: misma
  /// transacción y etiqueta copiada.
  @override
  Future<void> setStatus(ProjectId id, domain.ProjectStatus status, DateTime at) async {
    await _db.transaction(() async {
      final current = await _dao.findById(id.value);
      if (current == null) return;

      await _dao.updateProject(
        id.value,
        db.ProjectsCompanion(
          status: drift.Value(_statusToDb(status)),
          updatedAt: drift.Value(at),
        ),
      );

      await _db.into(_db.auditEntries).insert(
            db.AuditEntriesCompanion.insert(
              id: _idGenerator.generate(),
              projectId: id.value,
              operation: status == domain.ProjectStatus.closed
                  ? 'projectClosed'
                  : 'projectReopened',
              entityType: 'project',
              entityId: id.value,
              entityLabel: drift.Value(current.name),
              occurredAt: at,
              createdAt: at,
              updatedAt: at,
            ),
          );
    });
  }

  domain.Project _toDomain(db.Project row) {
    return domain.Project(
      id: ProjectId(row.id),
      name: row.name,
      client: row.client,
      description: row.description,
      status: _statusFromDb(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  String _statusToDb(domain.ProjectStatus status) => status.name;

  domain.ProjectStatus _statusFromDb(String value) => domain.ProjectStatus.values.byName(value);
}

@Riverpod(keepAlive: true)
ProjectRepository projectRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  return ProjectRepositoryImpl(
    database,
    ProjectsDao(database),
    ref.watch(idGeneratorProvider),
  );
}
