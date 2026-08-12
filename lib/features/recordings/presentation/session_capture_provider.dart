import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/session_status_reader.dart';

import '../data/recording_repository_impl.dart';
import '../domain/entities/recording.dart';
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

  return recordingRepository.watchBySession(id).asyncMap((recordings) async {
    final snapshot = await sessionStatusReader.find(id);
    final canRecord = snapshot != null &&
        snapshot.isInProgress &&
        await projectStatusReader.isActive(snapshot.projectId);
    final interrupted = await recordingRepository.findInterrupted();

    return SessionCaptureState(
      recordings: recordings,
      active: active,
      canRecord: canRecord,
      interrupted: interrupted,
    );
  });
}
