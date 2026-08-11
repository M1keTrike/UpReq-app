// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glossary_dao.dart';

// ignore_for_file: type=lint
mixin _$GlossaryDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $GlossaryTermsTable get glossaryTerms => attachedDatabase.glossaryTerms;
  GlossaryDaoManager get managers => GlossaryDaoManager(this);
}

class GlossaryDaoManager {
  final _$GlossaryDaoMixin _db;
  GlossaryDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$GlossaryTermsTableTableManager get glossaryTerms =>
      $$GlossaryTermsTableTableManager(_db.attachedDatabase, _db.glossaryTerms);
}
