import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:up_req/core/database/app_database.dart';

/// Abre una `AppDatabase` en memoria para pruebas. `closeStreamsSynchronously:
/// true` es imprescindible: sin él, drift retrasa un ciclo de eventos antes de
/// cerrar los streams de una consulta, y eso deja timers pendientes que
/// `testWidgets` reporta como fuga tras cada prueba.
AppDatabase openTestDatabase() {
  return AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
}
