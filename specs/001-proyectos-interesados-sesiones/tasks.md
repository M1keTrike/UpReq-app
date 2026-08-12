---

description: "Task list for 001-proyectos-interesados-sesiones"
---

# Tasks: Gestión de proyectos, interesados y sesiones de elicitación

**Input**: Design documents from `/specs/001-proyectos-interesados-sesiones/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: **INCLUIDOS Y OBLIGATORIOS.** No son opcionales en este proyecto: la sección
Calidad de la constitución exige probar **casos de uso y Notifier** con `ProviderContainer` y
overrides, cobertura mínima del 80% en `domain`, y que CI bloquee el merge si fallan las
pruebas o la cobertura.

> **Aviso sobre la puerta de cobertura**: el umbral del 80% mide solo
> `lib/features/*/domain/`. Los Notifier viven en `presentation/`, así que esa puerta **no**
> protege la regla de probarlos. Por eso cada historia lleva su tarea de prueba de Notifier
> de forma explícita: es lo único que la garantiza.

**Organization**: Tareas agrupadas por historia de usuario para poder implementarlas y
probarlas de forma independiente.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Se puede ejecutar en paralelo (archivos distintos, sin dependencias pendientes)
- **[Story]**: Historia a la que pertenece (US1…US6)
- Toda descripción lleva la ruta exacta del archivo

## Path Conventions

Aplicación Flutter de proyecto único, con la estructura que fija el Principio I de la
constitución:

- Código: `lib/core/` (compartido) y `lib/features/<feature>/{domain,data,presentation}/`
- Pruebas: `test/unit/`, `test/data/`, `test/widget/`, `test/drift/`, `integration_test/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Arrancar el proyecto Flutter con el toolchain y las puertas de calidad que la
constitución exige, antes de escribir una sola línea de dominio.

- [X] T001 Verificar el toolchain con `flutter --version`: debe ser Flutter 3.44.9 con Dart 3.12.2 según la constitución v1.1.1. Si no coincide, detenerse y resolver antes de continuar
- [X] T002 Crear el proyecto Flutter en la raíz del repositorio con `flutter create --project-name up_req --org com.upreq --platforms android,ios .`, conservando `.specify/`, `specs/` y `.claude/`
- [X] T003 Declarar las dependencias exactas en `pubspec.yaml`: flutter_riverpod 3.3.2, riverpod_annotation 4.0.3, drift 2.34.3, go_router, uuid, clock; y en dev_dependencies riverpod_generator 4.0.4, riverpod_lint 3.1.4, drift_dev ^2.34.0, build_runner ^2.15.1, flutter_lints, integration_test. **Ninguna dependencia de red** (FR-019) y **sin** `sqlite3_flutter_libs`, que drift ≥ 2.32.0 hace innecesario. ⚠️ **No subir las cuatro versiones de Riverpod**: `riverpod_generator` ≥ 4.0.6 exige `analyzer 13` y resulta incompatible con `drift_dev` por la cadena `test → io`; es la restricción del Principio I de la constitución v1.2.0
- [X] T004 [P] Configurar `analysis_options.yaml` con `include: package:flutter_lints/flutter.yaml` y la clave `plugins: riverpod_lint: 3.1.4` (mecanismo `plugins:` vigente desde riverpod_lint 3.1.0, **no** `custom_lint`)
- [X] T005 [P] Configurar `build.yaml` con las opciones de drift_dev: `databases: {app_database: lib/core/database/app_database.dart}`, `schema_dir: drift_schemas/` y `test_dir: test/drift/`
- [X] T006 [P] Crear la estructura de carpetas vacías de `lib/core/{database,domain,router,theme,widgets}/` y `lib/features/{projects,stakeholders,sessions,glossary,audit_log}/{domain,data,presentation}/`
- [X] T007 [P] Escribir `tool/check_no_network_deps.dart`: falla si aparece cualquier paquete de red (dio, http, web_socket_channel, grpc) en el árbol resuelto de `pubspec.lock`. Es la verificación estructural de FR-019
- [X] T008 [P] Escribir `tool/check_dependencies.dart`: falla si alguna dependencia resuelta carece de null safety, no ha tenido publicación en los últimos 12 meses, o tiene licencia GPL/AGPL. Es la verificación automática de la prohibición constitucional de dependencias, que hasta ahora solo se había comprobado a mano
- [X] T009 [P] Escribir `tool/check_coverage.dart`: lee `coverage/lcov.info` y falla si la cobertura de las rutas `lib/features/*/domain/` baja del 80%
- [X] T010 Crear el workflow `.github/workflows/ci.yml` con seis puertas que bloqueen el merge: versión del toolchain, `dart analyze --fatal-infos`, código generado al día (`build_runner` + `git diff --exit-code`), `flutter test --coverage`, los tres scripts de `tool/`, y `flutter build ios --no-codesign` como verificación de que no entran dependencias exclusivas de Android (FR-023)

**Checkpoint**: `flutter analyze` pasa sobre un proyecto vacío y CI está en verde.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Base de datos completa en esquema versión 1, tipos compartidos de dominio,
navegación y andamiaje de pruebas.

**⚠️ CRITICAL**: Ninguna historia puede empezar hasta que esta fase termine.

**⚠️ Nota de diseño**: las **seis tablas se crean juntas** en esta fase, no una por historia.
FR-017 exige que la base de datos arranque en la versión 1 con una única migración inicial;
si cada historia añadiera su tabla, harían falta migraciones v1→v2→v3 y el requisito se
incumpliría. Es una consecuencia deliberada del requisito, no un atajo.

### Tipos compartidos de dominio

- [X] T011 [P] Definir `Result<T>` sealed con `Ok<T>` y `Err` en `lib/core/domain/result.dart`
- [X] T012 [P] Definir `sealed class Failure` con las siete variantes de data-model.md (`ValidationFailure`, `ProjectClosedFailure`, `InvalidSessionTransitionFailure`, `SessionHeaderFrozenFailure`, `CrossProjectReferenceFailure`, `NotFoundFailure`, `StorageFailure`) en `lib/core/domain/failures.dart`
- [X] T013 [P] Definir los tipos de identificador (`ProjectId`, `StakeholderId`, `SessionId`, `ScriptPointId`, `GlossaryTermId`, `AuditEntryId`) como extension types sobre `String` en `lib/core/domain/ids.dart`
- [X] T014 [P] Declarar el contrato `ProjectStatusReader` en `lib/core/domain/project_status_reader.dart`: es el **único** punto por el que una feature conoce el estado de un proyecto sin importar otra feature
- [X] T015 [P] Exponer el reloj como provider inyectable con `package:clock` en `lib/core/domain/clock_provider.dart`, para que `created_at`, `updated_at` y el orden de la bitácora sean deterministas en pruebas
- [X] T016 [P] Exponer un generador de identificadores inyectable en `lib/core/domain/id_generator.dart`, que acuña UUID v4 con `package:uuid` y admite override con una secuencia fija en pruebas. **Sin esto los identificadores persistidos serían impredecibles y ninguna prueba podría afirmar sobre ellos**, igual que ocurriría con las fechas sin el reloj de T015

### Base de datos (esquema versión 1 completo)

- [X] T017 Declarar las seis tablas drift en `lib/core/database/tables/`: `projects.dart`, `stakeholders.dart`, `sessions.dart` (con `session_participants`), `script_points.dart`, `glossary_terms.dart`, `audit_entries.dart`, con las columnas, tipos, nulabilidad e índices exactos de data-model.md. **Ninguna clave foránea usa `onDelete: cascade`**: nada se borra físicamente
- [X] T018 Crear `AppDatabase` en `lib/core/database/app_database.dart` con `schemaVersion => 1`, `MigrationStrategy` con `onCreate: (m) async => m.createAll()` **declarado explícitamente** aunque sea el comportamiento por defecto (FR-017), y `beforeOpen` que activa `PRAGMA foreign_keys = ON` y llama a `validateDatabaseSchema()` en modo debug. El constructor acepta un `QueryExecutor` inyectable para poder abrirla en memoria en pruebas
- [X] T019 Generar el snapshot del esquema con `dart run drift_dev make-migrations` y versionar `drift_schemas/drift_schema_v1.json` más la prueba generada en `test/drift/`
- [X] T020 Escribir la prueba de esquema en `test/drift/schema_v1_test.dart` con `SchemaVerifier` de `package:drift_dev/api/migrations_native.dart`, que verifica que una base creada desde cero coincide con el snapshot de la versión 1
- [X] T021 Registrar el provider de `AppDatabase` en `lib/core/database/database_provider.dart` con `@Riverpod(keepAlive: true)` y justificación escrita en el propio archivo (la conexión debe sobrevivir a la navegación)

### Navegación, tema y widgets compartidos

- [X] T022 [P] Definir el tema Material 3 en `lib/core/theme/app_theme.dart`
- [X] T023 [P] Implementar `AsyncScaffoldBody<T>` en `lib/core/widgets/async_scaffold_body.dart`: el **único** lugar del código donde vive el `switch` exhaustivo sobre `AsyncValue` sealed, resolviendo cargando, datos, vacío y error, con el caso vacío dentro de la rama de datos (FR-020)
- [X] T024 Definir el árbol de rutas de `go_router` en `lib/core/router/app_router.dart` con la jerarquía de FR-021 y `projectId` presente en toda ruta interior, apuntando de momento a pantallas de marcador de posición
- [X] T025 Escribir `lib/main.dart` con `ProviderScope` en la raíz, el tema y el router

### Andamiaje de pruebas

- [X] T026 [P] Escribir el helper `test/support/test_database.dart` que abre una `AppDatabase` sobre `NativeDatabase.memory()` con `closeStreamsSynchronously: true`, imprescindible para no dejar timers pendientes en `testWidgets`
- [X] T027 [P] Escribir el helper `test/support/test_container.dart` sobre `ProviderContainer.test()`, con overrides de repositorio, del reloj y del generador de identificadores, y con `retry: (_, __) => null` para desactivar el reintento automático de Riverpod 3 en las pruebas del camino de error, que de lo contrario reintentarían indefinidamente
- [X] T028 [P] Escribir `test/support/seed.dart` con constructores de datos de prueba para las seis entidades, de modo que cada historia pueda probarse sin depender de las demás

**Checkpoint**: base de datos en v1 verificada contra su snapshot, tipos compartidos listos y
andamiaje de pruebas operativo. Las historias pueden empezar.

---

## Phase 3: User Story 1 - Administrar proyectos (Priority: P1) 🎯 MVP

**Goal**: Crear, listar, abrir, editar y cerrar proyectos lógicamente, con el proyecto
cerrado en solo lectura y reapertura explícita.

**Independent Test**: crear un proyecto desde la pantalla inicial, editarlo, cerrarlo y
comprobar que sale de activos y aparece bajo el filtro de cerrados con sus datos intactos, y
reabrirlo para comprobar que vuelve a ser editable.

### Tests for User Story 1 ⚠️

> Escribir estas pruebas PRIMERO y verificar que fallan antes de implementar.

- [X] T029 [P] [US1] Pruebas de los casos de uso de proyecto en `test/unit/domain/projects/project_usecases_test.dart`: validación de `name` obligatorio, transición `active↔closed`, y que `UpdateProject` devuelve `ProjectClosedFailure` sobre un proyecto cerrado (invariante I5)
- [X] T030 [P] [US1] Prueba del DAO en `test/data/projects_dao_test.dart` sobre base en memoria: cerrar un proyecto **no borra ninguna fila** y deja exactamente un asiento en `audit_entries` dentro de la misma transacción (invariantes I1 e I2); `updated_at` cambia en toda escritura y `created_at` nunca (FR-016); `ProjectCounters` devuelve los tres conteos correctos tras altas y bajas lógicas (FR-013); y **`entity_label` conserva el nombre que el proyecto tenía al asentarse**, comprobado cerrando un proyecto, renombrándolo después de reabrirlo y verificando que el asiento antiguo sigue mostrando el nombre viejo
- [X] T031 [P] [US1] Prueba de Notifier en `test/unit/notifiers/project_list_test.dart` con `ProviderContainer.test()` y repositorio doble, cubriendo el filtro activos/cerrados
- [X] T032 [P] [US1] Prueba de widget en `test/widget/projects/project_list_screen_test.dart` que verifica las **cuatro** situaciones: cargando, con datos, vacía (con invitación a crear, no mensaje de ausencia) y con error
- [X] T033 [P] [US1] Prueba de widget del formulario en `test/widget/projects/project_form_screen_test.dart`: al fallar la validación no se guarda, se señala el campo y **se conserva lo escrito en el resto de campos** (FR-022)

### Implementation for User Story 1

- [X] T034 [P] [US1] Entidad `Project` inmutable con su enum `ProjectStatus` en `lib/features/projects/domain/entities/project.dart`
- [X] T035 [P] [US1] Objeto de valor `ProjectDraft` con las reglas de validación de data-model.md en `lib/features/projects/domain/entities/project_draft.dart`
- [X] T036 [P] [US1] Clase inmutable `ProjectCounters` (interesados, sesiones, términos) en `lib/features/projects/domain/entities/project_counters.dart`
- [X] T037 [US1] Contrato `ProjectRepository` en `lib/features/projects/domain/project_repository.dart` según [domain-contracts.md](contracts/domain-contracts.md)
- [X] T038 [P] [US1] Casos de uso `WatchActiveProjects`, `WatchClosedProjects` y `WatchProjectDetail` en `lib/features/projects/domain/usecases/`, uno por archivo
- [X] T039 [P] [US1] Casos de uso `CreateProject`, `UpdateProject`, `CloseProject` y `ReopenProject` en `lib/features/projects/domain/usecases/`, uno por archivo
- [X] T040 [US1] `ProjectsDao` en `lib/features/projects/data/projects_dao.dart` con el helper de filtrado por estado y la consulta de contadores por `COUNT` en SQL, nunca contando en Dart
- [X] T041 [US1] `ProjectRepositoryImpl` en `lib/features/projects/data/project_repository_impl.dart`: `setStatus` escribe el cambio de estado **y** su asiento de bitácora en una única transacción de drift, copiando en `entity_label` el nombre del proyecto en ese momento. **Este es el patrón que siguen las cinco implementaciones que escriben asientos** (T041, T057, T075, T089, T101): misma transacción y etiqueta copiada
- [X] T042 [US1] Implementar `ProjectStatusReader` sobre el DAO en `lib/features/projects/data/project_status_reader_impl.dart` y registrarlo en el provider declarado en T014
- [X] T043 [P] [US1] Pantalla y provider de lista en `lib/features/projects/presentation/project_list_{screen,provider}.dart`, con filtro activos/cerrados y un único provider que devuelve `AsyncValue<ProjectListState>`
- [X] T044 [P] [US1] Pantalla y provider de formulario en `lib/features/projects/presentation/project_form_{screen,provider}.dart`, conservando lo escrito cuando la validación falla (FR-022)
- [X] T045 [US1] Pantalla y provider de detalle en `lib/features/projects/presentation/project_detail_{screen,provider}.dart`, exponiendo `ProjectCounters` y la bandera `isReadOnly` que oculta las acciones de escritura en las pantallas hijas
- [X] T046 [US1] Mutaciones `createProject`, `saveProject`, `closeProject` y `reopenProject` en `lib/features/projects/presentation/project_mutations.dart`, como objetos `Mutation<T>` observables. **Prohibido** derivar el progreso de una bandera `isLoading` en el estado de pantalla
- [X] T047 [US1] Conectar las tres rutas de proyecto en `lib/core/router/app_router.dart`, sustituyendo los marcadores de posición

**Checkpoint**: US1 completa y demostrable por sí sola. Es el MVP.

---

## Phase 4: User Story 2 - Registrar interesados (Priority: P2)

**Goal**: Listar, crear, editar y desactivar interesados dentro de un proyecto.

**Independent Test**: con un proyecto creado, agregar varios interesados, editar uno,
desactivar otro y comprobar que el desactivado conserva su registro y que ningún listado
muestra interesados de otro proyecto.

### Tests for User Story 2 ⚠️

- [X] T048 [P] [US2] Pruebas de casos de uso en `test/unit/domain/stakeholders/stakeholder_usecases_test.dart`: `name` e `influence` obligatorios, y rechazo con `ProjectClosedFailure` si el proyecto está cerrado (invariante I5)
- [X] T049 [P] [US2] Prueba del DAO en `test/data/stakeholders_dao_test.dart`: desactivar conserva la fila y asienta bitácora; `updated_at` cambia en toda escritura (FR-016); y **el invariante I4**, que una consulta con dos proyectos poblados nunca devuelve interesados del otro
- [X] T050 [P] [US2] Prueba de Notifier en `test/unit/notifiers/stakeholder_list_test.dart` con `ProviderContainer.test()` y repositorio doble
- [X] T051 [P] [US2] Prueba de widget en `test/widget/stakeholders/stakeholder_list_screen_test.dart` con las cuatro situaciones

### Implementation for User Story 2

- [X] T052 [P] [US2] Entidad `Stakeholder` con su enum `InfluenceLevel` en `lib/features/stakeholders/domain/entities/stakeholder.dart`
- [X] T053 [P] [US2] `StakeholderDraft` con validaciones en `lib/features/stakeholders/domain/entities/stakeholder_draft.dart`
- [X] T054 [US2] Contrato `StakeholderRepository` en `lib/features/stakeholders/domain/stakeholder_repository.dart`, con `watchByProject` y `watchSelectableByProject` separados: el segundo devuelve solo activos y es lo que consumirá el selector de participantes de US3
- [X] T055 [P] [US2] Casos de uso `WatchStakeholders`, `CreateStakeholder`, `UpdateStakeholder` y `DeactivateStakeholder` en `lib/features/stakeholders/domain/usecases/`, uno por archivo, todos comprobando `ProjectStatusReader` antes de escribir
- [X] T056 [US2] `StakeholdersDao` en `lib/features/stakeholders/data/stakeholders_dao.dart` con el helper de filtrado por proyecto y estado
- [X] T057 [US2] `StakeholderRepositoryImpl` en `lib/features/stakeholders/data/stakeholder_repository_impl.dart`, con la desactivación y su asiento `stakeholderDeactivated` en una sola transacción, copiando en `entity_label` el nombre del interesado (patrón de T041)
- [X] T058 [P] [US2] Pantalla, provider y mutaciones de lista en `lib/features/stakeholders/presentation/stakeholder_list_{screen,provider}.dart` y `stakeholder_mutations.dart`, distinguiendo visiblemente los inactivos
- [X] T059 [P] [US2] Pantalla y provider de formulario en `lib/features/stakeholders/presentation/stakeholder_form_{screen,provider}.dart`
- [X] T060 [US2] Conectar las rutas de interesados en `lib/core/router/app_router.dart`

**Checkpoint**: US1 y US2 funcionan de forma independiente.

---

## Phase 5: User Story 3 - Planificar sesiones con participantes (Priority: P3)

**Goal**: Registrar sesiones con técnica, estado y participantes del mismo proyecto, con
avance de estado en un solo sentido y cabecera congelada tras cerrar.

**Independent Test**: con un proyecto y dos interesados, crear una sesión que referencie a
ambos, avanzar su estado hasta cerrada y comprobar que la cabecera deja de ser editable y
que nunca se ofrece retroceder.

**⚠️ Depende de US2**: FR-009 exige al menos un participante, así que una sesión no puede
crearse sin interesados. Las pruebas de dominio pueden aislarse con dobles, pero la demo
end-to-end requiere US2 terminada.

### Tests for User Story 3 ⚠️

- [X] T061 [P] [US3] **Prueba exhaustiva de la máquina de estados** en `test/unit/domain/sessions/session_transition_test.dart`: las nueve combinaciones de la tabla de data-model.md, verificando que todo retroceso devuelve `InvalidSessionTransitionFailure` (invariante I6)
- [X] T062 [P] [US3] Pruebas de casos de uso en `test/unit/domain/sessions/session_usecases_test.dart`: sesión sin participantes rechazada, participante de otro proyecto rechazado con `CrossProjectReferenceFailure` (invariante I8), `SessionHeaderFrozenFailure` al editar la cabecera de una sesión cerrada mientras las notas sí se aceptan (invariante I7), y **rechazo con `ProjectClosedFailure` de toda escritura cuando el proyecto está cerrado** (invariante I5)
- [X] T063 [P] [US3] Prueba del DAO en `test/data/sessions_dao_test.dart`: creación de sesión y participantes en una sola transacción; `updated_at` en toda escritura (FR-016); `SessionCounters` correcto por estado (FR-013); **invariante I9**, que eliminar una sesión con cinco puntos de guion deja exactamente **un** asiento `sessionDeleted` y **cero** filas modificadas en `script_points`, y que esos puntos dejan de listarse por visibilidad transitiva; e **invariante I10**, que un interesado desactivado sigue apareciendo entre los participantes de una sesión ya registrada
- [X] T064 [P] [US3] Prueba de Notifier en `test/unit/notifiers/session_list_test.dart` con `ProviderContainer.test()` y repositorio doble
- [X] T065 [P] [US3] Prueba de widget en `test/widget/sessions/session_form_screen_test.dart`: el selector de participantes no ofrece interesados inactivos ni de otro proyecto, y la cabecera se renderiza deshabilitada con la sesión cerrada
- [X] T066 [P] [US3] Prueba de widget en `test/widget/sessions/session_list_screen_test.dart` con las cuatro situaciones

### Implementation for User Story 3

- [X] T067 [P] [US3] Entidad `ElicitationSession` con los enums `SessionTechnique` y `SessionStatus` en `lib/features/sessions/domain/entities/elicitation_session.dart`
- [X] T068 [P] [US3] `SessionDraft` con validaciones en `lib/features/sessions/domain/entities/session_draft.dart`
- [X] T069 [P] [US3] Clase inmutable `SessionCounters` (pendientes, cubiertos, omitidos, total) en `lib/features/sessions/domain/entities/session_counters.dart`
- [X] T070 [US3] **Función pura** `transitionSession(from, to)` en `lib/features/sessions/domain/session_transition.dart`, que concentra FR-008a en un único punto probable de forma exhaustiva
- [X] T071 [US3] Contrato `SessionRepository` en `lib/features/sessions/domain/session_repository.dart`
- [X] T072 [P] [US3] Casos de uso `WatchSessions`, `WatchSessionDetail` y `CreateSession` en `lib/features/sessions/domain/usecases/`, uno por archivo
- [X] T073 [P] [US3] Casos de uso `UpdateSessionHeader`, `UpdateSessionNotes`, `AdvanceSessionStatus` y `DeleteSession` en `lib/features/sessions/domain/usecases/`, uno por archivo
- [X] T074 [US3] `SessionsDao` en `lib/features/sessions/data/sessions_dao.dart`, incluyendo la tabla de unión de participantes y la consulta de contadores de guion por estado
- [X] T075 [US3] `SessionRepositoryImpl` en `lib/features/sessions/data/session_repository_impl.dart`, con inserción de sesión y participantes en una transacción y el sellado de `closed_at` al cerrar. `softDelete` marca `deleted_at` y escribe **un solo** asiento `sessionDeleted` con `entity_label` en la misma transacción, y **no toca los puntos de guion** (patrón de T041 y cascada por visibilidad transitiva de data-model.md)
- [X] T076 [P] [US3] Pantalla, provider y mutaciones de lista en `lib/features/sessions/presentation/session_list_{screen,provider}.dart` y `session_mutations.dart`
- [X] T077 [P] [US3] Pantalla y provider de formulario en `lib/features/sessions/presentation/session_form_{screen,provider}.dart`, con el selector alimentado por `watchSelectableByProject` para que estructuralmente no pueda ofrecer interesados de otro proyecto
- [X] T078 [US3] Control de estado en `lib/features/sessions/presentation/session_status_control.dart`, que ofrece **solo** las transiciones válidas desde el estado actual
- [X] T079 [US3] Conectar las rutas de sesiones en `lib/core/router/app_router.dart`

**Checkpoint**: US1, US2 y US3 funcionan.

---

## Phase 6: User Story 4 - Armar y trabajar el guion (Priority: P4)

**Goal**: Lista ordenada de puntos por sesión, que se agregan, editan, reordenan, marcan y
eliminan lógicamente, incluso con la sesión cerrada.

**Independent Test**: con una sesión creada, agregar cinco puntos, reordenar dos, marcar dos
como cubiertos y uno como omitido, y comprobar que el orden y los estados persisten.

**⚠️ Depende de US3**: el guion pertenece a una sesión.

### Tests for User Story 4 ⚠️

- [X] T080 [P] [US4] **Prueba del invariante de posición I3** en `test/data/script_points_position_test.dart`: tras cualquier secuencia de agregar, reordenar y eliminar, las posiciones vivas de la sesión son exactamente `{0..n-1}`, sin huecos ni duplicados. Incluir movimientos a los extremos y reordenamientos repetidos. Añadir el caso de **visibilidad transitiva**: con la sesión eliminada lógicamente, `watchBySession` devuelve lista vacía aunque los puntos conserven `deleted_at` nulo
- [X] T081 [P] [US4] Pruebas de casos de uso en `test/unit/domain/sessions/script_point_usecases_test.dart`: `text` obligatorio, marcado libre entre los tres estados, y que editar el guion **sí** se permite con la sesión cerrada pero **no** con el proyecto cerrado (invariante I5)
- [X] T082 [P] [US4] Prueba de Notifier en `test/unit/notifiers/session_detail_test.dart` con `ProviderContainer.test()` y repositorios dobles, cubriendo el reordenamiento y el marcado
- [X] T083 [P] [US4] Prueba de widget en `test/widget/sessions/session_detail_screen_test.dart` con las cuatro situaciones y el guion vacío invitando a agregar el primer punto

### Implementation for User Story 4

- [X] T084 [P] [US4] Entidad `ScriptPoint` con su enum `ScriptPointStatus` en `lib/features/sessions/domain/entities/script_point.dart`
- [X] T085 [US4] Contrato `ScriptPointRepository` en `lib/features/sessions/domain/script_point_repository.dart`
- [X] T086 [P] [US4] Casos de uso `AddScriptPoint`, `UpdateScriptPointText` y `MarkScriptPoint` en `lib/features/sessions/domain/usecases/`, uno por archivo
- [X] T087 [P] [US4] Casos de uso `ReorderScriptPoint` y `DeleteScriptPoint` en `lib/features/sessions/domain/usecases/`, uno por archivo
- [X] T088 [US4] `ScriptPointsDao` en `lib/features/sessions/data/script_points_dao.dart` con el desplazamiento en bloque dentro de una transacción y la compactación de posiciones al eliminar, según la decisión 8 de research.md. El helper `alive()` **debe llevar dos condiciones**: `deleted_at IS NULL` del punto **y** que su sesión esté viva. Un simple filtro por el `deleted_at` del punto resucitaría los puntos de sesiones eliminadas (visibilidad transitiva, data-model.md)
- [X] T089 [US4] `ScriptPointRepositoryImpl` en `lib/features/sessions/data/script_point_repository_impl.dart`, con la eliminación lógica, la compactación de posiciones y el asiento `scriptPointDeleted` en una sola transacción, copiando en `entity_label` el texto del punto (patrón de T041)
- [X] T090 [US4] Ampliar el provider de detalle de sesión en `lib/features/sessions/presentation/session_detail_provider.dart` para que un **único** provider devuelva sesión, participantes, puntos y contadores, evitando multiplicar las re-consultas que provoca la invalidación por tabla de drift
- [X] T091 [US4] Widget de guion con `ReorderableListView` en `lib/features/sessions/presentation/script_point_list.dart`
- [X] T092 [US4] Mutaciones del guion en `lib/features/sessions/presentation/script_point_mutations.dart`

**Checkpoint**: el flujo completo del criterio de aceptación SC-001 ya es ejecutable.

---

## Phase 7: User Story 5 - Mantener el glosario (Priority: P5)

**Goal**: Términos del dominio por proyecto, listados alfabéticamente y editables libremente.

**Independent Test**: agregar varios términos en orden no alfabético y comprobar que la
lista los muestra ordenados ignorando mayúsculas y acentos.

### Tests for User Story 5 ⚠️

- [X] T093 [P] [US5] Prueba del DAO en `test/data/glossary_dao_test.dart`: el orden por `term_sort_key` ignora mayúsculas y acentos, con casos como "Ábaco", "abaco" y "Zeta"; eliminación lógica que conserva la fila y asienta bitácora; y `updated_at` en toda escritura (FR-016)
- [X] T094 [P] [US5] Pruebas de casos de uso en `test/unit/domain/glossary/glossary_usecases_test.dart`: `term` obligatorio, recálculo de `term_sort_key` en cada escritura, y rechazo con `ProjectClosedFailure` si el proyecto está cerrado (invariante I5)
- [X] T095 [P] [US5] Prueba de Notifier en `test/unit/notifiers/glossary_list_test.dart` con `ProviderContainer.test()` y repositorio doble
- [X] T096 [P] [US5] Pruebas de widget en `test/widget/glossary/glossary_{list,form}_screen_test.dart`: las cuatro situaciones en la lista, con el estado vacío invitando a agregar el primer término (FR-020, SC-005), y la conservación de lo escrito al fallar la validación del formulario (FR-022)

### Implementation for User Story 5

- [X] T097 [P] [US5] Entidades `GlossaryTerm` y `GlossaryTermDraft` en `lib/features/glossary/domain/entities/`
- [X] T098 [P] [US5] Función pura de normalización de `term_sort_key` (minúsculas y sin acentos) en `lib/features/glossary/domain/term_sort_key.dart`
- [X] T099 [US5] Contrato `GlossaryRepository` en `lib/features/glossary/domain/glossary_repository.dart`
- [X] T100 [P] [US5] Casos de uso `WatchGlossary`, `CreateGlossaryTerm`, `UpdateGlossaryTerm` y `DeleteGlossaryTerm` en `lib/features/glossary/domain/usecases/`, uno por archivo
- [X] T101 [US5] `GlossaryDao` y `GlossaryRepositoryImpl` en `lib/features/glossary/data/`, con el orden resuelto en SQL y nunca en Dart, y con la eliminación lógica y su asiento `glossaryTermDeleted` en una sola transacción, copiando en `entity_label` el término (patrón de T041)
- [X] T102 [P] [US5] Pantallas, providers y mutaciones de lista y formulario en `lib/features/glossary/presentation/`
- [X] T103 [US5] Conectar las rutas de glosario en `lib/core/router/app_router.dart`

**Checkpoint**: US1 a US5 funcionan.

---

## Phase 8: User Story 6 - Consultar la bitácora (Priority: P6)

**Goal**: Pantalla de solo lectura por proyecto con las operaciones lógicas asentadas.

**Independent Test**: con un proyecto que ya tuvo un interesado desactivado y un punto de
guion eliminado, abrir la bitácora y comprobar que ambos asientos aparecen con fecha y
operación, y que no hay ninguna acción de escritura.

**⚠️ Nota**: los asientos ya los escriben US1 a US5 dentro de sus transacciones. Esta
historia **solo lee** y no expone ninguna mutación.

### Tests for User Story 6 ⚠️

- [X] T104 [P] [US6] Prueba del DAO en `test/data/audit_dao_test.dart`: orden del más reciente al más antiguo y filtrado estricto por proyecto (invariante I4)
- [X] T105 [P] [US6] Prueba de Notifier en `test/unit/notifiers/audit_log_test.dart` con `ProviderContainer.test()` y repositorio doble
- [X] T106 [P] [US6] Prueba de widget en `test/widget/audit_log/audit_log_screen_test.dart`: el estado vacío **no** invita a crear nada, sino que explica que aún no hay operaciones asentadas, que es la excepción declarada a FR-020

### Implementation for User Story 6

- [X] T107 [P] [US6] Entidad `AuditEntry` con los enums `AuditOperation` y `AuditEntityType` en `lib/features/audit_log/domain/entities/audit_entry.dart`
- [X] T108 [US6] Contrato `AuditRepository` y caso de uso `WatchAuditLog` en `lib/features/audit_log/domain/`, **sin ninguna operación de escritura**
- [X] T109 [US6] `AuditDao` y `AuditRepositoryImpl` en `lib/features/audit_log/data/`
- [X] T110 [US6] Pantalla y provider en `lib/features/audit_log/presentation/audit_log_{screen,provider}.dart`, sin ninguna mutación, y conectar la ruta en `lib/core/router/app_router.dart`

**Checkpoint**: las seis historias funcionan.

---

## Phase 9: Polish & Cross-Cutting Concerns

- [X] T111 [P] Prueba de flujo completo en `integration_test/full_flow_test.dart` que ejecuta la validación V1 del quickstart: proyecto, tres interesados, sesión con dos participantes, guion de cinco puntos, reordenar y marcar dos como cubiertos
- [X] T112 [P] Prueba de persistencia en `integration_test/persistence_test.dart` (validación V2): cerrar y reabrir la aplicación conserva toda la información
- [X] T113 [P] Prueba de solo lectura y reapertura en `integration_test/closed_project_test.dart` (validación V3): con el proyecto cerrado ninguna acción de escritura está disponible en ninguna pantalla hija, y la reapertura restituye la edición
- [X] T114 [P] Prueba de aislamiento en `integration_test/project_isolation_test.dart` (validación V6): con dos proyectos poblados, ningún listado cruza datos
- [X] T115 Auditoría de importaciones: verificar que ningún archivo bajo `lib/features/*/domain/` importa `package:flutter`, que ningún widget importa `drift` ni DTOs, y que ninguna feature importa carpetas internas de otra
- [X] T116 Verificar la cobertura de `domain` con `dart run tool/check_coverage.dart --min 80` y completar las pruebas que falten hasta superar el umbral
- [X] T117 Ejecutar la validación manual completa del [quickstart.md](quickstart.md) (V1 a V8) en un dispositivo Android físico con modo avión activado
- [X] T118 [P] Documentar en `README.md` los comandos de puesta en marcha, generación de código y pruebas

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sin dependencias, empieza de inmediato
- **Foundational (Phase 2)**: depende de Setup. **Bloquea todas las historias**
- **User Stories (Phase 3–8)**: todas dependen de Foundational
- **Polish (Phase 9)**: depende de las historias que se quieran incluir

### User Story Dependencies

Este incremento **no** tiene seis historias mutuamente independientes, y conviene saberlo
antes de repartir trabajo:

| Historia | Depende de | Motivo |
|---|---|---|
| US1 Proyectos | — | Raíz del modelo |
| US2 Interesados | US1 | Un interesado pertenece a un proyecto |
| US3 Sesiones | US2 | FR-009 exige al menos un participante |
| US4 Guion | US3 | El guion pertenece a una sesión |
| US5 Glosario | US1 | Solo necesita un proyecto |
| US6 Bitácora | US1 | Lee asientos; su valor crece con US2–US5 |

Cada historia sigue siendo **independientemente probable** con dobles y datos sembrados
(`test/support/seed.dart`), pero la demo end-to-end sigue la cadena de la tabla.

**US5 y US6 son las únicas que pueden desarrollarse en paralelo real** con la cadena
US2→US3→US4, porque ambas dependen solo de que exista un proyecto. US6 se prueba con
asientos sembrados, sin esperar a que US2–US5 los produzcan.

### Within Each User Story

- Las pruebas se escriben primero y deben fallar antes de implementar
- Entidades → contratos → casos de uso → DAO → repositorio → presentación → ruta
- Los casos de uso de escritura consultan `ProjectStatusReader` antes de tocar la base

### Parallel Opportunities

- Fase 1: T004 a T009 en paralelo
- Fase 2: T011 a T016 en paralelo; después T022, T023, T026, T027 y T028 en paralelo
- Dentro de cada historia: todas las pruebas marcadas [P] a la vez, y luego las entidades [P]
- Entre historias: US5 en paralelo con la cadena US2→US3→US4

---

## Parallel Example: User Story 1

```bash
# Primero, las cinco pruebas de US1 a la vez (deben fallar):
Task: "Pruebas de casos de uso en test/unit/domain/projects/project_usecases_test.dart"
Task: "Prueba del DAO en test/data/projects_dao_test.dart"
Task: "Prueba de Notifier en test/unit/notifiers/project_list_test.dart"
Task: "Prueba de widget de lista en test/widget/projects/project_list_screen_test.dart"
Task: "Prueba de widget de formulario en test/widget/projects/project_form_screen_test.dart"

# Después, entidades y casos de uso en paralelo:
Task: "Entidad Project en lib/features/projects/domain/entities/project.dart"
Task: "ProjectDraft en lib/features/projects/domain/entities/project_draft.dart"
Task: "ProjectCounters en lib/features/projects/domain/entities/project_counters.dart"
Task: "Casos de uso de lectura en lib/features/projects/domain/usecases/"
Task: "Casos de uso de escritura en lib/features/projects/domain/usecases/"
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Fase 1: Setup
2. Fase 2: Foundational — crítica, bloquea todo
3. Fase 3: US1
4. **PARAR Y VALIDAR**: ejecutar V3 y V7 del quickstart sobre US1 sola
5. Ya hay algo demostrable: gestión de proyectos con cierre lógico y reapertura

### Incremental Delivery

1. Setup + Foundational → base lista
2. US1 → validar → **MVP**
3. US2 → validar
4. US3 → validar
5. US4 → validar → **aquí el criterio SC-001 del insumo ya se cumple entero**
6. US5 y US6 → validar
7. Fase 9 → validación completa en dispositivo físico

### Parallel Team Strategy

Con dos personas, tras Foundational: una toma la cadena US1→US2→US3→US4 y la otra arranca
US5 en cuanto US1 tenga el contrato de proyecto, y sigue con US6. Con una sola persona, el
orden de prioridad de la tabla de dependencias es también el orden de trabajo.

---

## Notes

- El proyecto exige pruebas por constitución: no son opcionales y CI bloquea el merge
- **Cada historia lleva su prueba de Notifier**: la puerta de cobertura del 80% mide solo
  `domain/`, así que no protege esa regla y la tarea explícita es lo único que la garantiza
- Las seis tablas se crean juntas en Foundational porque FR-017 impone una única migración
  inicial en la versión 1; no es un atajo sino una consecuencia del requisito
- Toda escritura se expone como `Mutation<T>`; las banderas `isLoading`/`hasError` en el
  estado de pantalla están prohibidas por la constitución
- Cada baja lógica y su asiento de bitácora van en la **misma** transacción de drift
- El reloj (T015) y el generador de identificadores (T016) se inyectan para que fechas e
  identificadores sean deterministas en pruebas
- Ejecutar `dart run build_runner build --delete-conflicting-outputs` tras cada tarea que
  añada o cambie un provider o una tabla
- Confirmar con un commit tras cada tarea o grupo lógico
