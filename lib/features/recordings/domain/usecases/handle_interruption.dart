import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/recording_repository_impl.dart';
import '../contracts/recording_repository.dart';
import '../entities/recording.dart';

part 'handle_interruption.g.dart';

/// Disparado por una pausa que el notifier no pidió (llamada entrante).
/// Marca `interrupted` conservando el archivo tal cual está: la cabecera se
/// repara más tarde, cuando el analista elige cómo proceder
/// (`RecoverInterrupted`). FR-010.
final class HandleInterruption {
  const HandleInterruption(this._repository, this._clock);

  final RecordingRepository _repository;
  final Clock _clock;

  Future<Result<void>> call(RecordingId id) async {
    await _repository.updateStatus(id, RecordingStatus.interrupted, _clock.now());
    return const Ok(null);
  }
}

// keepAlive: se lee desde ActiveCaptureNotifier (T064). Ver start_recording.dart.
@Riverpod(keepAlive: true)
HandleInterruption handleInterruption(Ref ref) {
  return HandleInterruption(ref.watch(recordingRepositoryProvider), ref.watch(clockProvider));
}
