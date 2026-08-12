---

description: "Task list for 002-captura-transcripcion"
---

# Tasks: Captura y transcripción de entrevistas

**Input**: Design documents from `/specs/002-captura-transcripcion/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: **INCLUIDOS Y OBLIGATORIOS.** No son opcionales en este proyecto: la sección
Calidad de la constitución exige probar **casos de uso y Notifier** con `ProviderContainer` y
overrides, cobertura mínima del 80% en `domain`, y que CI bloquee el merge si fallan las
pruebas o la cobertura.

> **Regla que este incremento estrena**: la constitución exige además que **el transcriptor
> siempre se sustituya por un doble** y que ninguna prueba cargue un modelo Whisper ni abra el
> micrófono. `AudioRecorder`, `Transcriber`, `AudioPlayback` y `ModelRepository` son contratos
> de `domain` precisamente para que eso sea estructural: si una prueba los instanciara de
> verdad, tendría que importar `data/`, y la auditoría de importaciones lo detecta.

> **Aviso sobre la puerta de cobertura**: el umbral del 80% mide solo
> `lib/features/*/domain/`. Los Notifier viven en `presentation/`, así que esa puerta **no**
> los protege. Cada historia lleva su tarea de prueba de Notifier de forma explícita.

**Organization**: Tareas agrupadas por historia de usuario para poder implementarlas y
probarlas de forma independiente.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Se puede ejecutar en paralelo (archivos distintos, sin dependencias pendientes)
- **[Story]**: Historia a la que pertenece (US1…US6)
- Toda descripción lleva la ruta exacta del archivo

## Path Conventions

- Código: `lib/core/` (compartido) y `lib/features/<feature>/{domain,data,presentation}/`
- Pruebas: `test/unit/`, `test/data/`, `test/widget/`, `test/drift/`, `integration_test/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Incorporar las dependencias nativas y de red que este incremento estrena, y
**reescribir las puertas de CI** antes de escribir código que dependa de ellas. La puerta de
red cambia de sentido en este incremento; hacerlo primero evita un CI en rojo durante todo el
desarrollo.

- [X] T001 Verificar el toolchain con `flutter --version`: debe seguir en Flutter 3.44.9 con Dart 3.12.2 según la constitución v1.2.0. Si el canal stable se movió, anclar o enmendar antes de continuar
- [X] T002 **Reescribir** `tool/check_no_network_deps.dart`: la puerta pasa de "cero paquetes de red" (FR-019 del incremento 1) a dos comprobaciones nuevas — que ningún paquete de red **distinto de `dio`** entre en la clausura de `dependencies:`, y que `package:dio` se importe desde **exactamente un** archivo de `lib/`. Un segundo importador debe hacer fallar el script. Se hace **antes** de introducir `dio` para que CI no quede en rojo entre ambas tareas. Es la forma verificable de la excepción constitucional única (research.md, decisión 3)
- [X] T003 Añadir a `dependencies:` de `pubspec.yaml` las dependencias nuevas: `record: 7.1.1`, `whisper_ggml: 2.6.0`, `just_audio: 0.10.6`, `dio: 5.11.0` y `wakelock_plus: ^1.7.0`. ⚠️ **No tocar las cuatro versiones de Riverpod**: la restricción del Principio I sigue vigente
- [X] T004 Ejecutar `flutter pub get` y verificar en `pubspec.lock` que `whisper_ggml` arrastra `ffmpeg_kit_flutter_new_min` (variante **`_min`**, LGPL-3.0) y **no** la variante `-gpl`, que la constitución prohibiría
- [X] T005 Subir `minSdkVersion` a 24 en `android/app/build.gradle`: lo exige `ffmpeg_kit_flutter_new_min`. Sigue por debajo de Android 10 (API 29), que es el objetivo de producto
- [X] T006 [P] Declarar los permisos `RECORD_AUDIO` e `INTERNET` en `android/app/src/main/AndroidManifest.xml` según [quickstart.md](quickstart.md)
- [X] T007 [P] Declarar `NSMicrophoneUsageDescription` en `ios/Runner/Info.plist` con el texto de [quickstart.md](quickstart.md), que dice explícitamente que el audio nunca sale del dispositivo
- [X] T008 [P] Extender `tool/check_dependencies.dart` con un veto explícito a cualquier paquete cuyo nombre termine en `-gpl` o `_gpl`, para que una actualización futura de `whisper_ggml` no introduzca la variante GPL de ffmpeg sin que nadie lo note (research.md, decisión 7)
- [X] T008a [P] Escribir `tool/check_pinned_versions.dart`: falla si la versión resuelta en `pubspec.lock` de cualquier paquete anclado de forma exacta por la constitución —los cuatro de Riverpod y `drift`— no coincide **exactamente** con el número que la constitución v1.3.0 declara. Lo exige la viñeta "Verificación automática del anclaje" del Principio I, añadida precisamente porque el desajuste de drift (constitución 2.34.3 vs resuelto 2.34.0) sobrevivió a todo el incremento 1 y a una enmienda sin que nada lo detectara
- [X] T009 [P] Extender la auditoría de importaciones para verificar que `package:record`, `package:whisper_ggml` y `package:just_audio` se importen únicamente desde su archivo declarado en `lib/features/*/data/`, igual que ya se hace con `drift`
- [X] T010 [P] Crear la estructura de carpetas de las dos features nuevas: `lib/features/recordings/{domain,data,presentation}/` y `lib/features/transcription/{domain,data,presentation}/`, con subcarpetas `domain/{entities,contracts,usecases}/`
- [X] T011 Actualizar `.github/workflows/ci.yml` para que la puerta de red ejecute el script reescrito de T002 y para añadir `tool/check_pinned_versions.dart` (T008a) como puerta nueva, y verificar que CI queda en verde antes de continuar

**Checkpoint**: `flutter pub get` resuelve, `dart analyze` pasa y las siete puertas de CI están
en verde con las dependencias nuevas ya dentro.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Esquema en versión 2, tipos compartidos, contratos de infraestructura y dobles de
prueba. Ninguna historia puede empezar hasta que esta fase termine.

**⚠️ Nota de diseño**: las **cuatro tablas se crean juntas** en una sola migración v1→v2, no
una por historia. Es la misma consecuencia deliberada que en el incremento 1: si cada historia
añadiera su tabla harían falta migraciones v2→v3→v4→v5 sobre teléfonos que ya tienen datos
reales. Una sola migración aditiva no puede perder nada.

### Tipos compartidos de dominio

- [X] T012 [P] Añadir `RecordingId`, `LiveMarkId`, `TranscriptId` y `SegmentId` como extension types sobre `String` en `lib/core/domain/ids.dart`, siguiendo el patrón ya existente
- [X] T013 [P] Añadir los fallos nuevos en `lib/core/domain/failures.dart`: `MicrophonePermissionDenied`, `SessionNotInProgressFailure`, `RecordingAlreadyActiveFailure`, `NoActiveRecordingFailure`, `StorageFullFailure`, `ModelUnavailableFailure`, `DownloadFailure`, `TranscriptionFailure`, según [domain-contracts.md](contracts/domain-contracts.md)

### Esquema versión 2

- [X] T014 [P] Crear la tabla `Recordings` en `lib/core/database/tables/recordings.dart` con las columnas de [data-model.md](data-model.md): `id`, `session_id` (FK), `project_id`, `file_path` (relativa), `status`, `duration_ms`, `sample_rate`, `channels`, `started_at`, `stopped_at?`, `deleted_at?`, `created_at`, `updated_at`
- [X] T015 [P] Crear la tabla `LiveMarks` en `lib/core/database/tables/live_marks.dart` con `id`, `recording_id` (FK), `session_id`, `project_id`, `kind`, `at_ms`, `deleted_at?`, `created_at`, `updated_at`
- [X] T016 [P] Crear la tabla `Transcripts` en `lib/core/database/tables/transcripts.dart` con `id`, `recording_id` (FK), `session_id`, `project_id`, `pass`, `status`, `model_id`, `text?`, `failure_reason?`, `completed_at?`, `deleted_at?`, `created_at`, `updated_at`
- [X] T017 [P] Crear la tabla `TranscriptSegments` en `lib/core/database/tables/transcript_segments.dart` con `id`, `transcript_id` (FK), `recording_id`, `session_id`, `project_id`, `from_ms`, `to_ms`, `position`, `body`, `deleted_at?`, `created_at`, `updated_at`. ⚠️ La columna se llama `body` y **no** `text`: es la misma limitación de `drift_dev` ya documentada en `script_points.dart`
- [X] T018 Registrar las cuatro tablas en `@DriftDatabase` y subir `schemaVersion` a 2 en `lib/core/database/app_database.dart`, añadiendo un `onUpgrade` explícito que cree solo las tablas nuevas y sus índices cuando `from < 2`, sin tocar ninguna tabla del incremento 1
- [X] T019 Declarar los seis índices parciales de [data-model.md](data-model.md) en SQL crudo dentro de la migración, incluido el índice **único** `transcripts_one_per_pass` y el índice `segments_recording_time`, que no sirve a ninguna consulta de este incremento y se declara ahora para que el incremento 3 no necesite otra migración
- [X] T020 Ejecutar `dart run build_runner build --delete-conflicting-outputs` y luego `dart run drift_dev make-migrations` para generar `drift_schemas/drift_schema_v2.json`, **conservando** el v1 versionado

### Contratos de infraestructura

- [X] T021 [P] Declarar `AudioRecorder` y `RecorderState` en `lib/features/recordings/domain/contracts/audio_recorder.dart` según [domain-contracts.md](contracts/domain-contracts.md)
- [X] T022 [P] Declarar `WavSink` en `lib/features/recordings/domain/contracts/wav_sink.dart`
- [X] T023 [P] Declarar `AudioPlayback` en `lib/features/recordings/domain/contracts/audio_playback.dart`
- [X] T024 [P] Declarar `Transcriber`, `RawSegment`, `LiveTranscription` y `TranscriptionModel` en `lib/features/transcription/domain/contracts/transcriber.dart`
- [X] T025 [P] Declarar `ModelRepository`, `DownloadProgress` y `DownloadState` en `lib/features/transcription/domain/contracts/model_repository.dart`

### Andamiaje de pruebas

- [X] T026 [P] Escribir los dobles de prueba en `test/support/fake_audio_recorder.dart`, `test/support/fake_transcriber.dart`, `test/support/fake_audio_playback.dart` y `test/support/fake_model_repository.dart`, controlables desde la prueba (emiten estados y resultados a voluntad). Son los que garantizan que ninguna prueba abra el micrófono ni cargue un modelo
- [X] T027 Escribir la prueba de migración en `test/drift/schema_v2_test.dart` usando `SchemaVerifier` de `package:drift_dev/api/migrations_native.dart`: debe verificar **el paso de v1 a v2 con datos poblados**, no solo el esquema final. Verificar solo el resultado dejaría pasar una migración que funciona en instalación limpia y falla en actualización, que es el único caso que importa

**Checkpoint**: la base migra de v1 a v2 sin pérdida, los contratos compilan y los dobles están
listos. Las historias pueden empezar.

---

## Phase 3: User Story 1 - Grabar una entrevista durante la sesión (Priority: P1) 🎯 MVP

**Goal**: Capturar el audio de una entrevista y dejarlo asociado a la sesión, reproducible.

**Independent Test**: Con una sesión en curso, iniciar la grabación, hablar unos segundos,
detenerla, y verificar que el audio queda asociado a la sesión y se reproduce.

### Tests for User Story 1

> **Escribir primero y comprobar que fallan antes de implementar.**

- [X] T028 [P] [US1] Prueba de la cabecera WAV en `test/unit/domain/recordings/wav_header_test.dart`: verifica que `WavHeaderRepair.plan()` calcula bien `riffChunkSize`, `dataChunkSize` y `durationMs` a 16 kHz mono, incluidos archivo vacío y archivo con bytes sobrantes de una trama incompleta. **Es función pura**: la lógica más delicada del incremento se prueba sin grabar nada
- [X] T029 [P] [US1] Prueba de casos de uso en `test/unit/domain/recordings/start_stop_recording_test.dart`: `StartRecording` rechaza con `ProjectClosedFailure` si el proyecto está cerrado, con `SessionNotInProgressFailure` si la sesión está planeada o cerrada, con `MicrophonePermissionDenied` sin permiso y con `RecordingAlreadyActiveFailure` si ya hay una activa; `StopRecording` fija `duration_ms` y `stopped_at`
- [X] T030 [P] [US1] Prueba del DAO en `test/data/recordings_dao_test.dart` sobre `NativeDatabase.memory()`: alta, listado por sesión ordenado por `started_at`, baja lógica con asiento de bitácora en la misma transacción, **cascada que retira marcas, transcripciones y segmentos de esa grabación sin escribir asientos propios** (FR-023), y aislamiento por proyecto
- [X] T031 [P] [US1] Prueba de Notifier en `test/unit/notifiers/active_capture_test.dart` con `ProviderContainer.test()` y `FakeAudioRecorder`: el estado avanza de reposo a capturando, el tiempo transcurrido progresa y detener libera el recurso
- [X] T032 [P] [US1] Prueba de widget en `test/widget/recordings/session_capture_section_test.dart`: las cuatro situaciones, y sobre todo que el control de grabar **no aparece mientras el provider carga** (fallback fail-closed) ni con proyecto cerrado ni con sesión planeada
- [X] T032a [P] [US1] Prueba en `test/unit/domain/recordings/storage_full_test.dart`: cuando el escritor WAV falla por falta de espacio, la grabación pasa a `stopped` conservando el audio ya escrito, la cabecera se parchea con lo capturado y se devuelve `StorageFullFailure`. Es el caso borde de almacenamiento agotado del spec

### Implementation for User Story 1

- [X] T033 [P] [US1] Crear la entidad `Recording` y el enum `RecordingStatus` en `lib/features/recordings/domain/entities/recording.dart`, con las transiciones de estado de [data-model.md](data-model.md)
- [X] T034 [P] [US1] Implementar `WavHeaderRepair` como función pura en `lib/features/recordings/domain/wav_header_repair.dart`
- [X] T035 [US1] Declarar `RecordingRepository` en `lib/features/recordings/domain/contracts/recording_repository.dart` según [domain-contracts.md](contracts/domain-contracts.md)
- [X] T036 [P] [US1] Implementar los casos de uso `StartRecording`, `StopRecording` y `DeleteRecording` en `lib/features/recordings/domain/usecases/`, consultando `ProjectStatusReader` antes de toda escritura
- [X] T037 [US1] Implementar `RecordAudioRecorder` en `lib/features/recordings/data/record_audio_recorder.dart` sobre `record`, con `RecordConfig(encoder: pcm16bits, sampleRate: 16000, numChannels: 1)` y `audioInterruption` en su valor por defecto. **Único importador de `package:record`** en todo el árbol
- [X] T038 [US1] Implementar `WavFileSink` en `lib/features/recordings/data/wav_writer.dart`: escribe la cabecera RIFF de 44 bytes con los dos campos de tamaño **en cero**, anexa las tramas PCM conforme llegan y parchea ambos tamaños al cerrar. Es lo que hace recuperable una grabación interrumpida (research.md, decisión 4)
- [X] T038a [US1] Manejar el fallo de escritura por falta de espacio en `lib/features/recordings/data/wav_writer.dart` y propagarlo en `lib/features/recordings/presentation/active_capture_notifier.dart`: detener la captura, finalizar la cabecera con lo capturado e informar el motivo al analista **sin perder el audio ya grabado**
- [X] T039 [US1] Implementar `RecordingsDao` en `lib/features/recordings/data/recordings_dao.dart` y `RecordingRepositoryImpl`, con la baja lógica, su asiento `recordingDeleted` y la **cascada** que da de baja las marcas, transcripciones y segmentos de esa grabación, todo en la **misma transacción de drift**. La cascada no escribe asientos propios: FR-023 acota el incremento a no exponer eliminación individual de transcripciones ni segmentos
- [X] T040 [US1] Implementar `ActiveCaptureNotifier` en `lib/features/recordings/presentation/active_capture_notifier.dart` con `@Riverpod(keepAlive: true)` y **la justificación escrita en el código**: posee el flujo PCM y el escritor WAV, y con `autoDispose` navegar a otra pantalla a media entrevista destruiría la grabación en curso
- [X] T041 [US1] Implementar el bifurcador del flujo PCM en `lib/features/recordings/presentation/active_capture_notifier.dart`: un `StreamController` que alimenta al escritor WAV y deja un segundo suscriptor libre para la pasada en vivo de US4
- [X] T042 [US1] Implementar `sessionCaptureProvider` en `lib/features/recordings/presentation/session_capture_provider.dart` devolviendo `AsyncValue<SessionCaptureState>`, con `canRecord` calculado en el provider y **nunca** en el widget
- [X] T043 [US1] Implementar las mutaciones `startRecording`, `stopRecording` y `deleteRecording` como objetos `Mutation<T>` en `lib/features/recordings/presentation/recording_mutations.dart`
- [X] T044 [US1] Insertar la sección de captura en `lib/features/sessions/presentation/session_detail_screen.dart` usando `AsyncScaffoldBody`, con el fallback **fail-closed** `state.value?.canRecord ?? false`
- [X] T045 [US1] Activar `wakelock_plus` mientras la captura está activa y liberarlo al detener, en `lib/features/recordings/presentation/active_capture_notifier.dart`
- [X] T046 [US1] Ejecutar `dart run build_runner build --delete-conflicting-outputs` y verificar que las pruebas de T028 a T032a pasan

**Checkpoint**: se graba una entrevista y queda asociada a la sesión. Es el MVP del incremento.

---

## Phase 4: User Story 2 - Etiquetar momentos relevantes en vivo (Priority: P2)

**Goal**: Señalar momentos relevantes durante la entrevista sin interrumpir la conversación.

**Independent Test**: Durante una grabación activa, tocar marcadores de distinto tipo en
distintos instantes y verificar que cada marca quedó con su tipo y su instante correcto.

### Tests for User Story 2

- [X] T047 [P] [US2] Prueba de casos de uso en `test/unit/domain/recordings/live_mark_test.dart`: `PlaceLiveMark` rechaza con `NoActiveRecordingFailure` sin captura activa, calcula `at_ms` desde el inicio de **su grabación** y admite dos marcas en el mismo instante sin deduplicar; `ChangeMarkKind` funciona con la grabación ya detenida
- [X] T048 [P] [US2] Prueba del DAO en `test/data/live_marks_dao_test.dart`: listado por grabación ordenado por `at_ms`, cambio de tipo, y baja lógica con asiento `liveMarkDeleted` en la misma transacción
- [X] T049 [P] [US2] Prueba de Notifier en `test/unit/notifiers/live_marks_test.dart` con `ProviderContainer.test()`
- [X] T050 [P] [US2] Prueba de widget en `test/widget/recordings/live_mark_bar_test.dart`: los tres controles solo están visibles con captura activa y no interrumpida, y tocarlos **no abre ningún diálogo**

### Implementation for User Story 2

- [X] T051 [P] [US2] Crear la entidad `LiveMark` y el enum `LiveMarkKind` con exactamente tres valores —`requirement`, `doubt`, `quote`— en `lib/features/recordings/domain/entities/live_mark.dart`. Son los aclarados el 2026-08-11 y definen las ventanas de filtrado del incremento 3
- [X] T052 [US2] Declarar `LiveMarkRepository` en `lib/features/recordings/domain/contracts/live_mark_repository.dart`
- [X] T053 [P] [US2] Implementar los casos de uso `PlaceLiveMark`, `ChangeMarkKind`, `DeleteLiveMark` y `WatchMarks` en `lib/features/recordings/domain/usecases/`
- [X] T054 [US2] Implementar `LiveMarksDao` y `LiveMarkRepositoryImpl` en `lib/features/recordings/data/`, con la baja lógica y su asiento en la misma transacción
- [X] T055 [US2] Implementar las mutaciones `placeLiveMark`, `changeMarkKind` y `deleteLiveMark` en `lib/features/recordings/presentation/recording_mutations.dart`
- [X] T056 [US2] Implementar la barra de marcado en `lib/features/recordings/presentation/live_mark_bar.dart` con los tres botones y confirmación **pasiva y no bloqueante**: un diálogo rompería el propósito entero de la historia
- [X] T057 [US2] Mostrar la lista de marcas ordenada por instante, cada una con su tipo visible, en `lib/features/recordings/presentation/live_mark_list.dart`

**Checkpoint**: se marca en vivo sin interrumpir la captura, y las marcas se corrigen después.

---

## Phase 5: User Story 3 - Recuperar una grabación interrumpida (Priority: P3)

**Goal**: Que una interrupción —cierre inesperado o llamada entrante— nunca cueste una
entrevista.

**Independent Test**: Iniciar una grabación, forzar el cierre de la aplicación a mitad de la
captura, reabrirla y verificar que el audio se conservó y que la app ofrece cómo proceder.

### Tests for User Story 3

- [X] T058 [P] [US3] Prueba de recuperación en `test/unit/domain/recordings/recover_recording_test.dart`: `RecoverInterrupted` repara la cabecera en ambas ramas; `resume` deja la grabación en `recording` anexando al mismo archivo y `closeKeeping` la deja en `stopped` con la duración real
- [X] T059 [P] [US3] Prueba de detección de interrupción en `test/unit/notifiers/interruption_test.dart` con `FakeAudioRecorder`: una pausa **que el notifier no pidió** marca `interrupted`; una pausa pedida por la app, no
- [X] T060 [P] [US3] Prueba de arranque en `test/unit/domain/recordings/find_interrupted_test.dart`: al iniciar, una grabación que quedó en `recording` de una ejecución anterior se reporta como interrumpida
- [X] T061 [P] [US3] Prueba de widget en `test/widget/recordings/recovery_sheet_test.dart`: la hoja **no se puede descartar sin elegir**, y `resumeRecording` no se ofrece si la sesión ya se cerró

### Implementation for User Story 3

- [X] T062 [US3] Implementar `HandleInterruption` en `lib/features/recordings/domain/usecases/handle_interruption.dart`: marca `interrupted` conservando el archivo
- [X] T063 [US3] Implementar `RecoverInterrupted` con `RecoveryChoice` (`resume` | `closeKeeping`) en `lib/features/recordings/domain/usecases/recover_interrupted.dart`, aplicando `WavHeaderRepair` en ambas ramas
- [X] T064 [US3] Suscribir `ActiveCaptureNotifier` al stream `states` del grabador en `lib/features/recordings/presentation/active_capture_notifier.dart`, distinguiendo con un booleano las pausas propias de las impuestas por el sistema (llamada entrante)
- [X] T065 [US3] Implementar la detección al arrancar en `lib/features/recordings/presentation/session_capture_provider.dart`: `findInterrupted()` alimenta el campo `interrupted` del estado
- [X] T066 [US3] Implementar la hoja modal de recuperación en `lib/features/recordings/presentation/recovery_sheet.dart` con las dos acciones explícitas, **sin opción predeterminada** y sin poder descartarse sin elegir
- [X] T067 [US3] Implementar las mutaciones `resumeRecording` y `closeInterruptedRecording` en `lib/features/recordings/presentation/recording_mutations.dart`
- [X] T068 [US3] Permitir varias grabaciones por sesión (FR-003a) en el listado de `lib/features/recordings/presentation/session_capture_provider.dart`, ordenadas cronológicamente y cada una con su duración

**Checkpoint**: una interrupción por cualquiera de las dos causas deja de costar la entrevista.

---

## Phase 6: User Story 4 - Transcribir automáticamente la entrevista (Priority: P4)

**Goal**: Convertir el audio en segmentos de texto con ventana temporal, sin conexión.

**Independent Test**: Con una sesión con audio grabado y el modelo disponible, cerrarla y
verificar que produce una transcripción organizada en segmentos con inicio y fin.

> **Dependencia real con US6**: esta historia se implementa y se prueba entera con
> `FakeTranscriber` y `FakeModelRepository`, así que **no** está bloqueada por US6. Lo que sí
> necesita el modelo de verdad es la validación en dispositivo (V6 del quickstart). Si se
> trabaja en solitario, conviene adelantar US6 antes de esa validación.

### Tests for User Story 4

- [X] T069 [P] [US4] Prueba de `BuildInitialPrompt` en `test/unit/domain/transcription/initial_prompt_test.dart`: **función pura** que convierte el glosario en el `initialPrompt` y devuelve cadena vacía sin términos (FR-014)
- [X] T070 [P] [US4] Prueba de `RunFinalPass` en `test/unit/domain/transcription/final_pass_test.dart`: **sin modelo disponible devuelve `Ok` dejando el `Transcript` en `pending`**, no `Err` (FR-016); con modelo pasa a `processing` y luego a `done`; un fallo del transcriptor deja `failed` con `failure_reason`
- [X] T070a [P] [US4] Prueba en `test/unit/domain/transcription/final_pass_multi_test.dart`: una sesión con **dos** grabaciones produce dos transcripciones independientes al cerrarse, cada una con sus propios segmentos y sin que las marcas de tiempo de una contaminen a la otra (FR-003a)
- [X] T071 [P] [US4] Prueba de la barrera del modelo en `test/unit/domain/transcription/model_guard_test.dart`: verifica que `Transcriber` **no se invoca nunca** cuando `ModelRepository.isAvailable` devuelve `false`. Es la prueba que materializa el conflicto C3 de [plan.md](plan.md)
- [X] T072 [P] [US4] Prueba del mapeo de segmentos en `test/unit/domain/transcription/segment_mapping_test.dart`: `RawSegment` a `TranscriptSegment` con `position` contigua `0..n-1`, sin solapes y con `from_ms < to_ms` (invariantes S1 y S2)
- [X] T073 [P] [US4] Prueba del DAO en `test/data/transcripts_dao_test.dart`: el índice único impide dos transcripciones no borradas del mismo par (`recording_id`, `pass`), y `replaceSegments` corre en una sola transacción
- [X] T074 [P] [US4] Prueba de Notifier en `test/unit/notifiers/transcript_test.dart` con `FakeTranscriber`
- [X] T075 [P] [US4] Prueba de widget en `test/widget/transcription/transcript_view_test.dart`: `TranscriptPending` se presenta como **aviso con acción hacia ajustes, nunca como error**

### Implementation for User Story 4

- [X] T076 [P] [US4] Crear las entidades `Transcript`, `TranscriptSegment`, `TranscriptPass` y `TranscriptStatus` en `lib/features/transcription/domain/entities/`
- [X] T077 [P] [US4] Implementar `BuildInitialPrompt` como función pura en `lib/features/transcription/domain/usecases/build_initial_prompt.dart`, consumiendo el glosario del proyecto como lista plana de términos
- [X] T078 [US4] Declarar `TranscriptRepository` en `lib/features/transcription/domain/contracts/transcript_repository.dart`
- [X] T079 [US4] Implementar `RunFinalPass` en `lib/features/transcription/domain/usecases/run_final_pass.dart`, **comprobando `ModelRepository.isAvailable` antes de tocar el transcriptor** y devolviendo `Ok` con estado `pending` si falta el modelo
- [X] T080 [US4] Implementar `StartLivePass` en `lib/features/transcription/domain/usecases/start_live_pass.dart`, con la misma comprobación previa y sin hacer fallar la grabación si el modelo no está
- [X] T081 [US4] Implementar `WhisperTranscriber` en `lib/features/transcription/data/whisper_transcriber.dart` sobre `whisper_ggml`: `transcribe(model: small, lang: 'es', withSegments: true, initialPrompt: ...)` para la pasada definitiva y `transcribeLive(model: base, ...)` para la pasada en vivo. **Único importador de `package:whisper_ggml`**
- [X] T082 [US4] Implementar `TranscriptsDao` y `TranscriptRepositoryImpl` en `lib/features/transcription/data/`, con `replaceSegments` en una única transacción
- [X] T083 [US4] Conectar la pasada en vivo al segundo suscriptor del bifurcador de T041 en `lib/features/recordings/presentation/active_capture_notifier.dart`, volcando `partials` en el campo `livePartial` de `ActiveCapture`. **No se persiste**: vive en el notifier y muere al detener (FR-012)
- [X] T083a [US4] Implementar la zona de avance en vivo sobre la barra de marcado en `lib/features/recordings/presentation/live_mark_bar.dart`: altura acotada, desplazamiento automático, **sin interacción** —ni seleccionable ni tocable— y desaparece cuando `livePartial` es `null`. Es lo que da sentido a la pasada en vivo: el analista lee de reojo lo que se acaba de decir y decide si marcar
- [X] T083b [P] [US4] Prueba de widget en `test/widget/recordings/live_partial_test.dart`: la zona aparece con `livePartial` no nulo y desaparece con `null` sin desplazar los tres botones fuera de la vista, el texto **no** es seleccionable, y la captura sigue funcionando con la pasada en vivo ausente
- [X] T084 [US4] Disparar `RunFinalPass` al cerrar la sesión, **iterando sobre todas las grabaciones no borradas de la sesión** —una sesión puede tener varias (FR-003a)— y deteniendo antes la grabación que siguiera activa (FR-005). Cada grabación produce su propia transcripción con sus propios segmentos. Implementado en `lib/features/sessions/presentation/session_mutations.dart` (`runAdvanceSessionStatus`) y no en `session_detail_provider.dart`: el disparo es un efecto de la escritura de cierre (`Mutation<T>`, constitución Principio I), no una derivación del stream de lectura
- [X] T085 [US4] Implementar el sealed `TranscriptView` y su provider en `lib/features/transcription/presentation/transcript_provider.dart`, resolviendo `pending`, `running`, `ready` y `failed` sin banderas
- [X] T086 [US4] Implementar la vista de transcripción en `lib/features/transcription/presentation/transcript_section.dart`, con el aviso de `pending` enlazando a `/settings/models`

**Checkpoint**: una sesión cerrada produce segmentos con ventana temporal, y sin modelo queda
pendiente en vez de fallar.

---

## Phase 7: User Story 5 - Revisar la transcripción escuchando el segmento exacto (Priority: P5)

**Goal**: Confirmar que el texto es correcto saltando al audio de cada segmento.

**Independent Test**: Con una sesión transcrita, tocar distintos segmentos y verificar que la
reproducción salta al segundo correspondiente en cada caso.

### Tests for User Story 5

- [X] T087 [P] [US5] Prueba de `SeekToSegment` en `test/unit/domain/recordings/seek_to_segment_test.dart` con `FakeAudioPlayback`: resuelve `from_ms` del segmento y salta a esa posición
- [X] T088 [P] [US5] Prueba de `WatchActiveSegment` en `test/unit/domain/recordings/active_segment_test.dart`: cruza la posición del reproductor con las ventanas y devuelve `null` fuera de todo segmento
- [X] T089 [P] [US5] Prueba de widget en `test/widget/recordings/recording_detail_test.dart`: el reproductor funciona **sin transcripción** (FR-017) y el segmento activo se resalta conforme avanza la posición

### Implementation for User Story 5

- [X] T090 [US5] Implementar `JustAudioPlayback` en `lib/features/recordings/data/just_audio_player.dart` sobre `just_audio`, resolviendo la ruta relativa contra el sandbox. **Único importador de `package:just_audio`**
- [X] T091 [P] [US5] Implementar los casos de uso `LoadRecordingForPlayback`, `SeekToSegment` y `WatchActiveSegment` en `lib/features/recordings/domain/usecases/`
- [X] T092 [US5] Implementar `recordingDetailProvider` en `lib/features/recordings/presentation/recording_detail_provider.dart` devolviendo `AsyncValue<RecordingDetailState>` con grabación e `isReadOnly`. Marcas y transcripción quedan fuera a propósito: `LiveMarkList` y `TranscriptSection` ya son secciones autocontenidas con su propio provider (mismo criterio con el que `SessionDetailState` no incluye la captura), y el estado de reproducción vive en `RecordingPlaybackNotifier` (`recording_playback_notifier.dart`), nuevo, `autoDispose`
- [X] T093 [US5] Implementar la pantalla de detalle de grabación en `lib/features/recordings/presentation/recording_detail_screen.dart` con reproductor, marcas y transcripción. Se añadió navegación desde `_RecordingTile` en `session_capture_section.dart` (`ui-contracts.md` pantalla 1: "Navega a"), que antes no era alcanzable
- [X] T094 [US5] Registrar la ruta `/projects/:pid/sessions/:sid/recordings/:rid` en `lib/core/router/app_router.dart`
- [X] T095 [US5] Implementar el resaltado del segmento activo a partir del stream de posición, sin temporizador propio, en `lib/features/transcription/presentation/transcript_section.dart`, vía el nuevo `activeSegmentProvider` en `transcript_provider.dart`. Tocar un segmento dispara `seekToSegment` (nueva `Mutation<void>` en `recording_mutations.dart`)

**Checkpoint**: la transcripción se revisa contra el audio segmento a segmento.

---

## Phase 8: User Story 6 - Preparar el modelo de transcripción desde ajustes (Priority: P6)

**Goal**: Descargar el modelo de forma manual, observable y cancelable, sin que el paquete lo
haga por su cuenta.

**Independent Test**: Desde ajustes, iniciar la descarga, ver el progreso y confirmar que al
terminar queda disponible, sin que ninguna otra pantalla haya requerido conexión.

### Tests for User Story 6

- [X] T096 [P] [US6] Prueba de `DownloadModel` en `test/unit/domain/transcription/download_model_test.dart` con doble del cliente: emite progreso, y al completar dispara `ProcessPendingTranscripts`
- [X] T097 [P] [US6] Prueba de atomicidad en `test/unit/domain/transcription/download_atomicity_test.dart`: una descarga cancelada o fallida **no deja ningún modelo utilizable** (FR-022), y reintentar sobrescribe el `.part`. Usa un `HttpClientAdapter` de `dio` guionado en vez de la red real: ninguna prueba llama a la API real
- [X] T098 [P] [US6] Prueba de `ProcessPendingTranscripts` en `test/unit/domain/transcription/process_pending_test.dart`: recorre `findPending()` y lanza la pasada definitiva de cada uno
- [X] T099 [P] [US6] Prueba de widget en `test/widget/transcription/model_settings_test.dart`: sin `Content-Length` la barra es indeterminada y **no se inventa un porcentaje**

### Implementation for User Story 6

- [X] T100 [P] [US6] Crear la entidad `ModelEntry` y el enum `ModelStatus` en `lib/features/transcription/domain/entities/model_entry.dart`
- [X] T101 [US6] Implementar `ModelDownloadClient` en `lib/features/transcription/data/model_download_client.dart` sobre `dio`, con `onReceiveProgress` y `CancelToken`, escribiendo a `<ruta>.part` y renombrando de forma atómica al completar. **ÚNICO importador de `package:dio` en todo el árbol**, verificado por la puerta de CI de T002. La ruta destino y la URL de descarga son inyectables (`resolvePath`/`resolveUrl`, por defecto `whisperModelPath`/`whisperModelDownloadUrl` de `whisper_transcriber.dart`) para poder probarse sin tocar `path_provider` ni la red
- [X] T102 [US6] Implementar `ModelRepositoryImpl` en `lib/features/transcription/data/model_repository_impl.dart`, resolviendo la ruta destino con `whisperModelPath` (`whisper_transcriber.dart`), que envuelve `WhisperController.getPath(model)` para garantizar que el nombre de archivo es el que el paquete espera. **Reemplaza** el `UnavailableModelRepository` placeholder que T079/T080 (US4) dejaron en ese mismo archivo. `whisperModelPath`/`whisperModelDownloadUrl` viven en `whisper_transcriber.dart` y no aquí porque ese es el único archivo autorizado a importar `package:whisper_ggml` (tool/check_import_boundaries.dart); `ModelRepositoryImpl` y `ModelDownloadClient` los consumen sin importar el paquete
- [X] T103 [P] [US6] Implementar los casos de uso `WatchModelStatus`, `DownloadModel`, `CancelModelDownload` y `ProcessPendingTranscripts` en `lib/features/transcription/domain/usecases/`. `RunFinalPass`, `ProcessPendingTranscripts` y `DownloadModel` pasan a `keepAlive`: los lee en cadena `ModelDownloadNotifier` (presentation, keepAlive), y riverpod_lint exige que un provider keepAlive no dependa de uno autoDispose
- [X] T104 [US6] Implementar `modelSettingsProvider` en `lib/features/transcription/presentation/model_settings_provider.dart` con el contador de transcripciones pendientes. El progreso por modelo viene de `ModelDownloadNotifier` (nuevo, `model_download_notifier.dart`, `keepAlive` para que una descarga larga no muera si el analista sale de ajustes), no de la propia `Mutation`
- [X] T105 [US6] Implementar las mutaciones `downloadModel` y `cancelModelDownload` en `lib/features/transcription/presentation/model_mutations.dart`
- [X] T106 [US6] Implementar la pantalla de ajustes en `lib/features/transcription/presentation/model_settings_screen.dart` con los dos modelos, su estado y su progreso
- [X] T107 [US6] Registrar la ruta `/settings/models` en `lib/core/router/app_router.dart`, colgando de la raíz y **no** de un proyecto: el modelo es del dispositivo

**Checkpoint**: todas las historias funcionan de forma independiente.

---

## Phase 9: Polish, Cross-Cutting Concerns & Validation

**Purpose**: Cerrar el incremento y **medir**, que es su propósito declarado en el roadmap.

- [X] T108 [P] Auditoría de importaciones: verificar que `record`, `whisper_ggml`, `just_audio` y `dio` se importan cada uno desde un solo archivo de `data/`, que ningún archivo de `domain/` importa `package:flutter`, que ningún widget importa `drift` ni DTOs, y que **el único uso de `dio` es un `GET` de descarga**: ningún `post`, `put` ni `FormData` puede aparecer en `model_download_client.dart`. Es la verificación estructural de que el audio jamás sale del dispositivo (Principio II). Las cuatro comprobaciones se añadieron como puertas permanentes en `tool/check_import_boundaries.dart` (antes solo cubría domain/flutter y el confinamiento de paquetes nativos), no como una verificación puntual
- [X] T109 Verificar la cobertura de `domain` con `dart run tool/check_coverage.dart --min 80` y completar las pruebas que falten. Estaba en 71.39%; se cerró a **87.85%** con pruebas de entidad (`==`/`hashCode`/`toString`/`copyWith` de `Recording`, `LiveMark`, `Transcript`, `TranscriptSegment`, `ModelEntry`, casi sin cubrir) y pruebas que leen los casos de uso menores vía `ProviderContainer` (`DeleteRecording`, `DeleteLiveMark`, `ChangeMarkKind`, `FindInterrupted`, `RecoverInterrupted`, `HandleStorageFull`, `SeekToSegment`, `CancelModelDownload`, `WatchModelStatus`), que antes solo estaban cubiertos por instanciación directa (sin la línea del provider) o nada en absoluto
- [ ] T110 [P] Prueba de flujo completo en `integration_test/recording_flow_test.dart` (validaciones V1 y V2): grabar, marcar, detener y reproducir — **TODO, bloqueada por un fallo real detectado en dispositivo físico (2026-08-12)**: ver el comentario `TODO(device-run 2026-08-12)` en el propio archivo, junto al segundo `find.widgetWithText(FilledButton, 'Guardar')`. En Android 16 (API 36) real, `scrollUntilVisible` lanza `StateError: Bad state: No element` — el botón "Guardar" del formulario de "Nueva sesión" no se encuentra en absoluto. Descartado: no es `isReadOnly` (`CreateProject` fija `status: ProjectStatus.active` y `ProjectStatusReaderImpl.isActive` lo lee bien). Sin diagnosticar todavía si es un bug de la app o del arnés de prueba
- [ ] T111 [P] Prueba de flujo en `integration_test/interrupted_recovery_test.dart` (validación V3): simular la interrupción y verificar ambas ramas de recuperación — **no ejecutada todavía**; comparte el mismo helper de creación de sesión que T110, así que es sospechosa del mismo bloqueo hasta que se confirme lo contrario
- [ ] T112 [P] Prueba de flujo en `integration_test/transcription_flow_test.dart` (validaciones V4 y V6) con `FakeTranscriber`: transcripción pendiente sin modelo, y segmentos con salto de reproducción con modelo — **no ejecutada todavía**, misma sospecha que T111
- [ ] T113 [P] Prueba de aislamiento en `integration_test/recording_isolation_test.dart` (validación V7): con dos proyectos poblados, ningún listado de grabaciones cruza datos — **no ejecutada todavía**, misma sospecha que T111
- [ ] T114 [P] Prueba de solo lectura en `integration_test/closed_project_capture_test.dart` (validación V8): con proyecto cerrado, el control de grabar **no aparece en ningún instante**, ni siquiera durante la carga — **no ejecutada todavía** (esta no crea sesión, así que podría no compartir el bloqueo de T110-T113; queda por comprobar)
  - **T110–T114, estado real a partir de esta sesión con dispositivo conectado**: los cinco archivos existen y pasan `dart analyze`, y doblan todo el hardware/red vía `integration_test/support/hardware_fakes.dart`. La sesión anterior no pudo ejecutarlos por falta de dispositivo; **esta sesión sí tuvo un Android físico conectado** y, al ejecutar T110 de verdad, encontró el fallo descrito arriba — así que la advertencia "sin verificar" quedó resuelta a "verificada y falla". Antes de llegar ahí hubo que resolver tres problemas de compilación Android reales, ninguno relacionado con el código Dart ni con este incremento en particular — son gaps de configuración Gradle/Android que ningún build anterior había ejercitado en dispositivo real: `kotlin.incremental=false` en `android/gradle.properties` (el compilador incremental de Kotlin falla al calcular rutas relativas entre unidades en distintas letras de unidad de Windows — pub cache en `C:`, proyecto en `D:`), `compileSdk`/`ndkVersion` explícitos en `android/app/build.gradle.kts` (los valores por defecto de `flutter.compileSdkVersion`/`flutter.ndkVersion` con Flutter 3.44.9 resuelven a 34/28.2, insuficientes para `whisper_ggml`/`ffmpeg_kit_flutter_new_min`), y `compileSdk` forzado a 36 en todos los subproyectos desde `android/build.gradle.kts` (el propio `android/build.gradle` de `whisper_ggml` 2.6.0 fija `compileSdk 34` de forma hardcodeada, por debajo de lo que exige su propia dependencia `ffmpeg_kit_flutter_new_min`). De paso se había corregido ya un defecto real en una sesión previa: `integration_test/support/test_app.dart` (`pumpTestApp`) nunca sobreescribía `sessionStatusReaderProvider` como sí hace `main.dart`
- [X] T115 [P] Documentar en `README.md` los comandos nuevos y el requisito de descargar el modelo antes de transcribir
- [ ] T116 Ejecutar las validaciones manuales V1 a V5 y V7 a V9 del [quickstart.md](quickstart.md) en un dispositivo Android físico — **ya no bloqueado por falta de hardware** (esta sesión tuvo un Android físico, API 36, conectado), pero todavía no ejecutado. Recomendado arreglar primero el bug de T110 (el formulario de "Nueva sesión" es un paso obligatorio de V1), o al menos confirmar a mano si el botón "Guardar" aparece de verdad en uso manual normal — la prueba automática pudo estar topándose con un problema propio del arnés, no de la app
- [ ] T117 Ejecutar la validación V6 del [quickstart.md](quickstart.md) con una entrevista real de al menos 5 minutos en español, con dos voces y ruido de fondo, y **registrar las seis mediciones** de la tabla: duración de la pasada definitiva, su relación con la duración del audio, errores por minuto, aporte del glosario, impacto de la pasada en vivo y consumo de batería — sigue pendiente de una entrevista real grabada por una persona; ya no bloqueado por hardware
- [ ] T118 Fijar en [research.md](research.md) los valores definitivos de los modelos y de los tres parámetros del gate de silencio (`gateRmsMin`, `gateVoiceRatio`, `gateNoiseFloorCap`) a partir de lo medido en T117, sustituyendo los valores de arranque — **bloqueado**: depende de T117
- [ ] T119 Anotar lo aprendido en [roadmap.md](../../roadmap.md) y marcar el incremento 2 como hecho. **La regla 2 del roadmap lo exige antes de especificar el incremento 3**: ese incremento fija tamaño de bloque, traslape y umbral léxico contra la transcripción real que este produce, y especificarlo sin estos números sería inventarlos — **bloqueado**: depende de T117/T118

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Fase 1)**: sin dependencias. Reescribir la puerta de red **antes** de añadir `dio` evita un CI en rojo durante todo el desarrollo
- **Foundational (Fase 2)**: depende de Setup. **Bloquea todas las historias**
- **US1 (Fase 3)**: depende de Foundational. Sin dependencias de otras historias
- **US2 (Fase 4)**: depende de US1 — no hay dónde colocar marcas sin captura activa
- **US3 (Fase 5)**: depende de US1. Reutiliza el escritor WAV de T038 y el notifier de T040
- **US4 (Fase 6)**: depende de US1 para el audio y del bifurcador de T041 para la pasada en vivo. **No depende de US6**: se prueba entera con dobles
- **US5 (Fase 7)**: depende de US4 para los segmentos; el reproductor solo depende de US1
- **US6 (Fase 8)**: depende de Foundational. **Independiente de US4** en implementación
- **Polish (Fase 9)**: depende de todas

### Within Each User Story

- Las pruebas se escriben primero y deben fallar antes de implementar
- Entidades → contratos → casos de uso → DAO → repositorio → presentación → ruta
- Los casos de uso de escritura consultan `ProjectStatusReader` antes de tocar la base
- Todo camino hacia `Transcriber` pasa antes por `ModelRepository.isAvailable`

### Parallel Opportunities

- Fase 1: T006, T007, T008, T009 y T010 en paralelo, una vez hechas T002 a T005
- Fase 2: T012 y T013 en paralelo; luego T014 a T017 en paralelo; luego T021 a T026 en paralelo
- Dentro de cada historia: todas las pruebas marcadas [P] a la vez, y luego las entidades [P]
- Entre historias: **US6 en paralelo con toda la cadena US1→US2→US3→US4→US5**, porque no comparte ningún archivo con ella

---

## Parallel Example: User Story 1

```bash
# Primero, las cinco pruebas de US1 a la vez (deben fallar):
Task: "Prueba de cabecera WAV en test/unit/domain/recordings/wav_header_test.dart"
Task: "Pruebas de casos de uso en test/unit/domain/recordings/start_stop_recording_test.dart"
Task: "Prueba del DAO en test/data/recordings_dao_test.dart"
Task: "Prueba de Notifier en test/unit/notifiers/active_capture_test.dart"
Task: "Prueba de widget en test/widget/recordings/session_capture_section_test.dart"

# Después, entidad y función pura en paralelo:
Task: "Entidad Recording en lib/features/recordings/domain/entities/recording.dart"
Task: "WavHeaderRepair en lib/features/recordings/domain/wav_header_repair.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Fase 1: Setup — reescribir las puertas de CI primero
2. Fase 2: Foundational — crítica, bloquea todo
3. Fase 3: US1
4. **PARAR Y VALIDAR**: ejecutar V1 del quickstart en dispositivo físico
5. Ya hay algo demostrable: grabar una entrevista y reproducirla

### Incremental Delivery

1. Setup + Foundational → base lista
2. US1 → validar → **MVP**
3. US2 → validar
4. US3 → validar → **aquí la entrevista deja de ser perdible, que es el valor central**
5. US6 → validar (adelantada a propósito: desbloquea la validación real de US4)
6. US4 → validar con modelo real
7. US5 → validar
8. Fase 9 → medición y cierre

**Por qué US6 se adelanta en la práctica**: su prioridad es P6 porque se ejecuta una sola vez y
no compite en frecuencia con el trabajo de campo. Pero sin ella no se puede validar US4 en
dispositivo con un modelo de verdad, y la medición de T117 es el propósito declarado del
incremento. Implementarla antes que US4 no cambia ninguna prioridad del spec: cambia el orden
en que se descubren los problemas.

### Parallel Team Strategy

Con dos personas, tras Foundational: una toma la cadena US1→US2→US3→US4→US5 y la otra arranca
US6 de inmediato, porque no comparte ningún archivo con esa cadena. Con una sola persona, el
orden de la entrega incremental de arriba es también el orden de trabajo.

---

## Notes

- El proyecto exige pruebas por constitución: no son opcionales y CI bloquea el merge
- **Ninguna prueba abre el micrófono ni carga un modelo Whisper**: los cuatro dobles de T026
  son lo que lo garantiza, y la auditoría de importaciones de T108 lo verifica
- Las cuatro tablas se crean juntas en una sola migración v1→v2 sobre teléfonos que ya tienen
  datos reales; no es un atajo sino lo que impide perderlos
- **La barrera del modelo (T071, T079, T080) es la tarea constitucionalmente delicada del
  incremento**: es lo único que impide que `whisper_ggml` dispare su descarga automática, que
  sería una petición de red no iniciada por el usuario
- El `keepAlive` de T040 es la primera excepción real a `autoDispose` del proyecto y la
  constitución exige justificarla **en el código**, no solo aquí
- El fallback de solo lectura es **fail-closed** (`?? false`) en toda pantalla nueva: es el
  aprendizaje de la validación del incremento 1 ya anotado en el roadmap
- Cada baja lógica y su asiento de bitácora van en la **misma** transacción de drift
- Ejecutar `dart run build_runner build --delete-conflicting-outputs` tras cada tarea que
  añada o cambie un provider o una tabla, y `dart run drift_dev make-migrations` tras cambiar
  el esquema
- Confirmar con un commit tras cada tarea o grupo lógico
