import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';

import '../data/session_repository_impl.dart';
import '../domain/entities/elicitation_session.dart';
import '../domain/usecases/watch_sessions.dart';

part 'session_list_provider.g.dart';

final class SessionListState {
  const SessionListState({required this.sessions, this.isReadOnly = false});

  final List<ElicitationSession> sessions;

  /// Deriva de `ProjectStatusReader.isActive` (FR-004a): oculta las acciones
  /// de escritura (crear, eliminar) cuando el proyecto está cerrado. El
  /// valor por defecto `false` mantiene compatibilidad con las pruebas que
  /// construyen el estado directamente sin pasar por el provider.
  final bool isReadOnly;
}

/// Único provider que consume la pantalla de lista de sesiones
/// (ui-contracts.md, pantalla 5).
@riverpod
Stream<SessionListState> sessionList(Ref ref, String projectId) {
  final repository = ref.watch(sessionRepositoryProvider);
  final statusReader = ref.watch(projectStatusReaderProvider);
  return WatchSessions(repository)(ProjectId(projectId)).asyncMap((sessions) async {
    final isActive = await statusReader.isActive(ProjectId(projectId));
    return SessionListState(sessions: sessions, isReadOnly: !isActive);
  });
}
