// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stakeholders_dao.dart';

// ignore_for_file: type=lint
mixin _$StakeholdersDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $StakeholdersTable get stakeholders => attachedDatabase.stakeholders;
  StakeholdersDaoManager get managers => StakeholdersDaoManager(this);
}

class StakeholdersDaoManager {
  final _$StakeholdersDaoMixin _db;
  StakeholdersDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$StakeholdersTableTableManager get stakeholders =>
      $$StakeholdersTableTableManager(_db.attachedDatabase, _db.stakeholders);
}
