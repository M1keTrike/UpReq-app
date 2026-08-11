import 'package:up_req/core/domain/ids.dart';

import 'elicitation_session.dart';
import 'session_counters.dart';

/// Sesión, sus participantes y sus contadores en un único agregado
/// (FR-013): un solo stream combinado, para no multiplicar las
/// re-consultas que provoca la invalidación por tabla de drift (decisión 9
/// de research.md). US4 lo amplía con los puntos del guion.
final class SessionDetail {
  const SessionDetail({
    required this.session,
    required this.participantIds,
    required this.counters,
  });

  final ElicitationSession session;
  final List<StakeholderId> participantIds;
  final SessionCounters counters;
}
