import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/recordings/domain/entities/recording.dart';
import 'package:up_req/features/recordings/presentation/active_capture_notifier.dart';
import 'package:up_req/features/recordings/presentation/session_capture_provider.dart';
import 'package:up_req/features/recordings/presentation/session_capture_section.dart';

final _at = DateTime.utc(2026, 1, 1);

Future<void> _pump(WidgetTester tester, Override override) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [override],
      child: const MaterialApp(
        home: Scaffold(body: SessionCaptureSection(sessionId: 'session-1')),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'mientras el provider carga, el control de grabar no aparece (fallback fail-closed)',
    (tester) async {
      await _pump(
        tester,
        sessionCaptureProvider('session-1').overrideWith(
          (ref) => const Stream<SessionCaptureState>.empty(),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('start-recording-button')), findsNothing);
    },
  );

  testWidgets('con proyecto cerrado o sesión planeada (canRecord=false), no aparece el control', (
    tester,
  ) async {
    await _pump(
      tester,
      sessionCaptureProvider('session-1').overrideWith(
        (ref) => Stream.value(
          const SessionCaptureState(recordings: [], active: null, canRecord: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('start-recording-button')), findsNothing);
  });

  testWidgets('con sesión en curso y proyecto activo, el control de grabar aparece', (
    tester,
  ) async {
    await _pump(
      tester,
      sessionCaptureProvider('session-1').overrideWith(
        (ref) => Stream.value(
          const SessionCaptureState(recordings: [], active: null, canRecord: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('start-recording-button')), findsOneWidget);
  });

  testWidgets('con una grabación activa, muestra el tiempo transcurrido y el botón de detener', (
    tester,
  ) async {
    await _pump(
      tester,
      sessionCaptureProvider('session-1').overrideWith(
        (ref) => Stream.value(
          SessionCaptureState(
            recordings: const [],
            active: const ActiveCapture(
              id: RecordingId('recording-1'),
              elapsed: Duration(seconds: 65),
              marksPlaced: 0,
              isInterrupted: false,
            ),
            canRecord: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('start-recording-button')), findsNothing);
    expect(find.byKey(const Key('stop-recording-button')), findsOneWidget);
    expect(find.textContaining('01:05'), findsOneWidget);
  });

  testWidgets('con error, no muestra el control de grabar', (tester) async {
    await _pump(
      tester,
      sessionCaptureProvider('session-1').overrideWith(
        (ref) => Stream<SessionCaptureState>.error(Exception('boom')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('start-recording-button')), findsNothing);
  });

  testWidgets('lista las grabaciones existentes con su duración', (tester) async {
    await _pump(
      tester,
      sessionCaptureProvider('session-1').overrideWith(
        (ref) => Stream.value(
          SessionCaptureState(
            recordings: [
              Recording(
                id: const RecordingId('recording-1'),
                sessionId: const SessionId('session-1'),
                projectId: const ProjectId('project-1'),
                filePath: 'recordings/recording-1.wav',
                status: RecordingStatus.stopped,
                durationMs: 65000,
                sampleRate: 16000,
                channels: 1,
                startedAt: _at,
                stoppedAt: _at,
                createdAt: _at,
                updatedAt: _at,
              ),
            ],
            active: null,
            canRecord: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('01:05'), findsOneWidget);
    expect(find.text('Detenida'), findsOneWidget);
  });
}
