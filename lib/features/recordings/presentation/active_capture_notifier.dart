import 'dart:async';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/transcription/domain/contracts/transcriber.dart';
import 'package:up_req/features/transcription/domain/usecases/start_live_pass.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/record_audio_recorder.dart';
import '../data/wav_writer.dart';
import '../domain/contracts/audio_recorder.dart';
import '../domain/entities/recording.dart';
import '../domain/usecases/handle_interruption.dart';
import '../domain/usecases/handle_storage_full.dart';
import '../domain/usecases/recover_interrupted.dart';
import '../domain/usecases/start_recording.dart';
import '../domain/usecases/stop_recording.dart';

part 'active_capture_notifier.g.dart';

/// Lo que la pantalla de sesión muestra durante una grabación activa
/// (ui-contracts.md, pantalla 1). `livePartial` vive aquí y en ningún lado
/// más: no se persiste (FR-012), muere al detener.
final class ActiveCapture {
  const ActiveCapture({
    required this.id,
    required this.elapsed,
    required this.marksPlaced,
    required this.isInterrupted,
    this.livePartial,
  });

  final RecordingId id;
  final Duration elapsed;
  final int marksPlaced;
  final bool isInterrupted;
  final String? livePartial;

  ActiveCapture copyWith({
    Duration? elapsed,
    int? marksPlaced,
    bool? isInterrupted,
    String? livePartial,
  }) {
    return ActiveCapture(
      id: id,
      elapsed: elapsed ?? this.elapsed,
      marksPlaced: marksPlaced ?? this.marksPlaced,
      isInterrupted: isInterrupted ?? this.isInterrupted,
      livePartial: livePartial ?? this.livePartial,
    );
  }
}

/// Primera excepción real a `autoDispose` del proyecto (constitución,
/// Principio I). Justificación: este notifier posee el flujo PCM, el
/// escritor WAV y (desde US4) la sesión de transcripción en vivo. Con
/// `autoDispose`, navegar del detalle de sesión a otra pantalla a media
/// entrevista destruiría el provider y con él la grabación en curso — un
/// analista perdiendo una entrevista por haber consultado el glosario es
/// exactamente el modo de falla que este incremento existe para evitar. Se
/// libera de forma explícita al detener o al recuperar, no por ciclo de vida
/// de pantalla.
@Riverpod(keepAlive: true)
class ActiveCaptureNotifier extends _$ActiveCaptureNotifier {
  StreamSubscription<Uint8List>? _pcmSubscription;
  StreamSubscription<RecorderState>? _recorderStatesSubscription;
  Timer? _elapsedTicker;

  /// Sesión de la pasada en vivo (US4), presente solo cuando
  /// `StartLivePass` encontró el modelo `base` disponible. `null` es un
  /// estado válido y frecuente: FR-012 nunca falla la grabación por su
  /// ausencia.
  LiveTranscription? _liveSession;
  StreamSubscription<String>? _livePartialSubscription;

  /// Mide el tiempo transcurrido en pantalla (FR-002) con un cronómetro de
  /// pared, deliberadamente independiente del `Clock` inyectable: ese reloj
  /// se fija en las pruebas para que `started_at` sea determinista, y un
  /// cronómetro atado a un reloj congelado nunca avanzaría.
  final _stopwatch = Stopwatch();

  /// `true` mientras el propio notifier tiene pedida una pausa: distingue la
  /// suya de una impuesta por el sistema (llamada entrante), que el
  /// `_recorderStatesSubscription` interpreta como interrupción (US3).
  bool _ownPause = false;

  /// Lo ya grabado antes de esta captura, para que el cronómetro en pantalla
  /// retome donde se quedó al reanudar una interrupción, en vez de volver a
  /// 00:00 mientras el archivo sigue anexando desde el segundo real (FR-011).
  /// Cero en una grabación nueva.
  Duration _baseElapsed = Duration.zero;

  /// Bifurcador del flujo PCM (research.md, decisión 4 / T041): alimenta al
  /// escritor WAV y deja este stream como segundo suscriptor libre para la
  /// pasada en vivo de US4.
  final _pcmController = StreamController<Uint8List>.broadcast();

  /// Segundo suscriptor libre del bifurcador (T041), consumido por
  /// `StartLivePass` (US4) para alimentar la pasada en vivo. Método y no
  /// getter a propósito: `avoid_public_notifier_properties` solo exceptúa
  /// métodos, y este stream no es estado de pantalla — no cabe en `state`,
  /// que sigue siendo la única fuente de verdad para lo que la UI renderiza.
  Stream<Uint8List> pcmBroadcast() => _pcmController.stream;

  @override
  ActiveCapture? build() {
    ref.onDispose(() {
      _pcmSubscription?.cancel();
      _recorderStatesSubscription?.cancel();
      _livePartialSubscription?.cancel();
      _elapsedTicker?.cancel();
      _pcmController.close();
    });
    return null;
  }

  Future<Result<RecordingId>> start(SessionId sessionId) async {
    final result = await ref.read(startRecordingProvider)(sessionId);
    if (result is Err<RecordingId>) return result;
    final id = (result as Ok<RecordingId>).value;

    final wavSink = ref.read(wavSinkProvider);
    await wavSink.open('recordings/${id.value}.wav');
    await _beginCapture(id);

    return Ok(id);
  }

  /// Reanuda una grabación `interrupted` tras la elección explícita del
  /// analista (FR-011). La cabecera ya quedó reparada por
  /// `RecoverInterrupted`; aquí solo se reabre el archivo para anexar y se
  /// vuelve a abrir el micrófono, exactamente como un `start()` nuevo pero
  /// sin volver a validar sesión/proyecto ni generar otra fila.
  Future<Result<void>> resumeInterrupted(RecordingId id) async {
    final result = await ref.read(recoverInterruptedProvider)(id, RecoveryChoice.resume);
    if (result is Err<Recording>) return Err(result.failure);
    final recording = (result as Ok<Recording>).value;

    final wavSink = ref.read(wavSinkProvider);
    await wavSink.reopenForAppend(
      recording.filePath,
      sampleRate: recording.sampleRate,
      channels: recording.channels,
    );
    await _beginCapture(id, baseElapsed: Duration(milliseconds: recording.durationMs));

    return const Ok(null);
  }

  /// Cierra una grabación `interrupted` conservando lo capturado, sin volver
  /// a tocar hardware: ya está liberado desde que se detectó la
  /// interrupción (`_handleImposedPause`) o nunca llegó a abrirse en este
  /// proceso (recuperación tras un cierre inesperado).
  Future<Result<void>> closeInterrupted(RecordingId id) async {
    final result = await ref.read(recoverInterruptedProvider)(id, RecoveryChoice.closeKeeping);
    return switch (result) {
      Ok() => const Ok(null),
      Err(:final failure) => Err(failure),
    };
  }

  Future<void> _beginCapture(RecordingId id, {Duration baseElapsed = Duration.zero}) async {
    final recorder = ref.read(audioRecorderProvider);
    final wavSink = ref.read(wavSinkProvider);
    final pcmStream = await recorder.start();

    _ownPause = false;
    _pcmSubscription = pcmStream.listen((frame) {
      _pcmController.add(frame);
      wavSink.append(frame).catchError((Object _) => _onStorageFull(id));
    });
    _recorderStatesSubscription = recorder.states.listen(_onRecorderState);

    _baseElapsed = baseElapsed;
    _stopwatch
      ..reset()
      ..start();
    state = ActiveCapture(id: id, elapsed: baseElapsed, marksPlaced: 0, isInterrupted: false);

    unawaited(_enableWakelock());

    // Un segundo de granularidad: es lo que un reloj mm:ss necesita, y
    // mantiene bajo el coste de que `sessionCaptureProvider` reconstruya su
    // suscripción a la base cada vez que este estado cambia.
    _elapsedTicker?.cancel();
    _elapsedTicker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());

    unawaited(_startLiveIfAvailable(id));
  }

  /// FR-012: arranca la pasada en vivo sobre el segundo suscriptor del
  /// bifurcador. Si `StartLivePass` devuelve `Err` (modelo `base` ausente),
  /// se omite en silencio — la barrera del modelo (research.md, C3) no debe
  /// convertirse en un fallo de grabación. Corre en paralelo a `_beginCapture`
  /// (no se espera desde ahí) porque cargar el modelo puede tardar más que
  /// abrir el micrófono, y la captura no debe esperar por eso.
  Future<void> _startLiveIfAvailable(RecordingId id) async {
    final result = await ref.read(startLivePassProvider)(id, pcmBroadcast());
    if (result is! Ok<LiveTranscription>) return;

    if (state == null) {
      // La captura ya se detuvo (o nunca llegó a persistir el estado)
      // mientras esperábamos: no dejar una sesión de inferencia huérfana.
      await result.value.stop();
      return;
    }

    _liveSession = result.value;
    _livePartialSubscription = _liveSession!.partials.listen(updateLivePartial);
  }

  void _tick() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(elapsed: _baseElapsed + _stopwatch.elapsed);
  }

  Future<Result<void>> stop() async {
    final current = state;
    if (current == null) return const Ok(null);

    await _releaseHardware();
    final result = await ref.read(stopRecordingProvider)(current.id);
    state = null;
    return result;
  }

  /// Incrementa el contador visible de marcas colocadas (US2). El estado de
  /// las marcas en sí vive en `LiveMarkRepository`; este contador es solo
  /// realimentación en pantalla.
  void noteMarkPlaced() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(marksPlaced: current.marksPlaced + 1);
  }

  /// FR-012: vuelca el avance de la pasada en vivo. Nunca se persiste.
  void updateLivePartial(String? text) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(livePartial: text);
  }

  /// `_ownPause` se marca ANTES de pedir el `stop()` y la suscripción a
  /// `states` se cancela DESPUÉS de que resuelva: si `stop()` dispara
  /// internamente una transición transitoria a `paused` antes de `stopped`,
  /// `_onRecorderState` la reconoce como propia y no la confunde con una
  /// interrupción del sistema (research.md, decisión 5).
  Future<void> _releaseHardware() async {
    await _pcmSubscription?.cancel();
    _pcmSubscription = null;
    _elapsedTicker?.cancel();
    _elapsedTicker = null;
    _stopwatch.stop();
    _ownPause = true;
    await ref.read(audioRecorderProvider).stop();
    await _recorderStatesSubscription?.cancel();
    _recorderStatesSubscription = null;
    await _stopLiveSession();
    unawaited(_disableWakelock());
  }

  /// Cierra la sesión de la pasada en vivo, si la había: nunca sobrevive a
  /// una captura (FR-012, "vive en el notifier y muere al detener"), ni
  /// siquiera durante una interrupción impuesta por el sistema.
  Future<void> _stopLiveSession() async {
    await _livePartialSubscription?.cancel();
    _livePartialSubscription = null;
    final live = _liveSession;
    _liveSession = null;
    if (live != null) await live.stop();
  }

  Future<void> _onStorageFull(RecordingId id) async {
    await _releaseHardware();
    await ref.read(handleStorageFullProvider)(id);
    state = null;
  }

  void _onRecorderState(RecorderState recorderState) {
    if (recorderState != RecorderState.paused) return;
    if (_ownPause) {
      _ownPause = false;
      return;
    }
    // Pausa que el notifier no pidió: interrupción del sistema (llamada
    // entrante). FR-010.
    final current = state;
    if (current != null) unawaited(_handleImposedPause(current.id));
  }

  Future<void> _handleImposedPause(RecordingId id) async {
    await _releaseHardware();
    await ref.read(handleInterruptionProvider)(id);
    // El estado pasa a null, igual que tras `stop()`: la grabación queda en
    // `interrupted` en la base y la reporta `sessionCaptureProvider` (T065)
    // vía `FindInterrupted`, que es la única fuente de verdad para mostrar
    // la hoja de recuperación (evita un doble estado "activa e interrumpida"
    // más "interrumpida en la base" al mismo tiempo).
    state = null;
  }

  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {
      // Sin binding de plataforma (pruebas) o dispositivo sin soporte: no es
      // un fallo que deba interrumpir la captura.
    }
  }

  Future<void> _disableWakelock() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {
      // Ver _enableWakelock.
    }
  }
}
