# Quickstart & Validation Guide

**Feature**: 002-captura-transcripcion
**Source**: [spec.md](spec.md) · [plan.md](plan.md) · [research.md](research.md)

Cómo levantar el incremento y cómo comprobar que cumple lo que promete. Los detalles de
implementación no viven aquí, sino en `tasks.md` y en el código.

---

## Prerrequisitos

| Requisito | Valor exigido | Comprobación |
|---|---|---|
| Flutter | 3.44.9 | `flutter --version` |
| Dart | 3.12.2 | `dart --version` |
| Dispositivo | Android **físico**, Android 10+ | `flutter devices` |
| `minSdkVersion` | ≥ 24 | `android/app/build.gradle` |
| Conexión | Solo para descargar el modelo, una vez | — |

**El emulador no sirve para validar este incremento.** Su micrófono es sintético y su
rendimiento de inferencia no representa nada; las dos preguntas que este incremento existe
para responder —cuánto tarda Whisper en el teléfono real y qué tan limpia sale la
transcripción en español con audio de campo— solo se responden en hardware.

### Permisos y configuración de plataforma

`android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

`ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Graba las entrevistas de levantamiento de requerimientos. El audio nunca sale del dispositivo.</string>
```

`INTERNET` es necesario por la descarga del modelo y lo pide además `just_audio`. Que el
permiso exista no significa que la app llame a la red por otro motivo: eso lo garantiza la
puerta de CI de dependencias, no el manifiesto.

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

El tercer comando genera `drift_schemas/drift_schema_v2.json` **conservando** el v1. Ambos
deben quedar versionados: la prueba de migración compara uno contra otro y sin el v1 no hay
nada contra qué migrar.

```bash
flutter run
```

---

## Comprobaciones automáticas

Cada una corresponde a una puerta que CI bloquea.

**Análisis estático:**

```bash
dart analyze
```

**Código generado al día:**

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Pruebas:**

```bash
flutter test
```

**Cobertura de `domain` (mínimo 80%):**

```bash
dart run tool/check_coverage.dart --min 80
```

**Dependencias de red — puerta reescrita en este incremento:**

```bash
dart run tool/check_no_network_deps.dart
```

Ya no verifica "cero paquetes de red". Verifica dos cosas: que ningún paquete de red distinto
de `dio` entre en la clausura de `dependencies:`, y que `package:dio` se importe desde
**exactamente un** archivo del árbol. Un segundo importador bloquea el merge. Esa es la forma
que toma la excepción constitucional única (research.md, decisión 3).

**Licencias de dependencias:**

```bash
dart run tool/check_dependencies.dart
```

Gana en este incremento un veto explícito a la variante `-gpl` de `ffmpeg_kit_flutter_new_min`.
La variante `_min` que entra es LGPL-3.0 y está permitida; la `-gpl` no lo estaría, y una
actualización futura de `whisper_ggml` podría cambiarla sin que nadie lo note.

**Anclaje de versiones — puerta nueva en este incremento:**

```bash
dart run tool/check_pinned_versions.dart
```

Compara las versiones resueltas en `pubspec.lock` contra las que la constitución v1.3.0 ancla
de forma exacta (los cuatro paquetes de Riverpod y `drift`). Existe porque el anclaje que solo
vive en el documento no se sostiene: la constitución declaró `drift 2.34.3` mientras el
proyecto resolvía `2.34.0` durante todo el incremento 1, y ninguna puerta lo comprobaba.

**Auditoría de importaciones:**

Verifica, además de las reglas del incremento 1, que `record`, `whisper_ggml` y `just_audio`
se importen solo desde su único archivo de `data/` declarado en el plan.

---

## Validaciones manuales

Se ejecutan en un dispositivo Android físico. V1 a V4 exigen modo avión activado; V5 en
adelante lo indican explícitamente.

### V1 — Grabar y detener (US1, FR-001 a FR-006)

1. Crear un proyecto y una sesión; avanzar la sesión a **en curso**.
2. Comprobar que el control de grabar **no** aparecía mientras la sesión estaba planeada.
3. Iniciar la grabación. Conceder el permiso de micrófono cuando lo pida.
4. Verificar que la pantalla confirma que graba y que el tiempo transcurrido avanza.
5. Hablar unos 30 segundos. Detener.

**Esperado**: la grabación aparece listada en la sesión con su duración. Reproducirla suena
correcto. El archivo vive en el sandbox de la app.

**Verificación negativa**: repetir el paso 3 con el permiso de micrófono denegado. La app debe
señalarlo de forma explícita y no iniciar nada (FR-004).

### V2 — Marcado en vivo (US2, FR-007 a FR-009a)

1. Con una grabación activa, tocar los tres tipos de marca en distintos momentos.
2. Comprobar que ninguna toque interrumpe la captura ni abre un diálogo.
3. Detener. Abrir el detalle de la grabación.

**Esperado**: las marcas aparecen ordenadas por instante, cada una con su tipo. Cambiar el
tipo de una y eliminar otra persiste; la eliminada deja de listarse y su asiento aparece en la
bitácora del proyecto.

**Verificación negativa**: con la grabación detenida, comprobar que los controles de marcado
no están disponibles (FR-009).

### V3 — Grabación interrumpida (US3, FR-010, FR-011) — la validación crítica

Se hace **dos veces**, una por cada causa de interrupción.

**V3a, cierre inesperado:**

1. Iniciar una grabación y hablar 30 segundos.
2. Matar la aplicación desde el gestor de tareas del sistema, sin detener la grabación.
3. Reabrir la aplicación y entrar en la sesión.

**Esperado**: la app avisa de que la grabación quedó interrumpida y ofrece las dos acciones.
El audio capturado hasta el corte se reproduce íntegro y con la duración correcta —esa es la
prueba de que la cabecera se reparó—.

4. Elegir **reanudar**. Hablar 15 segundos más. Detener.

**Esperado**: una sola grabación con los 45 segundos.

5. Repetir 1 a 3 y elegir esta vez **cerrar conservando lo capturado**. Iniciar una grabación
   nueva en la misma sesión.

**Esperado**: dos grabaciones listadas por separado, cada una con su duración (FR-003a).

**V3b, llamada entrante:**

1. Iniciar una grabación desde el dispositivo bajo prueba.
2. Llamar a ese teléfono desde otro. Aceptar o rechazar la llamada.

**Esperado**: la grabación se pausa sola, queda marcada como interrumpida y el audio previo
está intacto. La app **no** reanuda por su cuenta.

### V4 — Transcripción sin modelo descargado (FR-016)

1. Con el modelo aún no descargado, grabar una sesión corta y cerrarla.

**Esperado**: la transcripción queda **pendiente**, presentada como aviso con acción hacia
ajustes, nunca como error. El audio se conserva y se reproduce.

**Esta validación se hace antes que V5 a propósito**: comprueba que la app no dispara la
descarga automática del paquete. Con modo avión activo, si la app intentara descargar por su
cuenta, aquí fallaría de forma visible.

### V5 — Descargar el modelo (US6, FR-020 a FR-022)

Requiere conexión. Es la única validación que la necesita.

1. Desactivar el modo avión. Ir a ajustes de modelos.
2. Descargar el modelo de la pasada definitiva. Observar el progreso.
3. A mitad de la descarga, cancelarla.

**Esperado**: no queda ningún modelo utilizable a medias (FR-022).

4. Descargar de nuevo hasta completar.

**Esperado**: el modelo queda disponible y el contador de transcripciones pendientes baja a
cero por su cuenta: es la confirmación de que la cola de V4 se procesó.

### V6 — Transcripción completa y revisión por segmento (US4, US5)

**Reactivar el modo avión antes de empezar.** El resto del incremento no debe tocar la red.

1. Grabar una entrevista real de al menos 5 minutos, en español, con al menos dos voces y
   ruido de fondo de oficina.
2. Colocar marcas de los tres tipos durante la conversación, **usando el avance en vivo** que
   aparece sobre la barra de marcado para decidir cuándo hacerlo (FR-012).
3. Cerrar la sesión y esperar la pasada definitiva.

**Esperado**: la transcripción aparece organizada en segmentos con inicio y fin. Mientras se
procesa, la app indica que está en curso y **sigue navegable**: se puede entrar y salir de
otras pantallas sin que se congele nada (FR-015).

4. Tocar varios segmentos del texto.

**Esperado**: la reproducción salta al instante correcto en cada caso, y el segmento en
reproducción se resalta conforme avanza el audio.

**Qué medir y anotar en el roadmap** —este es el propósito declarado del incremento—:

| Medición | Cómo |
|---|---|
| Duración de la pasada definitiva | Cronometrar desde cerrar la sesión hasta ver los segmentos |
| Relación con la duración del audio | Dividir lo anterior entre los minutos grabados |
| Calidad en español con audio de campo | Leer la transcripción y contar los errores por minuto |
| Aporte del glosario | Repetir con el glosario del proyecto vacío y comparar los términos de dominio |
| Impacto de la pasada en vivo | Comprobar si la captura se degrada con la pasada en vivo activa |
| Utilidad real del avance en vivo | ¿El texto llega con retraso suficiente para orientar el marcado, o tan tarde que el momento ya pasó? |
| Espera tras cerrar la sesión | Cuánto se queda el analista mirando "en proceso". Es el número que decide si conviene persistir la pasada en vivo como borrador legible |
| Consumo de batería | Porcentaje gastado en los 5 minutos de captura |

Si la pasada definitiva con `small` resulta impracticable, la decisión es bajar a `base`, y se
anota en el roadmap junto con el número que la motivó. Ese ajuste es un resultado esperado de
esta validación, no un fallo.

### V7 — Aislamiento y bajas lógicas

1. Con dos proyectos poblados, comprobar que ninguna lista de grabaciones cruza datos.
2. Eliminar una grabación y una marca.

**Esperado**: dejan de listarse, sus asientos aparecen en la bitácora del proyecto correcto, y
ningún registro desaparece de la base.

### V8 — Proyecto cerrado y fallback fail-closed

1. Cerrar un proyecto que tenga sesiones con grabaciones.
2. Entrar en una sesión, **observando la pantalla desde el primer instante de la carga**.

**Esperado**: el control de grabar **no aparece en ningún momento**, ni siquiera por
milisegundos mientras carga. Las grabaciones y transcripciones existentes se consultan y
reproducen en solo lectura.

Esta validación existe por el hallazgo de la validación del incremento 1 anotado en el
roadmap. Aquí el control que podría parpadear es el de iniciar una grabación, así que se
comprueba de forma explícita en vez de confiar en que el patrón se aplicó.

### V9 — Sin red salvo la descarga

1. Con modo avión activado y el modelo ya descargado, recorrer todas las pantallas del
   incremento: grabar, marcar, cerrar sesión, transcribir, reproducir, revisar segmentos.

**Esperado**: todo funciona. Ninguna pantalla pide conexión ni muestra un error de red
(FR-021, FR-024, SC-004).

---

## Criterios de aceptación del incremento

El incremento se da por terminado cuando:

- Las siete puertas automáticas pasan.
- V1 a V9 pasan en un dispositivo Android físico.
- Las mediciones de V6 están anotadas en [roadmap.md](../../roadmap.md), incluidos los valores
  finales de los modelos y de los tres parámetros del gate de silencio.
- La regla 2 del roadmap se cumple: **lo aprendido se escribe antes de especificar el
  incremento 3.**

La última no es burocracia. El incremento 3 fija tamaño de bloque, traslape y umbral léxico
contra la transcripción real que este incremento produce; especificarlo sin esos números sería
inventarlos.
