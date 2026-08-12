import 'package:drift/drift.dart';

import '../utc_date_time_converter.dart';

import 'recordings.dart';

/// `pass`: `live` | `final` — solo `final` se persiste con texto en este
/// incremento (data-model.md: la pasada en vivo no ancla evidencia). `status`:
/// `pending` | `processing` | `done` | `failed`. `pending` es el estado que
/// resuelve FR-016: una sesión cerrada sin modelo descargado no es un error.
///
/// La columna de texto completo se llama `body`, no `text`: la misma
/// limitación de `drift_dev` documentada en `script_points.dart` y
/// `transcript_segments.dart` — un getter llamado `text` colisiona con el
/// método `text()` que `Table` hereda para declarar columnas, y aquí se
/// manifiesta de forma directa porque el propio nombre del campo coincide
/// con el del método. El campo del lado Dart en `Transcript` sigue
/// llamándose `text`.
class Transcripts extends Table {
  TextColumn get id => text()();
  TextColumn get recordingId => text().references(Recordings, #id)();
  TextColumn get sessionId => text()();
  TextColumn get projectId => text()();
  TextColumn get pass => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get modelId => text()();
  TextColumn get body => text().nullable()();
  TextColumn get failureReason => text().nullable()();
  DateTimeColumn get completedAt => dateTime().map(const UtcDateTimeConverter()).nullable()();
  DateTimeColumn get deletedAt => dateTime().map(const UtcDateTimeConverter()).nullable()();
  DateTimeColumn get createdAt => dateTime().map(const UtcDateTimeConverter())();
  DateTimeColumn get updatedAt => dateTime().map(const UtcDateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
