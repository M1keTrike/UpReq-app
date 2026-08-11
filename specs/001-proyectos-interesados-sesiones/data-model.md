# Phase 1 Data Model: Gestión de proyectos, interesados y sesiones de elicitación

**Feature**: 001-proyectos-interesados-sesiones
**Date**: 2026-08-10
**Source**: [spec.md](spec.md) · decisiones en [research.md](research.md)

Fuente única de verdad: SQLite mediante drift, esquema en versión 1 con migración inicial
declarada explícitamente (FR-017). Toda entidad lleva identificador propio, `created_at` y
`updated_at` (FR-016). Todo identificador es UUID v4 almacenado como `TEXT`.

---

## Convenciones transversales

**Columnas comunes a toda tabla de entidad**

| Columna | Tipo | Regla |
|---|---|---|
| `id` | `TEXT` PK | UUID v4 generado en Dart |
| `created_at` | `INTEGER` (epoch UTC) | Obligatoria, inmutable |
| `updated_at` | `INTEGER` (epoch UTC) | Obligatoria, se actualiza en toda escritura |

**Aislamiento por proyecto (FR-018)**: toda tabla salvo `projects` lleva `project_id` y
toda consulta de lectura lo filtra. En las tablas que cuelgan de una sesión, `project_id` se
mantiene **desnormalizado** para que el filtro por proyecto no exija un join y para que
ninguna consulta pueda escribirse sin él por descuido.

**Baja lógica**: tres mecanismos distintos que no comparten columna.

| Mecanismo | Entidades | Columna | Reversible |
|---|---|---|---|
| Cierre / reapertura | Proyecto | `status` | Sí (FR-004b) |
| Desactivación | Interesado | `status` | No definido en este incremento |
| Eliminación lógica | Sesión, punto de guion, término | `deleted_at` nullable | No |

Ninguna fila se borra físicamente (FR-014). Las consultas de lista pasan siempre por el
helper `alive()` del DAO correspondiente.

---

## Entidades

### Project — `projects`

| Columna | Tipo | Nulo | Reglas |
|---|---|---|---|
| `id` | TEXT PK | no | UUID v4 |
| `name` | TEXT | no | Obligatorio, no vacío tras recortar, 1–120 |
| `client` | TEXT | sí | 0–120 |
| `description` | TEXT | sí | 0–500 |
| `status` | TEXT | no | `active` \| `closed`, por defecto `active` |
| `created_at` | INTEGER | no | |
| `updated_at` | INTEGER | no | |

- FR-002, FR-003. `created_at` es la "fecha de creación" que la lista muestra.
- Índice: `CREATE INDEX projects_status ON projects (status, name)`.
- **Sin** `deleted_at`: un proyecto se cierra, no se elimina.

**Transiciones de estado** (FR-004, FR-004a, FR-004b)

```text
active  ──cerrar──▶  closed
closed  ──reabrir─▶  active
```

Ambas transiciones asientan bitácora. Mientras `status = 'closed'`, **toda** escritura sobre
el proyecto y sobre cualquier entidad cuyo `project_id` apunte a él queda rechazada en
dominio con `ProjectClosedFailure`.

---

### Stakeholder — `stakeholders`

| Columna | Tipo | Nulo | Reglas |
|---|---|---|---|
| `id` | TEXT PK | no | UUID v4 |
| `project_id` | TEXT FK → `projects.id` | no | FR-007: pertenece a un solo proyecto |
| `name` | TEXT | no | Obligatorio, no vacío tras recortar, 1–120 |
| `role` | TEXT | sí | Rol en la organización, 0–120 |
| `area` | TEXT | sí | 0–120 |
| `influence` | TEXT | no | `high` \| `medium` \| `low` |
| `notes` | TEXT | sí | Notas libres |
| `status` | TEXT | no | `active` \| `inactive`, por defecto `active` |
| `created_at` | INTEGER | no | |
| `updated_at` | INTEGER | no | |

- FR-005, FR-006, FR-007.
- Índice: `CREATE INDEX stakeholders_project ON stakeholders (project_id, status, name)`.
- Desactivar asienta bitácora y **conserva** las participaciones históricas en sesiones.
- Un interesado `inactive` no se ofrece al elegir participantes de una sesión nueva
  (supuesto declarado en la spec), pero sigue mostrándose en las sesiones donde ya participa.

---

### ElicitationSession — `sessions`

| Columna | Tipo | Nulo | Reglas |
|---|---|---|---|
| `id` | TEXT PK | no | UUID v4 |
| `project_id` | TEXT FK → `projects.id` | no | |
| `title` | TEXT | no | Obligatorio, no vacío tras recortar, 1–160 |
| `scheduled_at` | INTEGER | no | Fecha y hora, epoch UTC |
| `technique` | TEXT | no | `openInterview` \| `structuredInterview` \| `workshop` \| `observation` \| `documentReview` |
| `location` | TEXT | sí | 0–160 |
| `status` | TEXT | no | `planned` \| `inProgress` \| `closed`, por defecto `planned` |
| `notes` | TEXT | sí | Notas libres |
| `closed_at` | INTEGER | sí | Se sella al pasar a `closed`; null en otro caso |
| `deleted_at` | INTEGER | sí | Eliminación lógica (FR-014a) |
| `created_at` | INTEGER | no | |
| `updated_at` | INTEGER | no | |

- FR-008, FR-008a, FR-008b, FR-009, FR-014a.
- Índices:
  `CREATE INDEX sessions_project ON sessions (project_id, scheduled_at) WHERE deleted_at IS NULL`
- Una sesión debe tener **al menos un** participante (FR-009). La restricción no es
  expresable en el esquema; se valida en dominio dentro de la transacción de creación y de
  edición.

**Transiciones de estado** (FR-008a) — avance en un solo sentido, sin retroceso ni reapertura

```text
planned ──▶ inProgress ──▶ closed
```

| Desde \ Hacia | planned | inProgress | closed |
|---|---|---|---|
| **planned** | — | permitida | permitida |
| **inProgress** | rechazada | — | permitida |
| **closed** | rechazada | rechazada | — |

`planned → closed` se admite: una sesión puede cerrarse sin haber pasado por "en curso"
(una entrevista que se documenta después). Cualquier transición marcada como rechazada
devuelve `InvalidSessionTransitionFailure`.

**Congelado de cabecera al cerrar** (FR-008b)

| Campo | Editable con `closed` |
|---|---|
| `title`, `scheduled_at`, `technique`, `location`, participantes | **No** |
| `notes` | Sí |
| Puntos del guion (tabla aparte) | Sí |

Todo lo anterior queda además sujeto a que el **proyecto** siga activo (FR-004a).

---

### SessionParticipant — `session_participants`

Tabla de unión que resuelve la relación muchos-a-muchos entre sesión e interesado.

| Columna | Tipo | Nulo | Reglas |
|---|---|---|---|
| `session_id` | TEXT FK → `sessions.id` | no | |
| `stakeholder_id` | TEXT FK → `stakeholders.id` | no | |
| `project_id` | TEXT | no | Desnormalizado, debe coincidir con el de ambos extremos |
| `created_at` | INTEGER | no | |

- Clave primaria compuesta `(session_id, stakeholder_id)`.
- FR-009: el interesado referenciado **debe** pertenecer al mismo proyecto que la sesión. La
  restricción se valida en dominio; `project_id` desnormalizado permite además verificarla
  en pruebas con una sola consulta.
- Sin `deleted_at`: quitar un participante de una sesión abierta es una edición de la
  sesión, no una baja de entidad. Al eliminar lógicamente una sesión, sus filas de
  participación permanecen intactas (la sesión deja de listarse, nada se destruye).

---

### ScriptPoint — `script_points`

| Columna | Tipo | Nulo | Reglas |
|---|---|---|---|
| `id` | TEXT PK | no | UUID v4 |
| `session_id` | TEXT FK → `sessions.id` | no | |
| `project_id` | TEXT | no | Desnormalizado para el filtro de FR-018 |
| `text` | TEXT | no | Obligatorio, no vacío tras recortar, 1–500 |
| `status` | TEXT | no | `pending` \| `covered` \| `skipped`, por defecto `pending` |
| `position` | INTEGER | no | Contigua `0..n-1` dentro de la sesión |
| `deleted_at` | INTEGER | sí | Eliminación lógica (FR-014) |
| `created_at` | INTEGER | no | |
| `updated_at` | INTEGER | no | |

- FR-010, FR-011.
- Índice: `CREATE INDEX script_points_session ON script_points (session_id, position) WHERE deleted_at IS NULL`.
- **Sin restricción `UNIQUE (session_id, position)`** — decisión 8 de research: SQLite
  evalúa `UNIQUE` fila a fila durante un `UPDATE` masivo, lo que rompería el desplazamiento
  en bloque del reordenamiento.

**Invariante de posición** (verificado en pruebas, no por el esquema)

> Para toda sesión, el conjunto de posiciones de sus puntos vivos es exactamente
> `{0, 1, …, n-1}`, sin huecos ni repeticiones.

Las tres operaciones que lo mantienen, cada una en una sola transacción:

| Operación | Efecto sobre las posiciones |
|---|---|
| Agregar | El punto nuevo toma `position = n` |
| Reordenar de `from` a `to` | Desplaza en bloque el rango intermedio ±1 y fija el movido en `to` |
| Eliminar lógicamente | Marca `deleted_at` y compacta `−1` todas las posiciones mayores |

**Transiciones de estado del punto** (FR-011): libres entre `pending`, `covered` y
`skipped`, en cualquier dirección y en cualquier momento, incluso con la sesión cerrada,
siempre que el proyecto esté activo.

---

### GlossaryTerm — `glossary_terms`

| Columna | Tipo | Nulo | Reglas |
|---|---|---|---|
| `id` | TEXT PK | no | UUID v4 |
| `project_id` | TEXT FK → `projects.id` | no | |
| `term` | TEXT | no | Obligatorio, no vacío tras recortar, 1–120 |
| `definition` | TEXT | sí | 0–2000 |
| `notes` | TEXT | sí | |
| `term_sort_key` | TEXT | no | `term` normalizado: minúsculas y sin acentos |
| `deleted_at` | INTEGER | sí | Eliminación lógica (FR-014a) |
| `created_at` | INTEGER | no | |
| `updated_at` | INTEGER | no | |

- FR-012.
- Índice: `CREATE INDEX glossary_project ON glossary_terms (project_id, term_sort_key) WHERE deleted_at IS NULL`.
- `term_sort_key` es columna almacenada, no calculada en la consulta, porque el
  ordenamiento alfabético debe ignorar mayúsculas y acentos (supuesto declarado en la spec)
  y `ORDER BY` de SQLite no lo hace sin una colación personalizada. Se recalcula en cada
  escritura del término.
- Este incremento **no** impone unicidad del término dentro del proyecto: el insumo no la
  pide y el glosario se describe como editable libremente.

---

### AuditEntry — `audit_entries`

| Columna | Tipo | Nulo | Reglas |
|---|---|---|---|
| `id` | TEXT PK | no | UUID v4 |
| `project_id` | TEXT FK → `projects.id` | no | La bitácora se consulta por proyecto |
| `operation` | TEXT | no | Ver catálogo abajo |
| `entity_type` | TEXT | no | `project` \| `stakeholder` \| `session` \| `scriptPoint` \| `glossaryTerm` |
| `entity_id` | TEXT | no | Identificador de la entidad afectada |
| `entity_label` | TEXT | sí | Copia del nombre/título al momento del asiento |
| `occurred_at` | INTEGER | no | Fecha y hora del asiento, epoch UTC |
| `created_at` | INTEGER | no | |
| `updated_at` | INTEGER | no | |

- FR-015, FR-015a.
- Índice: `CREATE INDEX audit_project ON audit_entries (project_id, occurred_at DESC)`.
- **Inmutable y de solo lectura**: no tiene `deleted_at` ni operación de escritura expuesta.
  El único camino de inserción es dentro de la transacción de la operación que registra
  (decisión 7 de research).
- `entity_label` se copia en el momento del asiento para que la bitácora siga siendo legible
  aunque la entidad se renombre después. Es duplicación deliberada.

**Catálogo de operaciones**

| `operation` | Origen |
|---|---|
| `projectClosed` | FR-004 |
| `projectReopened` | FR-004b |
| `stakeholderDeactivated` | FR-006 |
| `sessionDeleted` | FR-014a |
| `scriptPointDeleted` | FR-014 |
| `glossaryTermDeleted` | FR-014a |

Este incremento **no** asienta altas ni ediciones: FR-015 acota la bitácora a "toda
operación lógica de cierre, desactivación o eliminación", y FR-004b añade la reapertura.

---

## Relaciones

```text
Project 1 ──── N Stakeholder
Project 1 ──── N ElicitationSession
Project 1 ──── N GlossaryTerm
Project 1 ──── N AuditEntry

ElicitationSession 1 ──── N ScriptPoint
ElicitationSession N ──── N Stakeholder   (vía session_participants)
```

Todas las claves foráneas se declaran con `references(...)` y `PRAGMA foreign_keys = ON` se
activa en `beforeOpen`. **Ninguna** usa `onDelete: cascade`: nada se borra físicamente, así
que el borrado en cascada no debe existir siquiera como posibilidad.

---

## Vistas derivadas para contadores (FR-013)

No son vistas SQL sino consultas de agregación expuestas como stream (decisión 9 de
research). Se agrupan en un único provider por pantalla para no multiplicar las
re-ejecuciones que provoca la invalidación por tabla de drift.

**`ProjectCounters`** — detalle de proyecto

| Campo | Consulta |
|---|---|
| `stakeholders` | `COUNT(*)` de interesados `active` del proyecto |
| `sessions` | `COUNT(*)` de sesiones vivas del proyecto |
| `glossaryTerms` | `COUNT(*)` de términos vivos del proyecto |

**`SessionCounters`** — detalle de sesión

| Campo | Consulta |
|---|---|
| `pending` / `covered` / `skipped` | `COUNT(*)` de puntos vivos agrupados por `status` |
| `total` | Suma de los tres |

---

## Reglas de validación por formulario (FR-022)

| Formulario | Reglas |
|---|---|
| Proyecto | `name` obligatorio no vacío; resto opcional |
| Interesado | `name` obligatorio no vacío; `influence` obligatorio con valor por defecto `medium` |
| Sesión | `title` obligatorio; `scheduled_at` obligatorio; `technique` obligatoria; **al menos un participante**, todos del mismo proyecto |
| Punto de guion | `text` obligatorio no vacío |
| Término | `term` obligatorio no vacío |

La validación falla **antes** de tocar la base de datos y el formulario conserva lo escrito.
Los límites de longitud se validan en dominio; el esquema no los replica como `CHECK`, para
que el mensaje de error lo produzca siempre la misma capa.

---

## Fallos tipados del dominio

Un `sealed class Failure` en `core/domain` con las variantes que las pruebas verifican:

| Fallo | Cuándo |
|---|---|
| `ValidationFailure` | Alguna regla de la tabla anterior no se cumple |
| `ProjectClosedFailure` | Escritura sobre cualquier entidad de un proyecto cerrado (FR-004a) |
| `InvalidSessionTransitionFailure` | Transición de estado no permitida (FR-008a) |
| `SessionHeaderFrozenFailure` | Edición de cabecera con la sesión cerrada (FR-008b) |
| `CrossProjectReferenceFailure` | Participante de otro proyecto (FR-009, FR-018) |
| `NotFoundFailure` | La entidad no existe o ya está dada de baja |
| `StorageFailure` | Error de la base de datos |

---

## Migración inicial

`schemaVersion = 1`. `MigrationStrategy.onCreate` declarado explícitamente con
`m.createAll()` aunque sea el comportamiento por defecto de drift, porque FR-017 lo exige.
El snapshot `drift_schemas/drift_schema_v1.json` se genera con `dart run drift_dev
make-migrations` y queda versionado en el repositorio para que el incremento 2 encuentre la
infraestructura de migración ya montada.
