import 'package:drift/drift.dart';

import '../utc_date_time_converter.dart';

import 'sessions.dart';

/// `status`: `pending` | `covered` | `skipped`. `position`: contigua `0..n-1`
/// dentro de la sesión (invariante I3, verificado en pruebas, no por el
/// esquema — deliberadamente sin `UNIQUE (session_id, position)`, ver
/// data-model.md decisión 8 de research).
///
/// La columna de texto del punto se llama `body`, no `text` como en
/// data-model.md: `drift_dev schema generate` reconstruye una clase de tabla
/// de verificación a partir del esquema SQL, y una columna llamada `text`
/// colisiona con el método `text()` que la propia clase `Table` hereda para
/// declarar columnas. Es una limitación del generador (drift_dev 2.34.0), no
/// una decisión de dominio; el campo del lado Dart en `ScriptPoint` sigue
/// llamándose `text`.
class ScriptPoints extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  TextColumn get projectId => text()();
  TextColumn get body => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get position => integer()();
  DateTimeColumn get deletedAt => dateTime().map(const UtcDateTimeConverter()).nullable()();
  DateTimeColumn get createdAt => dateTime().map(const UtcDateTimeConverter())();
  DateTimeColumn get updatedAt => dateTime().map(const UtcDateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
