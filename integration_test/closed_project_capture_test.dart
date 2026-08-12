import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/hardware_fakes.dart';
import 'support/test_app.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await ensureVisible(tester, finder);
  await tester.tap(finder);
}

/// T114 — validación V8 del quickstart (fail-closed, aprendizaje del
/// incremento 1 anotado en el roadmap): con el proyecto cerrado, el control
/// de grabar **no aparece en ningún instante**, ni siquiera mientras el
/// provider todavía está cargando.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('V8: proyecto cerrado, el control de grabar no aparece ni durante la carga', (tester) async {
    final db = openMemoryDatabase();
    addTearDown(db.close);

    await pumpTestApp(tester, db, overrides: hardwareOverrides());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Nuevo proyecto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Proyecto Cerrado Captura');
    await _tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sesiones'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Nueva sesión'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Sesión En Proyecto Cerrado');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    // Cerrar el proyecto desde su detalle.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.widgetWithText(OutlinedButton, 'Cerrar'));
    await tester.pumpAndSettle();

    // Entrar a la sesión del proyecto ya cerrado: el fallback fail-closed
    // (`state.value?.canRecord ?? false`) exige que el control esté ausente
    // desde el primer frame, no solo tras asentarse.
    await tester.tap(find.text('Sesiones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sesión En Proyecto Cerrado'));
    await tester.pump();
    expect(find.byKey(const Key('start-recording-button')), findsNothing, reason: 'primer frame, aún cargando');

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('start-recording-button')), findsNothing, reason: 'ya asentado');
  });
}
