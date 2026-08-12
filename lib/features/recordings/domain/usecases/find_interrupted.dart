import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';

import '../../data/recording_repository_impl.dart';
import '../contracts/recording_repository.dart';
import '../entities/recording.dart';

part 'find_interrupted.g.dart';

/// Al arrancar, cualquier grabación que siga en `recording` es, por
/// definición, una interrupción: `ActiveCaptureNotifier` nace vacío en cada
/// proceso nuevo (es `keepAlive`, no persistente entre ejecuciones), así
/// que si la base todavía dice `recording` es porque el proceso anterior
/// murió sin llegar a `stop()`. La promueve a `interrupted` antes de
/// reportarla; a partir de ahí es indistinguible de una interrupción por
/// llamada entrante.
final class FindInterrupted {
  const FindInterrupted(this._repository, this._clock);

  final RecordingRepository _repository;
  final Clock _clock;

  Future<Recording?> call() async {
    final stale = await _repository.watchActive().first;
    if (stale != null) {
      await _repository.updateStatus(stale.id, RecordingStatus.interrupted, _clock.now());
    }
    return _repository.findInterrupted();
  }
}

@riverpod
FindInterrupted findInterrupted(Ref ref) {
  return FindInterrupted(ref.watch(recordingRepositoryProvider), ref.watch(clockProvider));
}
