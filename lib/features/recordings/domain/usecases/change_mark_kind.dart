import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/live_mark_repository_impl.dart';
import '../contracts/live_mark_repository.dart';
import '../entities/live_mark.dart';

part 'change_mark_kind.g.dart';

/// No exige grabación activa (FR-009a): se corrige después.
final class ChangeMarkKind {
  const ChangeMarkKind(this._repository, this._clock);

  final LiveMarkRepository _repository;
  final Clock _clock;

  Future<Result<void>> call(LiveMarkId id, LiveMarkKind kind) async {
    await _repository.updateKind(id, kind, _clock.now());
    return const Ok(null);
  }
}

@riverpod
ChangeMarkKind changeMarkKind(Ref ref) {
  return ChangeMarkKind(ref.watch(liveMarkRepositoryProvider), ref.watch(clockProvider));
}
