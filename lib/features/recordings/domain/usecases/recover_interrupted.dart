import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/recording_repository_impl.dart';
import '../../data/wav_writer.dart';
import '../contracts/recording_repository.dart';
import '../contracts/wav_sink.dart';
import '../entities/recording.dart';

part 'recover_interrupted.g.dart';

enum RecoveryChoice { resume, closeKeeping }

/// Repara la cabecera del archivo en AMBAS ramas (research.md, decisión 4):
/// el audio hasta el corte está íntegro, solo falta recalcular los tamaños.
/// `resume` deja la grabación en `recording`, lista para que el notifier
/// reabra el flujo anexando al mismo archivo (T064). `closeKeeping` la deja
/// en `stopped` con la duración real. FR-011.
final class RecoverInterrupted {
  const RecoverInterrupted(this._repository, this._wavSink, this._clock);

  final RecordingRepository _repository;
  final WavSink _wavSink;
  final Clock _clock;

  Future<Result<Recording>> call(RecordingId id, RecoveryChoice choice) async {
    final recording = await _repository.findById(id);
    if (recording == null) {
      return Err(NotFoundFailure('No se encontró la grabación $id.'));
    }

    final durationMs = await _wavSink.repairExisting(
      recording.filePath,
      sampleRate: recording.sampleRate,
      channels: recording.channels,
    );
    final now = _clock.now();

    switch (choice) {
      case RecoveryChoice.resume:
        await _repository.updateStatus(id, RecordingStatus.recording, now);
        return Ok(recording.copyWith(status: RecordingStatus.recording, updatedAt: now));
      case RecoveryChoice.closeKeeping:
        await _repository.setStopped(id, durationMs, now);
        return Ok(
          recording.copyWith(
            status: RecordingStatus.stopped,
            durationMs: durationMs,
            stoppedAt: now,
            updatedAt: now,
          ),
        );
    }
  }
}

// keepAlive: se lee desde ActiveCaptureNotifier (T064). Ver start_recording.dart.
@Riverpod(keepAlive: true)
RecoverInterrupted recoverInterrupted(Ref ref) {
  return RecoverInterrupted(
    ref.watch(recordingRepositoryProvider),
    ref.watch(wavSinkProvider),
    ref.watch(clockProvider),
  );
}
