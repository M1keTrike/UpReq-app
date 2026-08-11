import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/failures.dart';
import 'package:up_req/core/domain/id_generator.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/core/domain/result.dart';
import 'package:up_req/features/sessions/domain/entities/elicitation_session.dart';
import 'package:up_req/features/sessions/domain/entities/session_detail.dart';
import 'package:up_req/features/sessions/domain/entities/session_draft.dart';
import 'package:up_req/features/sessions/domain/session_repository.dart';
import 'package:up_req/features/sessions/domain/usecases/advance_session_status.dart';
import 'package:up_req/features/sessions/domain/usecases/create_session.dart';
import 'package:up_req/features/sessions/domain/usecases/delete_session.dart';
import 'package:up_req/features/sessions/domain/usecases/update_session_header.dart';
import 'package:up_req/features/sessions/domain/usecases/update_session_notes.dart';
import 'package:up_req/features/stakeholders/domain/entities/stakeholder.dart';
import 'package:up_req/features/stakeholders/domain/stakeholder_repository.dart';

class _FakeSessionRepository implements SessionRepository {
  final Map<String, ElicitationSession> store = {};
  final Map<String, List<StakeholderId>> participants = {};

  @override
  Future<void> insert(ElicitationSession session, List<StakeholderId> participantIds) async {
    store[session.id.value] = session;
    participants[session.id.value] = participantIds;
  }

  @override
  Future<void> updateHeader(ElicitationSession session, List<StakeholderId> participantIds) async {
    store[session.id.value] = session;
    participants[session.id.value] = participantIds;
  }

  @override
  Future<void> updateNotes(SessionId id, String? notes, DateTime at) async {
    final current = store[id.value]!;
    store[id.value] = ElicitationSession(
      id: current.id,
      projectId: current.projectId,
      title: current.title,
      scheduledAt: current.scheduledAt,
      technique: current.technique,
      location: current.location,
      status: current.status,
      notes: notes,
      closedAt: current.closedAt,
      createdAt: current.createdAt,
      updatedAt: at,
    );
  }

  @override
  Future<void> setStatus(SessionId id, SessionStatus status, DateTime at) async {
    final current = store[id.value]!;
    store[id.value] = ElicitationSession(
      id: current.id,
      projectId: current.projectId,
      title: current.title,
      scheduledAt: current.scheduledAt,
      technique: current.technique,
      location: current.location,
      status: status,
      notes: current.notes,
      closedAt: status == SessionStatus.closed ? at : current.closedAt,
      createdAt: current.createdAt,
      updatedAt: at,
    );
  }

  @override
  Future<void> softDelete(SessionId id, DateTime at) async {
    store.remove(id.value);
  }

  @override
  Future<ElicitationSession?> findById(SessionId id) async => store[id.value];

  @override
  Stream<List<ElicitationSession>> watchByProject(ProjectId id) => throw UnimplementedError();

  @override
  Stream<SessionDetail?> watchDetail(SessionId id) => throw UnimplementedError();
}

class _FakeStakeholderRepository implements StakeholderRepository {
  final Map<String, Stakeholder> store = {};

  @override
  Future<Stakeholder?> findById(StakeholderId id) async => store[id.value];

  @override
  Future<void> insert(Stakeholder stakeholder) => throw UnimplementedError();

  @override
  Future<void> update(Stakeholder stakeholder) => throw UnimplementedError();

  @override
  Future<void> deactivate(StakeholderId id, DateTime at) => throw UnimplementedError();

  @override
  Stream<List<Stakeholder>> watchByProject(ProjectId id) => throw UnimplementedError();

  @override
  Stream<List<Stakeholder>> watchSelectableByProject(ProjectId id) => throw UnimplementedError();
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
  const otherProjectId = ProjectId('project-2');
  late _FakeSessionRepository sessionRepository;
  late _FakeStakeholderRepository stakeholderRepository;

  setUp(() {
    sessionRepository = _FakeSessionRepository();
    stakeholderRepository = _FakeStakeholderRepository()
      ..store['stakeholder-1'] = Stakeholder(
        id: const StakeholderId('stakeholder-1'),
        projectId: projectId,
        name: 'Ana',
        influence: InfluenceLevel.medium,
        status: StakeholderStatus.active,
        createdAt: at,
        updatedAt: at,
      )
      ..store['stakeholder-2'] = Stakeholder(
        id: const StakeholderId('stakeholder-2'),
        projectId: otherProjectId,
        name: 'De otro proyecto',
        influence: InfluenceLevel.medium,
        status: StakeholderStatus.active,
        createdAt: at,
        updatedAt: at,
      );
  });

  group('CreateSession', () {
    test('rechaza una sesión sin participantes', () async {
      final useCase = CreateSession(
        sessionRepository,
        stakeholderRepository,
        _FakeProjectStatusReader(),
        Clock.fixed(at),
        _FixedIdGenerator('session-1'),
      );

      final result = await useCase(
        projectId,
        SessionDraft(
          title: 'Entrevista',
          scheduledAt: at,
          technique: SessionTechnique.openInterview,
          participantIds: const [],
        ),
      );

      expect(result, isA<Err<SessionId>>());
      expect((result as Err<SessionId>).failure, isA<ValidationFailure>());
      expect(sessionRepository.store, isEmpty);
    });

    test('rechaza un participante de otro proyecto con CrossProjectReferenceFailure (I8)', () async {
      final useCase = CreateSession(
        sessionRepository,
        stakeholderRepository,
        _FakeProjectStatusReader(),
        Clock.fixed(at),
        _FixedIdGenerator('session-1'),
      );

      final result = await useCase(
        projectId,
        SessionDraft(
          title: 'Entrevista',
          scheduledAt: at,
          technique: SessionTechnique.openInterview,
          participantIds: const [StakeholderId('stakeholder-2')],
        ),
      );

      expect(result, isA<Err<SessionId>>());
      expect((result as Err<SessionId>).failure, isA<CrossProjectReferenceFailure>());
      expect(sessionRepository.store, isEmpty);
    });

    test('rechaza con ProjectClosedFailure si el proyecto está cerrado (I5)', () async {
      final useCase = CreateSession(
        sessionRepository,
        stakeholderRepository,
        _FakeProjectStatusReader(active: false),
        Clock.fixed(at),
        _FixedIdGenerator('session-1'),
      );

      final result = await useCase(
        projectId,
        SessionDraft(
          title: 'Entrevista',
          scheduledAt: at,
          technique: SessionTechnique.openInterview,
          participantIds: const [StakeholderId('stakeholder-1')],
        ),
      );

      expect(result, isA<Err<SessionId>>());
      expect((result as Err<SessionId>).failure, isA<ProjectClosedFailure>());
      expect(sessionRepository.store, isEmpty);
    });

    test('crea la sesión con participantes del mismo proyecto', () async {
      final useCase = CreateSession(
        sessionRepository,
        stakeholderRepository,
        _FakeProjectStatusReader(),
        Clock.fixed(at),
        _FixedIdGenerator('session-1'),
      );

      final result = await useCase(
        projectId,
        SessionDraft(
          title: 'Entrevista',
          scheduledAt: at,
          technique: SessionTechnique.openInterview,
          participantIds: const [StakeholderId('stakeholder-1')],
        ),
      );

      expect(result, isA<Ok<SessionId>>());
      expect(sessionRepository.store['session-1']!.status, SessionStatus.planned);
      expect(sessionRepository.participants['session-1'], [const StakeholderId('stakeholder-1')]);
    });
  });

  group('UpdateSessionHeader', () {
    test('rechaza con SessionHeaderFrozenFailure al editar la cabecera de una sesión cerrada (I7)', () async {
      sessionRepository.store['session-1'] = ElicitationSession(
        id: const SessionId('session-1'),
        projectId: projectId,
        title: 'Original',
        scheduledAt: at,
        technique: SessionTechnique.openInterview,
        status: SessionStatus.closed,
        createdAt: at,
        updatedAt: at,
        closedAt: at,
      );
      sessionRepository.participants['session-1'] = [const StakeholderId('stakeholder-1')];

      final useCase = UpdateSessionHeader(
        sessionRepository,
        stakeholderRepository,
        _FakeProjectStatusReader(),
        Clock.fixed(at),
      );

      final result = await useCase(
        const SessionId('session-1'),
        SessionDraft(
          title: 'Nuevo título',
          scheduledAt: at,
          technique: SessionTechnique.workshop,
          participantIds: const [StakeholderId('stakeholder-1')],
        ),
      );

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<SessionHeaderFrozenFailure>());
      expect(sessionRepository.store['session-1']!.title, 'Original');
    });

    test('rechaza con ProjectClosedFailure si el proyecto está cerrado (I5)', () async {
      sessionRepository.store['session-1'] = ElicitationSession(
        id: const SessionId('session-1'),
        projectId: projectId,
        title: 'Original',
        scheduledAt: at,
        technique: SessionTechnique.openInterview,
        status: SessionStatus.planned,
        createdAt: at,
        updatedAt: at,
      );

      final useCase = UpdateSessionHeader(
        sessionRepository,
        stakeholderRepository,
        _FakeProjectStatusReader(active: false),
        Clock.fixed(at),
      );

      final result = await useCase(
        const SessionId('session-1'),
        SessionDraft(
          title: 'Nuevo título',
          scheduledAt: at,
          technique: SessionTechnique.workshop,
          participantIds: const [StakeholderId('stakeholder-1')],
        ),
      );

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ProjectClosedFailure>());
    });
  });

  group('UpdateSessionNotes', () {
    test('permite editar notas aunque la sesión esté cerrada (I7)', () async {
      sessionRepository.store['session-1'] = ElicitationSession(
        id: const SessionId('session-1'),
        projectId: projectId,
        title: 'Original',
        scheduledAt: at,
        technique: SessionTechnique.openInterview,
        status: SessionStatus.closed,
        createdAt: at,
        updatedAt: at,
        closedAt: at,
      );

      final useCase = UpdateSessionNotes(sessionRepository, _FakeProjectStatusReader(), Clock.fixed(at));

      final result = await useCase(const SessionId('session-1'), 'Notas nuevas');

      expect(result, isA<Ok<void>>());
      expect(sessionRepository.store['session-1']!.notes, 'Notas nuevas');
    });

    test('rechaza con ProjectClosedFailure si el proyecto está cerrado (I5)', () async {
      sessionRepository.store['session-1'] = ElicitationSession(
        id: const SessionId('session-1'),
        projectId: projectId,
        title: 'Original',
        scheduledAt: at,
        technique: SessionTechnique.openInterview,
        status: SessionStatus.planned,
        createdAt: at,
        updatedAt: at,
      );

      final useCase = UpdateSessionNotes(
        sessionRepository,
        _FakeProjectStatusReader(active: false),
        Clock.fixed(at),
      );

      final result = await useCase(const SessionId('session-1'), 'Notas nuevas');

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ProjectClosedFailure>());
    });
  });

  group('AdvanceSessionStatus', () {
    test('rechaza con ProjectClosedFailure si el proyecto está cerrado (I5)', () async {
      sessionRepository.store['session-1'] = ElicitationSession(
        id: const SessionId('session-1'),
        projectId: projectId,
        title: 'Original',
        scheduledAt: at,
        technique: SessionTechnique.openInterview,
        status: SessionStatus.planned,
        createdAt: at,
        updatedAt: at,
      );

      final useCase = AdvanceSessionStatus(
        sessionRepository,
        _FakeProjectStatusReader(active: false),
        Clock.fixed(at),
      );

      final result = await useCase(const SessionId('session-1'), SessionStatus.inProgress);

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ProjectClosedFailure>());
    });

    test('avanza de planned a inProgress', () async {
      sessionRepository.store['session-1'] = ElicitationSession(
        id: const SessionId('session-1'),
        projectId: projectId,
        title: 'Original',
        scheduledAt: at,
        technique: SessionTechnique.openInterview,
        status: SessionStatus.planned,
        createdAt: at,
        updatedAt: at,
      );

      final useCase = AdvanceSessionStatus(sessionRepository, _FakeProjectStatusReader(), Clock.fixed(at));

      final result = await useCase(const SessionId('session-1'), SessionStatus.inProgress);

      expect(result, isA<Ok<void>>());
      expect(sessionRepository.store['session-1']!.status, SessionStatus.inProgress);
    });
  });

  group('DeleteSession', () {
    test('rechaza con ProjectClosedFailure si el proyecto está cerrado (I5)', () async {
      sessionRepository.store['session-1'] = ElicitationSession(
        id: const SessionId('session-1'),
        projectId: projectId,
        title: 'Original',
        scheduledAt: at,
        technique: SessionTechnique.openInterview,
        status: SessionStatus.planned,
        createdAt: at,
        updatedAt: at,
      );

      final useCase = DeleteSession(sessionRepository, _FakeProjectStatusReader(active: false), Clock.fixed(at));

      final result = await useCase(const SessionId('session-1'));

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ProjectClosedFailure>());
      expect(sessionRepository.store, contains('session-1'));
    });
  });
}
