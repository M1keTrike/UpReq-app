# Quickstart & Validation Guide

**Feature**: 001-proyectos-interesados-sesiones
**Source**: [spec.md](spec.md) · [plan.md](plan.md)

Cómo levantar el proyecto y cómo comprobar que el incremento cumple lo que promete. Los
detalles de implementación no viven aquí, sino en `tasks.md` y en el código.

---

## Prerrequisitos

| Requisito | Valor exigido | Comprobación |
|---|---|---|
| Flutter | 3.44.9 | `flutter --version` |
| Dart | 3.12.2 | `dart --version` |
| Dispositivo | Android físico o emulador, Android 10+ | `flutter devices` |

Verificado el 2026-08-10: el entorno cumple. Las versiones las fija la constitución v1.1.1 y
CI las comprueba, así que si una actualización futura de Flutter mueve el canal stable, hay
que anclar el toolchain o enmendar la constitución antes de seguir. No basta con que
compile.

---

## Puesta en marcha

```bash
flutter pub get
```

```bash
dart run build_runner build --delete-conflicting-outputs
```

```bash
dart run drift_dev make-migrations
```

El tercer comando genera el snapshot `drift_schemas/drift_schema_v1.json` y las pruebas de
esquema. Se vuelve a ejecutar cada vez que cambie el esquema.

```bash
flutter run
```

---

## Comprobaciones automáticas

Cada una corresponde a una puerta que CI bloquea.

**Análisis estático** (incluye las reglas de `riverpod_lint`):

```bash
dart analyze --fatal-infos
```

**Código generado al día** — falla si alguien olvidó ejecutar `build_runner`:

```bash
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code
```

**Pruebas con cobertura**:

```bash
flutter test --coverage
```

**Cobertura mínima de `domain`** — la constitución exige 80%:

```bash
dart run tool/check_coverage.dart --min 80 --path lib/features/**/domain
```

**Ausencia de dependencias de red** — verificación estructural de FR-019:

```bash
dart run tool/check_no_network_deps.dart
```

**Pruebas de flujo en dispositivo**:

```bash
flutter test integration_test
```

---

## Validación manual del incremento

Los cuatro criterios de aceptación del insumo, en orden. Todos se ejecutan **con el modo
avión activado**, porque el incremento no debe necesitar red (FR-019).

### V1 — Flujo completo de punta a punta (SC-001)

1. Abrir la app recién instalada. **Esperado**: la lista de proyectos muestra la invitación
   a crear el primero, no un mensaje de ausencia.
2. Crear un proyecto con nombre y cliente. **Esperado**: aparece en activos con su fecha.
3. Abrirlo y agregar **tres** interesados con distintos niveles de influencia.
   **Esperado**: el detalle del proyecto muestra el contador en 3.
4. Crear una sesión que referencie a **dos** de ellos. **Esperado**: el selector solo ofrece
   interesados de este proyecto; guardar sin participantes es imposible.
5. Abrir la sesión y agregar **cinco** puntos de guion.
6. Reordenar dos de ellos arrastrándolos. **Esperado**: el nuevo orden persiste y no hay
   posiciones duplicadas ni saltos.
7. Marcar **dos** como cubiertos. **Esperado**: el contador de la sesión pasa a 2 cubiertos
   y 3 pendientes.

### V2 — Persistencia (SC-002)

1. Cerrar la aplicación por completo (retirarla de recientes, no solo minimizarla).
2. Volver a abrirla. **Esperado**: proyecto, tres interesados, sesión con sus dos
   participantes, los cinco puntos con su orden y sus estados siguen ahí, sin excepción.

### V3 — Cierre lógico y reapertura (SC-003, FR-004a, FR-004b)

1. Cerrar el proyecto desde su detalle. **Esperado**: desaparece de activos.
2. Cambiar al filtro de cerrados. **Esperado**: el proyecto aparece con todos sus datos.
3. Abrirlo y recorrer interesados, sesiones, guion y glosario. **Esperado**: todo se
   consulta pero **ninguna** acción de escritura está disponible.
4. Abrir la bitácora. **Esperado**: figura el asiento de cierre con su fecha.
5. Reabrir el proyecto. **Esperado**: vuelve a activos, la edición se restituye y la
   bitácora suma el asiento de reapertura.

### V4 — Dispositivo Android físico sin conexión (SC-004)

```bash
flutter build apk --release
```

1. Instalar el APK en un Android físico con Android 10 o superior.
2. Activar modo avión.
3. Ejecutar V1, V2 y V3 completos. **Esperado**: todo funciona igual; en ningún momento
   aparece un error de red ni un indicador de conexión.

### V5 — Bajas lógicas y bitácora (SC-006, FR-014, FR-014a, FR-015a)

1. Desactivar un interesado que participa en la sesión. **Esperado**: queda marcado como
   inactivo, sigue apareciendo entre los participantes de la sesión existente y ya no se
   ofrece al crear una sesión nueva.
2. Eliminar un punto del guion. **Esperado**: desaparece de la lista y los puntos restantes
   quedan con orden contiguo.
3. Eliminar un término del glosario y una sesión.
4. Abrir la bitácora. **Esperado**: un asiento por cada una de las cuatro operaciones, con
   fecha, operación y entidad afectada, del más reciente al más antiguo, y ninguna acción
   para modificarlos o borrarlos.

### V6 — Aislamiento entre proyectos (FR-018)

1. Crear un segundo proyecto con sus propios interesados.
2. Recorrer las listas de ambos. **Esperado**: en ningún listado aparece un dato del otro
   proyecto.
3. Crear una sesión en el segundo proyecto. **Esperado**: el selector de participantes solo
   ofrece los interesados de ese proyecto.

### V7 — Validación de formularios (FR-022)

1. En el formulario de proyecto, escribir cliente y descripción pero dejar el nombre vacío,
   e intentar guardar. **Esperado**: no guarda, señala el campo y **conserva** lo escrito en
   los otros dos.
2. Repetir en el formulario de sesión dejándola sin participantes. **Esperado**: mismo
   comportamiento, con el mensaje de que hace falta al menos un interesado.

### V8 — Estado de sesión (FR-008a, FR-008b)

1. Avanzar una sesión de planeada a en curso y luego a cerrada.
2. **Esperado**: en ningún momento la interfaz ofrece volver a un estado anterior.
3. Abrir la sesión cerrada. **Esperado**: título, fecha, técnica, lugar y participantes se
   ven pero no se editan; las notas y el guion sí se editan y se marcan.

---

## Mapa de validación

| Validación | Cubre |
|---|---|
| V1 | SC-001, SC-005, FR-009, FR-010, FR-011, FR-013, FR-020 |
| V2 | SC-002, FR-016, FR-017 |
| V3 | SC-003, FR-004, FR-004a, FR-004b |
| V4 | SC-004, FR-019, FR-023 |
| V5 | SC-006, FR-014, FR-014a, FR-015, FR-015a |
| V6 | FR-018 |
| V7 | FR-022 |
| V8 | FR-008a, FR-008b |
