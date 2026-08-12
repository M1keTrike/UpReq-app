import 'package:drift/drift.dart';

import '../utc_date_time_converter.dart';

import 'transcripts.dart';

/// Unidad de evidencia del sistema (data-model.md). La columna de texto se
/// llama `body`, no `text`: misma limitación de `drift_dev` ya documentada en
/// `script_points.dart` (colisión con el método `text()` de `Table`). El
/// campo del lado Dart sigue llamándose `text`. `recording_id`, `session_id`
/// y `project_id` van desnormalizados a propósito: el incremento 3 filtrará
/// por ventana de tiempo sin cruzar la transcripción.
class TranscriptSegments extends Table {
  TextColumn get id => text()();
  TextColumn get transcriptId => text().references(Transcripts, #id)();
  TextColumn get recordingId => text()();
  TextColumn get sessionId => text()();
  TextColumn get projectId => text()();
  IntColumn get fromMs => integer()();
  IntColumn get toMs => integer()();
  IntColumn get position => integer()();
  TextColumn get body => text()();
  DateTimeColumn get deletedAt => dateTime().map(const UtcDateTimeConverter()).nullable()();
  DateTimeColumn get createdAt => dateTime().map(const UtcDateTimeConverter())();
  DateTimeColumn get updatedAt => dateTime().map(const UtcDateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
