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

part 'handle_storage_full.g.dart';

/// El escritor WAV falló por falta de espacio a mitad de una trama
/// (disparado desde `ActiveCaptureNotifier`, que es quien observa el flujo
/// PCM). Cierra y parchea la cabecera con lo capturado hasta ese instante —
/// nunca se pierde el audio ya escrito—, deja la grabación en `stopped` con
/// su duración real, y devuelve `StorageFullFailure` para que la UI lo
/// informe en vez de tratarlo como un fallo silencioso.
final class HandleStorageFull {
  const HandleStorageFull(this._repository, this._wavSink, this._clock);

  final RecordingRepository _repository;
  final WavSink _wavSink;
  final Clock _clock;

  Future<Result<void>> call(RecordingId id) async {
    final durationMs = await _wavSink.closeAndFinalize();
    await _repository.setStopped(id, durationMs, _clock.now());
    return Err(StorageFullFailure('El almacenamiento del dispositivo se agotó durante la grabación.'));
  }
}

// keepAlive: se lee desde ActiveCaptureNotifier (T040). Ver start_recording.dart.
@Riverpod(keepAlive: true)
HandleStorageFull handleStorageFull(Ref ref) {
  return HandleStorageFull(
    ref.watch(recordingRepositoryProvider),
    ref.watch(wavSinkProvider),
    ref.watch(clockProvider),
  );
}
