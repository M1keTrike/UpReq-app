import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/domain/result.dart';

import '../domain/entities/elicitation_session.dart';
import '../domain/session_transition.dart';
import 'session_mutations.dart';

/// Ofrece **solo** las transiciones válidas desde el estado actual,
/// derivadas de `transitionSession` (FR-008a): un retroceso nunca se
/// renderiza porque nunca aparece entre las opciones válidas.
class SessionStatusControl extends ConsumerWidget {
  const SessionStatusControl({required this.sessionId, required this.status, super.key});

  final SessionId sessionId;
  final SessionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextOptions = _validNextStatuses(status);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Chip(label: Text('Estado: ${_label(status)}')),
        for (final next in nextOptions)
          OutlinedButton(
            onPressed: () => runAdvanceSessionStatus(ref, sessionId, next),
            child: Text('Pasar a ${_label(next)}'),
          ),
      ],
    );
  }

  static List<SessionStatus> _validNextStatuses(SessionStatus from) {
    return SessionStatus.values
        .where((to) => transitionSession(from, to) is Ok<SessionStatus>)
        .toList();
  }

  static String _label(SessionStatus status) => switch (status) {
        SessionStatus.planned => 'Planeada',
        SessionStatus.inProgress => 'En curso',
        SessionStatus.closed => 'Cerrada',
      };
}
