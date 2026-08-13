import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/session_status_reader.dart';
import 'package:up_req/features/recordings/data/recording_repository_impl.dart';
import 'package:up_req/features/recordings/domain/contracts/recording_repository.dart';
import 'package:up_req/features/recordings/domain/entities/recording.dart';
import 'package:up_req/features/recordings/presentation/active_capture_notifier.dart';
import 'package:up_req/features/recordings/presentation/session_capture_provider.dart';

import '../../support/test_container.dart';

/// A diferencia de `FakeRecordingRepository` (test/support), este doble deja
/// disparar `watchBySession` a voluntad para reproducir la carrera real: el
/// insert de `StartRecording` y el `state` de `ActiveCaptureNotifier` no son
/// atómicos, así que `watchBySession` puede emitir con la fila nueva en
/// `recording` mientras `active` todavía es `null`.
class _RaceableRecordingRepository implements RecordingRepository {
  final Map<String, Recording> store = {};
  final _sessionController = StreamController<List<Recording>>.broadcast();
  final List<RecordingStatus> statusUpdates = [];

  void insertSilently(Recording recording) => store[recording.id.value] = recording;

  /// Simula la notificación de drift tras el commit del insert, sin tocar
  /// `active` — es exactamente el hueco que `ActiveCaptureNotifier.start()`
  /// deja abierto entre insertar la fila y fijar su propio estado.
  void emitSessionSnapshot(SessionId id) {
    _sessionController.add(store.values.where((r) => r.sessionId == id).toList());
  }

  @override
  Stream<List<Recording>> watchBySession(SessionId id) async* {
    yield store.values.where((r) => r.sessionId == id).toList();
    yield* _sessionController.stream;
  }

  @override
  Stream<Recording?> watchActive() {
    final active = store.values.where((r) => r.status == RecordingStatus.recording).firstOrNull;
    return Stream.value(active);
  }

  @override
  Future<Recording?> findInterrupted() async {
    return store.values.where((r) => r.status == RecordingStatus.interrupted).firstOrNull;
  }

  @override
  Future<void> updateStatus(RecordingId id, RecordingStatus status, DateTime at) async {
    statusUpdates.add(status);
    final current = store[id.value]!;
    store[id.value] = current.copyWith(status: status, updatedAt: at);
    // Un `drift` real reacciona a cualquier escritura sobre la tabla que un
    // `watch()` observa, sin que importa qué consulta hizo la escritura:
    // esto reproduce esa reactividad para poder atrapar la carrera de
    // `session_capture_provider.dart` donde la propia escritura de
    // `findInterrupted()` retroalimenta `watchBySession`.
    emitSessionSnapshot(current.sessionId);
  }

  @override
  Future<void> insert(Recording recording) async => insertSilently(recording);

  @override
  Stream<Recording?> watchById(RecordingId id) => Stream.value(store[id.value]);

  @override
  Future<Recording?> findById(RecordingId id) async => store[id.value];

  @override
  Future<void> setStopped(RecordingId id, int durationMs, DateTime at) async {
    final current = store[id.value]!;
    store[id.value] = current.copyWith(
      status: RecordingStatus.stopped,
      durationMs: durationMs,
      stoppedAt: at,
      updatedAt: at,
    );
  }

  @override
  Future<void> softDelete(RecordingId id, DateTime at) async {
    store.remove(id.value);
  }
}

class _FakeSessionStatusReader implements SessionStatusReader {
  @override
  Future<SessionSnapshot?> find(SessionId id) async {
    return const SessionSnapshot(projectId: ProjectId('project-1'), isInProgress: true);
  }

  @override
  Stream<SessionSnapshot?> watch(SessionId id) => Stream.value(
        const SessionSnapshot(projectId: ProjectId('project-1'), isInProgress: true),
      );
}

class _FakeProjectStatusReader implements ProjectStatusReader {
  @override
  Future<bool> isActive(ProjectId id) async => true;
}

/// `activeCaptureProvider` real depende de hardware; para esta prueba solo
/// importa que se mantenga en `null` durante toda la carrera, igual que en
/// el proceso real entre el insert de `StartRecording` y `_beginCapture()`.
class _NullActiveCaptureNotifier extends ActiveCaptureNotifier {
  @override
  ActiveCapture? build() => null;
}

final _at = DateTime.utc(2026, 1, 1);
const _sessionId = SessionId('session-1');

Recording _recording(String id, RecordingStatus status) => Recording(
      id: RecordingId(id),
      sessionId: _sessionId,
      projectId: const ProjectId('project-1'),
      filePath: 'recordings/$id.wav',
      status: status,
      durationMs: 0,
      sampleRate: 16000,
      channels: 1,
      startedAt: _at,
      createdAt: _at,
      updatedAt: _at,
    );

void main() {
  test(
    'insertar la fila recording no la marca interrupted mientras sigue sin dueño en memoria '
    '(no reevalúa findInterrupted en cada emisión de watchBySession, T110 bug 3 en su variante '
    'de arranque)',
    () async {
      final repository = _RaceableRecordingRepository();
      final container = buildTestContainer(
        overrides: [
          recordingRepositoryProvider.overrideWithValue(repository),
          sessionStatusReaderProvider.overrideWithValue(_FakeSessionStatusReader()),
          projectStatusReaderProvider.overrideWithValue(_FakeProjectStatusReader()),
          activeCaptureProvider.overrideWith(_NullActiveCaptureNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      final states = <SessionCaptureState>[];
      final sub = container.listen(
        sessionCaptureProvider(_sessionId.value),
        (previous, next) {
          final value = next.value;
          if (value != null) states.add(value);
        },
        fireImmediately: true,
      );
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);

      // `StartRecording` acaba de insertar la fila `recording` (bug real:
      // ocurre antes de que `_beginCapture()` fije `active`, que en esta
      // prueba se queda en `null` a propósito con `_NullActiveCaptureNotifier`).
      repository.insertSilently(_recording('recording-1', RecordingStatus.recording));
      repository.emitSessionSnapshot(_sessionId);
      await Future<void>.delayed(Duration.zero);
      // Segunda emisión mientras `active` sigue en `null` (p. ej. otro
      // cambio de la sesión reconstruye el stream combinado): sin el
      // candado, esto dispararía una segunda llamada a `findInterrupted()`.
      repository.emitSessionSnapshot(_sessionId);
      await Future<void>.delayed(Duration.zero);

      expect(
        repository.store['recording-1']!.status,
        RecordingStatus.recording,
        reason: 'la grabación que se está iniciando no debe quedar interrupted en la base',
      );
      expect(
        repository.statusUpdates,
        isEmpty,
        reason: 'findInterrupted() no debería promover nada: no hay ninguna fila huérfana',
      );
    },
  );

  test(
    'una grabación huérfana de un proceso anterior sigue reportada como interrupted tras la '
    'reemisión que la propia escritura de findInterrupted() dispara (bug real: la hoja de '
    'recuperación nunca aparecía en dispositivo porque esa reemisión pisaba el hallazgo con null)',
    () async {
      final repository = _RaceableRecordingRepository()
        ..insertSilently(_recording('recording-1', RecordingStatus.recording));
      final container = buildTestContainer(
        overrides: [
          recordingRepositoryProvider.overrideWithValue(repository),
          sessionStatusReaderProvider.overrideWithValue(_FakeSessionStatusReader()),
          projectStatusReaderProvider.overrideWithValue(_FakeProjectStatusReader()),
          activeCaptureProvider.overrideWith(_NullActiveCaptureNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      final states = <SessionCaptureState>[];
      final sub = container.listen(
        sessionCaptureProvider(_sessionId.value),
        (previous, next) {
          final value = next.value;
          if (value != null) states.add(value);
        },
        fireImmediately: true,
      );
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        repository.store['recording-1']!.status,
        RecordingStatus.interrupted,
        reason: 'findInterrupted() sí debe promover una fila huérfana de un proceso anterior',
      );
      expect(
        states.last.interrupted?.id,
        const RecordingId('recording-1'),
        reason: 'el último estado emitido debe seguir reportando la interrupción, no perderla '
            'en la reemisión que la propia promoción disparó sobre watchBySession',
      );
    },
  );
}
