import 'package:up_req/core/domain/ids.dart';

import 'entities/stakeholder.dart';

abstract interface class StakeholderRepository {
  /// Todos los interesados del proyecto, activos e inactivos.
  Stream<List<Stakeholder>> watchByProject(ProjectId id);

  /// Solo activos: lo que alimenta el selector de participantes de sesión
  /// (US3), para que estructuralmente no pueda ofrecer interesados
  /// inactivos.
  Stream<List<Stakeholder>> watchSelectableByProject(ProjectId id);

  Future<Stakeholder?> findById(StakeholderId id);
  Future<void> insert(Stakeholder stakeholder);
  Future<void> update(Stakeholder stakeholder);

  /// Desactiva y asienta bitácora en la misma transacción. FR-006, FR-015.
  Future<void> deactivate(StakeholderId id, DateTime at);
}
