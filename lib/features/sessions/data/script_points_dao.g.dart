// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'script_points_dao.dart';

// ignore_for_file: type=lint
mixin _$ScriptPointsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $SessionsTable get sessions => attachedDatabase.sessions;
  $ScriptPointsTable get scriptPoints => attachedDatabase.scriptPoints;
  ScriptPointsDaoManager get managers => ScriptPointsDaoManager(this);
}

class ScriptPointsDaoManager {
  final _$ScriptPointsDaoMixin _db;
  ScriptPointsDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$ScriptPointsTableTableManager get scriptPoints =>
      $$ScriptPointsTableTableManager(_db.attachedDatabase, _db.scriptPoints);
}
