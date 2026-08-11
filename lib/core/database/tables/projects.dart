import 'package:drift/drift.dart';

/// `active` | `closed`. Enum de dominio vive en la feature de proyectos; aquí
/// solo se guarda el texto crudo (la capa de datos no depende de `features/`).
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get client => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
