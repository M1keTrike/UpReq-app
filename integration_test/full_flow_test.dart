import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:up_req/features/sessions/domain/entities/script_point.dart';

import 'support/test_app.dart';

/// T111 — validación V1 del quickstart (SC-001): proyecto, tres interesados,
/// sesión con dos participantes, guion de cinco puntos, reordenar dos y
/// marcar dos como cubiertos, recorriendo la app real de punta a punta tal
/// como la usaría una persona (sin dobles de ningún repositorio).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('V1: flujo completo de punta a punta (SC-001)', (tester) async {
    final db = openMemoryDatabase();
    addTearDown(db.close);

    await pumpTestApp(tester, db);
    await tester.pumpAndSettle();

    // 1. Lista vacía: invita a crear el primer proyecto (FR-020), no un
    // mensaje de ausencia.
    expect(find.textContaining('Crea el primero'), findsOneWidget);

    // 2. Crear un proyecto con nombre y cliente.
    await tester.tap(find.byTooltip('Nuevo proyecto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Proyecto Uno');
    await tester.enterText(find.widgetWithText(TextField, 'Cliente'), 'Cliente X');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    // Aterriza en el detalle del proyecto recién creado.
    expect(find.text('Proyecto Uno'), findsWidgets);

    // 3. Agregar tres interesados con distintos niveles de influencia.
    await tester.tap(find.text('Interesados'));
    await tester.pumpAndSettle();

    await _addStakeholder(tester, name: 'Ana', influenceLabel: 'Alta');
    await _addStakeholder(tester, name: 'Beto'); // medio, por defecto
    await _addStakeholder(tester, name: 'Carla', influenceLabel: 'Baja');

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Beto'), findsOneWidget);
    expect(find.text('Carla'), findsOneWidget);

    // El detalle del proyecto muestra el contador de interesados en 3.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Interesados'),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );

    // 4. Crear una sesión que referencie a dos de ellos. El selector solo
    // ofrece interesados de este proyecto (verificado a nivel de widget en
    // session_form_screen_test.dart); aquí solo comprobamos que Ana y Beto
    // están disponibles y que guardar sin participantes no es necesario
    // ejercitarlo de nuevo aquí.
    await tester.tap(find.text('Sesiones'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Nueva sesión'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Entrevista inicial');
    // Cierra el teclado nativo: con él abierto la ventana visible se reduce
    // (`adjustResize`) y agrava el problema de abajo.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final anaCheckbox = find.widgetWithText(CheckboxListTile, 'Ana');
    await ensureVisible(tester, anaCheckbox);
    await tester.tap(anaCheckbox);
    final betoCheckbox = find.widgetWithText(CheckboxListTile, 'Beto');
    await ensureVisible(tester, betoCheckbox);
    await tester.tap(betoCheckbox);
    await tester.pump();
    // El formulario de sesión es más largo que el de interesado (Fecha,
    // Técnica, Lugar, Participantes...): el botón "Guardar" queda fuera del
    // extent que el `ListView` construye de forma perezosa y ni siquiera
    // llega a montarse hasta hacer scroll hasta él.
    final saveSessionButton = find.widgetWithText(FilledButton, 'Guardar');
    await ensureVisible(tester, saveSessionButton);
    await tester.tap(saveSessionButton);
    await tester.pumpAndSettle();

    // 5. Abrir la sesión y agregar cinco puntos de guion.
    await tester.tap(find.text('Entrevista inicial'));
    await tester.pumpAndSettle();

    for (var i = 1; i <= 5; i++) {
      // A medida que el guion crece, tanto el campo como el botón "Agregar
      // punto" se desplazan más abajo en el `ListView` de
      // `SessionDetailScreen` y dejan de estar montados sin hacer scroll
      // hasta ellos (mismo problema que el botón "Guardar" de arriba).
      final newPointField = find.widgetWithText(TextField, 'Nuevo punto del guion');
      await ensureVisible(tester, newPointField);
      await tester.enterText(newPointField, 'Punto $i');
      final addPointButton = find.byTooltip('Agregar punto');
      await ensureVisible(tester, addPointButton);
      await tester.tap(addPointButton);
      await tester.pumpAndSettle();
    }

    for (var i = 1; i <= 5; i++) {
      expect(find.text('Punto $i'), findsOneWidget);
    }

    // 6. Reordenar dos de ellos arrastrándolos: "Punto 5" al principio y
    // "Punto 1" al final. El nuevo orden debe persistir sin posiciones
    // duplicadas ni saltos (invariante I3, ya probado exhaustivamente a
    // nivel de DAO en test/data/script_points_position_test.dart; aquí se
    // comprueba que el gesto de arrastrar en la UI real produce el mismo
    // resultado).
    const scriptPointLabels = ['Punto 1', 'Punto 2', 'Punto 3', 'Punto 4', 'Punto 5'];
    await _dragToTop(tester, 'Punto 5', scriptPointLabels);
    await _dragToBottom(tester, 'Punto 1', scriptPointLabels);

    final orderAfterReorder = _visibleOrder(tester, scriptPointLabels);
    expect(orderAfterReorder.first, 'Punto 5');
    expect(orderAfterReorder.last, 'Punto 1');
    expect(orderAfterReorder.toSet(), {'Punto 1', 'Punto 2', 'Punto 3', 'Punto 4', 'Punto 5'});

    // El orden persiste al salir y volver a entrar a la sesión.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrevista inicial'));
    await tester.pumpAndSettle();
    final orderAfterRevisit = _visibleOrder(tester, scriptPointLabels);
    expect(orderAfterRevisit, orderAfterReorder);

    // 7. Marcar dos como cubiertos ("Punto 5" y "Punto 1", ahora en los
    // extremos de la lista). El contador de la sesión pasa a 2 cubiertos y 3
    // pendientes.
    await _markCovered(tester, find.text('Punto 5'));
    await _markCovered(tester, find.text('Punto 1'));

    expect(find.text('Guion: 3 pendientes · 2 cubiertos · 0 omitidos'), findsOneWidget);
  });
}

Future<void> _addStakeholder(
  WidgetTester tester, {
  required String name,
  String? influenceLabel,
}) async {
  await tester.tap(find.byTooltip('Nuevo interesado'));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextField, 'Nombre'), name);
  if (influenceLabel != null) {
    await tester.tap(find.text(influenceLabel));
    await tester.pump();
  }
  final saveButton = find.widgetWithText(FilledButton, 'Guardar');
  await ensureVisible(tester, saveButton);
  await tester.tap(saveButton);
  await tester.pumpAndSettle();
}

/// Cuántos pasos y de qué tamaño usa [_dragBy] para simular un arrastre.
/// `ReorderableListView` recalcula con qué elemento vecino intercambiar el
/// que se arrastra en cada evento de movimiento del puntero que recibe: un
/// único `moveBy` con un delta enorme entrega un solo evento y solo dispara
/// UN intercambio con el vecino inmediato, dejando el elemento a mitad de
/// camino en vez de recorrer toda la lista, como sí ocurre con un dedo real
/// deslizándose (que genera muchos eventos de movimiento pequeños). Por eso
/// el arrastre se trocea en muchos pasos con un `pump` corto entre cada uno.
const _dragStepCount = 40;
const _dragStepDelta = 80.0;

Future<void> _dragBy(TestGesture gesture, WidgetTester tester, double direction) async {
  for (var i = 0; i < _dragStepCount; i++) {
    await gesture.moveBy(Offset(0, direction * _dragStepDelta));
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// Ejecuta un único gesto de arrastre (pulsación larga + [_dragBy] +
/// soltar) sobre el punto de guion cuyo texto es [label].
Future<void> _dragOnce(WidgetTester tester, String label, double direction) async {
  final itemText = find.text(label);
  await ensureVisible(tester, itemText);
  final itemFinder = find.ancestor(of: itemText, matching: find.byType(ListTile)).first;
  final start = tester.getCenter(itemFinder);
  final gesture = await tester.startGesture(start);
  await tester.pump(const Duration(milliseconds: 600));
  await _dragBy(gesture, tester, direction);
  await tester.pumpAndSettle();
  await gesture.up();
  await tester.pumpAndSettle();
}

/// Arrastra el punto de guion [label] hasta el principio de la lista
/// ([allLabels] enumera, en su orden original, todos los puntos del guion
/// presentes en la pantalla).
///
/// Un solo gesto de arrastre no siempre basta para llegar hasta el extremo:
/// `ReorderableListView` intercambia con el vecino inmediato en cada evento
/// de movimiento del puntero que recibe, así que si el arrastre no viaja lo
/// bastante lejos (por ejemplo, porque el gesto termina — `gesture.up()` —
/// antes de que la animación de intercambio en curso haya asentado la nueva
/// posición del elemento) puede quedar a mitad de camino en vez de en el
/// extremo. Por eso se repite el gesto, comprobando el orden real después
/// de cada intento, hasta confirmar que [label] llegó al principio.
Future<void> _dragToTop(WidgetTester tester, String label, List<String> allLabels) async {
  for (var attempt = 0; attempt < 3; attempt++) {
    if (_visibleOrder(tester, allLabels).first == label) return;
    await _dragOnce(tester, label, -1);
  }
  expect(_visibleOrder(tester, allLabels).first, label, reason: 'no llegó al principio tras 3 intentos');
}

/// Arrastra el punto de guion [label] hasta el final de la lista. Ver
/// [_dragToTop] para la razón de reintentar y verificar en vez de confiar
/// en un único gesto.
Future<void> _dragToBottom(WidgetTester tester, String label, List<String> allLabels) async {
  for (var attempt = 0; attempt < 3; attempt++) {
    if (_visibleOrder(tester, allLabels).last == label) return;
    await _dragOnce(tester, label, 1);
  }
  expect(_visibleOrder(tester, allLabels).last, label, reason: 'no llegó al final tras 3 intentos');
}

/// Marca como cubierto el punto de guion identificado por [itemText] usando
/// el menú "Marcar" de su fila.
Future<void> _markCovered(WidgetTester tester, Finder itemText) async {
  await ensureVisible(tester, itemText);
  final itemFinder = find.ancestor(of: itemText, matching: find.byType(ListTile)).first;
  final menuButton = find.descendant(of: itemFinder, matching: find.byTooltip('Marcar'));
  await ensureVisible(tester, menuButton);
  await tester.tap(menuButton);
  await tester.pumpAndSettle();
  // El menú emergente se pinta en un `Overlay` propio, fuera del `ListView`
  // de la pantalla, así que su contenido siempre está montado y no necesita
  // scroll.
  await tester.tap(find.widgetWithText(PopupMenuItem<ScriptPointStatus>, 'Cubierto'));
  await tester.pumpAndSettle();
}

/// Devuelve [labels] ordenados según su posición vertical actual en pantalla
/// (de arriba hacia abajo), para comprobar el orden visual tras arrastrar.
List<String> _visibleOrder(WidgetTester tester, List<String> labels) {
  final entries = labels.map((label) => MapEntry(label, tester.getTopLeft(find.text(label)).dy)).toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  return entries.map((e) => e.key).toList();
}
