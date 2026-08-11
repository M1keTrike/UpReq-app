import 'package:drift/drift.dart';

import 'tables/audit_entries.dart';
import 'tables/glossary_terms.dart';
import 'tables/projects.dart';
import 'tables/script_points.dart';
import 'tables/sessions.dart';
import 'tables/stakeholders.dart';
import 'utc_date_time_converter.dart';

part 'app_database.g.dart';

/// Índices exactos de data-model.md. Tres son parciales (`WHERE deleted_at IS
/// NULL`) y uno lleva orden `DESC`; ninguno de los dos es expresable con la
/// anotación `@TableIndex` de drift, así que se declaran en SQL crudo dentro
/// de `onCreate` en vez de mezclar dos mecanismos distintos.
const _indexStatements = [
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

@DriftDatabase(
  tables: [
    Projects,
    Stakeholders,
    Sessions,
    SessionParticipants,
    ScriptPoints,
    GlossaryTerms,
    AuditEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Acepta un `QueryExecutor` inyectable para poder abrirla en memoria en
  /// pruebas (ver test/support/test_database.dart).
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        // FR-017 exige que la migración inicial quede declarada de forma
        // explícita aunque `m.createAll()` sea el comportamiento por defecto.
        onCreate: (m) async {
          await m.createAll();
          for (final statement in _indexStatements) {
            await customStatement(statement);
          }
        },
        // La verificación del esquema contra el snapshot versionado (T019)
        // vive en test/drift/schema_v1_test.dart vía `SchemaVerifier`, no
        // aquí: esa utilidad pertenece a drift_dev, un dev_dependency que no
        // existe en el binario de producción.
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
