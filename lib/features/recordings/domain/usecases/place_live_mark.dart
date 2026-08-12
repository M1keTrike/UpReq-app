import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/live_mark_repository_impl.dart';
import '../../data/recording_repository_impl.dart';
import '../contracts/live_mark_repository.dart';
import '../contracts/recording_repository.dart';
import '../entities/live_mark.dart';
import '../entities/recording.dart';

part 'place_live_mark.g.dart';

/// Solo con grabación activa (FR-009). Calcula `at_ms` desde el inicio de
/// **su** grabación. Admite dos marcas en el mismo instante sin deduplicar
/// (caso borde ya resuelto en el spec).
final class PlaceLiveMark {
  const PlaceLiveMark(this._liveMarkRepository, this._recordingRepository, this._idGenerator, this._clock);

  final LiveMarkRepository _liveMarkRepository;
  final RecordingRepository _recordingRepository;
  final IdGenerator _idGenerator;
  final Clock _clock;

  Future<Result<LiveMarkId>> call(RecordingId recordingId, LiveMarkKind kind) async {
    final recording = await _recordingRepository.findById(recordingId);
    if (recording == null || recording.status != RecordingStatus.recording) {
      return Err(NoActiveRecordingFailure('No hay una grabación activa $recordingId.'));
    }

    final now = _clock.now();
    final atMs = now.difference(recording.startedAt).inMilliseconds;
    final id = LiveMarkId(_idGenerator.generate());

    await _liveMarkRepository.insert(
      LiveMark(
        id: id,
        recordingId: recordingId,
        sessionId: recording.sessionId,
        projectId: recording.projectId,
        kind: kind,
        atMs: atMs < 0 ? 0 : atMs,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return Ok(id);
  }
}

@riverpod
PlaceLiveMark placeLiveMark(Ref ref) {
  return PlaceLiveMark(
    ref.watch(liveMarkRepositoryProvider),
    ref.watch(recordingRepositoryProvider),
    ref.watch(idGeneratorProvider),
    ref.watch(clockProvider),
  );
}
