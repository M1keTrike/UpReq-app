import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:test/test.dart';
import 'package:up_req/core/database/app_database.dart';

import '../support/test_database.dart';
import 'app_database/generated/schema.dart';
import 'app_database/generated/schema_v1.dart' as v1;

void main() {
  final verifier = SchemaVerifier(GeneratedHelper());

  test('la base creada desde cero coincide con el snapshot de la versión 2', () async {
    final connection = await verifier.startAt(2);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 2);
  });

  // T027: verifica el paso de v1 a v2 CON DATOS POBLADOS, no solo el esquema
  // final. Verificar solo el resultado dejaría pasar una migración que
  // funciona en instalación limpia y falla en actualización, que es el único
  // caso que importa: el teléfono del analista ya tiene el incremento 1
  // encima con proyectos reales.
  test('la migración v1 -> v2 conserva los datos del incremento 1 y crea las tablas nuevas '
      'utilizables', () async {
    final schema = await verifier.schemaAt(1);
    final oldDb = v1.DatabaseAtV1(schema.newConnection());

    final now = DateTime.utc(2026, 8, 11).millisecondsSinceEpoch;
    await oldDb.into(oldDb.projects).insert(
          v1.ProjectsCompanion.insert(
            id: 'project-1',
            name: 'Proyecto existente',
            status: const Value('active'),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await oldDb.into(oldDb.sessions).insert(
          v1.SessionsCompanion.insert(
            id: 'session-1',
            projectId: 'project-1',
            title: 'Entrevista 1',
            scheduledAt: now,
            technique: 'openInterview',
            status: const Value('inProgress'),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await oldDb.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);

    final projects = await db.select(db.projects).get();
    expect(projects, hasLength(1));
    expect(projects.single.id, 'project-1');

    final sessions = await db.select(db.sessions).get();
    expect(sessions, hasLength(1));
    expect(sessions.single.id, 'session-1');

    // Las cuatro tablas nuevas existen y son utilizables tras la migración.
    await db.into(db.recordings).insert(
          RecordingsCompanion.insert(
            id: 'recording-1',
            sessionId: 'session-1',
            projectId: 'project-1',
            filePath: 'recordings/recording-1.wav',
            startedAt: DateTime.utc(2026, 8, 11),
            createdAt: DateTime.utc(2026, 8, 11),
            updatedAt: DateTime.utc(2026, 8, 11),
          ),
        );
    final recordings = await db.select(db.recordings).get();
    expect(recordings, hasLength(1));

    await db.into(db.liveMarks).insert(
          LiveMarksCompanion.insert(
            id: 'mark-1',
            recordingId: 'recording-1',
            sessionId: 'session-1',
            projectId: 'project-1',
            kind: 'requirement',
            atMs: 1500,
            createdAt: DateTime.utc(2026, 8, 11),
            updatedAt: DateTime.utc(2026, 8, 11),
          ),
        );
    expect(await db.select(db.liveMarks).get(), hasLength(1));

    await db.into(db.transcripts).insert(
          TranscriptsCompanion.insert(
            id: 'transcript-1',
            recordingId: 'recording-1',
            sessionId: 'session-1',
            projectId: 'project-1',
            pass: 'final',
            modelId: 'small',
            createdAt: DateTime.utc(2026, 8, 11),
            updatedAt: DateTime.utc(2026, 8, 11),
          ),
        );
    expect(await db.select(db.transcripts).get(), hasLength(1));

    await db.into(db.transcriptSegments).insert(
          TranscriptSegmentsCompanion.insert(
            id: 'segment-1',
            transcriptId: 'transcript-1',
            recordingId: 'recording-1',
            sessionId: 'session-1',
            projectId: 'project-1',
            fromMs: 0,
            toMs: 1000,
            position: 0,
            body: 'Hola',
            createdAt: DateTime.utc(2026, 8, 11),
            updatedAt: DateTime.utc(2026, 8, 11),
          ),
        );
    expect(await db.select(db.transcriptSegments).get(), hasLength(1));
  });

  test('transcripts_one_per_pass impide dos transcripciones no borradas del mismo par', () async {
    // Nota: usa openTestDatabase() (onCreate real, NativeDatabase.memory())
    // y no verifier.startAt(2): ese último reconstruye el esquema desde el
    // snapshot versionado, que solo captura tablas y columnas declaradas con
    // @DriftDatabase — los índices en SQL crudo de _v2IndexStatements no
    // viajan con el snapshot y no se crearían, dejando pasar en silencio una
    // prueba que debería fallar.
    final db = openTestDatabase();
    addTearDown(db.close);

    await db.into(db.projects).insert(
          ProjectsCompanion.insert(
            id: 'project-1',
            name: 'P',
            createdAt: DateTime.utc(2026, 8, 11),
            updatedAt: DateTime.utc(2026, 8, 11),
          ),
        );
    await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            id: 'session-1',
            projectId: 'project-1',
            title: 'S',
            scheduledAt: DateTime.utc(2026, 8, 11),
            technique: 'openInterview',
            createdAt: DateTime.utc(2026, 8, 11),
            updatedAt: DateTime.utc(2026, 8, 11),
          ),
        );
    await db.into(db.recordings).insert(
          RecordingsCompanion.insert(
            id: 'recording-1',
            sessionId: 'session-1',
            projectId: 'project-1',
            filePath: 'r.wav',
            startedAt: DateTime.utc(2026, 8, 11),
            createdAt: DateTime.utc(2026, 8, 11),
            updatedAt: DateTime.utc(2026, 8, 11),
          ),
        );
    await db.into(db.transcripts).insert(
          TranscriptsCompanion.insert(
            id: 'transcript-1',
            recordingId: 'recording-1',
            sessionId: 'session-1',
            projectId: 'project-1',
            pass: 'final',
            modelId: 'small',
            createdAt: DateTime.utc(2026, 8, 11),
            updatedAt: DateTime.utc(2026, 8, 11),
          ),
        );

    await expectLater(
      db.into(db.transcripts).insert(
            TranscriptsCompanion.insert(
              id: 'transcript-2',
              recordingId: 'recording-1',
              sessionId: 'session-1',
              projectId: 'project-1',
              pass: 'final',
              modelId: 'small',
              createdAt: DateTime.utc(2026, 8, 11),
              updatedAt: DateTime.utc(2026, 8, 11),
            ),
          ),
      throwsA(anything),
    );
  });
}
