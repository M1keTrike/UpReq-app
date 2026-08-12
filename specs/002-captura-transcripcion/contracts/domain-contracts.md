# Domain Contracts

**Feature**: 002-captura-transcripcion
**Source**: [spec.md](../spec.md) · [data-model.md](../data-model.md) · [research.md](../research.md)

Contratos de `domain`. Estos archivos no importan `package:flutter` ni nada de
infraestructura (prohibición constitucional). Un caso de uso por operación.

Firma común, heredada del incremento 1: todo caso de uso devuelve `Future<Result<T>>`, con
`Result` sealed en `Ok<T>` y `Err<Failure>`.

**Lo que hace este incremento distinto**: por primera vez `domain` describe recursos del
sistema —micrófono, altavoz, archivos, red— que solo `data` puede tocar. La regla que lo
mantiene limpio es que `domain` declara **qué** se necesita y nunca **con qué**: los nombres
`record`, `whisper_ggml`, `just_audio` y `dio` no aparecen en ninguna firma de esta página.

---

## Contratos de infraestructura (`recordings/domain/contracts`)

```dart
/// Captura de audio. Implementado en data/ sobre `record`, único importador.
abstract interface class AudioRecorder {
  /// Permiso de micrófono. FR-004.
  Future<bool> hasPermission();

  /// Abre el micrófono y devuelve el flujo PCM16 crudo, 16 kHz mono.
  /// El llamador lo bifurca: escritor WAV y pasada en vivo (research.md, 4).
  Future<Stream<Uint8List>> start();

  Future<void> stop();

  /// Emite cada cambio de estado del grabador, incluidas las pausas que
  /// **impone el sistema** (llamada entrante). El notifier distingue las
  /// suyas de las impuestas y marca `interrupted` solo en el segundo caso.
  /// FR-010.
  Stream<RecorderState> get states;
}

enum RecorderState { recording, paused, stopped }
```

```dart
/// Escritura incremental del archivo WAV. La pieza que hace recuperable una
/// grabación interrumpida (research.md, decisión 4).
abstract interface class WavSink {
  /// Escribe la cabecera RIFF con los dos campos de tamaño en cero y deja el
  /// archivo listo para anexar.
  Future<void> open(String relativePath, {int sampleRate, int channels});

  Future<void> append(Uint8List pcmFrames);

  /// Vuelve atrás y parchea los dos campos de tamaño con los valores reales.
  Future<int> closeAndFinalize();
}
```

```dart
/// Reparación de una cabecera que quedó sin parchear por un cierre inesperado.
/// FUNCIÓN PURA sobre los tamaños: no abre micrófono ni depende de plataforma,
/// y por eso se prueba sin grabar nada.
class WavHeaderRepair {
  /// Dados el tamaño real del archivo y el formato con que se grabó, devuelve
  /// los dos valores que deben escribirse en la cabecera y la duración
  /// resultante. Es todo lo que hace falta para recuperar un WAV truncado.
  static WavRepairPlan plan({
    required int fileLengthBytes,
    required int sampleRate,
    required int channels,
  });
}

class WavRepairPlan {
  final int riffChunkSize;   // offset 4
  final int dataChunkSize;   // offset 40
  final int durationMs;
}
```

```dart
/// Reproducción. Implementado en data/ sobre `just_audio`, único importador.
abstract interface class AudioPlayback {
  Future<void> load(String relativePath);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);       // FR-018
  Stream<Duration> get position;              // FR-019, resaltado del segmento activo
  Future<void> dispose();
}
```

---

## Contratos de infraestructura (`transcription/domain/contracts`)

```dart
/// Transcripción en el dispositivo. Implementado en data/ sobre `whisper_ggml`,
/// único importador. SIEMPRE se dobla en pruebas: ninguna prueba carga un
/// modelo Whisper (regla de Calidad de la constitución).
abstract interface class Transcriber {
  /// Pasada definitiva sobre un archivo ya cerrado. Produce segmentos con
  /// ventana temporal. FR-013.
  Future<List<RawSegment>> transcribeFile({
    required String relativePath,
    required TranscriptionModel model,
    String? initialPrompt,          // el glosario del proyecto, FR-014
  });

  /// Pasada en vivo sobre el flujo de captura. FR-012.
  Future<LiveTranscription> transcribeLive({
    required Stream<Uint8List> pcm16,
    required TranscriptionModel model,
    String? initialPrompt,
  });
}

class RawSegment {
  final int fromMs;
  final int toMs;
  final String text;
}

abstract interface class LiveTranscription {
  Stream<String> get partials;
  Future<void> stop();
}

enum TranscriptionModel { base, small }
```

```dart
/// Disponibilidad y descarga del modelo. Implementado en data/ sobre `dio`,
/// ÚNICO importador de `dio` en todo el árbol, verificado por puerta de CI.
abstract interface class ModelRepository {
  /// Comprueba que el archivo del modelo existe en disco.
  /// Es la barrera que impide que el paquete dispare su descarga automática,
  /// prohibida por la constitución (research.md, conflicto C3). Todo camino
  /// hacia `Transcriber` pasa por aquí primero.
  Future<bool> isAvailable(TranscriptionModel model);

  /// Descarga iniciada manualmente desde ajustes. Emite progreso real.
  /// Escribe a `.part` y renombra de forma atómica al completar, de modo que
  /// una descarga interrumpida nunca deja un modelo utilizable. FR-020, FR-022.
  Stream<DownloadProgress> download(TranscriptionModel model);

  Future<void> cancelDownload(TranscriptionModel model);
}

class DownloadProgress {
  final int receivedBytes;
  final int? totalBytes;   // nulo si el servidor no informa longitud
  final DownloadState state; // idle | downloading | done | failed | cancelled
}
```

---

## Repositorios

```dart
abstract interface class RecordingRepository {
  Stream<List<Recording>> watchBySession(SessionId id);          // FR-003a
  Stream<Recording?> watchActive();                              // invariante R1
  Future<Recording?> findInterrupted();                          // FR-011, al arrancar
  Future<void> insert(Recording recording);
  Future<void> updateStatus(RecordingId id, RecordingStatus status, DateTime at);
  Future<void> setStopped(RecordingId id, int durationMs, DateTime at);
  /// Baja lógica + asiento `recordingDeleted` en la MISMA transacción.
  Future<void> softDelete(RecordingId id, DateTime at);
}

abstract interface class LiveMarkRepository {
  Stream<List<LiveMark>> watchByRecording(RecordingId id);        // FR-008, orden por at_ms
  Future<void> insert(LiveMark mark);
  Future<void> updateKind(LiveMarkId id, LiveMarkKind kind, DateTime at);  // FR-009a
  /// Baja lógica + asiento `liveMarkDeleted` en la MISMA transacción.
  Future<void> softDelete(LiveMarkId id, DateTime at);
}

abstract interface class TranscriptRepository {
  Stream<Transcript?> watchByRecordingAndPass(RecordingId id, TranscriptPass pass);
  Stream<List<TranscriptSegment>> watchSegments(TranscriptId id);
  Future<List<Transcript>> findPending();                        // cola de FR-016
  Future<void> upsert(Transcript transcript);
  /// Reemplaza los segmentos de una transcripción en una sola transacción.
  Future<void> replaceSegments(TranscriptId id, List<TranscriptSegment> segments);
  Future<void> softDelete(TranscriptId id, DateTime at);
}
```

---

## Casos de uso

### Grabación

| Caso de uso | Firma | Precondiciones y efectos |
|---|---|---|
| `StartRecording` | `Future<Result<RecordingId>> call(SessionId)` | Exige proyecto activo (`ProjectStatusReader`) **y** sesión en curso (FR-003). Verifica permiso (FR-004) y que no haya otra grabación activa (R1). Abre WAV y flujo |
| `StopRecording` | `Future<Result<void>> call(RecordingId)` | Cierra el flujo, parchea la cabecera, fija `duration_ms` y `stopped_at`. Encola la pasada definitiva |
| `HandleInterruption` | `Future<Result<void>> call(RecordingId)` | Disparado por una pausa **no pedida**. Marca `interrupted` conservando el archivo. FR-010 |
| `RecoverInterrupted` | `Future<Result<RecoveryOutcome>> call(RecordingId, RecoveryChoice)` | `RecoveryChoice` es `resume` o `closeKeeping`. Repara la cabecera en ambos casos; `resume` reabre el flujo anexando al mismo archivo. FR-011 |
| `DeleteRecording` | `Future<Result<void>> call(RecordingId)` | Baja lógica + asiento |

**`StartRecording` no mueve la sesión a "en curso".** El spec lo declara en Assumptions: la
transición de estado sigue siendo del analista. El caso de uso **rechaza** con
`SessionNotInProgressFailure` si la sesión está planeada.

### Marcas en vivo

| Caso de uso | Firma | Precondiciones y efectos |
|---|---|---|
| `PlaceLiveMark` | `Future<Result<LiveMarkId>> call(RecordingId, LiveMarkKind)` | Solo con grabación activa (FR-009). Calcula `at_ms` desde el inicio de la grabación |
| `ChangeMarkKind` | `Future<Result<void>> call(LiveMarkId, LiveMarkKind)` | No exige grabación activa (FR-009a) |
| `DeleteLiveMark` | `Future<Result<void>> call(LiveMarkId)` | Baja lógica + asiento |
| `WatchMarks` | `Stream<List<LiveMark>> call(RecordingId)` | Orden por `at_ms` (FR-008) |

### Transcripción

| Caso de uso | Firma | Precondiciones y efectos |
|---|---|---|
| `StartLivePass` | `Future<Result<void>> call(RecordingId, Stream<Uint8List>)` | **Comprueba `ModelRepository.isAvailable` primero**; si falta el modelo no arranca y no falla la grabación |
| `RunFinalPass` | `Future<Result<TranscriptId>> call(RecordingId)` | **Comprueba disponibilidad primero**; si falta, deja el `Transcript` en `pending` y termina en `Ok` (FR-016). Si está, pasa a `processing`, transcribe con `small` y `withSegments`, mapea a segmentos y persiste |
| `BuildInitialPrompt` | `String call(List<GlossaryTerm>)` | **Función pura.** Convierte el glosario en el `initialPrompt` (FR-014). Devuelve cadena vacía si no hay términos |
| `ProcessPendingTranscripts` | `Future<Result<int>> call()` | Ejecutado tras completarse una descarga: recorre `findPending()` y lanza la pasada definitiva de cada uno |
| `WatchTranscript` | `Stream<TranscriptView> call(RecordingId, TranscriptPass)` | Texto, estado y segmentos en un solo stream |

**`RunFinalPass` devuelve `Ok` cuando falta el modelo.** No es un error: FR-016 define ese
camino como el comportamiento correcto. Devolver `Err` obligaría a cada llamador a distinguir
"falló" de "quedó pendiente a propósito", y el primero que lo olvidara mostraría un error al
analista por haber cerrado una sesión sin haber descargado nada.

### Modelo

| Caso de uso | Firma | Precondiciones y efectos |
|---|---|---|
| `WatchModelStatus` | `Stream<Map<TranscriptionModel, ModelStatus>> call()` | Alimenta la pantalla de ajustes |
| `DownloadModel` | `Stream<DownloadProgress> call(TranscriptionModel)` | FR-020. Al completar, dispara `ProcessPendingTranscripts` |
| `CancelModelDownload` | `Future<Result<void>> call(TranscriptionModel)` | Borra el `.part` (FR-022) |

### Reproducción

| Caso de uso | Firma | Precondiciones y efectos |
|---|---|---|
| `LoadRecordingForPlayback` | `Future<Result<void>> call(RecordingId)` | FR-017: funciona exista o no transcripción |
| `SeekToSegment` | `Future<Result<void>> call(SegmentId)` | Resuelve `from_ms` y salta. FR-018 |
| `WatchActiveSegment` | `Stream<SegmentId?> call(TranscriptId)` | Cruza `position` del reproductor con las ventanas. FR-019 |

---

## Fallos

| Fallo | Cuándo |
|---|---|
| `MicrophonePermissionDenied` | FR-004 |
| `SessionNotInProgressFailure` | Grabar en sesión planeada o cerrada (FR-003) |
| `ProjectClosedFailure` | Heredado del incremento 1 |
| `RecordingAlreadyActiveFailure` | Invariante R1 |
| `NoActiveRecordingFailure` | Colocar marca sin captura activa (FR-009) |
| `StorageFullFailure` | Caso borde: se detiene conservando lo capturado |
| `ModelUnavailableFailure` | Solo en la pasada **en vivo**; la definitiva usa `pending`, no este fallo |
| `DownloadFailure` | Red caída o respuesta inválida (FR-022) |
| `TranscriptionFailure` | El transcriptor devolvió error; deja `status = 'failed'` con `failure_reason` |

---

## Lo que este contrato deja abierto para el incremento 3

Deliberado, y exigido por el roadmap:

- `TranscriptSegment` lleva `recording_id`, `from_ms` y `to_ms` desnormalizados: el filtrado
  por ventanas de tiempo del incremento 3 no necesitará ningún join ni ninguna migración.
- `LiveMark.kind` es un conjunto cerrado de tres valores, no un booleano: las ventanas de
  filtrado podrán distinguir por qué se marcó cada momento.
- `Transcript.status` ya contempla `pending` y reintento, que es la forma de la cola que el
  incremento 3 reutilizará para sus bloques.

Ninguna de las tres cuesta trabajo hoy. Las tres serían una migración mañana.
