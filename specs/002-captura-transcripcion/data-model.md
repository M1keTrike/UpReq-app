# Phase 1 Data Model: Captura y transcripción de entrevistas

**Feature**: 002-captura-transcripcion
**Date**: 2026-08-11
**Input**: [spec.md](spec.md), [research.md](research.md)

Cuatro tablas nuevas. Ninguna tabla del incremento 1 se altera: la migración es puramente
aditiva, que es lo que la vuelve incapaz de perder datos en un teléfono que ya tiene proyectos
reales encima.

Convenciones heredadas del incremento 1 y respetadas sin excepción: identificadores UUID v4
generados en `domain`; fechas en UTC como epoch en milisegundos vía `UtcDateTimeConverter`;
`created_at` y `updated_at` en toda entidad; baja lógica con `deleted_at` nulable; columna
`project_id` desnormalizada donde el aislamiento por proyecto deba ser verificable con una
sola consulta.

---

## Migración v1 → v2

```dart
@override
int get schemaVersion => 2;

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
}
```

`onCreate` sigue creando todo de una vez para instalaciones nuevas. La prueba de esquema
verifica **ambos caminos**: que una base v1 poblada llegue a v2 sin pérdida, y que una base
nueva en v2 produzca el mismo esquema que la migrada. Verificar solo el esquema final dejaría
pasar una migración que funciona en instalación limpia y falla en actualización, que es el
único caso que importa.

---

## Entidad: Recording (`recordings`)

Captura de audio de una sesión. Una sesión puede tener **varias** (FR-003a): cuando una
grabación interrumpida se cierra sin reanudarse, la toma siguiente es una grabación
independiente.

| Columna | Tipo | Reglas |
|---|---|---|
| `id` | TEXT PK | UUID v4 generado en `domain` |
| `session_id` | TEXT → `sessions.id` | La grabación pertenece a una sesión |
| `project_id` | TEXT | Desnormalizada; aislamiento verificable sin join |
| `file_path` | TEXT | Ruta **relativa** al sandbox de la app, nunca absoluta |
| `status` | TEXT | `recording` \| `stopped` \| `interrupted` |
| `duration_ms` | INTEGER | Duración conocida; 0 mientras `recording` |
| `sample_rate` | INTEGER | Siempre 16000; se persiste para que el reparador de cabecera no lo suponga |
| `channels` | INTEGER | Siempre 1; misma razón |
| `started_at` | DATETIME | UTC |
| `stopped_at` | DATETIME? | Nulo mientras `recording` o `interrupted` |
| `deleted_at` | DATETIME? | Baja lógica |
| `created_at` / `updated_at` | DATETIME | Comunes a toda entidad |

**Por qué la ruta es relativa.** El sandbox de la app cambia de ruta absoluta entre
instalaciones y entre respaldo y restauración. Guardar la absoluta convertiría cualquier
restauración futura en una migración de datos; guardar la relativa la deja viable sin tocar el
esquema. Es el mismo criterio con el que el incremento 1 dejó abierta la puerta del respaldo.

**Por qué `sample_rate` y `channels` se persisten pese a ser constantes.** El reparador de
cabecera RIFF necesita ambos para recalcular los campos de tamaño de un archivo interrumpido.
Leerlos de la fila en vez de asumirlos deja el reparador como función pura y hace que un
cambio futuro de formato no corrompa en silencio los archivos ya grabados.

### Transiciones de estado

```
        ┌─────────────────────────────┐
        │                             ▼
   [recording] ──── stop() ────► [stopped]      (terminal)
        │                             ▲
        │                             │ cerrar sin reanudar (FR-011)
        └── crash / llamada ──► [interrupted]
                                      │
                                      └── reanudar (FR-011) ──► [recording]
```

`stopped` es terminal. `interrupted` es el único estado desde el que se puede volver a
`recording`, y solo por la acción explícita del analista de FR-011. No existe transición
automática desde `interrupted`: esa fue la decisión aclarada el 2026-08-11.

**Invariante R1**: como máximo una grabación en estado `recording` en toda la base. Se verifica
en pruebas, no por esquema: SQLite no expresa "único con condición" sin un índice parcial
único, y añadirlo obligaría a un orden de escritura frágil al reanudar.

**Invariante R2**: `status = 'stopped'` implica `stopped_at` no nulo y `duration_ms > 0`.

---

## Entidad: LiveMark (`live_marks`)

Marca que el analista coloca durante una grabación activa.

| Columna | Tipo | Reglas |
|---|---|---|
| `id` | TEXT PK | UUID v4 |
| `recording_id` | TEXT → `recordings.id` | Pertenece a una grabación |
| `session_id` | TEXT | Desnormalizada, para listar marcas por sesión sin join |
| `project_id` | TEXT | Desnormalizada |
| `kind` | TEXT | `requirement` \| `doubt` \| `quote` |
| `at_ms` | INTEGER | Milisegundos **desde el inicio de su grabación**, no epoch |
| `deleted_at` | DATETIME? | Baja lógica (FR-009a) |
| `created_at` / `updated_at` | DATETIME | |

**Los tres tipos son los aclarados el 2026-08-11**: posible requisito, duda y cita textual.
El roadmap exige que cada marca tenga tipo y no solo un booleano, porque estas marcas definen
las ventanas de filtrado del incremento 3. `kind` es un `TEXT` con conjunto cerrado, no un
booleano ni un entero de importancia.

**Por qué `at_ms` es relativo a la grabación y no epoch.** Es un desplazamiento dentro de un
archivo de audio. Guardarlo como epoch obligaría a restar la marca de inicio en cada consulta y
lo dejaría inservible en cuanto una grabación se reanude tras una interrupción. Relativo, el
salto del reproductor es directo.

**Invariante M1**: `at_ms >= 0` y, para una grabación `stopped`, `at_ms <= duration_ms`.

**Sin deduplicación por instante**: dos marcas pueden compartir `at_ms`. Es el caso borde ya
resuelto en el spec.

---

## Entidad: Transcript (`transcripts`)

Resultado de una pasada de transcripción sobre una grabación.

| Columna | Tipo | Reglas |
|---|---|---|
| `id` | TEXT PK | UUID v4 |
| `recording_id` | TEXT → `recordings.id` | |
| `session_id` | TEXT | Desnormalizada |
| `project_id` | TEXT | Desnormalizada |
| `pass` | TEXT | `live` \| `final` |
| `status` | TEXT | `pending` \| `processing` \| `done` \| `failed` |
| `model_id` | TEXT | `base` \| `small`; qué modelo la produjo |
| `text` | TEXT? | Texto completo; nulo mientras no esté `done` |
| `failure_reason` | TEXT? | Solo cuando `status = 'failed'` |
| `completed_at` | DATETIME? | |
| `deleted_at` | DATETIME? | Baja lógica |
| `created_at` / `updated_at` | DATETIME | |

**`pass` queda con un solo valor en uso en este incremento: `final`.** La pasada en vivo se
muestra en pantalla durante la captura (FR-012) pero **no se persiste**: su salida es un
`Stream<String>` sin marcas de tiempo, así que no puede producir segmentos y por tanto no
puede ser evidencia de nada. Guardar un texto aproximado que nadie puede anclar al audio sería
llenar la tabla de contenido con apariencia de evidencia, que es el peor resultado posible en
una herramienta cuyo índice de procedencia es una métrica del incremento 5.

La columna se declara igualmente, por dos razones. La primera es que el índice único
`transcripts_one_per_pass` necesita distinguir el par para que una segunda pasada definitiva
no duplique filas. La segunda es que persistir la pasada en vivo como borrador legible
mientras la definitiva se procesa es una opción real, y su valor depende por completo de
cuánto tarde la definitiva en el teléfono — número que mide T117. Si tarda lo bastante como
para que el analista se quede esperando, la columna ya está lista y el cambio es de una fila
de configuración, no una migración.

**El estado `pending` es lo que resuelve FR-016.** Una sesión que se cierra sin modelo
descargado produce un `Transcript` en `pending`, no un error ni la ausencia de registro. El
audio queda intacto y la fila es la cola de trabajo pendiente para cuando el modelo llegue.

**Invariante T1**: como máximo un `transcript` no borrado por par (`recording_id`, `pass`).
Este sí es expresable como índice único parcial y se declara como tal.

**Invariante T2**: `status = 'done'` implica `text` no nulo y `completed_at` no nulo.

### Transiciones de estado

```
[pending] ──► [processing] ──► [done]      (terminal)
    ▲              │
    │              └────────► [failed]
    └── reintento ────────────────┘
```

---

## Entidad: TranscriptSegment (`transcript_segments`)

Fragmento de texto con su ventana temporal. **Es la unidad de evidencia de todo el sistema**:
el roadmap lo declara y esta tabla debe poder referenciarse desde requisitos que todavía no
existen.

| Columna | Tipo | Reglas |
|---|---|---|
| `id` | TEXT PK | UUID v4 |
| `transcript_id` | TEXT → `transcripts.id` | |
| `recording_id` | TEXT | Desnormalizada: el incremento 3 ancla evidencia al audio, no a la pasada |
| `session_id` | TEXT | Desnormalizada |
| `project_id` | TEXT | Desnormalizada |
| `from_ms` | INTEGER | Inicio, relativo a la grabación |
| `to_ms` | INTEGER | Fin, relativo a la grabación |
| `position` | INTEGER | Orden contiguo `0..n-1` dentro de su transcripción |
| `body` | TEXT | Texto del segmento |
| `deleted_at` | DATETIME? | Baja lógica |
| `created_at` / `updated_at` | DATETIME | |

**La columna de texto se llama `body`, no `text`.** Es la misma limitación de `drift_dev` ya
documentada en `script_points`: una columna llamada `text` colisiona con el método `text()`
que `Table` hereda. El campo del lado Dart sigue llamándose `text`.

**Por qué `recording_id` está desnormalizada aquí.** El incremento 3 anclará cada requisito al
segmento que lo originó, y desde ahí querrá saltar al audio. Llegar a la grabación cruzando la
transcripción funciona, pero deja el filtro a criterio de quien escriba cada consulta futura.
Es el mismo razonamiento con el que el incremento 1 desnormalizó `project_id`, y por la misma
razón: el aislamiento que depende de recordar un join es el que se rompe.

**Invariante S1**: `from_ms < to_ms`.

**Invariante S2**: dentro de un `transcript`, los segmentos no se solapan y `position` es
contigua `0..n-1`. Verificado en pruebas, no por esquema, por la misma razón que en
`script_points`: SQLite evalúa `UNIQUE` fila a fila y no admite restricciones diferidas.

---

## Índices nuevos

```sql
CREATE INDEX recordings_session ON recordings (session_id, started_at)
  WHERE deleted_at IS NULL;
CREATE INDEX live_marks_recording ON live_marks (recording_id, at_ms)
  WHERE deleted_at IS NULL;
CREATE INDEX transcripts_recording ON transcripts (recording_id, pass)
  WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX transcripts_one_per_pass ON transcripts (recording_id, pass)
  WHERE deleted_at IS NULL;
CREATE INDEX segments_transcript ON transcript_segments (transcript_id, position)
  WHERE deleted_at IS NULL;
CREATE INDEX segments_recording_time ON transcript_segments (recording_id, from_ms)
  WHERE deleted_at IS NULL;
```

Todos parciales sobre `deleted_at IS NULL`, como los del incremento 1, y por eso declarados en
SQL crudo dentro de la migración: la anotación `@TableIndex` de drift no expresa índices
parciales.

`segments_recording_time` no sirve a ninguna consulta de este incremento. Se declara ahora
porque es la consulta que el incremento 3 hará en cada extracción —"dame los segmentos de esta
grabación en esta ventana de tiempo"— y añadirlo después obligaría a otra migración por una
línea.

---

## Bitácora: qué operaciones asientan

`audit_entries` no cambia de esquema. Gana valores nuevos en `operation` y `entity_type`,
que ya son `TEXT` de conjunto abierto:

| Operación | Cuándo |
|---|---|
| `recordingDeleted` | Baja lógica de una grabación |
| `liveMarkDeleted` | Baja lógica de una marca (FR-009a) |

Cada asiento se escribe en la **misma transacción de drift** que la baja que lo produce, igual
que en el incremento 1. Eso convierte la regla constitucional en un invariante imposible de
olvidar en vez de en una disciplina.

**Las transcripciones no tienen operación de bitácora propia.** FR-023 acota este incremento a
no exponer eliminación individual de transcripciones ni de segmentos: se retiran de la vista
únicamente en cascada, dentro de la misma transacción que da de baja su grabación. El asiento
`recordingDeleted` ya documenta esa operación por completo, y añadir un `transcriptDeleted`
redundante por cada cascada llenaría la pantalla de bitácora de ruido derivado en vez de
hechos. Las columnas `deleted_at` de ambas tablas siguen existiendo y es la cascada quien las
escribe; el día que una historia futura pida borrar una transcripción suelta, el esquema ya lo
admite sin migración.

**Lo que no asienta**: iniciar o detener una grabación, colocar una marca, editar el tipo de
una marca, o completar una pasada de transcripción. La bitácora del incremento 1 registra
**bajas lógicas**, no actividad. Ampliarla a un registro de actividad general la convertiría en
otra cosa y haría ilegible la pantalla que FR-015a definió.

---

## Relación con las entidades del incremento 1

```
Project ──┬── Stakeholder
          ├── GlossaryTerm ─────────────► initialPrompt de la transcripción (FR-014)
          ├── AuditEntry
          └── Session ──┬── ScriptPoint
                        └── Recording ──┬── LiveMark
                                        └── Transcript ── TranscriptSegment
```

Nada del incremento 1 apunta hacia el incremento 2: la dirección es siempre de lo nuevo hacia
lo viejo. Por eso la migración es aditiva y por eso `sessions` no necesita saber que las
grabaciones existen.

El glosario es la única pieza del incremento 1 que este incremento **consume**, y lo hace tal
como el roadmap exigió que quedara: como lista plana de términos, consultable sin
transformación.
