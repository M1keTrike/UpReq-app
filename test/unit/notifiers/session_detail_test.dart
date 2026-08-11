import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/features/sessions/data/script_point_repository_impl.dart';
import 'package:up_req/features/sessions/data/session_repository_impl.dart';
import 'package:up_req/features/sessions/domain/entities/elicitation_session.dart';
import 'package:up_req/features/sessions/domain/entities/script_point.dart';
import 'package:up_req/features/sessions/domain/entities/session_counters.dart';
import 'package:up_req/features/sessions/domain/entities/session_detail.dart';
import 'package:up_req/features/sessions/domain/script_point_repository.dart';
import 'package:up_req/features/sessions/domain/session_repository.dart';
import 'package:up_req/features/sessions/presentation/session_detail_provider.dart';

import '../../support/test_container.dart';

/// Estado compartido y reactivo entre los dos repositorios dobles, para
/// poder simular que reordenar y marcar cambian lo que el provider combinado
/// expone, igual que ocurriría con las consultas reales de drift.
class _World {
  _World({required this.session});

  ElicitationSession session;
  List<StakeholderId> participantIds = const [];
  final List<ScriptPoint> points = [];

  late final StreamController<List<ScriptPoint>> _pointsController =
      StreamController<List<ScriptPoint>>.broadcast(onListen: () => _pointsController.add(_sortedPoints()));
  late final StreamController<SessionDetail?> _detailController =
      StreamController<SessionDetail?>.broadcast(onListen: () => _detailController.add(_detail()));

  Stream<List<ScriptPoint>> get pointsStream => _pointsController.stream;
  Stream<SessionDetail?> get detailStream => _detailController.stream;

  List<ScriptPoint> _sortedPoints() => [...points]..sort((a, b) => a.position.compareTo(b.position));

  SessionDetail _detail() {
    return SessionDetail(
      session: session,
      participantIds: participantIds,
      counters: SessionCounters(
        pending: points.where((p) => p.status == ScriptPointStatus.pending).length,
        covered: points.where((p) => p.status == ScriptPointStatus.covered).length,
        skipped: points.where((p) => p.status == ScriptPointStatus.skipped).length,
      ),
    );
  }

  void _emit() {
    _pointsController.add(_sortedPoints());
    _detailController.add(_detail());
  }

  void append(ScriptPoint point) {
    points.add(point);
    _emit();
  }

  void move(String id, int to) {
    final idx = points.indexWhere((p) => p.id.value == id);
    final item = points.removeAt(idx);
    points.insert(to, item);
    for (var i = 0; i < points.length; i++) {
      points[i] = points[i].copyWith(position: i);
    }
    _emit();
  }

  void setStatus(String id, ScriptPointStatus status) {
    final idx = points.indexWhere((p) => p.id.value == id);
    points[idx] = points[idx].copyWith(status: status);
    _emit();
  }
}

class _FakeSessionRepository implements SessionRepository {
  _FakeSessionRepository(this._world);
  final _World _world;

  @override
  Future<ElicitationSession?> findById(SessionId id) async => _world.session;

  @override
  Stream<SessionDetail?> watchDetail(SessionId id) => _world.detailStream;

  @override
  Future<void> insert(ElicitationSession session, List<StakeholderId> participantIds) =>
      throw UnimplementedError();

  @override
  Future<void> softDelete(SessionId id, DateTime at) => throw UnimplementedError();

  @override
  Future<void> setStatus(SessionId id, SessionStatus status, DateTime at) => throw UnimplementedError();

  @override
  Future<void> updateHeader(ElicitationSession session, List<StakeholderId> participantIds) =>
      throw UnimplementedError();

  @override
  Future<void> updateNotes(SessionId id, String? notes, DateTime at) => throw UnimplementedError();

  @override
  Stream<List<ElicitationSession>> watchByProject(ProjectId id) => throw UnimplementedError();
}

class _FakeScriptPointRepository implements ScriptPointRepository {
  _FakeScriptPointRepository(this._world);
  final _World _world;

  @override
  Stream<List<ScriptPoint>> watchBySession(SessionId id) => _world.pointsStream;

  @override
  Future<ScriptPoint?> findById(ScriptPointId id) async {
    for (final point in _world.points) {
      if (point.id == id) return point;
    }
    return null;
  }

  @override
  Future<void> append(ScriptPoint point) => throw UnimplementedError();

  @override
  Future<void> move(SessionId session, ScriptPointId id, int from, int to) => throw UnimplementedError();

  @override
  Future<void> setStatus(ScriptPointId id, ScriptPointStatus status, DateTime at) => throw UnimplementedError();

  @override
  Future<void> softDelete(ScriptPointId id, DateTime at) => throw UnimplementedError();

  @override
  Future<void> updateText(ScriptPointId id, String text, DateTime at) => throw UnimplementedError();
}

class _FakeProjectStatusReader implements ProjectStatusReader {
  const _FakeProjectStatusReader();

  @override
  Future<bool> isActive(ProjectId id) async => true;
}

/// Deja correr varios turnos de microtareas para que las emisiones
/// encadenadas (stream doble -> `combineLatest2` -> `asyncMap`) lleguen al
/// listener antes de comprobar el estado.
Future<void> _flush() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  final at = DateTime.utc(2026, 1, 1);
  const projectId = ProjectId('project-1');
  const sessionId = SessionId('session-1');

  test('un único provider combina sesión, puntos y contadores, y refleja reordenar y marcar', () async {
    final world = _World(
      session: ElicitationSession(
        id: sessionId,
        projectId: projectId,
        title: 'Entrevista',
        scheduledAt: at,
        technique: SessionTechnique.openInterview,
        status: SessionStatus.planned,
        createdAt: at,
        updatedAt: at,
      ),
    )
      ..participantIds = [const StakeholderId('stakeholder-1')]
      ..append(
        ScriptPoint(
          id: const ScriptPointId('sp0'),
          sessionId: sessionId,
          projectId: projectId,
          text: 'Punto 0',
          status: ScriptPointStatus.pending,
          position: 0,
          createdAt: at,
          updatedAt: at,
        ),
      )
      ..append(
        ScriptPoint(
          id: const ScriptPointId('sp1'),
          sessionId: sessionId,
          projectId: projectId,
          text: 'Punto 1',
          status: ScriptPointStatus.pending,
          position: 1,
          createdAt: at,
          updatedAt: at,
        ),
      );

    final container = buildTestContainer(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(_FakeSessionRepository(world)),
        scriptPointRepositoryProvider.overrideWithValue(_FakeScriptPointRepository(world)),
        projectStatusReaderProvider.overrideWithValue(const _FakeProjectStatusReader()),
      ],
    );
    addTearDown(container.dispose);

    final states = <SessionDetailState>[];
    container.listen(sessionDetailProvider('session-1'), (_, next) {
      final value = next.value;
      if (value != null) states.add(value);
    }, fireImmediately: true);

    await container.read(sessionDetailProvider('session-1').future);

    expect(states.last.points.map((p) => p.id.value), ['sp0', 'sp1']);
    expect(states.last.counters.pending, 2);
    expect(states.last.counters.covered, 0);
    expect(states.last.isReadOnly, isFalse);
    expect(states.last.isHeaderFrozen, isFalse);

    // Marcar sp0 como cubierto: el provider único recalcula puntos y
    // contadores a partir del mismo cambio.
    world.setStatus('sp0', ScriptPointStatus.covered);
    await _flush();

    expect(states.last.points.firstWhere((p) => p.id.value == 'sp0').status, ScriptPointStatus.covered);
    expect(states.last.counters.covered, 1);
    expect(states.last.counters.pending, 1);

    // Reordenar: mover sp1 al principio.
    world.move('sp1', 0);
    await _flush();

    expect(states.last.points.map((p) => p.id.value), ['sp1', 'sp0']);
    expect(states.last.points.map((p) => p.position), [0, 1]);
  });
}
