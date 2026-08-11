import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/test_app.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await ensureVisible(tester, finder);
  await tester.tap(finder);
}

/// T114 — validación V6 del quickstart (FR-018): con dos proyectos
/// poblados, ningún listado cruza datos entre ellos.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('V6: aislamiento entre proyectos, ningún listado cruza datos', (tester) async {
    final db = openMemoryDatabase();
    addTearDown(db.close);

    await pumpTestApp(tester, db);
    await tester.pumpAndSettle();

    // Crear el primer proyecto con su propio interesado.
    await tester.tap(find.byTooltip('Nuevo proyecto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Proyecto A');
    await _tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Interesados'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Nuevo interesado'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Interesado A');
    await _tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    // Crear el segundo proyecto con sus propios interesados.
    await tester.pageBack(); // vuelve al detalle de Proyecto A
    await tester.pumpAndSettle();
    await tester.pageBack(); // vuelve a la lista de proyectos
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Nuevo proyecto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Proyecto B');
    await _tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Interesados'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Nuevo interesado'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Interesado B');
    await _tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    // La lista de interesados de Proyecto B no muestra el interesado de A.
    expect(find.text('Interesado B'), findsOneWidget);
    expect(find.text('Interesado A'), findsNothing);

    // Crear una sesión en el segundo proyecto: el selector de participantes
    // solo ofrece los interesados de ese proyecto.
    await tester.pageBack(); // vuelve al detalle de Proyecto B
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sesiones'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Nueva sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Interesado B'), findsOneWidget);
    expect(find.text('Interesado A'), findsNothing);
    await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Sesión B');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.widgetWithText(CheckboxListTile, 'Interesado B'));
    await tester.pump();
    // El formulario de sesión es más largo que una pantalla en un
    // dispositivo real: el botón "Guardar" no llega a montarse hasta hacer
    // scroll hasta él.
    await _tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    // La lista de sesiones de Proyecto B no muestra sesiones de A (no hay
    // ninguna, pero además comprobamos que la sesión de B sí aparece).
    expect(find.text('Sesión B'), findsOneWidget);

    // Volver a la lista de proyectos y entrar de nuevo a Proyecto A: su
    // lista de interesados no muestra al interesado de B, y su lista de
    // sesiones no muestra la sesión de B.
    await tester.pageBack(); // vuelve al detalle de Proyecto B
    await tester.pumpAndSettle();
    await tester.pageBack(); // vuelve a la lista de proyectos
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proyecto A'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Interesados'));
    await tester.pumpAndSettle();
    expect(find.text('Interesado A'), findsOneWidget);
    expect(find.text('Interesado B'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sesiones'));
    await tester.pumpAndSettle();
    expect(find.text('Sesión B'), findsNothing);
    expect(find.textContaining('Todavía no hay sesiones'), findsOneWidget);
  });
}
