import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/database/app_database.dart';
import 'package:up_req/features/transcription/data/transcripts_dao.dart';

import '../support/seed.dart';
import '../support/test_database.dart';

void main() {
  late AppDatabase db;
  final at = DateTime.utc(2026, 1, 1);

  setUp(() async {
    db = openTestDatabase();
    await db.into(db.projects).insert(seedProject(at: at, id: 'project-1'));
    await db.into(db.sessions).insert(seedSession(at: at, projectId: 'project-1', id: 'session-1'));
    await db.into(db.recordings).insert(
          seedRecording(
            at: at,
            id: 'recording-1',
            sessionId: 'session-1',
            projectId: 'project-1',
            status: 'stopped',
          ),
        );
  });

  tearDown(() => db.close());

  test(
    'el índice único impide dos transcripciones no borradas del mismo par '
    '(recording_id, pass)',
    () async {
      await db.into(db.transcripts).insert(
            seedTranscript(at: at, id: 'transcript-1', recordingId: 'recording-1', sessionId: 'session-1', projectId: 'project-1'),
          );

      Future<void> insertDuplicate() => db.into(db.transcripts).insert(
            seedTranscript(at: at, id: 'transcript-2', recordingId: 'recording-1', sessionId: 'session-1', projectId: 'project-1'),
          );

      await expectLater(insertDuplicate(), throwsA(anything));
    },
  );

  test('una transcripción borrada no cuenta para el índice único', () async {
    await db.into(db.transcripts).insert(
          seedTranscript(
            at: at,
            id: 'transcript-1',
            recordingId: 'recording-1',
            sessionId: 'session-1',
            projectId: 'project-1',
            deletedAt: at,
          ),
        );

    await db.into(db.transcripts).insert(
          seedTranscript(at: at, id: 'transcript-2', recordingId: 'recording-1', sessionId: 'session-1', projectId: 'project-1'),
        );

    final rows = await db.select(db.transcripts).get();
    expect(rows, hasLength(2));
  });

  test('replaceSegments corre en una sola transacción y sustituye el contenido anterior', () async {
    await db.into(db.transcripts).insert(
          seedTranscript(at: at, id: 'transcript-1', recordingId: 'recording-1', sessionId: 'session-1', projectId: 'project-1'),
        );
    final dao = TranscriptsDao(db);

    await dao.replaceSegments('transcript-1', [
      seedTranscriptSegment(
        at: at,
        transcriptId: 'transcript-1',
        recordingId: 'recording-1',
        sessionId: 'session-1',
        projectId: 'project-1',
        id: 'segment-1',
        fromMs: 0,
        toMs: 1000,
        position: 0,
      ),
    ]);

    var segments = await dao.watchSegments('transcript-1').first;
    expect(segments, hasLength(1));
    expect(segments.single.id, 'segment-1');

    await dao.replaceSegments('transcript-1', [
      seedTranscriptSegment(
        at: at,
        transcriptId: 'transcript-1',
        recordingId: 'recording-1',
        sessionId: 'session-1',
        projectId: 'project-1',
        id: 'segment-2',
        fromMs: 0,
        toMs: 2000,
        position: 0,
      ),
    ]);

    segments = await dao.watchSegments('transcript-1').first;
    expect(segments, hasLength(1));
    expect(segments.single.id, 'segment-2');
  });

  test('findPending devuelve solo las transcripciones en estado pending', () async {
    await db.into(db.transcripts).insert(
          seedTranscript(
            at: at,
            id: 'transcript-1',
            recordingId: 'recording-1',
            sessionId: 'session-1',
            projectId: 'project-1',
            status: 'pending',
          ),
        );
    await db.into(db.recordings).insert(
          seedRecording(at: at, id: 'recording-2', sessionId: 'session-1', projectId: 'project-1', status: 'stopped'),
        );
    await db.into(db.transcripts).insert(
          seedTranscript(
            at: at,
            id: 'transcript-2',
            recordingId: 'recording-2',
            sessionId: 'session-1',
            projectId: 'project-1',
            status: 'done',
          ),
        );

    final dao = TranscriptsDao(db);
    final pending = await dao.findPending();
    expect(pending.map((t) => t.id), ['transcript-1']);
  });
}
