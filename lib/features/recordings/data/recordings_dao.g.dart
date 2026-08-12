// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recordings_dao.dart';

// ignore_for_file: type=lint
mixin _$RecordingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $SessionsTable get sessions => attachedDatabase.sessions;
  $RecordingsTable get recordings => attachedDatabase.recordings;
  RecordingsDaoManager get managers => RecordingsDaoManager(this);
}

class RecordingsDaoManager {
  final _$RecordingsDaoMixin _db;
  RecordingsDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$RecordingsTableTableManager get recordings =>
      $$RecordingsTableTableManager(_db.attachedDatabase, _db.recordings);
}
