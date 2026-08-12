import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/live_mark_repository_impl.dart';
import '../contracts/live_mark_repository.dart';

part 'delete_live_mark.g.dart';

final class DeleteLiveMark {
  const DeleteLiveMark(this._repository, this._clock);

  final LiveMarkRepository _repository;
  final Clock _clock;

  Future<Result<void>> call(LiveMarkId id) async {
    await _repository.softDelete(id, _clock.now());
    return const Ok(null);
  }
}

@riverpod
DeleteLiveMark deleteLiveMark(Ref ref) {
  return DeleteLiveMark(ref.watch(liveMarkRepositoryProvider), ref.watch(clockProvider));
}
