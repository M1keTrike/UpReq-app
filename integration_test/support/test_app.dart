import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/database/app_database.dart';
import 'package:up_req/core/database/database_provider.dart';
import 'package:up_req/core/domain/project_status_reader.dart';
import 'package:up_req/features/projects/data/project_repository_impl.dart';
import 'package:up_req/features/projects/data/project_status_reader_impl.dart';
import 'package:up_req/main.dart';

/// Abre una `AppDatabase` en memoria, para las pruebas de integración que no
/// necesitan sobrevivir al cierre del "proceso" (T111, T113, T114).
/// `closeStreamsSynchronously: true` evita timers pendientes tras la prueba,
/// igual que en `test/support/test_database.dart`.
AppDatabase openMemoryDatabase() {
  return AppDatabase(
    DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
  );
}

/// Abre una `AppDatabase` respaldada por un archivo real en disco, para la
/// prueba de persistencia (T112, validación V2), que sí necesita que los
/// datos sobrevivan a cerrar una conexión y abrir otra nueva sobre el mismo
/// archivo.
AppDatabase openFileDatabase(File file) {
  return AppDatabase(
    DatabaseConnection(NativeDatabase(file), closeStreamsSynchronously: true),
  );
}

/// Monta la app real con la base de datos indicada, cableando
/// `projectStatusReaderProvider` con la implementación real de la feature de
/// proyectos, exactamente como hace `main.dart` en producción (`core` no
/// puede importar `features/projects`, así que ese cableado vive fuera de
/// ambos). Sin este override, cualquier pantalla que lo consulte —lista de
/// interesados, sesiones, glosario, sus formularios— lanzaría
/// `UnimplementedError` en vez de mostrar la app real.
///
/// El `ProviderScope` se construye como hijo directo de `pumpWidget` (en vez
/// de devolverlo desde una función y pasarlo después) a propósito: es el
/// patrón que exime a un `ProviderScope` de la regla `riverpod_lint`
/// `scoped_providers_should_specify_dependencies`, la misma que `main.dart`
/// cumple al construirlo como hijo directo de `runApp`.
Future<void> pumpTestApp(WidgetTester tester, AppDatabase database) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        projectStatusReaderProvider.overrideWith(
          (ref) => ProjectStatusReaderImpl(ref.watch(projectRepositoryProvider)),
        ),
      ],
      child: const UpReqApp(),
    ),
  );
}

/// Hace scroll (si hace falta) en el `Scrollable` ancestro más externo hasta
/// que [finder] esté montado y sea visible, antes de interactuar con él.
///
/// Necesario porque varias pantallas (formulario y detalle de sesión,
/// formulario de interesado, detalle de proyecto...) construyen su
/// contenido dentro de un `ListView(children: [...])` plano. Aunque la
/// lista de hijos ya está materializada (no usa `.builder`), el
/// `SliverList` subyacente sigue montando de forma perezosa solo los hijos
/// dentro del extent visible más un pequeño cache extent: en la pantalla de
/// un dispositivo real, muchos campos (el botón "Guardar" en formularios
/// largos, el campo "Nuevo punto del guion" a medida que el guion crece)
/// no llegan a montarse hasta hacer scroll hasta ellos, y
/// `find.widgetWithText`/`find.byTooltip` no encuentran nada porque buscan
/// en el árbol de elementos, no en el árbol lógico.
///
/// Si [finder] ya está visible, esto no hace nada (0 scrolls).
Future<void> ensureVisible(WidgetTester tester, Finder finder) {
  return tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
}
