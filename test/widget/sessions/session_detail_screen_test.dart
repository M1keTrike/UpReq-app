import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/sessions/domain/entities/elicitation_session.dart';
import 'package:up_req/features/sessions/domain/entities/script_point.dart';
import 'package:up_req/features/sessions/domain/entities/session_counters.dart';
import 'package:up_req/features/sessions/presentation/session_detail_provider.dart';
import 'package:up_req/features/sessions/presentation/session_detail_screen.dart';

final _at = DateTime.utc(2026, 1, 1);

final _session = ElicitationSession(
  id: const SessionId('session-1'),
  projectId: const ProjectId('p1'),
  title: 'Entrevista con Ana',
  scheduledAt: _at,
  technique: SessionTechnique.openInterview,
  status: SessionStatus.planned,
  createdAt: _at,
  updatedAt: _at,
);

SessionDetailState _state({List<ScriptPoint> points = const [], bool isReadOnly = false}) {
  return SessionDetailState(
    session: _session,
    participantIds: const [StakeholderId('stakeholder-1')],
    points: points,
    counters: SessionCounters(
      pending: points.where((p) => p.status == ScriptPointStatus.pending).length,
      covered: points.where((p) => p.status == ScriptPointStatus.covered).length,
      skipped: points.where((p) => p.status == ScriptPointStatus.skipped).length,
    ),
    isReadOnly: isReadOnly,
  );
}

Future<void> _pump(WidgetTester tester, Override override) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [override],
      child: const MaterialApp(home: SessionDetailScreen(projectId: 'p1', sessionId: 'session-1')),
    ),
  );
}

void main() {
  testWidgets('cargando: muestra el indicador de progreso', (tester) async {
    await _pump(
      tester,
      sessionDetailProvider('session-1').overrideWith((ref) => const Stream<SessionDetailState>.empty()),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('con datos: muestra la sesión y los puntos del guion', (tester) async {
    await _pump(
      tester,
      sessionDetailProvider('session-1').overrideWith(
        (ref) => Stream.value(
          _state(
            points: [
              ScriptPoint(
                id: const ScriptPointId('sp0'),
                sessionId: const SessionId('session-1'),
                projectId: const ProjectId('p1'),
                text: '¿Cuál es el objetivo del proyecto?',
                status: ScriptPointStatus.pending,
                position: 0,
                createdAt: _at,
                updatedAt: _at,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Entrevista con Ana'), findsOneWidget);
    expect(find.text('¿Cuál es el objetivo del proyecto?'), findsOneWidget);
  });

  testWidgets('guion vacío: invita a agregar el primer punto', (tester) async {
    await _pump(
      tester,
      sessionDetailProvider('session-1').overrideWith((ref) => Stream.value(_state())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Entrevista con Ana'), findsOneWidget);
    expect(find.textContaining('Todavía no hay puntos en el guion'), findsOneWidget);
  });

  testWidgets('con error: muestra un mensaje de error', (tester) async {
    await _pump(
      tester,
      sessionDetailProvider('session-1').overrideWith((ref) => Stream<SessionDetailState>.error(Exception('boom'))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Ha ocurrido un error'), findsOneWidget);
  });

  testWidgets('con el proyecto cerrado: oculta el campo de agregar punto', (tester) async {
    await _pump(
      tester,
      sessionDetailProvider('session-1').overrideWith(
        (ref) => Stream.value(_state(isReadOnly: true)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Nuevo punto del guion'), findsNothing);
  });
}
