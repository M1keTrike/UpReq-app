import 'package:drift/drift.dart';

import '../utc_date_time_converter.dart';

import 'projects.dart';

/// `term_sort_key` es columna almacenada (no calculada en la consulta): el
/// orden alfabético debe ignorar mayúsculas y acentos, y `ORDER BY` de SQLite
/// no lo hace sin una colación personalizada (data-model.md).
class GlossaryTerms extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get term => text()();
  TextColumn get definition => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get termSortKey => text()();
  DateTimeColumn get deletedAt => dateTime().map(const UtcDateTimeConverter()).nullable()();
  DateTimeColumn get createdAt => dateTime().map(const UtcDateTimeConverter())();
  DateTimeColumn get updatedAt => dateTime().map(const UtcDateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
