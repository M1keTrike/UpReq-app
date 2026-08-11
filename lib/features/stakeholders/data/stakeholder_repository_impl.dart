import 'package:drift/drift.dart' as drift;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/database/app_database.dart' as db;
import 'package:up_req/core/database/database_provider.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';

import '../domain/entities/stakeholder.dart' as domain;
import '../domain/stakeholder_repository.dart';
import 'stakeholders_dao.dart';

part 'stakeholder_repository_impl.g.dart';

class StakeholderRepositoryImpl implements StakeholderRepository {
  StakeholderRepositoryImpl(this._db, this._dao, this._idGenerator);

  final db.AppDatabase _db;
  final StakeholdersDao _dao;
  final IdGenerator _idGenerator;

  @override
  Stream<List<domain.Stakeholder>> watchByProject(ProjectId id) {
    return _dao.watchByProject(id.value).map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Stream<List<domain.Stakeholder>> watchSelectableByProject(ProjectId id) {
    return _dao.watchSelectableByProject(id.value).map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<domain.Stakeholder?> findById(StakeholderId id) async {
    final row = await _dao.findById(id.value);
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> insert(domain.Stakeholder stakeholder) {
    return _dao.insertStakeholder(
      db.StakeholdersCompanion.insert(
        id: stakeholder.id.value,
        projectId: stakeholder.projectId.value,
        name: stakeholder.name,
        role: drift.Value(stakeholder.role),
        area: drift.Value(stakeholder.area),
        influence: stakeholder.influence.name,
        notes: drift.Value(stakeholder.notes),
        status: drift.Value(stakeholder.status.name),
        createdAt: stakeholder.createdAt,
        updatedAt: stakeholder.updatedAt,
      ),
    );
  }

  @override
  Future<void> update(domain.Stakeholder stakeholder) {
    return _dao.updateStakeholder(
      stakeholder.id.value,
      db.StakeholdersCompanion(
        name: drift.Value(stakeholder.name),
        role: drift.Value(stakeholder.role),
        area: drift.Value(stakeholder.area),
        influence: drift.Value(stakeholder.influence.name),
        notes: drift.Value(stakeholder.notes),
        updatedAt: drift.Value(stakeholder.updatedAt),
      ),
    );
  }

  /// Desactiva y asienta bitácora en la misma transacción, copiando en
  /// `entity_label` el nombre del interesado (patrón de T041).
  @override
  Future<void> deactivate(StakeholderId id, DateTime at) async {
    await _db.transaction(() async {
      final current = await _dao.findById(id.value);
      if (current == null) return;

      await _dao.updateStakeholder(
        id.value,
        db.StakeholdersCompanion(status: const drift.Value('inactive'), updatedAt: drift.Value(at)),
      );

      await _db.into(_db.auditEntries).insert(
            db.AuditEntriesCompanion.insert(
              id: _idGenerator.generate(),
              projectId: current.projectId,
              operation: 'stakeholderDeactivated',
              entityType: 'stakeholder',
              entityId: id.value,
              entityLabel: drift.Value(current.name),
              occurredAt: at,
              createdAt: at,
              updatedAt: at,
            ),
          );
    });
  }

  domain.Stakeholder _toDomain(db.Stakeholder row) {
    return domain.Stakeholder(
      id: StakeholderId(row.id),
      projectId: ProjectId(row.projectId),
      name: row.name,
      role: row.role,
      area: row.area,
      influence: domain.InfluenceLevel.values.byName(row.influence),
      notes: row.notes,
      status: domain.StakeholderStatus.values.byName(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

@Riverpod(keepAlive: true)
StakeholderRepository stakeholderRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  return StakeholderRepositoryImpl(
    database,
    StakeholdersDao(database),
    ref.watch(idGeneratorProvider),
  );
}
