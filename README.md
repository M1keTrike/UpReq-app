# up_req

Levantamiento de requerimientos de software en campo. Aplicación Flutter
personal, monousuario y sin servidor: proyectos, interesados, sesiones de
elicitación, guion, glosario y bitácora, todo persistido localmente con
[drift](https://drift.simonbinder.eu/) sobre SQLite (incremento 1); grabación
de entrevistas, marcado en vivo y transcripción local con Whisper vía
`whisper_ggml` (incremento 2). Sin dependencias de red salvo una única
excepción declarada: la descarga manual del modelo de transcripción (ver
[Modelo de transcripción](#modelo-de-transcripción) más abajo y
`tool/check_no_network_deps.dart`).

Los detalles de diseño viven en `specs/001-proyectos-interesados-sesiones/` y
`specs/002-captura-transcripcion/` (`spec.md`, `plan.md`, `data-model.md`,
`contracts/`, `tasks.md`, `quickstart.md` en cada carpeta). Este README solo
cubre los comandos para levantar el proyecto, generar código y correr las
pruebas.

## Requisitos

| Herramienta | Versión |
|---|---|
| Flutter | 3.44.9 |
| Dart | 3.12.2 (viene con el Flutter anterior) |

```bash
flutter --version
```

## Puesta en marcha

```bash
flutter pub get
```

Generar el código de `riverpod_generator` y `drift_dev` (providers `.g.dart`,
DAOs, tablas):

```bash
dart run build_runner build --delete-conflicting-outputs
```

Vuelve a ejecutarse cada vez que cambie un provider anotado con `@riverpod` o
una tabla de drift. Si además cambia el esquema de la base de datos, hay que
regenerar también el snapshot versionado:

```bash
dart run drift_dev make-migrations
```

Esto actualiza el snapshot versionado más reciente (`drift_schemas/`,
actualmente hasta `drift_schema_v2.json` — el incremento 2 subió el esquema a
la versión 2 de forma aditiva) y la prueba de migración en `test/drift/`.

Ejecutar la app (dispositivo Android/iOS conectado, emulador, o `-d windows`
si se agrega soporte de escritorio más adelante — hoy el proyecto solo
declara las plataformas `android` e `ios`). El incremento 2 sube
`minSdkVersion` a 24 (lo exige `ffmpeg_kit_flutter_new_min`, dependencia
transitiva de `whisper_ggml`) y pide permiso de micrófono en el primer uso:

```bash
flutter run
```

## Modelo de transcripción

La transcripción (incremento 2) no funciona hasta que el modelo GGML se
descarga manualmente desde **Ajustes → Modelos de transcripción**
(`/settings/models`). Es la única operación de red de todo el proyecto y
**nunca** ocurre por su cuenta: cerrar una sesión sin el modelo descargado
deja esa entrevista en pantalla como "Transcripción pendiente" —no como
error—; el audio se conserva y la transcripción se procesa sola en cuanto el
modelo termina de descargarse (FR-016, FR-020 a FR-022).

Hay dos modelos, cada uno con su propio archivo a descargar la primera vez:
`base` para la pasada en vivo durante la grabación (texto aproximado, no se
persiste) y `small` para la pasada definitiva al cerrar la sesión (con
segmentos y marcas de tiempo, la que sí queda guardada). Ninguna pantalla
distinta de Ajustes toca la red.

## Pruebas

Suite completa (pruebas unitarias, de DAO sobre SQLite en memoria, de widget
y de esquema):

```bash
flutter test
```

Con cobertura (genera `coverage/lcov.info`):

```bash
flutter test --coverage
```

Pruebas de integración, que recorren la app real de punta a punta con
`go_router` y una base de datos SQLite real (en memoria o respaldada por
archivo, según el caso). Las del incremento 2 (captura, marcado,
recuperación de interrupciones, transcripción) doblan el micrófono, el
escritor WAV, el transcriptor, el modelo y el reproductor
(`integration_test/support/hardware_fakes.dart`) — nunca tocan hardware ni
red real, igual que las pruebas unitarias. **Requieren un dispositivo o
emulador Android/iOS**: `integration_test/` no corre sobre el motor de
pruebas del host ni sobre escritorio/web en este proyecto (varios paquetes
nativos —`drift` con `NativeDatabase`, `record`, `whisper_ggml`— no tienen
implementación web, y no hay soporte de escritorio declarado). Si
`flutter devices` no reporta ningún dispositivo Android/iOS, estas pruebas
no pueden ejecutarse en absoluto — es la misma limitación que las
validaciones manuales en dispositivo físico del incremento 2:

```bash
flutter test integration_test/
```

Para correr un solo archivo, o apuntar a un dispositivo concreto cuando hay
varios conectados (`flutter devices` para listarlos):

```bash
flutter test integration_test/full_flow_test.dart -d <deviceId>
```

## Análisis estático

Incluye las reglas de `riverpod_lint` (declaradas en `analysis_options.yaml`
vía `plugins:`, no `custom_lint`):

```bash
flutter analyze
```

CI corre `dart analyze --fatal-infos`, una variante más estricta que también
falla ante *infos* (no solo *warnings* y *errors*):

```bash
dart analyze --fatal-infos
```

## Verificaciones del proyecto (`tool/`)

Cada una corresponde a una puerta que bloquea CI (`.github/workflows/ci.yml`).

**Cobertura mínima del 80% en `lib/features/*/domain/`** (exige la
constitución del proyecto; el código generado `*.g.dart` queda excluido de la
medición porque es mecánico y no se prueba directamente — ejecutar primero
`flutter test --coverage`):

```bash
dart run tool/check_coverage.dart --min 80
```

**Ausencia de dependencias de red salvo la excepción única `dio`** (verifica
que ningún paquete de red distinto de `dio` entra en `dependencies:`, y que
`package:dio` se importa desde exactamente un archivo — el cliente de
descarga del modelo):

```bash
dart run tool/check_no_network_deps.dart
```

**Auditoría de importaciones** (ningún archivo de `domain/` importa
`package:flutter`; `record`/`whisper_ggml`/`just_audio`/`dio` se importan
cada uno desde un único archivo declarado; ningún archivo de `presentation/`
importa `package:drift`; el cliente de `dio` solo hace `GET`, nunca
`post`/`put`/`FormData`):

```bash
dart run tool/check_import_boundaries.dart
```

**Anclaje de versiones** (las versiones resueltas en `pubspec.lock` de los
paquetes que la constitución fija de forma exacta —Riverpod, `drift`—
coinciden con lo declarado):

```bash
dart run tool/check_pinned_versions.dart
```

**Higiene de dependencias** (null safety, publicación reciente, sin licencias
GPL/AGPL en el árbol resuelto — veta explícitamente la variante `-gpl` de
`ffmpeg_kit_flutter`, dependencia transitiva de `whisper_ggml`; la variante
`_min`, LGPL-3.0, sí está permitida):

```bash
dart run tool/check_dependencies.dart
```

## Código generado al día

CI falla si alguien olvidó ejecutar `build_runner` antes de subir cambios:

```bash
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code
```

## Estructura

```
lib/
  core/                    # Compartido: base de datos, tipos de dominio, router, tema, widgets
  features/
    projects/              # Incremento 1 — proyectos
    stakeholders/          # Incremento 1 — interesados
    sessions/              # Incremento 1 — sesiones y guion
    glossary/               # Incremento 1 — glosario
    audit_log/             # Incremento 1 — bitácora (solo lectura)
    recordings/             # Incremento 2 — captura, marcado en vivo, recuperación, reproducción
    transcription/          # Incremento 2 — pasadas de Whisper, modelo, ajustes de descarga
  main.dart

test/
  unit/domain/             # Casos de uso y entidades de dominio
  unit/notifiers/          # Providers de presentación (Notifier/AsyncNotifier)
  data/                    # DAOs sobre SQLite en memoria
  drift/                   # Verificación del esquema versionado (migración v1→v2 incluida)
  widget/                  # Pantallas
  support/                 # Helpers de prueba (base de datos, contenedor, seeds, dobles de hardware)

integration_test/          # Flujos de punta a punta sobre la app real
  support/hardware_fakes.dart  # Dobla micrófono/escritor WAV/transcriptor/modelo/reproductor
tool/                      # Scripts de verificación que CI ejecuta
```
