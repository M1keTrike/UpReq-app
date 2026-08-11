import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/ids.dart';

import '../data/stakeholder_repository_impl.dart';
import '../domain/entities/stakeholder.dart';
import '../domain/usecases/watch_stakeholders.dart';

part 'stakeholder_list_provider.g.dart';

final class StakeholderListState {
  const StakeholderListState({required this.stakeholders});

  final List<Stakeholder> stakeholders;
}

/// Único provider que consume la pantalla de lista de interesados
/// (ui-contracts.md, pantalla 4).
@riverpod
Stream<StakeholderListState> stakeholderList(Ref ref, String projectId) {
  final repository = ref.watch(stakeholderRepositoryProvider);
  return WatchStakeholders(repository)(ProjectId(projectId)).map(
        (stakeholders) => StakeholderListState(stakeholders: stakeholders),
      );
}
