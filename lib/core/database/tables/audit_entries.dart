import 'package:drift/drift.dart';

import '../utc_date_time_converter.dart';

import 'projects.dart';

/// Inmutable y de solo lectura: sin `deleted_at` ni operación de escritura
/// expuesta. `operation`: `projectClosed` | `projectReopened` |
/// `stakeholderDeactivated` | `sessionDeleted` | `scriptPointDeleted` |
/// `glossaryTermDeleted`. `entity_type`: `project` | `stakeholder` |
/// `session` | `scriptPoint` | `glossaryTerm`.
class AuditEntries extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get operation => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get entityLabel => text().nullable()();
  DateTimeColumn get occurredAt => dateTime().map(const UtcDateTimeConverter())();
  DateTimeColumn get createdAt => dateTime().map(const UtcDateTimeConverter())();
  DateTimeColumn get updatedAt => dateTime().map(const UtcDateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
