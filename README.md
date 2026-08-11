# up_req

Levantamiento de requerimientos de software en campo. Aplicación Flutter
personal, monousuario y sin servidor: proyectos, interesados, sesiones de
elicitación, guion, glosario y bitácora, todo persistido localmente con
[drift](https://drift.simonbinder.eu/) sobre SQLite. Sin dependencias de red
(ver `tool/check_no_network_deps.dart`).

Los detalles de diseño viven en `specs/001-proyectos-interesados-sesiones/`
(`spec.md`, `plan.md`, `data-model.md`, `contracts/`, `tasks.md`,
`quickstart.md`). Este README solo cubre los comandos para levantar el
proyecto, generar código y correr las pruebas.

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

Esto actualiza `drift_schemas/drift_schema_v1.json` y la prueba de esquema en
`test/drift/`.

Ejecutar la app (dispositivo Android/iOS conectado, emulador, o `-d windows`
si se agrega soporte de escritorio más adelante — hoy el proyecto solo
declara las plataformas `android` e `ios`):

```bash
flutter run
```

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
archivo, según el caso). Requieren un dispositivo o emulador Android/iOS —
no hay soporte de escritorio ni web para `integration_test` en este proyecto:

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

**Ausencia de dependencias de red** (verificación estructural de que ningún
paquete resuelto en `pubspec.lock` es `dio`, `http`, `web_socket_channel`,
`grpc`, etc.):

```bash
dart run tool/check_no_network_deps.dart
```

**Higiene de dependencias** (null safety, publicación reciente, sin licencias
GPL/AGPL en el árbol resuelto):

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
    projects/              # US1 — proyectos
    stakeholders/          # US2 — interesados
    sessions/              # US3/US4 — sesiones y guion
    glossary/               # US5 — glosario
    audit_log/             # US6 — bitácora (solo lectura)
  main.dart

test/
  unit/domain/             # Casos de uso y entidades de dominio
  unit/notifiers/          # Providers de presentación (Notifier/AsyncNotifier)
  data/                    # DAOs sobre SQLite en memoria
  drift/                   # Verificación del esquema versionado
  widget/                  # Pantallas
  support/                 # Helpers de prueba (base de datos, contenedor, seeds)

integration_test/          # Flujos de punta a punta sobre la app real (T111–T114)
tool/                      # Scripts de verificación que CI ejecuta
```
