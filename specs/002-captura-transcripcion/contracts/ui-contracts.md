# UI Contracts

**Feature**: 002-captura-transcripcion
**Source**: [spec.md](../spec.md) · [research.md](../research.md) · [domain-contracts.md](domain-contracts.md)

Contrato de cada pantalla: ruta, provider único, situaciones que resuelve y escrituras que
expone. Las mismas reglas constitucionales que el incremento 1 hizo verificables siguen
vigentes sin excepción:

- Cada pantalla consume **un único** provider que devuelve `AsyncValue<T>` con `T` inmutable.
- Las cuatro situaciones se resuelven de forma exhaustiva con `AsyncScaffoldBody`.
- Ninguna escritura se hace con métodos sueltos: cada una es un `Mutation<T>` observable.
- Ningún widget importa `drift`, `dio`, `record`, `whisper_ggml`, `just_audio` ni DTOs.

**Regla nueva que este incremento estrena**: el estado de solo lectura por proyecto cerrado se
resuelve con fallback **fail-closed**. Mientras el provider carga, todo control de escritura
se oculta. El incremento 1 aprendió esto en la validación en dispositivo —el botón de agregar
alcanzaba a verse por milisegundos en proyectos cerrados— y quedó anotado en el roadmap. Aquí
importa más: el control que parpadearía es el de **iniciar una grabación**.

```dart
// Correcto en todas las pantallas de este incremento.
final canRecord = state.value?.canRecord ?? false;   // ausencia de dato ⇒ no se puede
```

---

## Pantallas

### 1. Detalle de sesión, sección de captura — `/projects/:pid/sessions/:sid`

Amplía la pantalla que ya existe; no crea una ruta nueva. La sección de captura se inserta
bajo la cabecera y sobre el guion.

| Aspecto | Contrato |
|---|---|
| Provider | `sessionCaptureProvider(sessionId)` → `AsyncValue<SessionCaptureState>` |
| Estado | `SessionCaptureState({ List<RecordingSummary> recordings, ActiveCapture? active, bool canRecord, InterruptedRecording? interrupted })` |
| Vacío | Sin grabaciones: invitación a grabar la primera. Solo se muestra si `canRecord` |
| Escrituras | `startRecording`, `stopRecording`, `placeLiveMark`, `deleteRecording` |
| Navega a | `/projects/:pid/sessions/:sid/recordings/:rid` |

`canRecord` es `true` solo si el proyecto está activo **y** la sesión está en curso (FR-003).
Se calcula en el provider, no en el widget: dejarlo en el widget lo convertiría en una
condición repetida en cada control y por tanto en una que alguien olvidará.

`ActiveCapture` es lo que la pantalla muestra durante la grabación:

```dart
class ActiveCapture {
  final RecordingId id;
  final Duration elapsed;        // FR-002, tiempo transcurrido
  final int marksPlaced;
  final bool isInterrupted;
}
```

**El tiempo transcurrido no vive en el estado de pantalla como contador propio.** Viene del
notifier de captura, que es el mismo que posee el flujo. Duplicarlo en la UI produciría dos
relojes que se separan.

### 2. Barra de marcado en vivo — dentro de la pantalla anterior

No es una ruta. Es el contrato de los tres controles que FR-007 exige, y se documenta aparte
porque su disponibilidad es la parte fácil de equivocar.

| Aspecto | Contrato |
|---|---|
| Visible | Solo cuando `active != null && !active.isInterrupted` (FR-009) |
| Controles | Tres botones: posible requisito, duda, cita textual |
| Escritura | `placeLiveMark` — una `Mutation<LiveMarkId>` por toque |
| Realimentación | Confirmación breve y no bloqueante; **nunca** un diálogo |

Un diálogo de confirmación al colocar una marca rompería el propósito entero de la historia 2,
que es señalar sin interrumpir la conversación. La marca se coloca y se confirma de forma
pasiva; si estaba mal, se corrige después (FR-009a).

### 3. Detalle de grabación — `/projects/:pid/sessions/:sid/recordings/:rid`

Pantalla nueva. Reproductor, marcas y transcripción.

| Aspecto | Contrato |
|---|---|
| Provider | `recordingDetailProvider(recordingId)` → `AsyncValue<RecordingDetailState>` |
| Estado | `RecordingDetailState({ Recording recording, List<LiveMark> marks, TranscriptView? transcript, PlaybackState playback, bool isReadOnly })` |
| Vacío | Grabación sin marcas ni transcripción: se muestra el reproductor igual (FR-017) |
| Escrituras | `play`, `pause`, `seekToSegment`, `changeMarkKind`, `deleteLiveMark` |

`TranscriptView` resuelve por sí solo los estados de FR-015 y FR-016, y por eso es un sealed y
no una clase con banderas:

```dart
sealed class TranscriptView {}
class TranscriptPending  extends TranscriptView {}   // falta el modelo (FR-016)
class TranscriptRunning  extends TranscriptView {}   // en proceso (FR-015)
class TranscriptReady    extends TranscriptView { final List<SegmentView> segments; }
class TranscriptFailed   extends TranscriptView { final String reason; }
```

`TranscriptPending` **no es un error en pantalla**. Es un aviso con acción: explica que falta
descargar el modelo y lleva a ajustes. Mostrarlo como error diría que algo se rompió cuando lo
único que pasa es que el analista no ha descargado nada todavía.

`SegmentView` lleva `isActive`, calculado contra la posición del reproductor (FR-019). El
resaltado se recalcula desde el stream de posición, no desde un temporizador propio.

Cuando `transcript` es `TranscriptReady`, tocar un segmento dispara `seekToSegment` (FR-018).
Cuando no lo es, el reproductor sigue funcionando sobre el audio en bruto: es el caso borde ya
resuelto en el spec.

### 4. Recuperación de grabación interrumpida — hoja modal, sin ruta propia

Se presenta al abrir el detalle de una sesión que tiene una grabación en `interrupted`
(FR-011). No es una ruta porque no debe poder alcanzarse por navegación ni sobrevivir a un
enlace profundo: existe mientras exista la condición que la justifica.

| Aspecto | Contrato |
|---|---|
| Se muestra si | `interrupted != null` |
| Contenido | Qué sesión, cuánto audio se conservó, y por qué se interrumpió si se sabe |
| Escrituras | `resumeRecording`, `closeInterruptedRecording` |
| Descartable | **No** sin elegir. Las dos acciones son explícitas |

Las dos opciones son las aclaradas el 2026-08-11 y ninguna es la predeterminada. Cerrar la
hoja sin elegir dejaría el audio en un limbo que la siguiente apertura volvería a preguntar,
y el analista aprendería a descartar el aviso sin leerlo.

`resumeRecording` solo está disponible si `canRecord` sigue siendo cierto: si la sesión se
cerró mientras tanto, la única salida es conservar lo capturado.

### 5. Ajustes del modelo de transcripción — `/settings/models`

Pantalla nueva. La única de todo el proyecto que toca la red.

| Aspecto | Contrato |
|---|---|
| Provider | `modelSettingsProvider` → `AsyncValue<ModelSettingsState>` |
| Estado | `ModelSettingsState({ List<ModelEntry> models, int pendingTranscripts })` |
| Vacío | No aplica: la lista de modelos es fija y conocida |
| Escrituras | `downloadModel`, `cancelModelDownload` |

```dart
class ModelEntry {
  final TranscriptionModel model;       // base | small
  final String label;                   // "En vivo" | "Definitiva"
  final ModelStatus status;             // notDownloaded | downloading | available | failed
  final double? progress;               // 0..1; nulo si el servidor no informa longitud
  final int? sizeBytes;
}
```

`pendingTranscripts` es el contador de transcripciones esperando modelo. Se muestra porque es
la razón por la que el analista llegó aquí, y porque al completarse la descarga ese número
bajando a cero es la confirmación de que `ProcessPendingTranscripts` corrió.

**Descarga con progreso indeterminado**: si el servidor no informa `Content-Length`, `progress`
es nulo y la barra es indeterminada. No se inventa un porcentaje.

---

## Escrituras, una por una

Toda escritura de este incremento como `Mutation<T>`, según el contrato del incremento 1:

| Mutación | Tipo | Pantalla |
|---|---|---|
| `startRecording` | `Mutation<RecordingId>` | Detalle de sesión |
| `stopRecording` | `Mutation<void>` | Detalle de sesión |
| `placeLiveMark` | `Mutation<LiveMarkId>` | Barra de marcado |
| `changeMarkKind` | `Mutation<void>` | Detalle de grabación |
| `deleteLiveMark` | `Mutation<void>` | Detalle de grabación |
| `deleteRecording` | `Mutation<void>` | Detalle de sesión |
| `resumeRecording` | `Mutation<void>` | Hoja de recuperación |
| `closeInterruptedRecording` | `Mutation<void>` | Hoja de recuperación |
| `seekToSegment` | `Mutation<void>` | Detalle de grabación |
| `downloadModel` | `Mutation<void>` | Ajustes del modelo |
| `cancelModelDownload` | `Mutation<void>` | Ajustes del modelo |

Ninguna bandera `isLoading` ni `hasError` en ningún estado de pantalla. El progreso de la
descarga es la excepción aparente y no lo es: `progress` no es el estado de la escritura sino
un **dato del dominio** —cuántos bytes lleva el archivo—, y se observa por stream del
repositorio, no por la mutación.

---

## El notifier de captura, y por qué es `keepAlive`

```dart
@Riverpod(keepAlive: true)
class ActiveCaptureNotifier extends _$ActiveCaptureNotifier { ... }
```

Es la primera excepción real a `autoDispose` del proyecto y la constitución exige justificarla
en el código. La justificación es esta: el notifier posee el flujo PCM, el escritor WAV y la
sesión de transcripción en vivo. Con `autoDispose`, navegar del detalle de sesión al glosario a
media entrevista destruiría el provider y con él la grabación en curso. Un analista perdiendo
una entrevista por haber consultado un término es exactamente el modo de falla que este
incremento existe para evitar.

El notifier se libera de forma explícita al detener o al recuperar, no por ciclo de vida de
pantalla. Ese es el precio de `keepAlive` y se paga a conciencia.

---

## Navegación

```
/projects/:pid/sessions/:sid                       (ampliada: sección de captura)
  └── /recordings/:rid                             (nueva: reproductor + transcripción)

/settings/models                                   (nueva: descarga del modelo)
```

`/settings/models` cuelga de la raíz y no de un proyecto: el modelo es del dispositivo, no del
proyecto, y colgarlo de una ruta con `:pid` sugeriría que hay que descargarlo una vez por
proyecto.
