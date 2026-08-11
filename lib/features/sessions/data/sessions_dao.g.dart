// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sessions_dao.dart';

// ignore_for_file: type=lint
mixin _$SessionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $SessionsTable get sessions => attachedDatabase.sessions;
  $StakeholdersTable get stakeholders => attachedDatabase.stakeholders;
  $SessionParticipantsTable get sessionParticipants =>
      attachedDatabase.sessionParticipants;
  SessionsDaoManager get managers => SessionsDaoManager(this);
}

class SessionsDaoManager {
  final _$SessionsDaoMixin _db;
  SessionsDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$StakeholdersTableTableManager get stakeholders =>
      $$StakeholdersTableTableManager(_db.attachedDatabase, _db.stakeholders);
  $$SessionParticipantsTableTableManager get sessionParticipants =>
      $$SessionParticipantsTableTableManager(
        _db.attachedDatabase,
        _db.sessionParticipants,
      );
}
