import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/sessions/domain/entities/elicitation_session.dart';
import 'package:up_req/features/sessions/presentation/session_list_provider.dart';
import 'package:up_req/features/sessions/presentation/session_list_screen.dart';

Future<void> _pump(WidgetTester tester, Override override) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [override],
      child: const MaterialApp(home: SessionListScreen(projectId: 'p1')),
    ),
  );
}

void main() {
  testWidgets('cargando: muestra el indicador de progreso', (tester) async {
    await _pump(
      tester,
      sessionListProvider('p1').overrideWith((ref) => const Stream<SessionListState>.empty()),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('con datos: muestra las sesiones', (tester) async {
    final at = DateTime.utc(2026, 1, 1);
    await _pump(
      tester,
      sessionListProvider('p1').overrideWith(
        (ref) => Stream.value(
          SessionListState(
            sessions: [
              ElicitationSession(
                id: const SessionId('session-1'),
                projectId: const ProjectId('p1'),
                title: 'Entrevista uno',
                scheduledAt: at,
                technique: SessionTechnique.openInterview,
                status: SessionStatus.planned,
                createdAt: at,
                updatedAt: at,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Entrevista uno'), findsOneWidget);
  });

  testWidgets('vacía: invita a crear la primera sesión', (tester) async {
    await _pump(
      tester,
      sessionListProvider('p1').overrideWith((ref) => Stream.value(const SessionListState(sessions: []))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Crea la primera'), findsOneWidget);
  });

  testWidgets('con error: muestra un mensaje de error', (tester) async {
    await _pump(
      tester,
      sessionListProvider('p1').overrideWith((ref) => Stream<SessionListState>.error(Exception('boom'))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Ha ocurrido un error'), findsOneWidget);
  });
}
