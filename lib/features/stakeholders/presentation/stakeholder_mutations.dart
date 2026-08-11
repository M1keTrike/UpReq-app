import 'package:riverpod/experimental/mutation.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';

import '../domain/entities/stakeholder_draft.dart';
import '../domain/usecases/create_stakeholder.dart';
import '../domain/usecases/deactivate_stakeholder.dart';
import '../domain/usecases/update_stakeholder.dart';

final createStakeholder = Mutation<StakeholderId>();
final saveStakeholder = Mutation<void>();
final deactivateStakeholder = Mutation<void>();

Future<StakeholderId> runCreateStakeholder(
  MutationTarget target,
  ProjectId projectId,
  StakeholderDraft draft,
) {
  return createStakeholder.run(target, (tsx) async {
    final result = await tsx.get(createStakeholderProvider)(projectId, draft);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  });
}

Future<void> runSaveStakeholder(
  MutationTarget target,
  StakeholderId id,
  StakeholderDraft draft,
) {
  return saveStakeholder.run(target, (tsx) async {
    final result = await tsx.get(updateStakeholderProvider)(id, draft);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => throw failure,
    };
  });
}

Future<void> runDeactivateStakeholder(MutationTarget target, StakeholderId id) {
  return deactivateStakeholder.run(target, (tsx) async {
    final result = await tsx.get(deactivateStakeholderProvider)(id);
    return switch (result) {
      Ok() => null,
      Err(:final failure) => throw failure,
    };
  });
}
