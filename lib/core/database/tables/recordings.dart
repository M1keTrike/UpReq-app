import 'package:drift/drift.dart';

import '../utc_date_time_converter.dart';

import 'projects.dart';
import 'sessions.dart';

/// `status`: `recording` | `stopped` | `interrupted`. `file_path` es
/// relativa al sandbox de la app, nunca absoluta (data-model.md, por qué la
/// ruta es relativa). `sample_rate` y `channels` se persisten aunque sean
/// constantes: el reparador de cabecera RIFF los necesita como función pura.
class Recordings extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get filePath => text()();
  TextColumn get status => text().withDefault(const Constant('recording'))();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  IntColumn get sampleRate => integer().withDefault(const Constant(16000))();
  IntColumn get channels => integer().withDefault(const Constant(1))();
  DateTimeColumn get startedAt => dateTime().map(const UtcDateTimeConverter())();
  DateTimeColumn get stoppedAt => dateTime().map(const UtcDateTimeConverter()).nullable()();
  DateTimeColumn get deletedAt => dateTime().map(const UtcDateTimeConverter()).nullable()();
  DateTimeColumn get createdAt => dateTime().map(const UtcDateTimeConverter())();
  DateTimeColumn get updatedAt => dateTime().map(const UtcDateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
