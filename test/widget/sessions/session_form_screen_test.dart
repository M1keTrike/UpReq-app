import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/features/sessions/data/session_repository_impl.dart';
import 'package:up_req/features/sessions/domain/entities/elicitation_session.dart';
import 'package:up_req/features/sessions/domain/entities/session_counters.dart';
import 'package:up_req/features/sessions/domain/entities/session_detail.dart';
import 'package:up_req/features/sessions/domain/session_repository.dart';
import 'package:up_req/features/sessions/presentation/session_form_screen.dart';
import 'package:up_req/features/stakeholders/data/stakeholder_repository_impl.dart';
import 'package:up_req/features/stakeholders/domain/entities/stakeholder.dart';
import 'package:up_req/features/stakeholders/domain/stakeholder_repository.dart';

/// El provider de formulario resuelve `projectStatusReaderProvider` al
/// construirse (FR-004a); sin este doble lanzaría `UnimplementedError`
/// (core/domain/project_status_reader.dart) antes de llegar a renderizar.
class _FakeProjectStatusReader implements ProjectStatusReader {
  @override
  Future<bool> isActive(ProjectId id) async => true;
}

class _FakeStakeholderRepository implements StakeholderRepository {
  List<Stakeholder> selectable = [];
  List<Stakeholder> all = [];

  @override
  Stream<List<Stakeholder>> watchByProject(ProjectId id) => Stream.value(all);

  @override
  Stream<List<Stakeholder>> watchSelectableByProject(ProjectId id) => Stream.value(selectable);

  @override
  Future<Stakeholder?> findById(StakeholderId id) async {
    for (final stakeholder in [...all, ...selectable]) {
      if (stakeholder.id == id) return stakeholder;
    }
    return null;
  }

  @override
  Future<void> insert(Stakeholder stakeholder) => throw UnimplementedError();

  @override
  Future<void> update(Stakeholder stakeholder) => throw UnimplementedError();

  @override
  Future<void> deactivate(StakeholderId id, DateTime at) => throw UnimplementedError();
}

class _FakeSessionRepository implements SessionRepository {
  ElicitationSession? session;
  List<StakeholderId> participantIds = [];

  @override
  Stream<SessionDetail?> watchDetail(SessionId id) {
    final current = session;
    if (current == null) return Stream.value(null);
    return Stream.value(
      SessionDetail(
        session: current,
        participantIds: participantIds,
        counters: const SessionCounters(pending: 0, covered: 0, skipped: 0),
      ),
    );
  }

  @override
  Future<ElicitationSession?> findById(SessionId id) async => session;

  @override
  Stream<List<ElicitationSession>> watchByProject(ProjectId id) => throw UnimplementedError();

  @override
  Future<void> insert(ElicitationSession s, List<StakeholderId> participantIds) => throw UnimplementedError();

  @override
  Future<void> updateHeader(ElicitationSession s, List<StakeholderId> participantIds) =>
      throw UnimplementedError();

  @override
  Future<void> updateNotes(SessionId id, String? notes, DateTime at) => throw UnimplementedError();

  @override
  Future<void> setStatus(SessionId id, SessionStatus status, DateTime at) => throw UnimplementedError();

  @override
  Future<void> softDelete(SessionId id, DateTime at) => throw UnimplementedError();
}

void main() {
  testWidgets('el selector de participantes no ofrece inactivos ni de otro proyecto', (tester) async {
    final at = DateTime.utc(2026, 1, 1);
    final stakeholderRepository = _FakeStakeholderRepository()
      ..selectable = [
        Stakeholder(
          id: const StakeholderId('s1'),
          projectId: const ProjectId('p1'),
          name: 'Activo del proyecto',
          influence: InfluenceLevel.medium,
          status: StakeholderStatus.active,
          createdAt: at,
          updatedAt: at,
        ),
      ]
      ..all = [
        Stakeholder(
          id: const StakeholderId('s1'),
          projectId: const ProjectId('p1'),
          name: 'Activo del proyecto',
          influence: InfluenceLevel.medium,
          status: StakeholderStatus.active,
          createdAt: at,
          updatedAt: at,
        ),
        Stakeholder(
          id: const StakeholderId('s2'),
          projectId: const ProjectId('p1'),
          name: 'Inactivo del proyecto',
          influence: InfluenceLevel.medium,
          status: StakeholderStatus.inactive,
          createdAt: at,
          updatedAt: at,
        ),
        Stakeholder(
          id: const StakeholderId('s3'),
          projectId: const ProjectId('p2'),
          name: 'Activo de otro proyecto',
          influence: InfluenceLevel.medium,
          status: StakeholderStatus.active,
          createdAt: at,
          updatedAt: at,
        ),
      ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stakeholderRepositoryProvider.overrideWithValue(stakeholderRepository),
          sessionRepositoryProvider.overrideWithValue(_FakeSessionRepository()),
          projectStatusReaderProvider.overrideWithValue(_FakeProjectStatusReader()),
        ],
        child: const MaterialApp(
          home: SessionFormScreen(projectId: 'p1', sessionId: null),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Activo del proyecto'), findsOneWidget);
    expect(find.text('Inactivo del proyecto'), findsNothing);
    expect(find.text('Activo de otro proyecto'), findsNothing);
  });

  testWidgets('la cabecera se renderiza deshabilitada con la sesión cerrada', (tester) async {
    final at = DateTime.utc(2026, 1, 1);
    final sessionRepository = _FakeSessionRepository()
      ..session = ElicitationSession(
        id: const SessionId('session-1'),
        projectId: const ProjectId('p1'),
        title: 'Sesión cerrada',
        scheduledAt: at,
        technique: SessionTechnique.workshop,
        status: SessionStatus.closed,
        createdAt: at,
        updatedAt: at,
        closedAt: at,
      )
      ..participantIds = [const StakeholderId('s1')];
    final stakeholderRepository = _FakeStakeholderRepository()
      ..selectable = [
        Stakeholder(
          id: const StakeholderId('s1'),
          projectId: const ProjectId('p1'),
          name: 'Ana',
          influence: InfluenceLevel.medium,
          status: StakeholderStatus.active,
          createdAt: at,
          updatedAt: at,
        ),
      ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stakeholderRepositoryProvider.overrideWithValue(stakeholderRepository),
          sessionRepositoryProvider.overrideWithValue(sessionRepository),
          projectStatusReaderProvider.overrideWithValue(_FakeProjectStatusReader()),
        ],
        child: const MaterialApp(
          home: SessionFormScreen(projectId: 'p1', sessionId: 'session-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final titleField = tester.widget<TextField>(find.widgetWithText(TextField, 'Sesión cerrada'));
    expect(titleField.enabled, isFalse);
  });
}
