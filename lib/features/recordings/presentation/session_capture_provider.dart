import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/combine_latest.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/session_status_reader.dart';

import '../data/recording_repository_impl.dart';
import '../domain/entities/recording.dart';
import '../domain/usecases/find_interrupted.dart';
import 'active_capture_notifier.dart';

part 'session_capture_provider.g.dart';

/// `sessionCaptureProvider(sessionId)` de ui-contracts.md, pantalla 1.
final class SessionCaptureState {
  const SessionCaptureState({
    required this.recordings,
    required this.active,
    required this.canRecord,
    this.interrupted,
  });

  final List<Recording> recordings;
  final ActiveCapture? active;

  /// `true` solo si el proyecto está activo **y** la sesión en curso
  /// (FR-003). Calculado aquí, nunca en el widget.
  final bool canRecord;

  /// Grabación en `interrupted` a la espera de que el analista decida
  /// (FR-011). Se completa en US3; en US1 es siempre `null`.
  final Recording? interrupted;
}

@riverpod
Stream<SessionCaptureState> sessionCapture(Ref ref, String sessionId) {
  final id = SessionId(sessionId);
  final recordingRepository = ref.watch(recordingRepositoryProvider);
  final sessionStatusReader = ref.watch(sessionStatusReaderProvider);
  final projectStatusReader = ref.watch(projectStatusReaderProvider);

  // Watch deliberado: cuando el estado de captura activa cambia (incluido el
  // tick de `elapsed`, a 1 s), esta reconstrucción reabre la suscripción a
  // `watchBySession`. Es el precio de un único provider por pantalla
  // (constitución) en vez de fragmentar el estado en dos.
  final active = ref.watch(activeCaptureProvider);

  final findInterrupted = ref.watch(findInterruptedProvider);

  return combineLatest2(
    recordingRepository.watchBySession(id),
    sessionStatusReader.watch(id),
    (recordings, snapshot) => (recordings, snapshot),
  ).asyncMap((pair) async {
    final (recordings, snapshot) = pair;
    final canRecord = snapshot != null &&
        snapshot.isInProgress &&
        await projectStatusReader.isActive(snapshot.projectId);

    // Promueve y reporta cualquier grabación `recording` huérfana de un
    // proceso anterior (T060), pero solo se muestra si pertenece a ESTA
    // sesión: la hoja de recuperación es propia de la pantalla que se abre.
    // Si `active` no es nulo, este mismo proceso posee la grabación que
    // sigue en `recording` en la base — no es huérfana, así que ni siquiera
    // se consulta: `findInterrupted()` promueve escribiendo en la base, y
    // llamarla aquí marcaría como interrumpida una grabación que se está
    // capturando en este instante (bug real encontrado en dispositivo:
    // el tick de `elapsed` reconstruye este stream cada segundo).
    final anyInterrupted = active == null ? await findInterrupted() : null;
    final interrupted = anyInterrupted?.sessionId == id ? anyInterrupted : null;

    return SessionCaptureState(
      recordings: recordings,
      active: active,
      canRecord: canRecord,
      interrupted: interrupted,
    );
  });
}
