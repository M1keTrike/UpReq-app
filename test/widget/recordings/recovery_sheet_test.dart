import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/recordings/domain/entities/recording.dart';
import 'package:up_req/features/recordings/presentation/recovery_sheet.dart';

final _at = DateTime.utc(2026, 1, 1);

final _interrupted = Recording(
  id: const RecordingId('recording-1'),
  sessionId: const SessionId('session-1'),
  projectId: const ProjectId('project-1'),
  filePath: 'recordings/recording-1.wav',
  status: RecordingStatus.interrupted,
  durationMs: 20000,
  sampleRate: 16000,
  channels: 1,
  startedAt: _at,
  createdAt: _at,
  updatedAt: _at,
);

class _OpenSheetButton extends ConsumerWidget {
  const _OpenSheetButton({required this.canResume});

  final bool canResume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => showRecoverySheet(context, ref, interrupted: _interrupted, canResume: canResume),
      child: const Text('abrir'),
    );
  }
}

Future<void> _pumpAndOpen(WidgetTester tester, {required bool canResume}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: Scaffold(body: _OpenSheetButton(canResume: canResume))),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no se puede descartar tocando fuera ni con el botón atrás', (tester) async {
    await _pumpAndOpen(tester, canResume: true);

    expect(find.text('Grabación interrumpida'), findsOneWidget);

    // Tocar fuera de la hoja (barrier) no debe cerrarla: isDismissible=false.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Grabación interrumpida'), findsOneWidget);

    // El botón atrás del sistema tampoco: PopScope(canPop: false).
    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Grabación interrumpida'), findsOneWidget);
  });

  testWidgets('resumeRecording no se ofrece si la sesión ya se cerró (canResume=false)', (
    tester,
  ) async {
    await _pumpAndOpen(tester, canResume: false);

    expect(find.byKey(const Key('resume-recording-button')), findsNothing);
    expect(find.byKey(const Key('close-interrupted-button')), findsOneWidget);
  });

  testWidgets('con la sesión en curso, ofrece las dos acciones explícitas', (tester) async {
    await _pumpAndOpen(tester, canResume: true);

    expect(find.byKey(const Key('resume-recording-button')), findsOneWidget);
    expect(find.byKey(const Key('close-interrupted-button')), findsOneWidget);
  });
}
