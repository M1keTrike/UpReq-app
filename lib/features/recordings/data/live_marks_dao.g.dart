// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_marks_dao.dart';

// ignore_for_file: type=lint
mixin _$LiveMarksDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $SessionsTable get sessions => attachedDatabase.sessions;
  $RecordingsTable get recordings => attachedDatabase.recordings;
  $LiveMarksTable get liveMarks => attachedDatabase.liveMarks;
  LiveMarksDaoManager get managers => LiveMarksDaoManager(this);
}

class LiveMarksDaoManager {
  final _$LiveMarksDaoMixin _db;
  LiveMarksDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$RecordingsTableTableManager get recordings =>
      $$RecordingsTableTableManager(_db.attachedDatabase, _db.recordings);
  $$LiveMarksTableTableManager get liveMarks =>
      $$LiveMarksTableTableManager(_db.attachedDatabase, _db.liveMarks);
}
