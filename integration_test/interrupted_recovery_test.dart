import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/fake_audio_recorder.dart';
import 'support/hardware_fakes.dart';
import 'support/test_app.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await ensureVisible(tester, finder);
  await tester.tap(finder);
}

/// Deja la app en una sesión "en curso" con una grabación activa, lista
/// para que la prueba simule la interrupción sobre [recorder].
Future<void> _startSessionAndRecording(WidgetTester tester, {required String sessionTitle}) async {
  await tester.tap(find.byTooltip('Nueva sesión'));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextField, 'Título'), sessionTitle);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
  await tester.pumpAndSettle();

  await tester.tap(find.text(sessionTitle));
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.widgetWithText(OutlinedButton, 'Pasar a En curso'));
  await tester.pumpAndSettle();

  await _tapVisible(tester, find.byKey(const Key('start-recording-button')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('stop-recording-button')), findsOneWidget);
}

/// T111 — validación V3 del quickstart (FR-010, FR-011): una interrupción
/// —simulada aquí como la pausa que `record` emite ante una llamada
/// entrante, vía `FakeAudioRecorder.emitSystemPause()`— nunca cuesta la
/// entrevista, en las dos ramas de recuperación.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('V3a: reanudar tras una interrupción deja una sola grabación', (tester) async {
    final db = openMemoryDatabase();
    addTearDown(db.close);
    final recorder = FakeAudioRecorder();

    await pumpTestApp(tester, db, overrides: hardwareOverrides(audioRecorder: recorder));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Nuevo proyecto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Proyecto Interrupciones');
    await _tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sesiones'));
    await tester.pumpAndSettle();

    await _startSessionAndRecording(tester, sessionTitle: 'Sesión Reanudable');

    // Interrupción: una pausa que el notifier no pidió.
    recorder.emitSystemPause();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('resume-recording-button')), findsOneWidget);
    expect(find.byKey(const Key('close-interrupted-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('resume-recording-button')));
    await tester.pumpAndSettle();

    // La hoja se cierra y la grabación sigue activa (reanudada).
    expect(find.byKey(const Key('resume-recording-button')), findsNothing);
    expect(find.byKey(const Key('stop-recording-button')), findsOneWidget);

    await _tapVisible(tester, find.byKey(const Key('stop-recording-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Grabación 00:'), findsOneWidget);
  });

  testWidgets('V3a: cerrar conservando lo capturado deja dos grabaciones separadas', (tester) async {
    final db = openMemoryDatabase();
    addTearDown(db.close);
    final recorder = FakeAudioRecorder();

    await pumpTestApp(tester, db, overrides: hardwareOverrides(audioRecorder: recorder));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Nuevo proyecto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Proyecto Interrupciones 2');
    await _tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sesiones'));
    await tester.pumpAndSettle();

    await _startSessionAndRecording(tester, sessionTitle: 'Sesión Cerrable');

    recorder.emitSystemPause();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('close-interrupted-button')));
    await tester.pumpAndSettle();

    // Sin grabación activa; el control de grabar vuelve a ofrecerse.
    expect(find.byKey(const Key('close-interrupted-button')), findsNothing);
    expect(find.byKey(const Key('start-recording-button')), findsOneWidget);
    expect(find.textContaining('Grabación 00:'), findsOneWidget, reason: 'la primera toma quedó conservada');

    // Nueva grabación en la misma sesión (FR-003a).
    await _tapVisible(tester, find.byKey(const Key('start-recording-button')));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.byKey(const Key('stop-recording-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Grabación 00:'), findsNWidgets(2));
  });
}
