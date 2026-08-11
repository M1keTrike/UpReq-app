# Phase 0 Research: Gestión de proyectos, interesados y sesiones de elicitación

**Feature**: 001-proyectos-interesados-sesiones
**Date**: 2026-08-10
**Input**: [spec.md](spec.md), [constitution.md](../../.specify/memory/constitution.md)

Toda decisión se contrasta contra la constitución. Cuando la realidad de las librerías
contradice una regla constitucional, se declara aquí y se escala al gate de Constitution
Check en [plan.md](plan.md); no se resuelve en silencio.

---

## 0. Estado del entorno

**Hallazgo inicial**: el toolchain instalado era Flutter 3.44.0 / Dart 3.12.0, mientras la
constitución v1.1.0 exigía Flutter 3.44.7 con Dart 3.12.1.

**Actualización del 2026-08-10**: ejecutado `flutter upgrade`, el toolchain quedó en Flutter
3.44.9 / Dart 3.12.2, dos parches **por encima** de lo fijado. `flutter upgrade` sigue el
canal stable y no admite un destino exacto, de modo que repetirlo no acercaba a 3.44.7.

**Resuelto**: la constitución v1.1.1 fija ahora Flutter 3.44.9 con Dart 3.12.2. El entorno
coincide con lo declarado y el gate de plataforma pasa sin salvedades.

**Alternativa descartada**: anclar el toolchain a 3.44.7 / 3.12.1 con FVM y dejar la
constitución intacta. Habría exigido renunciar a dos parches de correcciones ya instalados
para satisfacer un número escrito antes de que existieran.

**Regla que queda viva**: la constitución fija versiones exactas y CI las verifica. Cuando
una actualización futura mueva el canal stable, hay que anclar o enmendar antes de seguir;
convivir con la discrepancia dejaría esa puerta de CI fallando de forma permanente, que es
el modo en que una regla se convierte en ruido que todo el mundo ignora.

---

## 1. CONFLICTO (resuelto en constitución v1.1.0) — `@mutation` no existe

**Hallazgo verificado**: la constitución exige "escrituras expuestas con `@mutation`". La
anotación `@mutation` existió solo en preversiones de `riverpod_generator`
(3.0.0-dev.12, abril 2026) y **fue eliminada** en 3.0.0-dev.16 con la nota "Reworked
Mutations to be independent from code-generation". En `riverpod_annotation` 4.0.6 —la
versión que fija la constitución— no se exporta ninguna anotación `mutation`.

Las mutaciones **sí existen**, pero como objeto y no como anotación, y están marcadas como
experimentales por la documentación oficial: "Mutations are experimental, and the API may
change in a breaking way without a major version bump."

```dart
import 'package:riverpod/experimental/mutation.dart';

final createProject = Mutation<ProjectId>();

// disparo
createProject.run(ref, (tsx) async {
  final notifier = tsx.get(projectListProvider.notifier);
  return notifier.create(draft);
});

// consumo con switch exhaustivo
switch (ref.watch(createProject)) {
  case MutationIdle(): ...
  case MutationPending(): ...
  case MutationError(): ...
  case MutationSuccess(): ...
}
```

**Decisión**: usar la API experimental `Mutation<T>` de
`package:riverpod/experimental/mutation.dart` para toda escritura de formulario y toda
operación lógica (cerrar, reabrir, desactivar, eliminar, reordenar).

**Rationale**: es lo que preserva la intención constitucional —que las escrituras sean
objetos observables con estado propio, no banderas dentro del estado de pantalla— y resuelve
además el problema real de que un provider autoDispose muera a mitad de un `onPressed`. El
riesgo de que la API rompa está contenido porque la constitución fija versiones exactas de
todos los paquetes, de modo que una actualización nunca llega sola.

**Alternativas consideradas**:
- Métodos normales del Notifier moviendo `state` a `AsyncLoading` durante la escritura:
  estable y convencional, pero mezcla el progreso de la escritura con el estado de la
  pantalla, que es exactamente lo que la constitución quiere evitar.
- Esperar a que las mutaciones dejen de ser experimentales: bloquearía el incremento.

**Resuelto**: la constitución v1.1.0 sustituyó "escrituras expuestas con `@mutation`" por la
API real y añadió una viñeta que documenta y acota la aceptación de esta dependencia
experimental. Ver Constitution Check en [plan.md](plan.md).

**Fuentes**: https://riverpod.dev/docs/concepts2/mutations ·
https://pub.dev/packages/riverpod_generator/changelog ·
https://pub.dev/documentation/riverpod/latest/experimental_mutation/Mutation-class.html

---

## 2. CONFLICTO (resuelto en constitución v1.1.0) — `riverpod_lint` sin `custom_lint`

**Hallazgo verificado**: la constitución exige "riverpod_lint sobre custom_lint activo en
CI". Desde `riverpod_lint` 3.1.0 (diciembre 2025) el paquete dejó de implementarse sobre
`custom_lint` y pasó a `analysis_server_plugin`. La configuración actual es:

```yaml
# analysis_options.yaml
plugins:
  riverpod_lint: 3.1.8
```

Ya no se declara `custom_lint` en `dev_dependencies`, ya no se añade el bloque
`analyzer: plugins: - custom_lint`, y en CI se ejecuta `dart analyze` en lugar de
`dart run custom_lint`.

**Decisión**: configurar `riverpod_lint` con el mecanismo `plugins:` y bloquear el merge con
`dart analyze`.

**Rationale**: la intención constitucional —reglas de Riverpod verificadas automáticamente
y bloqueando el merge— se cumple íntegra; solo cambia el mecanismo, que la constitución
nombró por su implementación de entonces.

**Resuelto**: la constitución v1.1.0 nombra ahora el mecanismo vigente. La exigencia de que
el lint bloquee el merge no cambió.

**Nota de planificación**: no existe una regla de lint que verifique "ref.watch solo en
build", y la regla `avoid_manual_providers_as_generated_provider_dependency` fue eliminada
por dejar de ser necesaria. Esas dos reglas constitucionales quedan verificadas por revisión
de código, no por herramienta.

**Fuentes**: https://pub.dev/packages/riverpod_lint ·
https://riverpod.dev/docs/introduction/getting_started

---

## 3. Patrones de Riverpod 3 aplicables al incremento

**Decisión**: providers declarados con `@riverpod` y generados con `build_runner`; una
pantalla, un provider; `Ref` sin subclases (las subclases tipo `ExampleRef` desaparecieron
en Riverpod 3); autoDispose por defecto con codegen (`keepAlive = false`), y
`@Riverpod(keepAlive: true)` solo con justificación escrita en el propio archivo.

**Hallazgos que cambian el diseño respecto a Riverpod 2**:

- `AsyncValue` es ahora `sealed`, así que el `switch` exhaustivo sobre `AsyncData` /
  `AsyncError` / `AsyncLoading` no necesita `default`. Esto encaja directamente con la
  exigencia constitucional de resolver de forma exhaustiva cargando, datos, vacío y error.
- `valueOrNull` se renombró a `value` y el `value` antiguo desapareció; el nuevo devuelve
  `null` en error o carga en vez de lanzar.
- **Reintento automático activado por defecto**: un provider que falla al inicializarse
  reintenta con backoff exponencial indefinidamente. Es un comportamiento nuevo y sorprende
  en pruebas del camino de error.
- Los providers de widgets no visibles se **pausan** automáticamente (basado en
  `TickerMode`).
- Leer un provider que falló envuelve el error en `ProviderException`; `AsyncValue.error` y
  `ref.listen(onError:)` siguen recibiendo el error original.

**Decisión derivada**: desactivar el reintento automático en las pruebas que ejercitan el
camino de error (`retry: (_, __) => null`), porque de lo contrario el reintento indefinido
cuelga o ralentiza el test. En producción se deja el valor por defecto: sin red ni I/O
remoto, los fallos posibles son de base de datos y un reintento acotado no daña.

**Alternativa descartada**: desactivar el reintento globalmente en `ProviderScope`. Se
prefiere acotarlo a las pruebas para no perder la recuperación automática en la app.

**Estado vacío**: `AsyncData` con lista vacía no es un cuarto caso de `AsyncValue`; se
resuelve dentro de la rama de datos. Se encapsula en un widget compartido de `core` para que
las cuatro situaciones se resuelvan de manera uniforme en todas las pantallas.

---

## 4. Pruebas con Riverpod 3

**Decisión**: usar `ProviderContainer.test()`, que crea el contenedor y lo libera al
terminar la prueba, en lugar del helper `createContainer` + `addTearDown` de Riverpod 2.
Para widgets, `ProviderScope` en la raíz más `tester.container()`.

**Hallazgo relevante**: con un provider autoDispose, `container.read` puede destruir el
provider a mitad de la prueba. El patrón correcto es suscribirse y leer desde la
suscripción:

```dart
final sub = container.listen<Something>(myProvider, (_, _) {});
expect(sub.read(), ...);
```

**Decisión sobre dobles**: no se mockean Notifiers. Se sobreescriben los **repositorios**
(contratos de `domain`) con implementaciones falsas, que es además lo que la documentación
oficial recomienda. Esto encaja con la exigencia constitucional de que los casos de uso se
prueben con `ProviderContainer` y overrides.

---

## 5. drift: esquema versionado y migración inicial explícita

**Decisión**: una única clase `AppDatabase` con `schemaVersion => 1` y `MigrationStrategy`
declarada explícitamente con `onCreate: (m) async => m.createAll()`, más `beforeOpen` para
activar claves foráneas.

**Hallazgo**: el `onCreate` por defecto de drift ya equivale a `m.createAll()`, de modo que
declararlo en la versión 1 es redundante en comportamiento. Se declara igual porque la
constitución lo exige de forma explícita (FR-017) y porque deja la estrategia en su sitio
para cuando aparezca el primer `onUpgrade`.

```dart
@override
int get schemaVersion => 1;

@override
MigrationStrategy get migration => MigrationStrategy(
      onCreate: (m) async => m.createAll(),
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        if (kDebugMode) await validateDatabaseSchema();
      },
    );
```

**Decisión sobre verificación de esquema**: adoptar el flujo `make-migrations` de
`drift_dev` desde el primer día, con `schema_dir: drift_schemas/` y `test_dir: test/drift/`
en `build.yaml`. Genera el snapshot de la versión 1 y la prueba de esquema, de modo que el
incremento 2 herede la infraestructura de migración ya montada en lugar de improvisarla.

**Hallazgo de simplificación**: desde drift 2.32.0 el paquete empaqueta automáticamente una
copia actualizada de SQLite y **`sqlite3_flutter_libs` ya no es necesario**. Se elimina esa
dependencia del plan.

**Fuentes**: https://drift.simonbinder.eu/migrations/ ·
https://drift.simonbinder.eu/platforms/

---

## 6. Borrado lógico en drift

**Hallazgo**: drift **no tiene** filtros globales de consulta (nada equivalente a los global
query filters de EF Core). No existe soporte nativo de soft delete. El filtro hay que
garantizarlo por construcción.

**Decisión**: tres piezas combinadas.

1. Columna `deleted_at` nullable (`DateTimeColumn ... nullable()`) en vez de un booleano,
   porque conserva la fecha que la bitácora necesita y hace el filtro trivial.
2. Un único helper por DAO que devuelve `MultiSelectable<T>` con el filtro ya aplicado, y
   la regla de que ninguna consulta de lectura de listas se escribe sin pasar por él:
   ```dart
   MultiSelectable<Stakeholder> alive(ProjectId p) =>
       select(stakeholders)..where((t) => t.projectId.equals(p.value) & t.deletedAt.isNull());
   ```
3. Índice parcial para que el filtro no degrade:
   `@TableIndex.sql('CREATE INDEX ... WHERE deleted_at IS NULL')`.

**Alternativa considerada y descartada**: vistas de drift (`View`) con el `WHERE` incrustado.
Encapsulan mejor, pero no admiten escritura, obligan a `drop`+recrear en cada migración que
toque la tabla, y la documentación oficial no muestra ningún ejemplo de `..where()` dentro de
`View.as()`, así que se estaría construyendo sobre terreno no verificado.

**Distinción de vocabulario importante para el modelo**: el incremento tiene **tres**
mecanismos de baja que no deben confundirse en una sola columna.

| Mecanismo | Entidades | Columna | Reversible |
|---|---|---|---|
| Cierre / reapertura | Proyecto | `status` (activo/cerrado) | Sí, FR-004b |
| Desactivación | Interesado | `status` (activo/inactivo) | No definido en el incremento |
| Eliminación lógica | Sesión, punto de guion, término | `deleted_at` | No |

---

## 7. Bitácora: dónde se escribe

**Decisión**: el asiento de bitácora se escribe en la **misma transacción de drift** que la
operación lógica, dentro de la implementación del repositorio en `data`. Ningún caso de uso
llama a un "servicio de bitácora" por separado.

**Rationale**: convierte "toda baja lógica queda asentada" en un invariante imposible de
olvidar, en vez de una convención que depende de que cada caso de uso se acuerde de llamar a
otro. Además, evita que cada feature dependa de la feature de bitácora, lo que rompería el
aislamiento entre features que exige la constitución.

**Consecuencia de diseño**: la feature `audit_log` solo **lee**. No expone ninguna operación
de escritura, lo que es exactamente lo que FR-015a pide de su pantalla.

**Alternativa descartada**: un caso de uso `RecordAuditEntry` compartido invocado desde cada
feature. Explícito, pero deja la garantía en manos de la disciplina del programador y crea
una dependencia cruzada entre features.

---

## 8. Reordenamiento del guion

**Hallazgo**: drift no documenta ningún patrón para columnas de posición ni listas
reordenables. Hay que elegir uno y justificarlo.

**Decisión**: posiciones enteras contiguas `0..n-1` por sesión, con desplazamiento en bloque
dentro de una transacción, y **sin** restricción `UNIQUE` sobre `(session_id, position)`.

```dart
Future<void> move(SessionId s, ScriptPointId id, int from, int to) => transaction(() async {
      if (from < to) {
        await (update(scriptPoints)
              ..where((t) => t.sessionId.equals(s.value)
                  & t.position.isBiggerThanValue(from)
                  & t.position.isSmallerOrEqualValue(to)))
            .write(ScriptPointsCompanion.custom(position: scriptPoints.position - Constant(1)));
      } else { /* simétrico, +1 */ }
      await (update(scriptPoints)..where((t) => t.id.equals(id.value)))
          .write(ScriptPointsCompanion(position: Value(to)));
    });
```

**Rationale**: el guion de una sesión son unidades o decenas de puntos, así que escribir
O(n) filas es irrelevante, y a cambio se obtiene el invariante más fácil de verificar en
pruebas: las posiciones de una sesión son siempre exactamente `0..n-1` sin huecos ni
duplicados. Ese invariante es lo que el escenario 2 de la historia 4 exige ("el resto de los
puntos conserva un orden coherente").

**Alternativas consideradas**:
- Enteros con hueco (100, 200, 300…) y punto medio: escribe una sola fila por movimiento,
  pero necesita renumeración perezosa cuando el hueco se agota, y deja posiciones no
  contiguas que complican la verificación.
- Posición `REAL` con índice fraccionario: sin colisiones, pero pierde precisión tras unas
  50 inserciones en el mismo hueco y también acaba necesitando renumeración de rescate.

**Aviso incorporado**: no se declara `UNIQUE (session_id, position)`. SQLite evalúa `UNIQUE`
fila a fila durante un `UPDATE` masivo y no admite restricciones diferidas salvo en claves
foráneas, así que el desplazamiento en bloque fallaría a mitad. El invariante de contigüidad
se verifica en pruebas, no con una restricción de tabla.

**La eliminación lógica de un punto compacta las posiciones restantes** en la misma
transacción, para preservar el invariante `0..n-1`.

---

## 9. Streams reactivos y contadores

**Hallazgo**: la invalidación de streams en drift es **por tabla, no por fila**. Cualquier
escritura sobre una tabla re-ejecuta todas las consultas activas que la leen. La
documentación advierte que las consultas expuestas como stream deben devolver pocas filas y
no ser caras.

**Decisión**: los contadores de FR-013 se resuelven con consultas de agregación (`COUNT`)
expuestas como stream, no contando en Dart la lista completa. Para el detalle de proyecto se
usa un único provider que devuelve una clase inmutable con los tres contadores, en lugar de
tres providers independientes que dispararían tres re-consultas por cada escritura.

**Rationale**: mantiene la exigencia de "cada pantalla consume un único provider" y evita
multiplicar las re-ejecuciones que la invalidación por tabla ya provoca.

---

## 10. Identificadores

**Decisión**: claves primarias `TEXT` con UUID v4 generado en Dart (paquete `uuid`), no
enteros autoincrementales.

**Rationale**: la constitución contempla respaldo y restauración mediante un archivo local
cifrado, y los incrementos siguientes anclan requisitos a segmentos de audio y a
recomendaciones. Un identificador estable e independiente del orden de inserción evita
colisiones al restaurar y hace que las referencias sobrevivan a una reimportación. El coste
en una base local de este tamaño es despreciable.

**Verificación de la dependencia contra las prohibiciones constitucionales**: `uuid` tiene
null safety, licencia MIT y mantenimiento activo. Cumple.

**Alternativa descartada**: `integer().autoIncrement()`. Más simple, pero los identificadores
dependerían del orden de inserción y chocarían al fusionar un respaldo.

---

## 11. Fechas

**Decisión**: todas las columnas de fecha se almacenan en UTC y se formatean a hora local
solo en `presentation`. `created_at` y `updated_at` obligatorias en todas las entidades
(FR-016).

**Rationale**: el analista trabaja en campo y puede cruzar husos; guardar hora local haría
que el orden de la bitácora dejara de ser fiable.

**Decisión de prueba**: el reloj se inyecta como dependencia (`Clock` de `package:clock`)
para que las pruebas de `created_at`/`updated_at` y del orden de la bitácora sean
deterministas. drift ofrece además `TestSqliteFileSystem` de `package:sqlite3_test` para que
`CURRENT_TIMESTAMP` respete un reloj simulado, pero al generar las fechas en Dart no hace
falta.

---

## 12. Ausencia de red

**Decisión**: el incremento no declara ninguna dependencia de red en `pubspec.yaml`. Sin
`dio`, sin `http`. La verificación de FR-019 es estructural, no de comportamiento: una
prueba de CI que falle si aparece un paquete de red entre las dependencias resueltas.

**Rationale**: es la única forma de probar "no realiza ninguna petición de red" sin
inspeccionar tráfico. Que el paquete no exista en el árbol de dependencias es una garantía
más fuerte que cualquier aserción en tiempo de ejecución.

---

## 13. Navegación

**Decisión**: `go_router` con rutas anidadas que reflejan la jerarquía de FR-021, y el
identificador de proyecto siempre presente en la ruta a partir del detalle.

```text
/                                                  lista de proyectos (activos | cerrados)
/projects/new
/projects/:projectId                               detalle + contadores
/projects/:projectId/edit
/projects/:projectId/stakeholders                  · /new · /:stakeholderId/edit
/projects/:projectId/sessions                      · /new
/projects/:projectId/sessions/:sessionId           detalle de sesión + guion
/projects/:projectId/sessions/:sessionId/edit
/projects/:projectId/glossary                      · /new · /:termId/edit
/projects/:projectId/audit                         bitácora, solo lectura
```

**Rationale**: llevar `projectId` en la ruta hace que el aislamiento por proyecto de FR-018
sea estructural: ninguna pantalla interior puede construir una consulta sin proyecto porque
no tiene forma de existir sin él.

---

## 14. Solo lectura del proyecto cerrado

**Decisión**: la restricción se aplica en **dos capas**, y la de dominio es la que manda.

1. `domain`: cada caso de uso de escritura de cualquier feature comprueba primero que el
   proyecto está activo y devuelve un fallo tipado `ProjectClosedFailure` si no lo está.
2. `presentation`: las acciones de escritura no se renderizan cuando el proyecto está
   cerrado.

**Rationale**: si solo se ocultara en la interfaz, cualquier ruta profunda abierta
directamente (o un incremento futuro) podría escribir sobre un proyecto cerrado. La
comprobación en dominio es la que se prueba; la de presentación es comodidad.

**Consecuencia**: los casos de uso de escritura de interesados, sesiones, guion y glosario
reciben el `ProjectId` y consultan el estado del proyecto. Ese es el único punto donde una
feature necesita saber algo de otra, y se resuelve con un contrato mínimo de solo lectura
(`ProjectStatusReader`) declarado en `core/domain` e implementado en la feature de
proyectos.

**Alternativa descartada**: que cada feature importe `features/projects/domain`. Violaría
el aislamiento entre features que exige la constitución.

---

## 15. Máquina de estados de la sesión

**Decisión**: `SessionStatus` como enum `{ planeada, enCurso, cerrada }` con una única
función de transición en `domain` que solo admite `planeada → enCurso → cerrada`. El cierre
además congela la cabecera: el caso de uso de edición rechaza cambios de título, fecha,
técnica, lugar y participantes cuando la sesión está cerrada, y sigue admitiendo notas.

**Rationale**: concentra FR-008a y FR-008b en una función pura, que es lo más barato de
probar exhaustivamente (las nueve combinaciones de transición caben en una tabla).

---

## Resumen de decisiones

| # | Área | Decisión |
|---|---|---|
| 0 | Entorno | Flutter 3.44.9 / Dart 3.12.2 — alineado en constitución v1.1.1 |
| 1 | Escrituras | `Mutation<T>` experimental — conflicto resuelto en constitución v1.1.0 |
| 2 | Lint | `plugins:` + `dart analyze` — conflicto resuelto en constitución v1.1.0 |
| 3 | Estado | `@riverpod` codegen, autoDispose por defecto, `AsyncValue` sealed |
| 4 | Pruebas de estado | `ProviderContainer.test()`, dobles de repositorio |
| 5 | Esquema | `schemaVersion 1` con `onCreate` explícito, `make-migrations` desde el día 1 |
| 6 | Baja lógica | `deleted_at` + helper `alive()` por DAO + índice parcial |
| 7 | Bitácora | Escrita en la misma transacción que la operación, en `data` |
| 8 | Reordenar | Posiciones contiguas `0..n-1`, desplazamiento en bloque, sin `UNIQUE` |
| 9 | Contadores | `COUNT` en SQL, un solo provider por pantalla |
| 10 | Identificadores | UUID v4 en `TEXT` |
| 11 | Fechas | UTC en base, `Clock` inyectado en pruebas |
| 12 | Red | Ninguna dependencia de red en `pubspec.yaml` |
| 13 | Navegación | `go_router` anidado con `projectId` siempre en la ruta |
| 14 | Proyecto cerrado | Guarda en dominio + ocultación en presentación |
| 15 | Estado de sesión | Transición pura, avance en un solo sentido, cabecera congelada |

**NEEDS CLARIFICATION pendientes**: ninguno.
