import 'package:drift/drift.dart';
import 'package:up_req/core/database/app_database.dart';
import 'package:up_req/core/database/tables/stakeholders.dart';

part 'stakeholders_dao.g.dart';

@DriftAccessor(tables: [Stakeholders])
class StakeholdersDao extends DatabaseAccessor<AppDatabase> with _$StakeholdersDaoMixin {
  StakeholdersDao(super.db);

  /// Todos los interesados del proyecto, activos e inactivos. Único helper
  /// de filtrado por proyecto y estado (data-model.md, "Aislamiento por
  /// proyecto", invariante I4).
  Stream<List<Stakeholder>> watchByProject(String projectId) {
    return (select(stakeholders)
          ..where((s) => s.projectId.equals(projectId))
          ..orderBy([(s) => OrderingTerm(expression: s.name)]))
        .watch();
  }

  /// Solo activos, para el selector de participantes de sesión (US3).
  Stream<List<Stakeholder>> watchSelectableByProject(String projectId) {
    return (select(stakeholders)
          ..where((s) => s.projectId.equals(projectId) & s.status.equals('active'))
          ..orderBy([(s) => OrderingTerm(expression: s.name)]))
        .watch();
  }

  Future<Stakeholder?> findById(String id) {
    return (select(stakeholders)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertStakeholder(StakeholdersCompanion companion) =>
      into(stakeholders).insert(companion);

  Future<void> updateStakeholder(String id, StakeholdersCompanion companion) {
    return (update(stakeholders)..where((s) => s.id.equals(id))).write(companion);
  }
}
