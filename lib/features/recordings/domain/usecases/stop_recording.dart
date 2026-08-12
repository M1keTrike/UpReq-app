import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/clock_provider.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';

import '../../data/recording_repository_impl.dart';
import '../../data/wav_writer.dart';
import '../contracts/recording_repository.dart';
import '../contracts/wav_sink.dart';

part 'stop_recording.g.dart';

/// Cierra y parchea la cabecera del escritor WAV que el notifier dejó
/// abierto (research.md, decisión 4) y fija `duration_ms`/`stopped_at`.
/// No detiene el grabador de hardware: eso sigue siendo del notifier, que es
/// quien posee la suscripción activa al flujo PCM.
final class StopRecording {
  const StopRecording(this._repository, this._wavSink, this._clock);

  final RecordingRepository _repository;
  final WavSink _wavSink;
  final Clock _clock;

  Future<Result<void>> call(RecordingId id) async {
    final durationMs = await _wavSink.closeAndFinalize();
    await _repository.setStopped(id, durationMs, _clock.now());
    return const Ok(null);
  }
}

// keepAlive: se lee desde ActiveCaptureNotifier (T040). Ver start_recording.dart.
@Riverpod(keepAlive: true)
StopRecording stopRecording(Ref ref) {
  return StopRecording(
    ref.watch(recordingRepositoryProvider),
    ref.watch(wavSinkProvider),
    ref.watch(clockProvider),
  );
}
