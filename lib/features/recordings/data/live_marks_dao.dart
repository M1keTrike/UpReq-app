import 'package:drift/drift.dart';
import 'package:up_req/core/database/app_database.dart';
import 'package:up_req/core/database/tables/live_marks.dart';

part 'live_marks_dao.g.dart';

@DriftAccessor(tables: [LiveMarks])
class LiveMarksDao extends DatabaseAccessor<AppDatabase> with _$LiveMarksDaoMixin {
  LiveMarksDao(super.db);

  Stream<List<LiveMark>> watchByRecording(String recordingId) {
    final query = select(liveMarks)
      ..where((m) => m.recordingId.equals(recordingId) & m.deletedAt.isNull())
      ..orderBy([(m) => OrderingTerm(expression: m.atMs)]);
    return query.watch();
  }

  Future<LiveMark?> findById(String id) {
    final query = select(liveMarks)..where((m) => m.id.equals(id) & m.deletedAt.isNull());
    return query.getSingleOrNull();
  }

  Future<void> insertMark(LiveMarksCompanion companion) => into(liveMarks).insert(companion);

  Future<void> updateMark(String id, LiveMarksCompanion companion) {
    return (update(liveMarks)..where((m) => m.id.equals(id))).write(companion);
  }
}
