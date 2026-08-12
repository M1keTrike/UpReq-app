import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/recording_repository_impl.dart';
import '../contracts/recording_repository.dart';

part 'delete_recording.g.dart';

/// Baja lógica + asiento `recordingDeleted`, con cascada sobre marcas,
/// transcripciones y segmentos, todo dentro de `RecordingRepositoryImpl`.
final class DeleteRecording {
  const DeleteRecording(this._repository, this._clock);

  final RecordingRepository _repository;
  final Clock _clock;

  Future<Result<void>> call(RecordingId id) async {
    await _repository.softDelete(id, _clock.now());
    return const Ok(null);
  }
}

@riverpod
DeleteRecording deleteRecording(Ref ref) {
  return DeleteRecording(ref.watch(recordingRepositoryProvider), ref.watch(clockProvider));
}
