# Implementation Plan: Gestión de proyectos, interesados y sesiones de elicitación

**Branch**: `001-proyectos-interesados-sesiones` | **Date**: 2026-08-10 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-proyectos-interesados-sesiones/spec.md`

## Summary

Primer incremento de la aplicación: la estructura navegable y la base de datos sobre las que
se apoyarán los incrementos siguientes. Cubre proyectos, interesados, sesiones de
elicitación con participantes, guion ordenado por sesión, glosario por proyecto y una
bitácora de solo lectura de las bajas lógicas. Sin audio, transcripción, LLM,
recomendaciones, tablero ni exportación.

El enfoque técnico, derivado de [research.md](research.md): aplicación Flutter sin backend,
con drift como única fuente de verdad en esquema versión 1 y migración inicial explícita;
arquitectura limpia por feature con `domain` puro; Riverpod 3 generado con `@riverpod`, un
provider por pantalla devolviendo `AsyncValue` de un estado inmutable, y toda escritura
expuesta como `Mutation` observable; navegación jerárquica con `go_router` llevando siempre
el identificador de proyecto en la ruta, de modo que el aislamiento entre proyectos sea
estructural y no una convención. Nada se borra: cada baja lógica escribe su asiento de
bitácora dentro de la misma transacción de drift que la produce, lo que convierte la regla
constitucional en un invariante imposible de olvidar.

La investigación de Fase 0 descubrió que dos reglas de la constitución nombraban mecanismos
que ya no existen en las versiones de paquetes que ella misma fija. Se escalaron al gate y
quedaron resueltas por la enmienda a **constitución v1.1.0**. No queda ningún bloqueo para
implementar.

## Technical Context

**Language/Version**: Dart 3.12.1 sobre Flutter 3.44.7
(entorno actual: Dart 3.12.0 / Flutter 3.44.0 → requiere `flutter upgrade`)

**Primary Dependencies**: flutter_riverpod 3.4.2 · riverpod_annotation 4.0.6 ·
riverpod_generator 4.0.8 · riverpod_lint 3.1.8 · drift 2.34.3 · drift_dev · go_router ·
uuid · clock · build_runner

**Storage**: SQLite mediante drift 2.34.3, esquema versión 1 con migración inicial
explícita. Sin `sqlite3_flutter_libs`: drift ≥ 2.32.0 empaqueta SQLite por su cuenta.

**Testing**: flutter_test · integration_test · `ProviderContainer.test()` con overrides de
repositorio · `NativeDatabase.memory()` para la capa de datos ·
`package:drift_dev/api/migrations_native.dart` para la prueba de esquema

**Target Platform**: Android 10+ e iOS 16+ como objetivo de producto. Verificación en
dispositivo físico exigida por este incremento: solo Android (FR-023, SC-004).

**Project Type**: Aplicación móvil monousuario, sin servidor, sin red

**Performance Goals**: Sin metas propias declaradas. Expectativas habituales de aplicación
móvil local: listas fluidas a 60 fps y arranque sin espera perceptible.

**Constraints**: Funciona por completo sin conexión; este incremento no realiza **ninguna**
petición de red y no declara ninguna dependencia de red. Nada se borra físicamente.

**Scale/Scope**: Un solo analista por dispositivo. Decenas de proyectos, cientos de sesiones
y puntos de guion. 8 pantallas, 6 entidades, 5 features.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Constitución evaluada**: v1.1.0 (2026-08-10)

### Resultado

**PASS** — el diseño cumple todos los principios aplicables.

Queda una sola salvedad, y es de entorno, no de diseño: el toolchain local está en Flutter
3.44.0 / Dart 3.12.0 y la constitución fija 3.44.7 / 3.12.1. Se resuelve con
`flutter upgrade` antes de la primera tarea de implementación.

Este gate estuvo en **CONDICIONAL** durante la Fase 0: la investigación encontró dos reglas
constitucionales que no eran ejecutables con las versiones de paquetes que la propia
constitución fijaba. Ambas se resolvieron con la enmienda a v1.1.0, que realineó el texto
con la realidad verificada conservando su intención. El historial se conserva más abajo
porque explica por qué el diseño toma las decisiones que toma.

### Principio I — Plataforma y Arquitectura

| Regla | Estado | Cómo se cumple |
|---|---|---|
| Flutter 3.44.7 / Dart 3.12.1, Material 3, go_router | ⚠️ Entorno | Local en 3.44.0/3.12.0; requiere `flutter upgrade` |
| Sin backend, cuentas, login, roles ni nube | ✅ | El incremento no declara ninguna dependencia de red |
| Providers con `@riverpod` + build_runner | ✅ | Todos generados; ninguno escrito a mano |
| Estado mutable solo en Notifier/AsyncNotifier generados | ✅ | Contratos de UI |
| autoDispose por defecto, keepAlive justificado | ✅ | Es el valor por defecto de la anotación con codegen |
| `ref.watch` solo en build, `ref.listen` efectos, `ref.read` callbacks | ✅ Revisión | No hay regla de lint que lo verifique; queda en revisión de código |
| Toda escritura expuesta como `Mutation<T>` observable, nunca como bandera | ✅ | Contrato de escritura en [ui-contracts.md](contracts/ui-contracts.md); regla vigente desde v1.1.0 (ver C1) |
| Ninguna API experimental salvo la de mutaciones | ✅ | La de mutaciones es la única; ninguna otra entra en el incremento |
| Un provider por pantalla, `AsyncValue`/sealed, 4 situaciones exhaustivas | ✅ | `AsyncScaffoldBody` centraliza el switch exhaustivo |
| `lib/features/<feature>/{domain,data,presentation}` + `lib/core` | ✅ | Ver Project Structure |
| `domain` sin Flutter ni infraestructura | ✅ | Verificable con lint de importaciones |
| Ninguna feature importa carpetas internas de otra | ✅ | `ProjectStatusReader` en `core/domain` es el único punto de contacto |
| drift como única fuente de verdad, esquema versionado, migraciones explícitas | ✅ | `schemaVersion 1` + `onCreate` explícito (FR-017) |

### Principios II a VI — Captura, LLM, Requisitos, Iteración, Exportación

**No aplican a este incremento.** El alcance declarado los excluye por completo. La
verificación relevante es negativa y está cubierta: ninguna dependencia de audio,
transcripción o red entra en `pubspec.yaml`.

### Calidad

| Regla | Estado | Cómo se cumple |
|---|---|---|
| Casos de uso y Notifier con `ProviderContainer` y overrides | ✅ | `ProviderContainer.test()`; se sobreescriben repositorios, no Notifiers |
| Ninguna prueba llama a la API real ni carga Whisper | ✅ | No existen en este incremento |
| Widgets con flutter_test, flujos con integration_test | ✅ | Quickstart |
| Cobertura mínima 80% en `domain` | ✅ | Puerta de CI |
| Lint con flutter_lints y riverpod_lint 3.1.8 vía `plugins:` y `dart analyze` | ✅ | Puerta de CI; mecanismo vigente desde v1.1.0 (ver C2) |
| CI bloquea merge por lint, código generado, pruebas o cobertura | ✅ | Cuatro puertas en el quickstart |

### Prohibiciones

Todas verificadas contra el diseño. Ninguna se incumple. Las que este incremento podría
haber rozado:

| Prohibición | Cómo se evita |
|---|---|
| API heredada de Riverpod, providers a mano | Todo con `@riverpod` generado |
| `setState`/`StatefulWidget` para estado de pantalla | Solo en controladores de UI puros (campos de texto, scroll) |
| Banderas `isLoading`/`hasError` | Prohibidas por contrato; el progreso de escritura vive en la mutación |
| Widgets que importen drift, dio o DTOs | Contratos de UI; verificable por revisión de importaciones |
| `domain` importando `package:flutter` | Contratos de dominio |
| SQL crudo fuera de `data` | Todo el SQL vive en DAOs |
| Singletons globales mutables | Todo pasa por providers |
| ORM distinto de drift, Firebase | No se declaran |
| Peticiones a cualquier host | Sin dependencias de red en `pubspec.yaml` |
| Dependencias sin null safety, sin mantenimiento o GPL/AGPL | `uuid` (MIT), `clock` (BSD), `go_router` (BSD), todas activas |

### Conflictos detectados en Fase 0 — resueltos en constitución v1.1.0

#### C1 — `@mutation` no existía en las versiones fijadas · RESUELTO

La constitución exige "escrituras expuestas con `@mutation`". Esa anotación existió solo en
preversiones de `riverpod_generator` y **fue eliminada** antes de la estable; en
`riverpod_annotation` 4.0.6 no se exporta. Las mutaciones existen como objeto
`Mutation<T>` en `package:riverpod/experimental/mutation.dart`, y la documentación oficial
las declara **experimentales**, con API que puede romper sin cambio de versión mayor.

Seguir la constitución al pie de la letra era imposible: el símbolo no existe.

**Resolución aplicada** (v1.1.0): la constitución ahora exige que toda escritura se exponga
como un objeto `Mutation<T>` observable y prohíbe explícitamente la alternativa —una bandera
dentro del estado de pantalla—. Añade además una viñeta que documenta el riesgo asumido con
una API experimental y lo acota: ninguna otra entra sin enmienda previa. El diseño de este
incremento ya está escrito contra esa regla.

#### C2 — `riverpod_lint` ya no se ejecuta sobre `custom_lint` · RESUELTO

La constitución exige "riverpod_lint sobre custom_lint activo en CI". Desde `riverpod_lint`
3.1.0 el paquete se implementa sobre `analysis_server_plugin`; se configura con `plugins:`
en `analysis_options.yaml` y se ejecuta con `dart analyze`. `custom_lint` ya no interviene.

La intención —reglas verificadas automáticamente que bloquean el merge— se cumple íntegra.
Solo el mecanismo nombrado quedó obsoleto.

**Resolución aplicada** (v1.1.0): la constitución nombra ahora el mecanismo vigente,
`riverpod_lint` 3.1.8 declarado bajo la clave `plugins` de `analysis_options.yaml` y
ejecutado con `dart analyze`. La exigencia de que el lint bloquee el merge no cambió.

Ambas enmiendas se aplicaron con `/speckit-constitution`; el bump combinado fue **MINOR**
(1.0.0 → 1.1.0), determinado por C1. C2 por sí solo habría sido PATCH.

### Re-evaluación posterior al diseño de Fase 1

Ejecutada sobre `data-model.md`, `contracts/` y `quickstart.md`, y repetida contra la
constitución v1.1.0. **Sin violaciones.** El diseño no introdujo ningún proyecto extra,
ninguna capa adicional ni ningún patrón que la constitución no contemple, y los dos
conflictos de Fase 0 quedaron cerrados por la enmienda.

## Project Structure

### Documentation (this feature)

```text
specs/001-proyectos-interesados-sesiones/
├── plan.md                      # Este archivo
├── research.md                  # Fase 0
├── data-model.md                # Fase 1
├── quickstart.md                # Fase 1
├── contracts/                   # Fase 1
│   ├── domain-contracts.md
│   └── ui-contracts.md
├── checklists/
│   └── requirements.md
├── spec.md
└── tasks.md                     # Fase 2 (/speckit-tasks — no lo crea /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── main.dart                              # ProviderScope + AppDatabase + router
├── core/
│   ├── database/                          # AppDatabase drift: todas las tablas, schemaVersion 1
│   ├── domain/                            # Result/Failure, tipos de id, ProjectStatusReader
│   ├── router/                            # go_router, rutas jerárquicas
│   ├── theme/                             # Material 3
│   └── widgets/                           # AsyncScaffoldBody y estados compartidos
└── features/
    ├── projects/{domain,data,presentation}
    ├── stakeholders/{domain,data,presentation}
    ├── sessions/{domain,data,presentation}      # sesión + guion (mismo agregado)
    ├── glossary/{domain,data,presentation}
    └── audit_log/{domain,data,presentation}     # solo lectura

test/
├── unit/
│   ├── domain/                            # casos de uso y funciones puras (cobertura ≥ 80%)
│   └── notifiers/                         # ProviderContainer.test() con overrides
├── data/                                  # DAOs sobre NativeDatabase.memory()
├── widget/                                # las cuatro situaciones de cada pantalla
└── drift/                                 # prueba de esquema generada por make-migrations

integration_test/                          # flujos completos en dispositivo
drift_schemas/                             # snapshot drift_schema_v1.json versionado
tool/                                      # check_coverage.dart, check_no_network_deps.dart
```

**Structure Decision**: aplicación móvil de proyecto único con arquitectura limpia por
feature, exactamente la que impone el Principio I. Cinco features verticales bajo
`lib/features/` y lo compartido en `lib/core/`.

Dos decisiones de agrupación merecen justificación explícita:

**El guion vive dentro de `sessions`, no como feature propia.** Un punto de guion no existe
fuera de su sesión, y el contador de la sesión lo necesita. Separarlos crearía una
dependencia entre features que la constitución prohíbe, a cambio de nada.

**La bitácora es una feature de solo lectura y nadie depende de ella.** Los asientos los
escribe cada repositorio dentro de su propia transacción, así que ninguna feature necesita
importar la de bitácora para registrar nada. La feature `audit_log` solo lee, que es
justamente lo que FR-015a pide de su pantalla.

La base de datos drift es una sola y vive en `core/database/`, porque un esquema
fragmentado por feature haría imposible la migración versionada única que exige FR-017. Cada
feature aporta su DAO en su propia carpeta `data/`.

## Complexity Tracking

> **Ninguna desviación respecto de la constitución v1.1.0.** C1 y C2 dejaron de serlo al
> aplicarse la enmienda: lo que antes era una desviación es hoy la regla vigente.
>
> Se conservan aquí las decisiones de diseño que **añaden complejidad** y que, por tanto,
> un revisor tiene derecho a cuestionar. No son incumplimientos.

| Decisión | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Columna desnormalizada `project_id` en `session_participants` y `script_points` | Hace que el aislamiento por proyecto de FR-018 sea verificable con una sola consulta y que ninguna lectura pueda escribirse sin filtro por descuido | Llegar al proyecto por join a través de la sesión deja el filtro a criterio de quien escribe cada consulta, que es el modo exacto en que se filtra mal |
| Columna `term_sort_key` derivada de `term` | El orden alfabético debe ignorar mayúsculas y acentos, y `ORDER BY` de SQLite no lo hace sin una colación personalizada | Ordenar en Dart tras leer la tabla rompe el streaming por consulta y no escala; registrar una colación personalizada en SQLite añade una pieza nativa por un solo `ORDER BY` |
| Ausencia de `UNIQUE (session_id, position)` pese al invariante de contigüidad | SQLite evalúa `UNIQUE` fila a fila durante un `UPDATE` masivo y no admite restricciones diferidas fuera de claves foráneas: el desplazamiento en bloque del reordenamiento fallaría a mitad | La alternativa sería posiciones fraccionarias o con hueco, que evitan el `UPDATE` masivo pero pierden la contigüidad `0..n-1`, que es el invariante más barato de verificar en pruebas |
