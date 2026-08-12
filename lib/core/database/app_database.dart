import 'package:drift/drift.dart';

import 'tables/audit_entries.dart';
import 'tables/glossary_terms.dart';
import 'tables/live_marks.dart';
import 'tables/projects.dart';
import 'tables/recordings.dart';
import 'tables/script_points.dart';
import 'tables/sessions.dart';
import 'tables/stakeholders.dart';
import 'tables/transcript_segments.dart';
import 'tables/transcripts.dart';
import 'utc_date_time_converter.dart';

part 'app_database.g.dart';

/// Índices del esquema v1 (incremento 1). Tres son parciales (`WHERE
/// deleted_at IS NULL`) y uno lleva orden `DESC`; ninguno de los dos es
/// expresable con la anotación `@TableIndex` de drift, así que se declaran en
/// SQL crudo dentro de `onCreate` en vez de mezclar dos mecanismos distintos.
const _v1IndexStatements = [
  'CREATE INDEX projects_status ON projects (status, name)',
  'CREATE INDEX stakeholders_project ON stakeholders (project_id, status, name)',
  'CREATE INDEX sessions_project ON sessions (project_id, scheduled_at) '
      'WHERE deleted_at IS NULL',
  'CREATE INDEX script_points_session ON script_points (session_id, position) '
      'WHERE deleted_at IS NULL',
  'CREATE INDEX glossary_project ON glossary_terms (project_id, term_sort_key) '
      'WHERE deleted_at IS NULL',
  'CREATE INDEX audit_project ON audit_entries (project_id, occurred_at DESC)',
];

/// Índices nuevos del esquema v2 (incremento 2, data-model.md). Todos
/// parciales sobre `deleted_at IS NULL`. `segments_recording_time` no sirve a
/// ninguna consulta de este incremento: se declara ahora porque es la
/// consulta que el incremento 3 hará en cada extracción, y añadirla después
/// obligaría a otra migración por una sola línea.
const _v2IndexStatements = [
  'CREATE INDEX recordings_session ON recordings (session_id, started_at) '
      'WHERE deleted_at IS NULL',
  'CREATE INDEX live_marks_recording ON live_marks (recording_id, at_ms) '
      'WHERE deleted_at IS NULL',
  'CREATE INDEX transcripts_recording ON transcripts (recording_id, pass) '
      'WHERE deleted_at IS NULL',
  'CREATE UNIQUE INDEX transcripts_one_per_pass ON transcripts (recording_id, pass) '
      'WHERE deleted_at IS NULL',
  'CREATE INDEX segments_transcript ON transcript_segments (transcript_id, position) '
      'WHERE deleted_at IS NULL',
  'CREATE INDEX segments_recording_time ON transcript_segments (recording_id, from_ms) '
      'WHERE deleted_at IS NULL',
];

@DriftDatabase(
  tables: [
    Projects,
    Stakeholders,
    Sessions,
    SessionParticipants,
    ScriptPoints,
    GlossaryTerms,
    AuditEntries,
    Recordings,
    LiveMarks,
    Transcripts,
    TranscriptSegments,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Acepta un `QueryExecutor` inyectable para poder abrirla en memoria en
  /// pruebas (ver test/support/test_database.dart).
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        // FR-017 (incremento 1) exige que la migración inicial quede
        // declarada de forma explícita aunque `m.createAll()` sea el
        // comportamiento por defecto. Una instalación nueva llega
        // directamente a v2 con las once tablas y ambos juegos de índices.
        onCreate: (m) async {
          await m.createAll();
          for (final statement in [..._v1IndexStatements, ..._v2IndexStatements]) {
            await customStatement(statement);
          }
        },
        // Migración v1 -> v2 (research.md, decisión 9): puramente aditiva,
        // no toca ninguna tabla del incremento 1. Las cuatro tablas se crean
        // juntas en una sola migración (data-model.md): la consecuencia
        // deliberada de no fragmentarlas por historia sobre un teléfono que
        // ya tiene datos reales.
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(recordings);
            await m.createTable(liveMarks);
            await m.createTable(transcripts);
            await m.createTable(transcriptSegments);
            for (final statement in _v2IndexStatements) {
              await customStatement(statement);
            }
          }
        },
        // La verificación del esquema contra los snapshots versionados vive
        // en test/drift/schema_v2_test.dart vía `SchemaVerifier`, no aquí:
        // esa utilidad pertenece a drift_dev, un dev_dependency que no
        // existe en el binario de producción.
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
