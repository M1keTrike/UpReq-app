import 'package:drift/drift.dart';

import '../utc_date_time_converter.dart';

import 'recordings.dart';

/// `kind`: `requirement` | `doubt` | `quote`, conjunto cerrado aclarado el
/// 2026-08-11. `at_ms` es relativo al inicio de **su** grabación, no epoch
/// (data-model.md): así el salto del reproductor es directo y sobrevive a
/// una reanudación tras interrupción.
class LiveMarks extends Table {
  TextColumn get id => text()();
  TextColumn get recordingId => text().references(Recordings, #id)();
  TextColumn get sessionId => text()();
  TextColumn get projectId => text()();
  TextColumn get kind => text()();
  IntColumn get atMs => integer()();
  DateTimeColumn get deletedAt => dateTime().map(const UtcDateTimeConverter()).nullable()();
  DateTimeColumn get createdAt => dateTime().map(const UtcDateTimeConverter())();
  DateTimeColumn get updatedAt => dateTime().map(const UtcDateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
