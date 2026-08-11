import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/test_app.dart';

/// T113 — validación V3 del quickstart (SC-003, FR-004a, FR-004b): con el
/// proyecto cerrado, ninguna acción de escritura está disponible en ninguna
/// pantalla hija (interesados, sesiones, guion, glosario), y reabrirlo
/// restituye la edición.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'V3: cierre lógico oculta toda acción de escritura y la reapertura la restituye',
    (tester) async {
      final db = openMemoryDatabase();
      addTearDown(db.close);

      await pumpTestApp(tester, db);
      await tester.pumpAndSettle();

      // Preparación: un proyecto con un interesado, una sesión con un punto
      // de guion, y un término de glosario, todo mientras el proyecto sigue
      // activo.
      await tester.tap(find.byTooltip('Nuevo proyecto'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Proyecto Cerrable');
      final saveProjectButton = find.widgetWithText(FilledButton, 'Guardar');
      await ensureVisible(tester, saveProjectButton);
      await tester.tap(saveProjectButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Interesados'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Nuevo interesado'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Interesado Uno');
      final saveStakeholderButton = find.widgetWithText(FilledButton, 'Guardar');
      await ensureVisible(tester, saveStakeholderButton);
      await tester.tap(saveStakeholderButton);
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sesiones'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Nueva sesión'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Sesión Uno');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final stakeholderCheckbox = find.widgetWithText(CheckboxListTile, 'Interesado Uno');
      await ensureVisible(tester, stakeholderCheckbox);
      await tester.tap(stakeholderCheckbox);
      await tester.pump();
      // El formulario de sesión (Fecha, Técnica, Lugar, Participantes...) es
      // más largo que una pantalla en un dispositivo real: el botón
      // "Guardar" no llega a montarse hasta hacer scroll hasta él.
      final saveSessionButton = find.widgetWithText(FilledButton, 'Guardar');
      await ensureVisible(tester, saveSessionButton);
      await tester.tap(saveSessionButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sesión Uno'));
      await tester.pumpAndSettle();
      final newPointField = find.widgetWithText(TextField, 'Nuevo punto del guion');
      await ensureVisible(tester, newPointField);
      await tester.enterText(newPointField, 'Punto Uno');
      final addPointButton = find.byTooltip('Agregar punto');
      await ensureVisible(tester, addPointButton);
      await tester.tap(addPointButton);
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Glosario'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Nuevo término'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Término'), 'Término Uno');
      final saveGlossaryButton = find.widgetWithText(FilledButton, 'Guardar');
      await ensureVisible(tester, saveGlossaryButton);
      await tester.tap(saveGlossaryButton);
      await tester.pumpAndSettle();

      // Cerrar el proyecto desde su detalle.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cerrar'));
      await tester.pumpAndSettle();

      // Desaparece de activos.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Proyecto Cerrable'), findsNothing);

      // Aparece bajo el filtro de cerrados, con sus datos intactos.
      await tester.tap(find.text('Cerrados'));
      await tester.pumpAndSettle();
      expect(find.text('Proyecto Cerrable'), findsOneWidget);

      await tester.tap(find.text('Proyecto Cerrable'));
      await tester.pumpAndSettle();

      // El detalle del proyecto ya no ofrece "Editar", solo "Reabrir".
      expect(find.widgetWithText(OutlinedButton, 'Editar'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Reabrir'), findsOneWidget);

      // Interesados: se consulta, pero no hay botón de crear ni de
      // desactivar.
      await tester.tap(find.text('Interesados'));
      await tester.pumpAndSettle();
      expect(find.text('Interesado Uno'), findsOneWidget);
      expect(find.byTooltip('Nuevo interesado'), findsNothing);
      expect(find.byTooltip('Desactivar'), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Sesiones: se consulta, pero no hay botón de crear ni de eliminar.
      await tester.tap(find.text('Sesiones'));
      await tester.pumpAndSettle();
      expect(find.text('Sesión Uno'), findsOneWidget);
      expect(find.byTooltip('Nueva sesión'), findsNothing);
      expect(find.byTooltip('Eliminar'), findsNothing);

      // Guion: se consulta, pero no hay control de estado, ni campo para
      // agregar puntos, ni acciones de marcar/eliminar sobre los existentes.
      await tester.tap(find.text('Sesión Uno'));
      await tester.pumpAndSettle();
      expect(find.text('Punto Uno'), findsOneWidget);
      expect(find.textContaining('Pasar a'), findsNothing);
      expect(find.text('Nuevo punto del guion'), findsNothing);
      expect(find.byTooltip('Marcar'), findsNothing);
      expect(find.byTooltip('Eliminar'), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Glosario: se consulta, pero no hay botón de crear ni de eliminar.
      await tester.tap(find.text('Glosario'));
      await tester.pumpAndSettle();
      expect(find.text('Término Uno'), findsOneWidget);
      expect(find.byTooltip('Nuevo término'), findsNothing);
      expect(find.byTooltip('Eliminar'), findsNothing);

      // La bitácora registra el cierre.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bitácora'));
      await tester.pumpAndSettle();
      expect(find.textContaining('projectClosed'), findsOneWidget);

      // Reabrir el proyecto restituye la edición.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Reabrir'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'Editar'), findsOneWidget);

      await tester.tap(find.text('Interesados'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Nuevo interesado'), findsOneWidget);
      expect(find.byTooltip('Desactivar'), findsOneWidget);
    },
  );
}
