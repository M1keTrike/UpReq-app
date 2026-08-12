# Phase 0 Research: Captura y transcripción de entrevistas

**Feature**: 002-captura-transcripcion
**Date**: 2026-08-11
**Input**: [spec.md](spec.md), [constitution.md](../../.specify/memory/constitution.md), [roadmap.md](../../roadmap.md)

Toda decisión se contrasta contra la constitución. Cuando la realidad de las librerías
contradice una regla constitucional, se declara aquí y se escala al gate de Constitution
Check en [plan.md](plan.md); no se resuelve en silencio.

Este incremento es el primero que introduce código nativo pesado (inferencia y captura de
audio) y el primero que abre una conexión de red. Ambas cosas están previstas por la
constitución, pero ninguna estaba ejercitada todavía, así que la investigación se concentra
en verificar que lo previsto es realizable con las versiones publicadas.

---

## 1. `whisper_ggml` 2.6.0 — verificado, coincide con la constitución

**Hallazgo verificado en pub.dev**: `whisper_ggml` 2.6.0 existe, está publicado hace días,
tiene licencia **MIT** y empaqueta **whisper.cpp v1.9.1**. Ambos números coinciden
exactamente con los que fija el Principio II, que hasta ahora no se había ejercitado.

API pública real (`WhisperController`):

```dart
Future<String> downloadModel(WhisperModel model);   // descarga y devuelve la ruta
Future<String> getPath(WhisperModel model);         // ruta local del archivo
static Future<String> getModelDir();                // directorio de modelos
Future<void> initModel(WhisperModel model);
Future<void> releaseModel();

Future<TranscribeResult?> transcribe({
  required WhisperModel model,
  required String audioPath,
  String lang = 'en',
  String? initialPrompt,
  bool withSegments = false,
  bool splitOnWord = false,
  bool keepModelLoaded = false,
  void Function(int percent)? onProgress,
  ...
});

Future<WhisperLiveSession> transcribeLive({
  WhisperModel? model,
  String? modelPath,
  required Stream<Uint8List> pcm16Stream,
  String lang = 'en',
  String? initialPrompt,
  double gateRmsMin = 0.0015,
  double gateVoiceRatio = 2.5,
  double gateNoiseFloorCap = 0.01,
  ...
});
```

**Decisión**: adoptar `whisper_ggml` 2.6.0 tal como lo nombra la constitución, con
`WhisperModel.base` en la pasada en vivo y `WhisperModel.small` en la definitiva,
`lang: 'es'` fijo y `withSegments: true` en la definitiva.

**Rationale**: cada exigencia del Principio II tiene una contraparte literal en la API:
`withSegments` produce los segmentos con marca de inicio y fin que son la unidad de
evidencia; `initialPrompt` recibe el glosario; `lang` se fija en `'es'`. La documentación
del paquete declara además que **la inferencia corre en un isolate de fondo y nunca bloquea
la interfaz**, que es exactamente la última frase del Principio II. No hay que construir esa
garantía: viene dada y solo hay que verificarla.

**Alternativas consideradas**:
- `whisper_flutter_plus` y bindings propios sobre whisper.cpp vía FFI: obligarían a
  reimplementar el isolate, la descarga y la conversión de audio, y a enmendar la
  constitución, que nombra `whisper_ggml` 2.6.0 de forma exacta.

**Consecuencia para la calibración**: `transcribeLive` expone `gateRmsMin`,
`gateVoiceRatio` y `gateNoiseFloorCap`. Ese es el "umbral de energía para descartar
silencio" que el roadmap marca como parámetro a calibrar en este incremento. No hay que
implementarlo: hay que **medirlo** contra audio de campo y fijar los tres valores.

---

## 2. CONFLICTO — `whisper_ggml` descarga el modelo solo, sin pedir permiso

**Hallazgo verificado**: la documentación del paquete dice que los modelos se "descargan
automáticamente en el primer uso" y quedan cacheados. Es decir, una llamada a `transcribe()`
con un modelo ausente **abre una conexión de red por su cuenta**.

Eso choca de frente con una prohibición explícita de la constitución, que permite una única
excepción de red además de DeepSeek: *"la descarga del modelo GGML desde el host de modelos
configurado, **iniciada manualmente por el usuario desde ajustes** y ejecutada una sola vez
por modelo"*. Una descarga disparada de forma implícita por transcribir no es iniciada
manualmente desde ajustes. También rompería FR-021, que exige que la descarga sea la única
operación de red del incremento y que ninguna otra pantalla dependa de la red.

Segundo hallazgo, en la misma dirección: `downloadModel()` **no reporta progreso**. Devuelve
`Future<String>` y nada más. FR-020 exige mostrar el progreso de la descarga.

**Decisión**: la aplicación nunca llama a `transcribe()` ni a `transcribeLive()` sin haber
verificado antes que el archivo del modelo existe en disco, y descarga el modelo ella misma:

1. `WhisperController.getPath(model)` da la ruta exacta donde el paquete espera el archivo.
2. Si el archivo existe, el modelo está disponible; si no, la transcripción queda
   **pendiente** (FR-016) y jamás se invoca al transcriptor.
3. La descarga desde ajustes la ejecuta la app con `dio`, contra el host de modelos
   configurado, escribiendo en `<ruta>.part` y renombrando de forma atómica al terminar.
   `onReceiveProgress` da el porcentaje real que pide FR-020.

**Rationale**: esto convierte una descarga implícita e inobservable en una explícita,
observable y cancelable, que es literalmente lo que exigen la constitución y FR-020. El
renombrado atómico resuelve FR-022 sin necesidad de reanudación por rangos: un `.part`
interrumpido nunca es un modelo utilizable, y reintentar simplemente lo sobrescribe.

La comprobación de existencia previa es además la barrera que garantiza que la ruta
automática del paquete **nunca se dispara**. No es una precaución de estilo: es lo único que
hace verificable la prohibición.

**Alternativas consideradas**:
- Llamar a `downloadModel()` desde ajustes y mostrar un progreso indeterminado: cumple "se
  inicia desde ajustes" pero incumple "mostrando el progreso" de FR-020, y deja viva la ruta
  implícita si alguna vez se transcribe sin modelo.
- Empaquetar los modelos como assets de la app: el paquete lo permite y eliminaría la red
  por completo, pero `small` pesa cientos de megabytes y quedaría dentro del binario para
  todos los usuarios aunque nunca transcriban. Se descarta por tamaño, no por arquitectura.

---

## 3. `dio` entra al proyecto, y el gate de red de CI debe cambiar

**Hallazgo**: `tool/check_no_network_deps.dart`, la puerta de CI escrita en el incremento 1,
prohíbe `dio` (y `http`, `web_socket_channel`, etc.) en la clausura de `dependencies:`. Esa
puerta materializaba FR-019 del incremento 1: *"este incremento MUST no realizar ninguna
petición de red"*.

Ese requisito era del incremento 1 y este incremento lo sustituye por FR-021: la descarga
del modelo es la única operación de red permitida.

**Decisión**: incorporar `dio` 5.11.0 (MIT) como dependencia y **reescribir** el gate en vez
de eliminarlo. La puerta pasa de "cero paquetes de red" a "cero paquetes de red **salvo
`dio`**, y `dio` solo puede usarse desde un único archivo".

El gate reescrito verifica dos cosas:
1. Ningún paquete de red distinto de `dio` entra en la clausura de `dependencies:`.
2. `package:dio` se importa desde exactamente **un** archivo del árbol: el cliente de
   descarga del modelo. Cualquier otro import de `dio` bloquea el merge.

**Rationale**: eliminar la puerta porque el requisito que la motivó cambió sería tirar la
garantía justo cuando empieza a ser útil. La regla constitucional no es "no hay red", es
"hay exactamente una excepción declarada"; una puerta que cuente los puntos de uso expresa
esa regla mejor que la ausencia de puerta. La verificación por número de importadores es
barata y detecta el modo de falla real: que en el incremento 3 alguien añada una segunda
llamada de red sin pasar por el cliente declarado.

**Alternativas consideradas**:
- Borrar el gate: deja la prohibición sin verificación automática justo en el incremento que
  la estrena.
- Dejar el gate intacto y descargar con `HttpClient` de `dart:io`: pasaría la puerta sin
  tocarla, pero solo porque la puerta mira nombres de paquete y no conductas. Sería cumplir
  la letra evadiendo el propósito, y además contradice a la constitución, que nombra `dio`
  como el cliente HTTP del proyecto.

---

## 4. Captura: un solo flujo PCM alimentando dos destinos

**Hallazgo verificado**: `record` 7.1.1 (BSD-3-Clause) soporta `AudioEncoder.pcm16bits` con
`sampleRate` y `numChannels` configurables, expone `hasPermission()`, `startStream()`,
`start()`, `pause()`, `resume()`, `stop()`, `amplitude` y `onStateChanged()`.

El problema de diseño: `start()` escribe a archivo y `startStream()` entrega un
`Stream<Uint8List>`, pero **no hay un modo que haga las dos cosas a la vez**. Y este
incremento necesita las dos: el archivo WAV para la pasada definitiva y el flujo PCM16 para
`transcribeLive`.

**Decisión**: usar `startStream()` como única fuente y bifurcar el flujo en la app:

```
record.startStream(RecordConfig(
  encoder: AudioEncoder.pcm16bits,
  sampleRate: 16000,
  numChannels: 1,
))
        │
        ├──► escritor WAV incremental  ──► sesión.wav  (pasada definitiva)
        └──► transcribeLive(pcm16Stream) ──► parciales  (pasada en vivo)
```

El escritor WAV abre el archivo, escribe una cabecera RIFF de 44 bytes con los dos campos de
tamaño **en cero**, y va anexando las tramas PCM tal como llegan. Al detener, vuelve atrás y
parchea los dos tamaños con los valores reales.

**Rationale**: `startStream()` con 16 kHz mono PCM16 produce exactamente el formato que el
Principio II exige y que `transcribeLive` pide, sin transcodificar nada. La bifurcación es
trivial (un `StreamController` con dos suscriptores) y deja el archivo escrito de forma
incremental, que es justo lo que hace recuperable una grabación interrumpida.

**Consecuencia clave para FR-010**: como la cabecera se parchea solo al detener, un cierre
inesperado deja un WAV con tamaños en cero. Eso **no es corrupción**: el audio está íntegro
detrás de la cabecera. La recuperación consiste en recalcular ambos campos desde el tamaño
real del archivo y reescribirlos. Es una operación de 8 bytes y determinista, y se prueba
como función pura sin grabar nada.

**Alternativas consideradas**:
- `start()` a archivo y correr la pasada en vivo leyendo el archivo por trozos: obliga a
  releer desde disco lo que ya pasó por memoria, y a inventar un protocolo de "hasta dónde
  leí" que se desincroniza en cuanto la escritura se retrasa.
- Dos grabadores simultáneos: el micrófono es un recurso exclusivo; el segundo falla.

---

## 5. Interrupciones del sistema operativo: la librería ya hace lo aclarado

**Hallazgo verificado**: `RecordConfig` tiene un parámetro
`audioInterruption: AudioInterruptionMode` cuyo **valor por defecto es
`AudioInterruptionMode.pause`**: ante una interrupción del sistema (una llamada entrante), el
grabador se pausa y **no** reanuda solo.

La aclaración de la sesión 2026-08-11 decidió exactamente eso: la grabación se pausa, queda
marcada como interrumpida y el analista decide después si reanuda o cierra la toma.

**Decisión**: dejar `audioInterruption` en su valor por defecto y observar
`onStateChanged()`; una transición a `RecordState.pause` que la app no pidió se interpreta
como interrupción y marca la grabación como `interrupted` en la base de datos.

**Rationale**: la conducta aclarada con el usuario y la conducta por defecto de la librería
coinciden, así que no hay que forzar nada. Distinguir "pausa que pedí yo" de "pausa que me
impusieron" es un booleano en el notifier, no un mecanismo.

**Riesgo declarado**: `record` **no** soporta grabación en segundo plano y su documentación
remite a un paquete externo (`flutter_foreground_task`) para ello. Ver decisión 8.

---

## 6. Reproducción: `just_audio`

**Hallazgo verificado**: `just_audio` 0.10.6, licencia Apache-2.0 / MIT, con
`seek(Duration)`, `positionStream`, reproducción de archivo local. Sus dependencias son
`async`, `audio_session`, `crypto`, `just_audio_platform_interface`, `just_audio_web`,
`meta`, `path`, `path_provider`, `rxdart`, `synchronized`, `uuid`. **Ninguna es un paquete
de red**, así que no altera el gate de la decisión 3.

**Decisión**: `just_audio` para el reproductor. `seek()` cubre FR-018 y `positionStream`
cubre el resaltado del segmento activo de FR-019.

**Rationale**: es el reproductor de Flutter con mejor soporte de posición y búsqueda, con
las dos primitivas que el spec pide de forma literal, y sin arrastrar red.

**Salvedad de configuración**: la guía de `just_audio` pide declarar el permiso
`android.permission.INTERNET`. Este incremento **ya** necesita ese permiso por la descarga
del modelo, así que no añade superficie. Se documenta para que nadie lo lea después como una
vía de red encubierta del reproductor: el reproductor solo abre archivos locales.

**Alternativa considerada**: `audioplayers`, equivalente en lo básico pero con un modelo de
posición menos fino para el resaltado continuo del segmento activo.

---

## 7. `ffmpeg_kit_flutter_new_min` es LGPL-3.0, y eso está permitido

**Hallazgo**: `whisper_ggml` depende de forma transitiva de
`ffmpeg_kit_flutter_new_min`, cuya licencia es **LGPL-3.0**. Es la dependencia más pesada que
entra al proyecto y conviene declararla antes de que aparezca sola en un `pub deps`.

La constitución prohíbe "dependencias sin null safety, sin mantenimiento en los últimos 12
meses o con licencia **GPL/AGPL**". LGPL no es ninguna de las dos, y la distinción es
deliberada en el original: LGPL permite el enlace desde una aplicación de licencia distinta,
que es exactamente este caso.

Verificado además que la variante `_min` **no contiene componentes GPL**: la propia
documentación del paquete indica que quien necesite `x264`/`x265`/`xvidcore`/`vid.stab` debe
usar el paquete `-gpl`. Elegir esa otra variante sí incumpliría la constitución.

**Decisión**: aceptar `ffmpeg_kit_flutter_new_min` como dependencia transitiva y **fijar en
CI que la variante `-gpl` nunca entre**. El gate de dependencias existente
(`tool/check_dependencies.dart`) gana una comprobación de un renglón.

**Rationale**: la prohibición constitucional se cumple, pero se cumple por un detalle
—`_min` frente a `-gpl`— que una actualización futura de `whisper_ggml` podría cambiar sin
que nadie lo note. Una comprobación automática cuesta menos que descubrirlo en una auditoría
de licencias.

**Requisitos de plataforma que impone**: Android API 24+ e iOS 14.0+. El objetivo de producto
es Android 10 (API 29) e iOS 16+, ambos holgadamente por encima. `record` pide minSdk 23.
El `minSdkVersion` efectivo del proyecto queda en **24 o superior**.

---

## 8. Grabación en segundo plano: fuera de alcance, con mitigación declarada

**Hallazgo verificado**: la documentación de `record` dice que el paquete **no** soporta
grabación en segundo plano y recomienda `flutter_foreground_task`. En Android, si la
aplicación pasa a segundo plano o la pantalla se bloquea durante una entrevista larga, el
sistema puede detener la captura.

**Decisión**: este incremento graba **en primer plano**, manteniendo la pantalla encendida
durante la captura activa, y **no** incorpora un servicio en primer plano.

**Rationale**: el spec no pide grabar con la aplicación en segundo plano, y el flujo real lo
respalda —el analista tiene el teléfono en la mano tocando marcas en vivo, que es
precisamente una interacción de primer plano—. Añadir un servicio en primer plano trae
notificación persistente, un tipo de servicio declarado en el manifiesto, permisos nuevos y
una superficie de ciclo de vida propia; es un incremento de complejidad que no responde a
ningún requisito escrito.

**Lo que sí queda cubierto**: la historia 3 completa. Si el sistema mata la aplicación, el
audio está íntegro (decisión 4) y el analista decide qué hacer (FR-011). La pérdida de una
entrevista no depende de este diseño.

**Lo que queda expuesto, dicho sin adornos**: si el analista cambia de aplicación a mitad de
entrevista, Android puede cortar la captura y él lo notará al volver, no en el momento. Es
un riesgo real, es el candidato número uno a corregirse si la validación en campo lo topa, y
por eso queda escrito aquí en vez de descubrirse en uso.

---

## 9. Esquema: la primera migración real del proyecto

**Hallazgo**: el incremento 1 dejó `schemaVersion 1` con `onCreate` explícito y un snapshot
versionado en `drift_schemas/`, con una prueba de esquema que lo verifica. Este incremento
añade cuatro tablas y es, por tanto, la primera migración de verdad.

**Decisión**: subir a `schemaVersion 2` con un `onUpgrade` explícito que crea únicamente las
tablas e índices nuevos, generar el snapshot `drift_schema_v2.json` y extender la prueba de
esquema para verificar **el paso de v1 a v2**, no solo el estado final.

**Rationale**: la constitución exige "esquema versionado y migraciones explícitas". Verificar
solo el esquema resultante dejaría pasar una migración que produce el esquema correcto en una
instalación nueva y falla en una que ya tenía datos, que es el único caso que importa: el
teléfono del analista ya tiene el incremento 1 encima con proyectos reales.

**Consecuencia**: ninguna tabla del incremento 1 se altera. Las cuatro nuevas cuelgan de
`sessions` y de `projects` por clave foránea, así que la migración es puramente aditiva y no
puede perder datos.

---

## 10. Parámetros que este incremento debe fijar

El roadmap declara estos como "pendientes de calibración, se declaran en el `/speckit-plan`
del incremento correspondiente". Se fijan aquí como valores de arranque y se **miden** en la
validación en dispositivo:

| Parámetro | Valor de arranque | Cómo se ajusta |
|---|---|---|
| Modelo, pasada en vivo | `WhisperModel.base` | Si no sostiene el tiempo real en el teléfono, bajar a `tiny` |
| Modelo, pasada definitiva | `WhisperModel.small` | Si tarda de más al cerrar sesión, bajar a `base` |
| `gateRmsMin` | `0.0015` (valor por defecto del paquete) | Subir si entra ruido de fondo como habla |
| `gateVoiceRatio` | `2.5` (por defecto) | Bajar si se pierden intervenciones en voz baja |
| `gateNoiseFloorCap` | `0.01` (por defecto) | Ajustar contra la sala real |
| Frecuencia y canales | 16 kHz, mono | Fijo: lo imponen el Principio II y `transcribeLive` |
| `lang` | `'es'` | Fijo por el Principio II |

Los tres valores del gate se dejan en su valor por defecto **a propósito**: son el punto de
partida del autor del paquete y no hay base para inventar otros antes de medir. El roadmap
pide calibrarlos contra audio real, y eso ocurre en la validación, no aquí.

---

## Resumen de decisiones

| # | Decisión | Estado |
|---|---|---|
| 1 | `whisper_ggml` 2.6.0, `base` en vivo, `small` definitiva, `lang: 'es'`, `withSegments` | Verificado contra pub.dev |
| 2 | La app comprueba el modelo y lo descarga ella misma; nunca dispara la descarga implícita | **Conflicto resuelto en diseño** |
| 3 | `dio` entra; el gate de red se reescribe a "solo `dio`, y solo desde un archivo" | Cambia una puerta de CI |
| 4 | Un `startStream()` PCM16 bifurcado a escritor WAV y a `transcribeLive` | Decidido |
| 5 | `AudioInterruptionMode.pause` por defecto + `onStateChanged()` | La librería ya hace lo aclarado |
| 6 | `just_audio` para reproducir y buscar | Decidido |
| 7 | `ffmpeg_kit_flutter_new_min` LGPL-3.0 aceptada; CI veta la variante `-gpl` | Permitido, con guardia |
| 8 | Sin grabación en segundo plano; riesgo declarado | Alcance acotado a propósito |
| 9 | `schemaVersion 2` con `onUpgrade` explícito y prueba de migración v1→v2 | Decidido |
| 10 | Parámetros de arranque fijados, calibración en dispositivo | Pendiente de medir |

**Ningún NEEDS CLARIFICATION queda abierto.** El único conflicto con la constitución
(decisión 2) se resuelve dentro del diseño, sin necesidad de enmienda: la regla
constitucional se cumple más estrictamente de lo que la librería lo haría por su cuenta.
