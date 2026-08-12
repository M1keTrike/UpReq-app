# Implementation Plan: Captura y transcripción de entrevistas

**Branch**: `002-captura-transcripcion` | **Date**: 2026-08-11 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-captura-transcripcion/spec.md`

## Summary

Segundo incremento: grabar entrevistas en el dispositivo, etiquetarlas en vivo, transcribirlas
localmente en dos pasadas y revisarlas saltando al segundo exacto de cada segmento. Ninguna
llamada al LLM: la transcripción se guarda y nadie la procesa todavía.

El enfoque técnico, derivado de [research.md](research.md): una sola captura
`record.startStream()` en PCM16 de 16 kHz mono, bifurcada hacia un escritor WAV incremental y
hacia `whisper_ggml.transcribeLive()`; la pasada definitiva corre con `transcribe(...,
withSegments: true)` al cerrar la sesión, con el glosario del proyecto inyectado como
`initialPrompt`. La inferencia corre en un isolate que aporta el propio paquete. La
reproducción usa `just_audio`, cuyo `seek()` y `positionStream` cubren el salto a segmento y
el resaltado del segmento activo.

Dos hallazgos de la Fase 0 moldean el diseño más que cualquier otra cosa:

**`whisper_ggml` descarga modelos por su cuenta en el primer uso**, lo que sería una petición
de red no iniciada por el usuario y por tanto una violación directa de la constitución. El
diseño lo neutraliza: la app comprueba la existencia del archivo del modelo antes de
transcribir y, si falta, deja la transcripción pendiente en vez de llamar al transcriptor. La
descarga la hace la propia app desde ajustes, con `dio` y progreso real. La ruta implícita del
paquete nunca llega a dispararse.

**El escritor WAV incremental es lo que hace recuperable una grabación interrumpida.** La
cabecera RIFF se escribe con los tamaños en cero y se parchea al detener; un cierre inesperado
deja el audio íntegro detrás de una cabecera sin parchear, y la recuperación es un cálculo
determinista de 8 bytes sobre el tamaño real del archivo. FR-010 deja de ser una promesa y
pasa a ser una función pura con prueba unitaria.

## Technical Context

**Language/Version**: Dart 3.12.2 sobre Flutter 3.44.9, sin cambios respecto del incremento 1

**Primary Dependencies**: las del incremento 1 (flutter_riverpod 3.3.2 · riverpod_annotation
4.0.3 · riverpod_generator 4.0.4 · riverpod_lint 3.1.4 · drift 2.34.0 · go_router · uuid ·
clock · path_provider) más las que estrena este incremento:

| Paquete | Versión | Licencia | Para qué |
|---|---|---|---|
| `record` | 7.1.1 | BSD-3-Clause | Captura PCM16 16 kHz mono |
| `whisper_ggml` | 2.6.0 | MIT | Transcripción en el dispositivo (whisper.cpp 1.9.1) |
| `just_audio` | 0.10.6 | Apache-2.0 / MIT | Reproducción con `seek` y `positionStream` |
| `dio` | 5.11.0 | MIT | **Único** punto de red: descarga del modelo GGML |
| `wakelock_plus` | ^1.7.0 | BSD-3-Clause | Mantener la pantalla activa durante la captura |

Entra además, de forma transitiva vía `whisper_ggml`, `ffmpeg_kit_flutter_new_min` con
licencia **LGPL-3.0**. Está permitida: la constitución prohíbe GPL/AGPL, y LGPL no es ninguna
de las dos. La variante `-gpl` del mismo paquete **sí** estaría prohibida, y por eso CI la
veta de forma explícita (research.md, decisión 7).

**Storage**: SQLite mediante drift, **esquema versión 2** con `onUpgrade` explícito y
aditivo. Los archivos WAV viven en el sandbox de la app, fuera de la base de datos; la tabla
guarda la ruta relativa, nunca el audio.

**Testing**: flutter_test · integration_test · `ProviderContainer.test()` con overrides ·
`NativeDatabase.memory()` para DAOs · `SchemaVerifier` de drift_dev verificando la
**migración v1→v2**, no solo el esquema final. El transcriptor y el grabador se sustituyen
siempre por dobles: ninguna prueba carga un modelo Whisper ni abre el micrófono.

**Target Platform**: Android 10+ e iOS 16+ como objetivo de producto. `minSdkVersion` efectivo
sube a **24** por `ffmpeg_kit_flutter_new_min`; sigue muy por debajo de Android 10 (API 29).
Verificación en dispositivo físico exigida por este incremento: solo Android (SC-005).

**Project Type**: Aplicación móvil monousuario, sin servidor, con una única excepción de red

**Performance Goals**: el spec no fija metas numéricas y este plan no las inventa. Lo que sí
fija es una restricción cualitativa verificable: la pasada en vivo no debe interrumpir la
captura ni bloquear la interfaz (FR-012), y la definitiva no debe bloquearla tampoco
(FR-015). Ambas se apoyan en el isolate del paquete. Los tiempos reales se **miden** en la
validación en dispositivo y se anotan en el roadmap: ese es, según el propio roadmap, el
aprendizaje central de este incremento.

**Constraints**: la descarga del modelo es la única operación de red (FR-021), verificada por
una puerta de CI reescrita. El audio nunca sale del dispositivo (FR-006). Nada se borra
físicamente. La grabación es de primer plano por decisión declarada (research.md, decisión 8).

**Scale/Scope**: un analista por dispositivo. Entrevistas de decenas de minutos, cientos de
segmentos por grabación. 4 pantallas nuevas o ampliadas, 4 entidades nuevas, 2 features
nuevas.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Constitución evaluada**: v1.2.0 (2026-08-10)

### Resultado

**PASS sin salvedades.** El diseño cumple todos los principios aplicables. El único conflicto
detectado en Fase 0 se resuelve **dentro del diseño**, sin necesidad de enmienda: la conducta
por defecto de `whisper_ggml` incumpliría la constitución, y el diseño la anula en vez de
adaptarse a ella.

Este incremento es el primero que ejerce los Principios II (Captura y Transcripción) y, de
forma parcial, la excepción de red del bloque de Prohibiciones. Ambos estaban escritos pero
sin ejercitar.

### Principio I — Plataforma y Arquitectura

| Regla | Estado | Cómo se cumple |
|---|---|---|
| Flutter 3.44.9 / Dart 3.12.2, Material 3, go_router | ✅ | Sin cambios respecto del incremento 1 |
| Sin backend, cuentas, login, roles ni nube | ✅ | La única red es la descarga del modelo desde el host configurado |
| Providers con `@riverpod` + build_runner | ✅ | Todos generados |
| Estado mutable solo en Notifier/AsyncNotifier generados | ✅ | Contratos de UI |
| autoDispose por defecto, keepAlive justificado | ⚠️ Justificado | El notifier de grabación activa **requiere** `keepAlive`: la captura no puede morir porque el analista navegue a otra pantalla a media entrevista. Es la primera excepción real del proyecto y se justifica en el código, como manda la regla |
| `ref.watch` en build, `ref.listen` efectos, `ref.read` callbacks | ✅ Revisión | Sin lint que lo verifique; revisión de código |
| Toda escritura como `Mutation<T>` observable | ✅ | Incluidas iniciar/detener grabación, descargar modelo y disparar la pasada definitiva |
| Ninguna API experimental salvo la de mutaciones | ✅ | No se añade ninguna otra |
| Un provider por pantalla, `AsyncValue`/sealed, 4 situaciones | ✅ | `AsyncScaffoldBody` ya centraliza el switch |
| `lib/features/<feature>/{domain,data,presentation}` + `lib/core` | ✅ | Ver Project Structure |
| `domain` sin Flutter ni infraestructura | ✅ | `record`, `whisper_ggml`, `just_audio` y `dio` viven solo en `data/`; `domain` los ve como contratos |
| Ninguna feature importa carpetas internas de otra | ✅ | `recordings` publica su contrato; `sessions` lo consume por `core/domain` |
| drift única fuente de verdad, esquema versionado, migraciones explícitas | ✅ | `schemaVersion 2` con `onUpgrade` explícito y prueba de migración v1→v2 |
| **Audio e imágenes en el sandbox de la app** | ✅ **Entra en vigor** | Los WAV viven en el sandbox vía `path_provider`; la base de datos guarda ruta relativa, nunca binarios |
| Respaldo y restauración por archivo local cifrado | ⏸️ Diferido | Sigue fuera de alcance. Guardar rutas relativas y no absolutas mantiene el respaldo viable sin migración destructiva |

### Principio II — Captura y Transcripción

**Este es el incremento que lo estrena.** Regla por regla:

| Regla | Estado | Cómo se cumple |
|---|---|---|
| Grabación con `record` en WAV 16 kHz, mono, un canal | ✅ | `RecordConfig(encoder: pcm16bits, sampleRate: 16000, numChannels: 1)` |
| `whisper_ggml` 2.6.0 sobre whisper.cpp 1.9.1 | ✅ | Verificado en pub.dev: la versión publicada empaqueta exactamente whisper.cpp v1.9.1 |
| Dos pasadas: en vivo con `base`, definitiva con `small` | ✅ | `transcribeLive(model: base)` durante la captura; `transcribe(model: small)` al cerrar |
| `withSegments` activo | ✅ | En la pasada definitiva, que es la que produce evidencia |
| `lang` fijo en `'es'` | ✅ | Constante, no configurable |
| Glosario del proyecto como `initialPrompt` | ✅ | FR-014; el glosario ya es consultable como lista plana desde el incremento 1, tal como el roadmap exigió |
| Segmentos con `fromTs`/`toTs` como unidad de evidencia | ✅ | Tabla `transcript_segments`, diseñada para ser referenciada por requisitos que aún no existen |
| La inferencia corre en un isolate y nunca bloquea la interfaz | ✅ | Lo garantiza el paquete; se verifica en la validación en dispositivo |
| **El audio jamás sale del dispositivo** | ✅ | FR-006. `dio` solo hace `GET` del modelo; no existe ninguna ruta de subida en el código |

### Principio III — LLM

**No aplica.** El incremento excluye toda llamada al LLM. La verificación relevante es
negativa y está cubierta por el gate reescrito: `dio` se importa desde **un solo archivo**, el
cliente de descarga del modelo. Cualquier segundo importador bloquea el merge, que es
exactamente lo que impediría que una llamada al LLM entrase aquí por descuido.

### Principios IV a VI — Requisitos, Iteración, Exportación

**No aplican.** El alcance declarado los excluye por completo.

### Calidad

| Regla | Estado | Cómo se cumple |
|---|---|---|
| Casos de uso y Notifier con `ProviderContainer` y overrides | ✅ | Sin cambios de patrón |
| **El transcriptor siempre se sustituye por doble; ninguna prueba carga un modelo Whisper** | ✅ | `Transcriber` es un contrato de `domain`; su implementación real vive en `data/` y jamás se instancia en pruebas |
| Ninguna prueba llama a la API real | ✅ | No hay API en este incremento; el cliente de descarga también se dobla |
| Widgets con flutter_test, flujos con integration_test | ✅ | Quickstart |
| Cobertura mínima 80% en `domain` | ✅ | Puerta de CI. El reparador de cabecera WAV y el mapeo de segmentos son funciones puras, así que la lógica delicada es barata de cubrir |
| Lint con flutter_lints y riverpod_lint vía `plugins:` | ✅ | Sin cambios |
| CI bloquea merge por lint, código generado, pruebas o cobertura | ✅ | Cuatro puertas, más las dos de dependencias |

### Prohibiciones

| Prohibición | Cómo se evita |
|---|---|
| Petición a cualquier host distinto de api.deepseek.com **salvo la descarga del modelo, iniciada manualmente desde ajustes** | Es la parte delicada de este incremento. Ver conflicto C3 abajo: resuelto en diseño |
| Envío de audio, imágenes o archivos al LLM | No hay LLM. El audio no tiene ninguna ruta de salida en el código |
| SDK de analítica, publicidad, telemetría o rastreo | Ninguno se declara |
| API key en el repositorio | No hay API key en este incremento |
| Dependencias con licencia GPL/AGPL | Verificado paquete por paquete. LGPL-3.0 de `ffmpeg_kit_flutter_new_min` está permitida; la variante `-gpl` la veta CI |
| Widgets que importen drift, dio o DTOs | Contratos de UI; `dio` además está confinado por gate a un único archivo |
| `domain` importando `package:flutter` | Contratos de dominio; verificado por la auditoría de importaciones ya existente |
| Bloquear la interfaz esperando al transcriptor | El isolate del paquete más el estado `processing` en pantalla (FR-015) |
| Eliminar registros: todo borrado es lógico con bitácora | Las cuatro tablas nuevas llevan `deleted_at`; las bajas escriben su asiento en la misma transacción |
| Singletons globales mutables | El grabador y el transcriptor son providers `keepAlive` justificados, no singletons |

### Conflicto detectado en Fase 0

#### C3 — `whisper_ggml` descarga el modelo sin que nadie se lo pida · RESUELTO EN DISEÑO

La documentación del paquete declara que los modelos se descargan **automáticamente en el
primer uso**. Una llamada a `transcribe()` con el modelo ausente abriría una conexión de red
que el usuario no inició desde ajustes, incumpliendo la prohibición literal de la
constitución y FR-021.

**Resolución**: no se enmienda nada. El diseño impone una barrera anterior al paquete:

1. Antes de transcribir, la app comprueba que el archivo devuelto por
   `WhisperController.getPath(model)` existe.
2. Si no existe, la transcripción queda en estado `pending` (FR-016) y **el transcriptor no
   se invoca**. La ruta implícita del paquete es inalcanzable.
3. La descarga la hace la app con `dio`, desde ajustes, con progreso real, a un archivo
   `.part` que se renombra de forma atómica al completarse.

Esto cumple la constitución **más estrictamente** de lo que el paquete lo haría solo, y
convierte una descarga inobservable en una explícita, cancelable y medible. La comprobación
previa no es una precaución de estilo: es lo único que hace verificable la prohibición.

A diferencia de C1 y C2 del incremento 1, C3 **no requiere enmienda constitucional**: la regla
estaba bien escrita y era realizable; el que se apartaba era el paquete.

### Re-evaluación posterior al diseño de Fase 1

Ejecutada sobre [data-model.md](data-model.md), [contracts/](contracts/) y
[quickstart.md](quickstart.md). **Sin violaciones.** El diseño no introduce ningún proyecto
extra, ninguna capa adicional ni ningún patrón que la constitución no contemple. Las dos
desviaciones que añaden complejidad —el `keepAlive` del notifier de grabación y la escritura
manual de la cabecera WAV— quedan registradas en Complexity Tracking con su justificación.

## Project Structure

### Documentation (this feature)

```text
specs/002-captura-transcripcion/
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
├── core/
│   ├── database/
│   │   ├── app_database.dart              # schemaVersion 2 + onUpgrade explícito
│   │   └── tables/
│   │       ├── recordings.dart            # NUEVA
│   │       ├── live_marks.dart            # NUEVA
│   │       ├── transcripts.dart           # NUEVA
│   │       └── transcript_segments.dart   # NUEVA
│   └── domain/
│       └── ids.dart                       # + RecordingId, LiveMarkId, TranscriptId, SegmentId
└── features/
    ├── recordings/                        # NUEVA: captura, marcas, recuperación, reproducción
    │   ├── domain/
    │   │   ├── entities/                  # Recording, LiveMark, RecordingState
    │   │   ├── contracts/                 # AudioRecorder, AudioPlayer, WavFile
    │   │   └── usecases/
    │   ├── data/
    │   │   ├── record_audio_recorder.dart # único importador de `record`
    │   │   ├── just_audio_player.dart     # único importador de `just_audio`
    │   │   ├── wav_writer.dart            # cabecera RIFF incremental
    │   │   └── recordings_dao.dart
    │   └── presentation/
    └── transcription/                     # NUEVA: pasadas, modelo, segmentos
        ├── domain/
        │   ├── entities/                  # Transcript, TranscriptSegment, ModelStatus
        │   ├── contracts/                 # Transcriber, ModelRepository
        │   └── usecases/
        ├── data/
        │   ├── whisper_transcriber.dart   # único importador de `whisper_ggml`
        │   ├── model_download_client.dart # ÚNICO importador de `dio` en todo el árbol
        │   └── transcripts_dao.dart
        └── presentation/                  # incluye la pantalla de ajustes del modelo

test/
├── unit/domain/                           # incluye el reparador de cabecera WAV (función pura)
├── unit/notifiers/
├── data/                                  # DAOs sobre NativeDatabase.memory()
├── widget/
└── drift/                                 # migración v1→v2, no solo esquema final

drift_schemas/                             # + drift_schema_v2.json
tool/
├── check_no_network_deps.dart             # REESCRITO: solo `dio`, y desde un archivo
└── check_dependencies.dart                # + veto a la variante `-gpl` de ffmpeg_kit
```

**Structure Decision**: se mantiene la arquitectura limpia por feature del incremento 1 y se
añaden **dos** features verticales.

**Por qué dos y no una.** `recordings` y `transcription` tienen ciclos de vida distintos y
dependencias nativas distintas: la primera captura y reproduce, la segunda infiere y descarga.
Una grabación existe y es útil sin transcripción alguna —es la historia 1, que el spec declara
entregable por sí sola—, mientras que una transcripción sin grabación no significa nada. Esa
asimetría es una dirección de dependencia, y separarlas la hace explícita: `transcription`
conoce el identificador de una grabación, `recordings` no sabe que la transcripción existe.

**Por qué las marcas en vivo viven en `recordings` y no en una feature propia.** Una marca no
existe fuera de su grabación y se coloca con la captura activa: es parte del mismo agregado.
Es el mismo criterio con el que el guion vive dentro de `sessions` en el incremento 1.

**Confinamiento de las dependencias nativas.** Cada paquete de infraestructura tiene
exactamente un importador, nombrado arriba. Para `dio` eso no es una convención sino una
puerta de CI. Para los otros tres es una regla de revisión que la auditoría de importaciones
ya existente puede verificar con una línea más.

La base de datos sigue siendo una sola en `core/database/`, por la misma razón que en el
incremento 1: un esquema fragmentado por feature haría imposible la migración versionada
única.

## Complexity Tracking

> **Ninguna desviación respecto de la constitución v1.2.0.** C3 se resolvió en el diseño, sin
> enmienda.
>
> Se registran aquí las decisiones que **añaden complejidad** y que un revisor tiene derecho a
> cuestionar. No son incumplimientos.

| Decisión | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| `keepAlive` en el notifier de grabación activa | Es la primera excepción real a `autoDispose` del proyecto. La captura no puede morir porque el analista navegue del detalle de sesión al glosario a media entrevista, y `autoDispose` la mataría en ese instante | Mantener el estado en el widget con `StatefulWidget` está prohibido por la constitución; moverlo a un singleton también. `keepAlive` con justificación escrita es el mecanismo que la propia constitución contempla |
| Escritura manual de la cabecera RIFF en vez de dejar que `record` produzca el WAV | Es lo que hace recuperable una grabación interrumpida: el archivo crece de forma incremental y un cierre inesperado deja el audio íntegro tras una cabecera sin parchear, reparable de forma determinista | Usar `record.start()` a archivo entrega el WAV ya formado pero **no** deja acceder al flujo PCM que `transcribeLive` necesita, y obligaría a releer el archivo por trozos inventando un protocolo de sincronización que se desajusta en cuanto la escritura se retrasa |
| Comprobar la existencia del modelo antes de cada transcripción | Es la barrera que impide que `whisper_ggml` dispare su descarga automática, prohibida por la constitución (C3) | Confiar en que el modelo esté descargado deja viva una ruta de red no iniciada por el usuario, que es precisamente lo que la prohibición veta |
| Dos features nuevas en vez de una | `recordings` es entregable sin `transcription`; la dependencia es unidireccional y separarlas la hace explícita e imposible de invertir por descuido | Una sola feature `capture` mezclaría captura y inferencia en el mismo agregado y permitiría que el reproductor terminara dependiendo del transcriptor sin que nada lo impidiera |
| Puerta de CI que cuenta importadores de `dio` | La prohibición constitucional no es "no hay red" sino "hay exactamente una excepción declarada". Contar puntos de uso expresa esa regla; la ausencia de puerta no expresa nada | Eliminar el gate al cambiar FR-019 por FR-021 tiraría la garantía justo en el incremento que estrena la excepción |
