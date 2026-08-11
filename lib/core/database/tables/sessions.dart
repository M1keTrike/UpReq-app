import 'package:drift/drift.dart';

import 'projects.dart';
import 'stakeholders.dart';

/// `technique`: `openInterview` | `structuredInterview` | `workshop` |
/// `observation` | `documentReview`. `status`: `planned` | `inProgress` |
/// `closed`. Avance en un solo sentido (FR-008a), verificado en dominio.
class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get title => text()();
  DateTimeColumn get scheduledAt => dateTime()();
  TextColumn get technique => text()();
  TextColumn get location => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('planned'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de unión N-a-N entre sesión e interesado. Sin `deleted_at`: quitar un
/// participante de una sesión abierta es una edición de la sesión, no una baja
/// de entidad (data-model.md).
class SessionParticipants extends Table {
  TextColumn get sessionId => text().references(Sessions, #id)();
  TextColumn get stakeholderId => text().references(Stakeholders, #id)();
  TextColumn get projectId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {sessionId, stakeholderId};
}
