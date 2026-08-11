import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:up_req/core/router/app_router.dart';

import 'support/test_app.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await ensureVisible(tester, finder);
  await tester.tap(finder);
}

/// T112 — validación V2 del quickstart (SC-002): cerrar y reabrir la
/// aplicación conserva toda la información.
///
/// **Nota sobre fidelidad de la prueba**: `integration_test` corre dentro de
/// un único proceso de prueba (`flutter test integration_test/`), así que no
/// hay manera de "matar" de verdad el proceso de la app y relanzarlo desde
/// cero como haría una persona retirándola de recientes en un dispositivo —
/// eso solo es observable manualmente (T117, validación V4 en un Android
/// físico). El equivalente fiel disponible en este arnés, y el que sigue esta
/// prueba, es: escribir los datos con una `AppDatabase` respaldada por un
/// **archivo** real (no en memoria), cerrar esa conexión por completo
/// (`db.close()`), reconstruir el árbol de widgets desde cero
/// (`tester.pumpWidget` con una `UpReqApp` nueva dentro de un `ProviderScope`
/// nuevo, exactamente como ocurre al relanzar el proceso) y abrir una
/// **segunda** conexión a **la misma ruta de archivo**. Si los datos
/// sobreviven a ese ciclo, sobreviven por la misma razón que sobrevivirían a
/// cerrar y reabrir la app de verdad: están en el archivo SQLite, no en
/// memoria del proceso.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('V2: cerrar y reabrir la aplicación conserva toda la información', (tester) async {
    final dir = await Directory.systemTemp.createTemp('up_req_persistence_test');
    final dbFile = File('${dir.path}${Platform.pathSeparator}up_req_test.sqlite');
    addTearDown(() async {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    // --- Primera "sesión de uso": crear proyecto, interesados, sesión con
    // participantes y cinco puntos de guion con distintos estados. ---
    final firstDb = openFileDatabase(dbFile);
    await pumpTestApp(tester, firstDb);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Nuevo proyecto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Proyecto Persistente');
    await _tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Interesados'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Nuevo interesado'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Interesado Persistente');
    await _tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sesiones'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Nueva sesión'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Sesión Persistente');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.widgetWithText(CheckboxListTile, 'Interesado Persistente'));
    await tester.pump();
    // El formulario de sesión es más largo que una pantalla en un
    // dispositivo real: el botón "Guardar" no llega a montarse hasta hacer
    // scroll hasta él.
    await _tapVisible(tester, find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sesión Persistente'));
    await tester.pumpAndSettle();
    final newPointField = find.widgetWithText(TextField, 'Nuevo punto del guion');
    await ensureVisible(tester, newPointField);
    await tester.enterText(newPointField, 'Punto persistente');
    await _tapVisible(tester, find.byTooltip('Agregar punto'));
    await tester.pumpAndSettle();

    expect(find.text('Punto persistente'), findsOneWidget);

    // Desmonta el árbol de widgets primero (así ninguna suscripción activa a
    // los streams de drift queda escuchando cuando la conexión se cierre) y
    // solo entonces cierra la conexión: nada queda vivo en memoria del
    // proceso salvo lo que esté en el archivo.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await firstDb.close();

    // --- "Reabrir la aplicación": árbol de widgets nuevo, ProviderScope
    // nuevo, conexión nueva sobre el mismo archivo. ---
    final secondDb = openFileDatabase(dbFile);
    addTearDown(secondDb.close);

    // `appRouter` (lib/core/router/app_router.dart) es un `final` de nivel
    // superior: sobrevive dentro del mismo aislado de prueba entre este
    // "cierre" y "reapertura" simulados, así que conserva la última
    // ubicación visitada en la primera sesión. Una app relanzada de verdad
    // arranca siempre en `initialLocation: '/'`; forzarlo aquí reproduce esa
    // parte del relanzamiento que el simple remontaje del árbol de widgets
    // no cubre por sí solo.
    appRouter.go('/');
    await pumpTestApp(tester, secondDb);
    await tester.pumpAndSettle();

    expect(find.text('Proyecto Persistente'), findsOneWidget);

    await tester.tap(find.text('Proyecto Persistente'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Interesados'),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Sesiones'),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Interesados'));
    await tester.pumpAndSettle();
    expect(find.text('Interesado Persistente'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sesiones'));
    await tester.pumpAndSettle();
    expect(find.text('Sesión Persistente'), findsOneWidget);

    await tester.tap(find.text('Sesión Persistente'));
    await tester.pumpAndSettle();
    expect(find.text('Punto persistente'), findsOneWidget);
  });
}
