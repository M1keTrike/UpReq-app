import 'package:drift/drift.dart';
import 'package:up_req/core/database/app_database.dart';
import 'package:up_req/core/database/tables/recordings.dart';

part 'recordings_dao.g.dart';

@DriftAccessor(tables: [Recordings])
class RecordingsDao extends DatabaseAccessor<AppDatabase> with _$RecordingsDaoMixin {
  RecordingsDao(super.db);

  Stream<List<Recording>> watchBySession(String sessionId) {
    final query = select(recordings)
      ..where((r) => r.sessionId.equals(sessionId) & r.deletedAt.isNull())
      ..orderBy([(r) => OrderingTerm(expression: r.startedAt)]);
    return query.watch();
  }

  /// Invariante R1: como máximo una grabación en estado `recording`.
  Stream<Recording?> watchActive() {
    final query = select(recordings)
      ..where((r) => r.status.equals('recording') & r.deletedAt.isNull());
    return query.watchSingleOrNull();
  }

  Future<Recording?> findInterrupted() {
    final query = select(recordings)
      ..where((r) => r.status.equals('interrupted') & r.deletedAt.isNull())
      ..orderBy([(r) => OrderingTerm(expression: r.startedAt, mode: OrderingMode.desc)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<Recording?> findById(String id) {
    final query = select(recordings)..where((r) => r.id.equals(id) & r.deletedAt.isNull());
    return query.getSingleOrNull();
  }

  Future<void> insertRecording(RecordingsCompanion companion) => into(recordings).insert(companion);

  Future<void> updateRecording(String id, RecordingsCompanion companion) {
    return (update(recordings)..where((r) => r.id.equals(id))).write(companion);
  }
}
