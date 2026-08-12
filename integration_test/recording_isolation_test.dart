import 'dart:typed_data';

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

/// Crea un interesado, requerido por `SessionDraft.validate()`
/// (data-model.md): una sesión no se puede guardar sin al menos un
/// participante. Deja al usuario en la pestaña "Sesiones" al terminar.
Future<void> _createStakeholder(WidgetTester tester, String name) async {
  await tester.tap(find.text('Interesados'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Nuevo interesado'));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextField, 'Nombre'), name);
  await _tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sesiones'));
  await tester.pumpAndSettle();
}

/// Crea un proyecto, una sesión llevada a "en curso" y una grabación
/// detenida, y deja al usuario en la lista de proyectos.
Future<void> _createProjectWithRecording(
  WidgetTester tester,
  FakeAudioRecorder recorder, {
  required String projectName,
  required String sessionTitle,
}) async {
  await tester.tap(find.byTooltip('Nuevo proyecto'));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextField, 'Nombre'), projectName);
  await _tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
  await tester.pumpAndSettle();

  await _createStakeholder(tester, 'Entrevistado $sessionTitle');

  await tester.tap(find.byTooltip('Nueva sesión'));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextField, 'Título'), sessionTitle);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.widgetWithText(CheckboxListTile, 'Entrevistado $sessionTitle'));
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
  await tester.pumpAndSettle();

  await tester.tap(find.text(sessionTitle));
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.widgetWithText(OutlinedButton, 'Pasar a En curso'));
  await tester.pumpAndSettle();

  await _tapVisible(tester, find.byKey(const Key('start-recording-button')));
  await tester.pumpAndSettle();
  recorder.emitFrame(Uint8List.fromList([1, 2, 3, 4]));
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.byKey(const Key('stop-recording-button')));
  await tester.pumpAndSettle();

  // Vuelve a la sesión -> proyecto -> lista de proyectos.
  await tester.pageBack();
  await tester.pumpAndSettle();
  await tester.pageBack();
  await tester.pumpAndSettle();
  await tester.pageBack();
  await tester.pumpAndSettle();
}

/// T113 — validación V7 del quickstart (invariante de aislamiento por
/// proyecto): con dos proyectos poblados, ningún listado de grabaciones
/// cruza datos.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('V7: el listado de grabaciones no cruza datos entre proyectos', (tester) async {
    final db = openMemoryDatabase();
    addTearDown(db.close);
    final recorder = FakeAudioRecorder();

    await pumpTestApp(tester, db, overrides: hardwareOverrides(audioRecorder: recorder));
    await tester.pumpAndSettle();

    await _createProjectWithRecording(
      tester,
      recorder,
      projectName: 'Proyecto Aislado A',
      sessionTitle: 'Sesión A',
    );
    await _createProjectWithRecording(
      tester,
      recorder,
      projectName: 'Proyecto Aislado B',
      sessionTitle: 'Sesión B',
    );

    // Proyecto B: su sesión muestra exactamente una grabación.
    await tester.tap(find.text('Proyecto Aislado B'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sesiones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sesión B'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Grabación 00:'), findsOneWidget);

    // Proyecto A: su propia sesión también muestra exactamente una, la
    // suya — no dos por haber cruzado con la de B.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proyecto Aislado A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sesiones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sesión A'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Grabación 00:'), findsOneWidget);
    expect(find.text('Sesión B'), findsNothing);
  });
}
