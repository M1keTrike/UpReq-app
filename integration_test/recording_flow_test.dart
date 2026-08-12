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

/// T110 — validaciones V1 y V2 del quickstart (FR-001 a FR-009a): grabar
/// una entrevista, marcar en vivo, detener y reproducir, recorriendo la app
/// real de punta a punta. El micrófono, el escritor WAV y el reproductor son
/// dobles (`hardwareOverrides`); todo lo demás —base de datos, providers,
/// pantallas— es real.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('V1+V2: grabar, marcar, detener y reproducir', (tester) async {
    final db = openMemoryDatabase();
    addTearDown(db.close);
    final recorder = FakeAudioRecorder();

    await pumpTestApp(tester, db, overrides: hardwareOverrides(audioRecorder: recorder));
    await tester.pumpAndSettle();

    // Proyecto y sesión, llevada a "en curso": el control de grabar exige
    // proyecto activo y sesión en curso (FR-003).
    await tester.tap(find.byTooltip('Nuevo proyecto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Proyecto Entrevistas');
    await _tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sesiones'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Nueva sesión'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Entrevista Uno');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    // TODO(device-run 2026-08-12): en dispositivo real (Android 16, API 36),
    // esta línea falla con `StateError: Bad state: No element` dentro de
    // `scrollUntilVisible` — `find.widgetWithText(FilledButton, 'Guardar')`
    // no encuentra NINGÚN elemento en el formulario de "Nueva sesión" (no es
    // ambigüedad, es ausencia total). Descartado ya: `isReadOnly` no es la
    // causa — `CreateProject` fija `status: ProjectStatus.active` por
    // defecto y `ProjectStatusReaderImpl.isActive` lo lee bien, así que
    // `fieldsEnabled` en `session_form_screen.dart` debería ser `true` y el
    // botón debería renderizar. Pendiente de investigar en la próxima
    // sesión, con el dispositivo conectado para poder inspeccionar en vivo:
    //   1. Confirmar con el árbol de widgets real (`flutter inspector` o un
    //      `debugDumpApp()` insertado aquí) si el botón existe pero está
    //      fuera del área que `ensureVisible` puede alcanzar, o si
    //      simplemente no se construye.
    //   2. Revisar si `selectableStakeholdersProvider` (el spinner bajo
    //      "Participantes" en session_form_screen.dart) se queda en
    //      `AsyncLoading` para siempre en este escenario concreto —
    //      indeterminado, animaría sin fin y podría estar enmascarando el
    //      verdadero estado del formulario.
    //   3. Probar el mismo flujo a mano en el dispositivo (crear proyecto,
    //      sesión) para ver si el bug es real en la app o es un problema del
    //      arnés de prueba (temporización, finder equivocado, etc.).
    // Bloquea T110 (y por herencia cualquier integration_test que cree una
    // sesión) hasta resolverse.
    await _tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrevista Uno'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('start-recording-button')), findsNothing, reason: 'sesión aún planeada');

    await _tapVisible(tester, find.widgetWithText(OutlinedButton, 'Pasar a En curso'));
    await tester.pumpAndSettle();

    // Iniciar la grabación.
    await _tapVisible(tester, find.byKey(const Key('start-recording-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stop-recording-button')), findsOneWidget);

    // Marcar en vivo: los tres controles no interrumpen la captura.
    await tester.tap(find.byKey(const Key('mark-button-doubt')));
    await tester.pump();
    recorder.emitFrame(Uint8List.fromList([1, 2, 3, 4]));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stop-recording-button')), findsOneWidget, reason: 'marcar no interrumpe');

    // Detener.
    await _tapVisible(tester, find.byKey(const Key('stop-recording-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('start-recording-button')), findsOneWidget);
    expect(find.textContaining('Detenida'), findsOneWidget);

    // Entrar al detalle de la grabación: la marca colocada aparece, y el
    // reproductor funciona (FR-017), aunque no haya transcripción.
    await _tapVisible(tester, find.textContaining('Grabación 00:'));
    await tester.pumpAndSettle();

    expect(find.text('Duda'), findsOneWidget);
    expect(find.byKey(const Key('playback-toggle-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('playback-toggle-button')));
    await tester.pump();
    expect(find.byIcon(Icons.pause), findsOneWidget);
  });
}
