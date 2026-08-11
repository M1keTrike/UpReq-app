# Domain Contracts

**Feature**: 001-proyectos-interesados-sesiones
**Source**: [spec.md](../spec.md) · [data-model.md](../data-model.md) · [research.md](../research.md)

Contratos de `domain`. Estos archivos no importan `package:flutter` ni nada de
infraestructura (prohibición constitucional). Un caso de uso por operación.

Firma común: todo caso de uso devuelve `Future<Result<T>>`, donde `Result` es un sealed con
`Ok<T>` y `Err<Failure>`. Los fallos son los de la tabla de [data-model.md](../data-model.md).

---

## Contrato compartido (`lib/core/domain`)

```dart
/// Único punto por el que una feature conoce el estado de un proyecto.
/// Existe para que interesados, sesiones, guion y glosario puedan aplicar
/// FR-004a sin importar `features/projects` (aislamiento entre features).
abstract interface class ProjectStatusReader {
  Future<bool> isActive(ProjectId id);
}
```

Implementado por la feature de proyectos, registrado en `core` mediante un provider. Toda
escritura de cualquier feature lo consulta primero.

---

## Projects

```dart
abstract interface class ProjectRepository {
  Stream<List<Project>> watchByStatus(ProjectStatus status);   // FR-003, FR-004
  Stream<Project?> watchById(ProjectId id);
  Stream<ProjectCounters> watchCounters(ProjectId id);         // FR-013
  Future<Project?> findById(ProjectId id);
  Future<void> insert(Project project);
  Future<void> update(Project project);
  /// Cambia status y asienta bitácora en la MISMA transacción. FR-004, FR-004b, FR-015.
  Future<void> setStatus(ProjectId id, ProjectStatus status, DateTime at);
}
```

| Caso de uso | Firma | Precondiciones y efectos |
|---|---|---|
| `WatchActiveProjects` | `Stream<List<Project>> call()` | FR-003 |
| `WatchClosedProjects` | `Stream<List<Project>> call()` | FR-004, filtro de cerrados |
| `WatchProjectDetail` | `Stream<ProjectDetail> call(ProjectId)` | Proyecto + contadores, un solo stream (FR-013) |
| `CreateProject` | `Future<Result<ProjectId>> call(ProjectDraft)` | Valida `name`; sella `created_at`/`updated_at` |
| `UpdateProject` | `Future<Result<void>> call(ProjectId, ProjectDraft)` | Rechaza con `ProjectClosedFailure` si está cerrado |
| `CloseProject` | `Future<Result<void>> call(ProjectId)` | `active → closed`; asienta `projectClosed` |
| `ReopenProject` | `Future<Result<void>> call(ProjectId)` | `closed → active`; asienta `projectReopened` |

---

## Stakeholders

```dart
abstract interface class StakeholderRepository {
  Stream<List<Stakeholder>> watchByProject(ProjectId id);        // activos e inactivos
  Stream<List<Stakeholder>> watchSelectableByProject(ProjectId); // solo activos, para sesiones
  Future<Stakeholder?> findById(StakeholderId id);
  Future<void> insert(Stakeholder s);
  Future<void> update(Stakeholder s);
  /// Desactiva y asienta bitácora en la misma transacción. FR-006, FR-015.
  Future<void> deactivate(StakeholderId id, DateTime at);
}
```

| Caso de uso | Firma | Precondiciones y efectos |
|---|---|---|
| `WatchStakeholders` | `Stream<List<Stakeholder>> call(ProjectId)` | FR-005, siempre filtrado por proyecto (FR-018) |
| `CreateStakeholder` | `Future<Result<StakeholderId>> call(ProjectId, StakeholderDraft)` | Proyecto activo; `name` e `influence` obligatorios |
| `UpdateStakeholder` | `Future<Result<void>> call(StakeholderId, StakeholderDraft)` | Proyecto activo |
| `DeactivateStakeholder` | `Future<Result<void>> call(StakeholderId)` | Proyecto activo; asienta `stakeholderDeactivated`; conserva participaciones |

---

## Sessions (incluye el guion)

El guion vive dentro de la feature `sessions` porque no tiene existencia fuera de su sesión
y porque el contador de la sesión lo necesita. Separarlo obligaría a una dependencia
cruzada entre features.

```dart
abstract interface class SessionRepository {
  Stream<List<ElicitationSession>> watchByProject(ProjectId id);   // vivas
  Stream<SessionDetail?> watchDetail(SessionId id);                // sesión + participantes + contadores
  Future<ElicitationSession?> findById(SessionId id);
  /// Inserta sesión y participantes en una transacción. FR-009.
  Future<void> insert(ElicitationSession s, List<StakeholderId> participants);
  Future<void> updateHeader(ElicitationSession s, List<StakeholderId> participants);
  Future<void> updateNotes(SessionId id, String? notes, DateTime at);
  Future<void> setStatus(SessionId id, SessionStatus status, DateTime at);
  /// Marca deleted_at y asienta bitácora en la misma transacción. FR-014a, FR-015.
  Future<void> softDelete(SessionId id, DateTime at);
}

abstract interface class ScriptPointRepository {
  Stream<List<ScriptPoint>> watchBySession(SessionId id);          // vivos, ordenados por position
  /// Inserta en position = n. FR-010.
  Future<void> append(ScriptPoint point);
  Future<void> updateText(ScriptPointId id, String text, DateTime at);
  Future<void> setStatus(ScriptPointId id, ScriptPointStatus status, DateTime at);
  /// Desplazamiento en bloque en una transacción; mantiene 0..n-1. Decisión 8 de research.
  Future<void> move(SessionId session, ScriptPointId id, int from, int to);
  /// Marca deleted_at, compacta posiciones y asienta bitácora, todo en una transacción.
  Future<void> softDelete(ScriptPointId id, DateTime at);
}
```

**Función pura de transición**, en `domain`, probada exhaustivamente:

```dart
Result<SessionStatus> transitionSession(SessionStatus from, SessionStatus to);
// planned → inProgress | closed      ✔
// inProgress → closed                ✔
// cualquier retroceso                ✘ InvalidSessionTransitionFailure
```

| Caso de uso | Firma | Precondiciones y efectos |
|---|---|---|
| `WatchSessions` | `Stream<List<ElicitationSession>> call(ProjectId)` | Solo vivas |
| `WatchSessionDetail` | `Stream<SessionDetail> call(SessionId)` | Sesión, participantes y contadores (FR-013) |
| `CreateSession` | `Future<Result<SessionId>> call(ProjectId, SessionDraft)` | Proyecto activo; ≥1 participante; todos del mismo proyecto o `CrossProjectReferenceFailure` |
| `UpdateSessionHeader` | `Future<Result<void>> call(SessionId, SessionDraft)` | Proyecto activo; `SessionHeaderFrozenFailure` si la sesión está cerrada (FR-008b) |
| `UpdateSessionNotes` | `Future<Result<void>> call(SessionId, String?)` | Proyecto activo; permitido con la sesión cerrada |
| `AdvanceSessionStatus` | `Future<Result<void>> call(SessionId, SessionStatus)` | Usa `transitionSession`; sella `closed_at` al cerrar |
| `DeleteSession` | `Future<Result<void>> call(SessionId)` | Proyecto activo; asienta `sessionDeleted` |
| `AddScriptPoint` | `Future<Result<ScriptPointId>> call(SessionId, String)` | Proyecto activo; `text` no vacío; `position = n` |
| `UpdateScriptPointText` | `Future<Result<void>> call(ScriptPointId, String)` | Proyecto activo; permitido con la sesión cerrada (FR-011) |
| `MarkScriptPoint` | `Future<Result<void>> call(ScriptPointId, ScriptPointStatus)` | Proyecto activo; libre entre los tres estados |
| `ReorderScriptPoint` | `Future<Result<void>> call(SessionId, ScriptPointId, int from, int to)` | Proyecto activo; preserva el invariante `0..n-1` |
| `DeleteScriptPoint` | `Future<Result<void>> call(ScriptPointId)` | Proyecto activo; compacta posiciones; asienta `scriptPointDeleted` |

---

## Glossary

```dart
abstract interface class GlossaryRepository {
  /// Vivos, ordenados por term_sort_key. FR-012.
  Stream<List<GlossaryTerm>> watchByProject(ProjectId id);
  Future<GlossaryTerm?> findById(GlossaryTermId id);
  Future<void> insert(GlossaryTerm t);
  Future<void> update(GlossaryTerm t);
  Future<void> softDelete(GlossaryTermId id, DateTime at);
}
```

| Caso de uso | Firma | Precondiciones y efectos |
|---|---|---|
| `WatchGlossary` | `Stream<List<GlossaryTerm>> call(ProjectId)` | Orden alfabético por `term_sort_key` |
| `CreateGlossaryTerm` | `Future<Result<GlossaryTermId>> call(ProjectId, GlossaryTermDraft)` | Proyecto activo; calcula `term_sort_key` |
| `UpdateGlossaryTerm` | `Future<Result<void>> call(GlossaryTermId, GlossaryTermDraft)` | Proyecto activo; recalcula `term_sort_key` |
| `DeleteGlossaryTerm` | `Future<Result<void>> call(GlossaryTermId)` | Proyecto activo; asienta `glossaryTermDeleted` |

---

## Audit log

Solo lectura. No expone ninguna escritura: los asientos los inserta cada repositorio dentro
de su propia transacción (decisión 7 de research).

```dart
abstract interface class AuditRepository {
  /// Del más reciente al más antiguo. FR-015a.
  Stream<List<AuditEntry>> watchByProject(ProjectId id);
}
```

| Caso de uso | Firma |
|---|---|
| `WatchAuditLog` | `Stream<List<AuditEntry>> call(ProjectId)` |

---

## Invariantes que las pruebas deben verificar

| # | Invariante | Origen |
|---|---|---|
| I1 | Ninguna operación borra filas físicamente | FR-014 |
| I2 | Toda baja lógica deja exactamente un asiento de bitácora, en la misma transacción | FR-015 |
| I3 | Las posiciones vivas de una sesión son siempre `{0..n-1}` | FR-010, FR-011 |
| I4 | Ninguna consulta de lista devuelve datos de otro proyecto | FR-018 |
| I5 | Ninguna escritura prospera con el proyecto cerrado | FR-004a |
| I6 | Ninguna transición de sesión retrocede | FR-008a |
| I7 | La cabecera de una sesión cerrada no cambia; notas y guion sí | FR-008b |
| I8 | Una sesión nunca queda sin participantes ni con participantes de otro proyecto | FR-009 |
