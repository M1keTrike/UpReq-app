import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_database.dart';

part 'database_provider.g.dart';

/// `keepAlive: true` a propósito: la conexión SQLite debe sobrevivir a la
/// navegación entre pantallas. Si el provider se destruyera al salir de una
/// ruta (comportamiento por defecto de Riverpod), cada vuelta a una pantalla
/// reabriría la base de datos, perdiendo la ventaja de mantener una única
/// conexión y arriesgando fugas de recursos nativos de SQLite.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(_openConnection());
  ref.onDispose(db.close);
  return db;
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}up_req.sqlite');
    return NativeDatabase.createInBackground(file);
  });
}
