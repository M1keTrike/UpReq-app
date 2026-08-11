import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/features/sessions/data/session_repository_impl.dart';
import 'package:up_req/features/sessions/domain/entities/elicitation_session.dart';
import 'package:up_req/features/sessions/domain/entities/session_detail.dart';
import 'package:up_req/features/sessions/domain/session_repository.dart';
import 'package:up_req/features/sessions/presentation/session_list_provider.dart';

import '../../support/test_container.dart';

/// El provider consulta `projectStatusReaderProvider` para derivar
/// `isReadOnly` (FR-004a); sin este doble lanzaría `UnimplementedError`.
class _FakeProjectStatusReader implements ProjectStatusReader {
  @override
  Future<bool> isActive(ProjectId id) async => true;
}

class _FakeSessionRepository implements SessionRepository {
  List<ElicitationSession> sessions = [];

  @override
  Stream<List<ElicitationSession>> watchByProject(ProjectId id) => Stream.value(sessions);

  @override
  Stream<SessionDetail?> watchDetail(SessionId id) => throw UnimplementedError();

  @override
  Future<ElicitationSession?> findById(SessionId id) => throw UnimplementedError();

  @override
  Future<void> insert(ElicitationSession session, List<StakeholderId> participantIds) =>
      throw UnimplementedError();

  @override
  Future<void> updateHeader(ElicitationSession session, List<StakeholderId> participantIds) =>
      throw UnimplementedError();

  @override
  Future<void> updateNotes(SessionId id, String? notes, DateTime at) => throw UnimplementedError();

  @override
  Future<void> setStatus(SessionId id, SessionStatus status, DateTime at) => throw UnimplementedError();

  @override
  Future<void> softDelete(SessionId id, DateTime at) => throw UnimplementedError();
}

void main() {
  test('expone las sesiones del proyecto a través de un único provider', () async {
    final at = DateTime.utc(2026, 1, 1);
    final repository = _FakeSessionRepository()
      ..sessions = [
        ElicitationSession(
          id: const SessionId('session-1'),
          projectId: const ProjectId('p1'),
          title: 'Entrevista',
          scheduledAt: at,
          technique: SessionTechnique.openInterview,
          status: SessionStatus.planned,
          createdAt: at,
          updatedAt: at,
        ),
      ];

    final container = buildTestContainer(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(repository),
        projectStatusReaderProvider.overrideWithValue(_FakeProjectStatusReader()),
      ],
    );
    container.listen(sessionListProvider('p1'), (_, _) {});

    final state = await container.read(sessionListProvider('p1').future);

    expect(state.sessions.map((s) => s.title), ['Entrevista']);
    expect(state.isReadOnly, isFalse);
  });
}
