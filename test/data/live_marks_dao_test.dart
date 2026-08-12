import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/database/app_database.dart' hide LiveMark;
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/recordings/data/live_mark_repository_impl.dart';
import 'package:up_req/features/recordings/data/live_marks_dao.dart';
import 'package:up_req/features/recordings/domain/entities/live_mark.dart';

import '../support/seed.dart';
import '../support/test_container.dart';
import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  late LiveMarkRepositoryImpl repository;
  final at = DateTime.utc(2026, 1, 1);

  setUp(() async {
    db = openTestDatabase();
    repository = LiveMarkRepositoryImpl(db, LiveMarksDao(db), SequentialIdGenerator(prefix: 'audit'));
    await db.into(db.projects).insert(seedProject(at: at, id: 'project-1'));
    await db.into(db.sessions).insert(seedSession(at: at, projectId: 'project-1', id: 'session-1'));
    await db.into(db.recordings).insert(
          seedRecording(at: at, id: 'recording-1', sessionId: 'session-1', projectId: 'project-1'),
        );
  });

  tearDown(() => db.close());

  test('listado por grabación ordenado por at_ms', () async {
    await db.into(db.liveMarks).insert(
          seedLiveMark(
            at: at,
            id: 'mark-2',
            recordingId: 'recording-1',
            sessionId: 'session-1',
            projectId: 'project-1',
            atMs: 5000,
          ),
        );
    await db.into(db.liveMarks).insert(
          seedLiveMark(
            at: at,
            id: 'mark-1',
            recordingId: 'recording-1',
            sessionId: 'session-1',
            projectId: 'project-1',
            atMs: 1000,
          ),
        );

    final marks = await repository.watchByRecording(const RecordingId('recording-1')).first;
    expect(marks.map((m) => m.id.value), ['mark-1', 'mark-2']);
  });

  test('cambio de tipo persiste', () async {
    await db.into(db.liveMarks).insert(
          seedLiveMark(
            at: at,
            id: 'mark-1',
            recordingId: 'recording-1',
            sessionId: 'session-1',
            projectId: 'project-1',
            kind: 'requirement',
          ),
        );

    await repository.updateKind(const LiveMarkId('mark-1'), LiveMarkKind.quote, at);

    final marks = await repository.watchByRecording(const RecordingId('recording-1')).first;
    expect(marks.single.kind, LiveMarkKind.quote);
  });

  test('baja lógica con asiento liveMarkDeleted en la misma transacción', () async {
    await db.into(db.liveMarks).insert(
          seedLiveMark(
            at: at,
            id: 'mark-1',
            recordingId: 'recording-1',
            sessionId: 'session-1',
            projectId: 'project-1',
          ),
        );

    await repository.softDelete(const LiveMarkId('mark-1'), at);

    final marks = await repository.watchByRecording(const RecordingId('recording-1')).first;
    expect(marks, isEmpty);

    final auditRows = await db.select(db.auditEntries).get();
    expect(auditRows, hasLength(1));
    expect(auditRows.single.operation, 'liveMarkDeleted');
    expect(auditRows.single.entityId, 'mark-1');
  });
}
