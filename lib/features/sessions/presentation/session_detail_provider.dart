import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/core/domain/combine_latest.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/project_status_reader.dart';

import '../data/script_point_repository_impl.dart';
import '../data/session_repository_impl.dart';
import '../domain/entities/elicitation_session.dart';
import '../domain/entities/script_point.dart';
import '../domain/entities/session_counters.dart';
import '../domain/usecases/watch_session_detail.dart';

part 'session_detail_provider.g.dart';

/// Sesión, participantes, guion y contadores en un **único** agregado
/// (ui-contracts.md, pantalla 6): un solo stream combinado, para no
/// multiplicar las re-consultas que provoca la invalidación por tabla de
/// drift (decisión 9 de research.md).
final class SessionDetailState {
  const SessionDetailState({
    required this.session,
    required this.participantIds,
    required this.points,
    required this.counters,
    required this.isReadOnly,
  });

  final ElicitationSession session;
  final List<StakeholderId> participantIds;
  final List<ScriptPoint> points;
  final SessionCounters counters;

  /// Deriva de `ProjectStatusReader.isActive` (FR-004a): el proyecto está
  /// cerrado. Distinto de `isHeaderFrozen`, que es propio de la sesión.
  final bool isReadOnly;

  /// Cabecera congelada con la sesión cerrada (FR-008b, invariante I7); las
  /// notas y el guion siguen siendo editables.
  bool get isHeaderFrozen => session.status == SessionStatus.closed;
}

/// `sessionDetailProvider(sessionId)` de ui-contracts.md, pantalla 6.
@riverpod
Stream<SessionDetailState> sessionDetail(Ref ref, String sessionId) {
  final sessionRepository = ref.watch(sessionRepositoryProvider);
  final scriptPointRepository = ref.watch(scriptPointRepositoryProvider);
  final statusReader = ref.watch(projectStatusReaderProvider);

  final detailStream = WatchSessionDetail(sessionRepository)(SessionId(sessionId));
  final pointsStream = scriptPointRepository.watchBySession(SessionId(sessionId));

  return combineLatest2(detailStream, pointsStream, (detail, points) => (detail, points))
      .asyncMap((pair) async {
    final (detail, points) = pair;
    final isActive = await statusReader.isActive(detail.session.projectId);
    return SessionDetailState(
      session: detail.session,
      participantIds: detail.participantIds,
      points: points,
      counters: detail.counters,
      isReadOnly: !isActive,
    );
  });
}
