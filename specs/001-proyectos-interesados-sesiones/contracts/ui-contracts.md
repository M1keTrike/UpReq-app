# UI Contracts

**Feature**: 001-proyectos-interesados-sesiones
**Source**: [spec.md](../spec.md) · [research.md](../research.md)

Contrato de cada pantalla: ruta, provider único, situaciones que resuelve y escrituras que
expone. Reglas constitucionales que este documento hace verificables:

- Cada pantalla consume **un único** provider que devuelve `AsyncValue<T>` con `T`
  inmutable.
- Las cuatro situaciones —cargando, datos, vacío, error— se resuelven de forma exhaustiva.
  `AsyncValue` es `sealed` en Riverpod 3, así que el `switch` no lleva `default`; el caso
  vacío se resuelve dentro de la rama de datos.
- Ninguna escritura se hace con métodos sueltos: cada una es un `Mutation<T>` observable
  (decisión 1 de research).
- Ningún widget importa `drift`, `dio` ni DTOs.

---

## Widget compartido de situaciones — `core/widgets`

```dart
class AsyncScaffoldBody<T> extends StatelessWidget {
  const AsyncScaffoldBody({
    required this.value,        // AsyncValue<T>
    required this.isEmpty,      // bool Function(T)
    required this.empty,        // WidgetBuilder — invitación a crear (FR-020)
    required this.data,         // Widget Function(T)
    this.onRetry,
  });
}
```

Un solo lugar donde vive el `switch` exhaustivo, para que "resuelve sus cuatro situaciones"
sea una propiedad estructural y no una convención repetida en cada pantalla.

---

## Pantallas

### 1. Lista de proyectos — `/`

| Aspecto | Contrato |
|---|---|
| Provider | `projectListProvider` → `AsyncValue<ProjectListState>` |
| Estado | `ProjectListState({ List<ProjectSummary> projects, ProjectFilter filter })` con `filter ∈ {active, closed}` |
| Vacío | Filtro `active`: invitación a crear el primer proyecto. Filtro `closed`: mensaje de que no hay proyectos cerrados |
| Escrituras | `createProject`, `closeProject`, `reopenProject` |
| Navega a | `/projects/new`, `/projects/:id` |

Requisitos: FR-001, FR-003, FR-004, FR-020.

### 2. Formulario de proyecto — `/projects/new` · `/projects/:projectId/edit`

| Aspecto | Contrato |
|---|---|
| Provider | `projectFormProvider(projectId?)` → `AsyncValue<ProjectFormState>` |
| Escrituras | `saveProject` |
| Validación | `name` obligatorio; el estado del formulario conserva lo escrito cuando la validación falla (FR-022) |

El `MutationError` se muestra junto al campo sin vaciar el formulario.

### 3. Detalle de proyecto — `/projects/:projectId`

| Aspecto | Contrato |
|---|---|
| Provider | `projectDetailProvider(projectId)` → `AsyncValue<ProjectDetailState>` |
| Estado | Proyecto + `ProjectCounters` + `bool isReadOnly` |
| Vacío | No aplica: si el proyecto no existe, es `AsyncError` con `NotFoundFailure` |
| Escrituras | `closeProject`, `reopenProject` |
| Navega a | interesados, sesiones, glosario, bitácora, edición |

`isReadOnly` deriva de `status == closed` y **oculta toda acción de escritura de las
pantallas hijas** (FR-004a). La ocultación es comodidad; la garantía está en dominio.
Requisitos: FR-013, FR-021.

### 4. Interesados — `/projects/:projectId/stakeholders`

| Aspecto | Contrato |
|---|---|
| Provider | `stakeholderListProvider(projectId)` → `AsyncValue<StakeholderListState>` |
| Vacío | Invitación a crear el primer interesado |
| Escrituras | `deactivateStakeholder` |
| Formulario | `/new` y `/:stakeholderId/edit` con `stakeholderFormProvider`, escritura `saveStakeholder` |

Los inactivos se listan con distintivo visible y no se ofrecen al elegir participantes.
Requisitos: FR-005, FR-006, FR-007.

### 5. Sesiones — `/projects/:projectId/sessions`

| Aspecto | Contrato |
|---|---|
| Provider | `sessionListProvider(projectId)` → `AsyncValue<SessionListState>` |
| Vacío | Invitación a crear la primera sesión |
| Escrituras | `deleteSession` |
| Formulario | `/new` y `/:sessionId/edit` con `sessionFormProvider`, escritura `saveSession` |

El selector de participantes se alimenta de `watchSelectableByProject`, de modo que
estructuralmente no puede ofrecer interesados de otro proyecto (FR-009). Con la sesión
cerrada, el formulario de edición renderiza la cabecera deshabilitada y solo admite notas
(FR-008b). Requisitos: FR-008, FR-009.

### 6. Detalle de sesión y guion — `/projects/:projectId/sessions/:sessionId`

| Aspecto | Contrato |
|---|---|
| Provider | `sessionDetailProvider(sessionId)` → `AsyncValue<SessionDetailState>` |
| Estado | Sesión + participantes + `List<ScriptPoint>` + `SessionCounters` + `bool isHeaderFrozen` + `bool isReadOnly` |
| Vacío | Sesión con guion vacío: invitación a agregar el primer punto |
| Escrituras | `advanceSessionStatus`, `addScriptPoint`, `updateScriptPointText`, `markScriptPoint`, `reorderScriptPoint`, `deleteScriptPoint` |

Un único provider para sesión y guion: son el mismo agregado y separarlos multiplicaría las
re-consultas que provoca la invalidación por tabla de drift (decisión 9 de research).

El control de estado ofrece **solo** las transiciones válidas desde el estado actual; un
retroceso no se renderiza (FR-008a). El reordenamiento usa `ReorderableListView` y llama a
`reorderScriptPoint` con `from` y `to`. Requisitos: FR-010, FR-011, FR-013.

### 7. Glosario — `/projects/:projectId/glossary`

| Aspecto | Contrato |
|---|---|
| Provider | `glossaryListProvider(projectId)` → `AsyncValue<GlossaryListState>` |
| Vacío | Invitación a agregar el primer término |
| Escrituras | `deleteGlossaryTerm` |
| Formulario | `/new` y `/:termId/edit` con `glossaryFormProvider`, escritura `saveGlossaryTerm` |

Orden alfabético resuelto en SQL por `term_sort_key`, nunca ordenando en Dart.
Requisitos: FR-012.

### 8. Bitácora — `/projects/:projectId/audit`

| Aspecto | Contrato |
|---|---|
| Provider | `auditLogProvider(projectId)` → `AsyncValue<AuditLogState>` |
| Vacío | **Excepción declarada a FR-020**: explica que aún no hay operaciones asentadas, sin invitar a crear nada |
| Escrituras | Ninguna. La pantalla no expone ningún `Mutation` |

Del más reciente al más antiguo. Requisitos: FR-015a.

---

## Contrato de escritura (`Mutation`)

Toda escritura de la tabla anterior sigue la misma forma:

```dart
final saveProject = Mutation<ProjectId>();

// disparo desde un callback
saveProject.run(ref, (tsx) async {
  final result = await tsx.get(createProjectProvider)(draft);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});

// consumo en build
switch (ref.watch(saveProject)) {
  case MutationIdle():    // botón habilitado
  case MutationPending(): // botón deshabilitado + progreso
  case MutationError(:final error): // mensaje, formulario intacto
  case MutationSuccess(): // navegar atrás
}
```

Prohibido derivar el progreso de una escritura de una bandera `isLoading` o `hasError` en el
estado de pantalla.

---

## Mapa pantalla ↔ requisitos

| Pantalla | Requisitos |
|---|---|
| Lista de proyectos | FR-001, FR-003, FR-004 |
| Formulario de proyecto | FR-002, FR-022 |
| Detalle de proyecto | FR-004a, FR-004b, FR-013, FR-021 |
| Interesados | FR-005, FR-006, FR-007 |
| Sesiones | FR-008, FR-008b, FR-009, FR-014a |
| Detalle de sesión y guion | FR-008a, FR-010, FR-011, FR-013, FR-014 |
| Glosario | FR-012, FR-014a |
| Bitácora | FR-015, FR-015a |
| Todas | FR-016, FR-018, FR-019, FR-020, FR-022, FR-023 |
