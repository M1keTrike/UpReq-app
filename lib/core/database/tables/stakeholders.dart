import 'package:drift/drift.dart';

import 'projects.dart';

/// `influence`: `high` | `medium` | `low`. `status`: `active` | `inactive`.
class Stakeholders extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get name => text()();
  TextColumn get role => text().nullable()();
  TextColumn get area => text().nullable()();
  TextColumn get influence => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
