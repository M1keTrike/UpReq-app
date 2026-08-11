import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';

import '../data/stakeholder_repository_impl.dart';
import '../domain/entities/stakeholder.dart';
import '../domain/usecases/watch_stakeholders.dart';

part 'stakeholder_list_provider.g.dart';

final class StakeholderListState {
  const StakeholderListState({required this.stakeholders, this.isReadOnly = false});

  final List<Stakeholder> stakeholders;

  /// Deriva de `ProjectStatusReader.isActive` (FR-004a): oculta las acciones
  /// de escritura (crear, desactivar) cuando el proyecto está cerrado. El
  /// valor por defecto `false` mantiene compatibilidad con las pruebas que
  /// construyen el estado directamente sin pasar por el provider.
  final bool isReadOnly;
}

/// Único provider que consume la pantalla de lista de interesados
/// (ui-contracts.md, pantalla 4).
@riverpod
Stream<StakeholderListState> stakeholderList(Ref ref, String projectId) {
  final repository = ref.watch(stakeholderRepositoryProvider);
  final statusReader = ref.watch(projectStatusReaderProvider);
  return WatchStakeholders(repository)(ProjectId(projectId)).asyncMap((stakeholders) async {
    final isActive = await statusReader.isActive(ProjectId(projectId));
    return StakeholderListState(stakeholders: stakeholders, isReadOnly: !isActive);
  });
}
