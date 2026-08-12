// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcripts_dao.dart';

// ignore_for_file: type=lint
mixin _$TranscriptsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $SessionsTable get sessions => attachedDatabase.sessions;
  $RecordingsTable get recordings => attachedDatabase.recordings;
  $TranscriptsTable get transcripts => attachedDatabase.transcripts;
  $TranscriptSegmentsTable get transcriptSegments =>
      attachedDatabase.transcriptSegments;
  TranscriptsDaoManager get managers => TranscriptsDaoManager(this);
}

class TranscriptsDaoManager {
  final _$TranscriptsDaoMixin _db;
  TranscriptsDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$RecordingsTableTableManager get recordings =>
      $$RecordingsTableTableManager(_db.attachedDatabase, _db.recordings);
  $$TranscriptsTableTableManager get transcripts =>
      $$TranscriptsTableTableManager(_db.attachedDatabase, _db.transcripts);
  $$TranscriptSegmentsTableTableManager get transcriptSegments =>
      $$TranscriptSegmentsTableTableManager(
        _db.attachedDatabase,
        _db.transcriptSegments,
      );
}
