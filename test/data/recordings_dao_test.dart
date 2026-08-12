import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/database/app_database.dart' hide Recording;
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/features/recordings/data/recording_repository_impl.dart';
import 'package:up_req/features/recordings/data/recordings_dao.dart';

import '../support/seed.dart';
import '../support/test_container.dart';
import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  late RecordingRepositoryImpl repository;
  final at = DateTime.utc(2026, 1, 1);

  setUp(() async {
    db = openTestDatabase();
    repository = RecordingRepositoryImpl(db, RecordingsDao(db), SequentialIdGenerator(prefix: 'audit'));
    await db.into(db.projects).insert(seedProject(at: at, id: 'project-1'));
    await db.into(db.projects).insert(seedProject(at: at, id: 'project-2'));
    await db.into(db.sessions).insert(seedSession(at: at, projectId: 'project-1', id: 'session-1'));
    await db.into(db.sessions).insert(seedSession(at: at, projectId: 'project-2', id: 'session-2'));
  });

  tearDown(() => db.close());

  test('alta y listado por sesión ordenado por started_at', () async {
    await db.into(db.recordings).insert(
          seedRecording(
            at: at,
            id: 'recording-2',
            sessionId: 'session-1',
            projectId: 'project-1',
            startedAt: at.add(const Duration(minutes: 5)),
          ),
        );
    await db.into(db.recordings).insert(
          seedRecording(
            at: at,
            id: 'recording-1',
            sessionId: 'session-1',
            projectId: 'project-1',
            startedAt: at,
          ),
        );

    final list = await repository.watchBySession(const SessionId('session-1')).first;
    expect(list.map((r) => r.id.value), ['recording-1', 'recording-2']);
  });

  test('baja lógica con asiento de bitácora en la misma transacción', () async {
    await db.into(db.recordings).insert(seedRecording(at: at, id: 'recording-1', sessionId: 'session-1', projectId: 'project-1'));

    await repository.softDelete(const RecordingId('recording-1'), at);

    final list = await repository.watchBySession(const SessionId('session-1')).first;
    expect(list, isEmpty);

    final auditRows = await db.select(db.auditEntries).get();
    expect(auditRows, hasLength(1));
    expect(auditRows.single.operation, 'recordingDeleted');
    expect(auditRows.single.entityId, 'recording-1');
  });

  test(
    'la cascada retira marcas, transcripciones y segmentos de la grabación sin asientos propios',
    () async {
      await db.into(db.recordings).insert(
            seedRecording(at: at, id: 'recording-1', sessionId: 'session-1', projectId: 'project-1'),
          );
      await db.into(db.liveMarks).insert(
            seedLiveMark(at: at, id: 'mark-1', recordingId: 'recording-1', sessionId: 'session-1', projectId: 'project-1'),
          );
      await db.into(db.transcripts).insert(
            seedTranscript(at: at, id: 'transcript-1', recordingId: 'recording-1', sessionId: 'session-1', projectId: 'project-1'),
          );
      await db.into(db.transcriptSegments).insert(
            seedTranscriptSegment(
              at: at,
              id: 'segment-1',
              transcriptId: 'transcript-1',
              recordingId: 'recording-1',
              sessionId: 'session-1',
              projectId: 'project-1',
              fromMs: 0,
              toMs: 1000,
              position: 0,
            ),
          );

      await repository.softDelete(const RecordingId('recording-1'), at);

      final marks = await (db.select(db.liveMarks)..where((m) => m.deletedAt.isNull())).get();
      final transcripts = await (db.select(db.transcripts)..where((t) => t.deletedAt.isNull())).get();
      final segments =
          await (db.select(db.transcriptSegments)..where((s) => s.deletedAt.isNull())).get();
      expect(marks, isEmpty);
      expect(transcripts, isEmpty);
      expect(segments, isEmpty);

      // Un solo asiento: recordingDeleted. La cascada no escribe los suyos.
      final auditRows = await db.select(db.auditEntries).get();
      expect(auditRows, hasLength(1));
      expect(auditRows.single.operation, 'recordingDeleted');
    },
  );

  test('aislamiento por proyecto: la lista de una sesión no cruza datos de otro proyecto', () async {
    await db.into(db.recordings).insert(
          seedRecording(at: at, id: 'recording-1', sessionId: 'session-1', projectId: 'project-1'),
        );
    await db.into(db.recordings).insert(
          seedRecording(at: at, id: 'recording-2', sessionId: 'session-2', projectId: 'project-2'),
        );

    final list1 = await repository.watchBySession(const SessionId('session-1')).first;
    final list2 = await repository.watchBySession(const SessionId('session-2')).first;

    expect(list1.map((r) => r.id.value), ['recording-1']);
    expect(list2.map((r) => r.id.value), ['recording-2']);
  });
}
