import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/sessions/domain/entities/elicitation_session.dart';
import 'package:up_req/features/sessions/domain/entities/script_point.dart';
import 'package:up_req/features/sessions/domain/entities/session_detail.dart';
import 'package:up_req/features/sessions/domain/script_point_repository.dart';
import 'package:up_req/features/sessions/domain/session_repository.dart';
import 'package:up_req/features/sessions/domain/usecases/add_script_point.dart';
import 'package:up_req/features/sessions/domain/usecases/delete_script_point.dart';
import 'package:up_req/features/sessions/domain/usecases/mark_script_point.dart';
import 'package:up_req/features/sessions/domain/usecases/reorder_script_point.dart';
import 'package:up_req/features/sessions/domain/usecases/update_script_point_text.dart';

class _FakeScriptPointRepository implements ScriptPointRepository {
  final Map<String, ScriptPoint> store = {};

  @override
  Future<void> append(ScriptPoint point) async => store[point.id.value] = point;

  @override
  Future<ScriptPoint?> findById(ScriptPointId id) async => store[id.value];

  @override
  Future<void> move(SessionId session, ScriptPointId id, int from, int to) async {
    final current = store[id.value]!;
    store[id.value] = current.copyWith(position: to);
  }

  @override
  Future<void> setStatus(ScriptPointId id, ScriptPointStatus status, DateTime at) async {
    final current = store[id.value]!;
    store[id.value] = current.copyWith(status: status, updatedAt: at);
  }

  @override
  Future<void> softDelete(ScriptPointId id, DateTime at) async {
    store.remove(id.value);
  }

  @override
  Future<void> updateText(ScriptPointId id, String text, DateTime at) async {
    final current = store[id.value]!;
    store[id.value] = current.copyWith(text: text, updatedAt: at);
  }

  @override
  Stream<List<ScriptPoint>> watchBySession(SessionId id) {
    final points = store.values.where((p) => p.sessionId == id).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return Stream.value(points);
  }
}

class _FakeSessionRepository implements SessionRepository {
  final Map<String, ElicitationSession> store = {};

  @override
  Future<ElicitationSession?> findById(SessionId id) async => store[id.value];

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

  @override
  Stream<SessionDetail?> watchDetail(SessionId id) => throw UnimplementedError();
}

class _FakeProjectStatusReader implements ProjectStatusReader {
  _FakeProjectStatusReader({this.active = true});

  final bool active;

  @override
  Future<bool> isActive(ProjectId id) async => active;
}

class _FixedIdGenerator implements IdGenerator {
  _FixedIdGenerator(this._id);

  final String _id;

  @override
  String generate() => _id;
}

void main() {
  final at = DateTime.utc(2026, 1, 1);
  const projectId = ProjectId('project-1');
  const sessionId = SessionId('session-1');

  late _FakeScriptPointRepository scriptPointRepository;
  late _FakeSessionRepository sessionRepository;

  setUp(() {
    scriptPointRepository = _FakeScriptPointRepository();
    sessionRepository = _FakeSessionRepository()
      ..store['session-1'] = ElicitationSession(
        id: sessionId,
        projectId: projectId,
        title: 'Entrevista',
        scheduledAt: at,
        technique: SessionTechnique.openInterview,
        status: SessionStatus.planned,
        createdAt: at,
        updatedAt: at,
      );
  });

  group('AddScriptPoint', () {
    test('rechaza texto vacío con ValidationFailure', () async {
      final useCase = AddScriptPoint(
        scriptPointRepository,
        sessionRepository,
        _FakeProjectStatusReader(),
        Clock.fixed(at),
        _FixedIdGenerator('sp-1'),
      );

      final result = await useCase(sessionId, '   ');

      expect(result, isA<Err<ScriptPointId>>());
      expect((result as Err<ScriptPointId>).failure, isA<ValidationFailure>());
      expect(scriptPointRepository.store, isEmpty);
    });

    test('rechaza con ProjectClosedFailure si el proyecto está cerrado (I5)', () async {
      final useCase = AddScriptPoint(
        scriptPointRepository,
        sessionRepository,
        _FakeProjectStatusReader(active: false),
        Clock.fixed(at),
        _FixedIdGenerator('sp-1'),
      );

      final result = await useCase(sessionId, 'Primer punto');

      expect(result, isA<Err<ScriptPointId>>());
      expect((result as Err<ScriptPointId>).failure, isA<ProjectClosedFailure>());
      expect(scriptPointRepository.store, isEmpty);
    });

    test('agrega el punto con position = n', () async {
      final useCase = AddScriptPoint(
        scriptPointRepository,
        sessionRepository,
        _FakeProjectStatusReader(),
        Clock.fixed(at),
        _FixedIdGenerator('sp-1'),
      );

      final first = await useCase(sessionId, 'Primer punto');
      expect(first, isA<Ok<ScriptPointId>>());
      expect(scriptPointRepository.store['sp-1']!.position, 0);

      final useCase2 = AddScriptPoint(
        scriptPointRepository,
        sessionRepository,
        _FakeProjectStatusReader(),
        Clock.fixed(at),
        _FixedIdGenerator('sp-2'),
      );
      await useCase2(sessionId, 'Segundo punto');
      expect(scriptPointRepository.store['sp-2']!.position, 1);
    });

    test('permite agregar aunque la sesión esté cerrada (FR-011)', () async {
      sessionRepository.store['session-1'] = ElicitationSession(
        id: sessionId,
        projectId: projectId,
        title: 'Entrevista',
        scheduledAt: at,
        technique: SessionTechnique.openInterview,
        status: SessionStatus.closed,
        createdAt: at,
        updatedAt: at,
        closedAt: at,
      );

      final useCase = AddScriptPoint(
        scriptPointRepository,
        sessionRepository,
        _FakeProjectStatusReader(),
        Clock.fixed(at),
        _FixedIdGenerator('sp-1'),
      );

      final result = await useCase(sessionId, 'Punto con sesión cerrada');

      expect(result, isA<Ok<ScriptPointId>>());
    });
  });

  group('UpdateScriptPointText', () {
    setUp(() {
      scriptPointRepository.store['sp-1'] = ScriptPoint(
        id: const ScriptPointId('sp-1'),
        sessionId: sessionId,
        projectId: projectId,
        text: 'Original',
        status: ScriptPointStatus.pending,
        position: 0,
        createdAt: at,
        updatedAt: at,
      );
    });

    test('rechaza texto vacío', () async {
      final useCase = UpdateScriptPointText(scriptPointRepository, _FakeProjectStatusReader(), Clock.fixed(at));

      final result = await useCase(const ScriptPointId('sp-1'), '');

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ValidationFailure>());
      expect(scriptPointRepository.store['sp-1']!.text, 'Original');
    });

    test('permite editar el texto con la sesión cerrada pero el proyecto activo (FR-011)', () async {
      final useCase = UpdateScriptPointText(scriptPointRepository, _FakeProjectStatusReader(), Clock.fixed(at));

      final result = await useCase(const ScriptPointId('sp-1'), 'Texto editado');

      expect(result, isA<Ok<void>>());
      expect(scriptPointRepository.store['sp-1']!.text, 'Texto editado');
    });

    test('rechaza con ProjectClosedFailure si el proyecto está cerrado (I5)', () async {
      final useCase = UpdateScriptPointText(
        scriptPointRepository,
        _FakeProjectStatusReader(active: false),
        Clock.fixed(at),
      );

      final result = await useCase(const ScriptPointId('sp-1'), 'Texto editado');

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ProjectClosedFailure>());
      expect(scriptPointRepository.store['sp-1']!.text, 'Original');
    });
  });

  group('MarkScriptPoint', () {
    setUp(() {
      scriptPointRepository.store['sp-1'] = ScriptPoint(
        id: const ScriptPointId('sp-1'),
        sessionId: sessionId,
        projectId: projectId,
        text: 'Punto',
        status: ScriptPointStatus.pending,
        position: 0,
        createdAt: at,
        updatedAt: at,
      );
    });

    test('marca libremente entre los tres estados, en cualquier dirección', () async {
      final useCase = MarkScriptPoint(scriptPointRepository, _FakeProjectStatusReader(), Clock.fixed(at));

      var result = await useCase(const ScriptPointId('sp-1'), ScriptPointStatus.covered);
      expect(result, isA<Ok<void>>());
      expect(scriptPointRepository.store['sp-1']!.status, ScriptPointStatus.covered);

      result = await useCase(const ScriptPointId('sp-1'), ScriptPointStatus.skipped);
      expect(result, isA<Ok<void>>());
      expect(scriptPointRepository.store['sp-1']!.status, ScriptPointStatus.skipped);

      result = await useCase(const ScriptPointId('sp-1'), ScriptPointStatus.pending);
      expect(result, isA<Ok<void>>());
      expect(scriptPointRepository.store['sp-1']!.status, ScriptPointStatus.pending);
    });

    test('rechaza con ProjectClosedFailure si el proyecto está cerrado (I5)', () async {
      final useCase = MarkScriptPoint(
        scriptPointRepository,
        _FakeProjectStatusReader(active: false),
        Clock.fixed(at),
      );

      final result = await useCase(const ScriptPointId('sp-1'), ScriptPointStatus.covered);

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ProjectClosedFailure>());
    });
  });

  group('ReorderScriptPoint', () {
    setUp(() {
      for (var i = 0; i < 3; i++) {
        scriptPointRepository.store['sp$i'] = ScriptPoint(
          id: ScriptPointId('sp$i'),
          sessionId: sessionId,
          projectId: projectId,
          text: 'Punto $i',
          status: ScriptPointStatus.pending,
          position: i,
          createdAt: at,
          updatedAt: at,
        );
      }
    });

    test('rechaza un destino fuera de rango', () async {
      final useCase = ReorderScriptPoint(scriptPointRepository, _FakeProjectStatusReader());

      final result = await useCase(sessionId, const ScriptPointId('sp0'), 0, 5);

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ValidationFailure>());
    });

    test('rechaza con ProjectClosedFailure si el proyecto está cerrado (I5)', () async {
      final useCase = ReorderScriptPoint(scriptPointRepository, _FakeProjectStatusReader(active: false));

      final result = await useCase(sessionId, const ScriptPointId('sp0'), 0, 2);

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ProjectClosedFailure>());
    });

    test('mueve el punto a una posición válida', () async {
      final useCase = ReorderScriptPoint(scriptPointRepository, _FakeProjectStatusReader());

      final result = await useCase(sessionId, const ScriptPointId('sp0'), 0, 2);

      expect(result, isA<Ok<void>>());
      expect(scriptPointRepository.store['sp0']!.position, 2);
    });
  });

  group('DeleteScriptPoint', () {
    setUp(() {
      scriptPointRepository.store['sp-1'] = ScriptPoint(
        id: const ScriptPointId('sp-1'),
        sessionId: sessionId,
        projectId: projectId,
        text: 'Punto',
        status: ScriptPointStatus.pending,
        position: 0,
        createdAt: at,
        updatedAt: at,
      );
    });

    test('rechaza con ProjectClosedFailure si el proyecto está cerrado (I5)', () async {
      final useCase = DeleteScriptPoint(
        scriptPointRepository,
        _FakeProjectStatusReader(active: false),
        Clock.fixed(at),
      );

      final result = await useCase(const ScriptPointId('sp-1'));

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ProjectClosedFailure>());
      expect(scriptPointRepository.store, contains('sp-1'));
    });

    test('elimina el punto con el proyecto activo', () async {
      final useCase = DeleteScriptPoint(scriptPointRepository, _FakeProjectStatusReader(), Clock.fixed(at));

      final result = await useCase(const ScriptPointId('sp-1'));

      expect(result, isA<Ok<void>>());
      expect(scriptPointRepository.store, isNot(contains('sp-1')));
    });
  });
}
