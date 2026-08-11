// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_dao.dart';

// ignore_for_file: type=lint
mixin _$AuditDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $AuditEntriesTable get auditEntries => attachedDatabase.auditEntries;
  AuditDaoManager get managers => AuditDaoManager(this);
}

class AuditDaoManager {
  final _$AuditDaoMixin _db;
  AuditDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$AuditEntriesTableTableManager get auditEntries =>
      $$AuditEntriesTableTableManager(_db.attachedDatabase, _db.auditEntries);
}
