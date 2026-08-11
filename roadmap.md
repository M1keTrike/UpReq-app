# Roadmap — up-req

Aplicación móvil personal para el levantamiento de requerimientos de software en campo.

**Este archivo no es una especificación.** No lo consumen los comandos de spec-kit como insumo de generación. Sirve para tres cosas: recordar el orden de construcción, evitar que un incremento cierre puertas al siguiente, y guardar los parámetros que solo pueden fijarse después de medir contra uso real.

Cada incremento recorre el ciclo completo por su cuenta:

```
/speckit-specify → /speckit-clarify → /speckit-plan → /speckit-checklist → /speckit-tasks → /speckit-implement
```

Un incremento no se especifica hasta que el anterior corre en un dispositivo físico.

---

## Estado

| #   | Incremento                        | Estado    |
| --- | --------------------------------- | --------- |
| 1   | Proyectos, interesados y sesiones | En curso  |
| 2   | Captura y transcripción           | Pendiente |
| 3   | Extracción con LLM                | Pendiente |
| 4   | Recomendaciones y antes/después   | Pendiente |
| 5   | Tablero global                    | Pendiente |
| 6   | Exportación                       | Pendiente |

Los incrementos 1 a 3 producen ya una herramienta usable en una entrevista real. Ese es el hito que importa.

---

## 1. Proyectos, interesados y sesiones

**Objetivo.** Esqueleto navegable con persistencia. Estructura por feature, drift en versión 1, borrado lógico y bitácora.

**Incluye.** CRUD de proyectos, interesados, sesiones, guion de sesión y glosario del proyecto. Navegación jerárquica con go_router. Contadores de elementos asociados.

**Excluye.** Audio, red, LLM, métricas, exportación. Sin paquetes de red en `pubspec`.

**Puertas que debe dejar abiertas.**

- El guion de sesión recibirá en el incremento 4 los campos generados pendientes de validar. Sus puntos necesitan poder referenciar el origen de la pregunta, no solo texto libre.
- El glosario del proyecto alimentará el `initialPrompt` del transcriptor en el incremento 2. Debe ser consultable como lista plana de términos.
- Los identificadores son UUID v4 generados en `domain`, nunca autoincrementales de SQLite, porque el respaldo y la reimportación dependen de ello.
- Las fechas se guardan en UTC como epoch en milisegundos y se formatean solo en `presentation`.

**Qué aprendizaje aporta.** Confirma que la estructura por feature y la disciplina de Riverpod generado son sostenibles antes de que haya complejidad real.

---

## 2. Captura y transcripción

**Objetivo.** Grabar entrevistas y transcribirlas en el dispositivo, con segmentos anclados por marca de tiempo.

**Incluye.** Grabación con `record` en WAV 16 kHz mono. Etiquetado en vivo con marca de tiempo durante la sesión. Transcripción en dos pasadas con `whisper_ggml`. Descarga del modelo GGML desde ajustes. Reproductor que salta al segundo de un segmento.

**Excluye.** Cualquier llamada al LLM. La transcripción se guarda pero nadie la procesa todavía.

**Puertas que debe dejar abiertas.**

- Los segmentos con `fromTs` y `toTs` son la unidad de evidencia de todo el sistema. Su tabla debe poder referenciarse desde requisitos que aún no existen.
- El etiquetado en vivo define las ventanas de filtrado del incremento 3. Cada marca necesita tipo y marca de tiempo, no solo un booleano.
- La recuperación de una sesión interrumpida a media grabación tiene que resolverse aquí, no después.

**Qué aprendizaje aporta.** Cuánto tarda Whisper en el teléfono real, y por tanto si la pasada definitiva usa `small` o `base`. Qué tan limpia sale la transcripción en español con audio de campo, y cuánto ayuda el glosario como `initialPrompt`.

---

## 3. Extracción con LLM

**Objetivo.** Convertir transcripciones en requisitos fichados, con procedencia por campo.

**Incluye.** Cliente `dio` contra DeepSeek. Filtrado por marcas y por puntuación léxica. Troceado en bloques con traslape. Cola persistida con hash, estado y reintentos. Ficha de requisito con los cuatro estados de procedencia y su marcado visual. Flujo de confirmación antes de persistir.

**Excluye.** Recomendaciones, métricas, exportación.

**Puertas que debe dejar abiertas.**

- La procedencia se guarda por campo, no por requisito. Todo lo que viene después depende de esta granularidad.
- Los candidatos deben conservar `segmentId`, `fromTs` y `toTs` para que el incremento 6 pueda decidir el reparto entre cuerpo y anexo.
- La cola debe ser reutilizable por el motor de recomendaciones del incremento 4.

**Qué aprendizaje aporta.** Los parámetros del pipeline, que hasta aquí son suposiciones. Y qué tan buenos salen los requisitos extraídos, lo cual determina si el incremento 4 debe priorizar recomendaciones de calidad o de cobertura.

**Antes de cerrarlo:** medir exhaustividad. Extraer a mano los requisitos de una entrevista real y comparar contra lo que devuelve el pipeline. Perder requisitos en silencio es el peor modo de falla de esta herramienta.

---

## 4. Recomendaciones y antes/después

**Objetivo.** Iterar sobre los requisitos ya capturados con propuestas aplicables y reversibles.

**Incluye.** Los cuatro tipos de recomendación. Parche estructurado campo por campo. Pantalla de comparación con diff. Aplicar dentro de una transacción que crea versión nueva. Revertir. Promoción de campos generados al guion de la siguiente sesión.

**Excluye.** El delta de métricas en la pantalla de comparación queda como hueco hasta el incremento 5.

**Puertas que debe dejar abiertas.**

- Las instantáneas de métricas asociadas a cada recomendación aceptada se diseñan aquí aunque se llenen en el incremento 5.
- Las notas de diseño del cuarto tipo de recomendación viven aparte del texto del requisito y no deben mezclarse con él.

**Qué aprendizaje aporta.** Qué proporción de recomendaciones se acepta. Si es muy baja, el prompt está mal calibrado; si es muy alta, probablemente no estás revisando con suficiente escepticismo.

---

## 5. Tablero global

**Objetivo.** Responder si el levantamiento va bien y cuándo parar.

**Incluye.** Cobertura separada entre contenido con y sin respaldo, calidad, distribución, volatilidad, saturación e índice de procedencia. Todo en SQL sobre drift. Instantáneas fechadas. Cierre del hueco de delta en la pantalla de comparación del incremento 4.

**Excluye.** Cualquier cálculo con LLM.

**Qué aprendizaje aporta.** La curva de saturación indica cuándo una fuente se agotó. El índice de procedencia indica cuánto de la especificación es real y cuánto es propuesta sin validar.

---

## 6. Exportación

**Objetivo.** Producir el SRS entregable, el backlog y la matriz de trazabilidad.

**Incluye.** `BuildSrsExport` como función pura en `domain`. Reparto entre cuerpo y anexo. Notas explícitas de hueco. Perfiles entregable y trabajo interno. Compuerta de confirmación previa.

**Decisión pendiente.** Formato de salida. El paquete `pdf` de Dart es la ruta sólida sin conexión; generar DOCX desde Dart es frágil. Si se necesita Word editable, exportar Markdown estructurado y convertir fuera de la app. La decisión no afecta a los incrementos anteriores porque el reparto ya viene resuelto desde el dominio.

---

## Parámetros pendientes de calibración

Estos valores salieron deliberadamente de la constitución porque solo pueden fijarse midiendo. Se declaran en el `/speckit-plan` del incremento correspondiente.

| Parámetro                                 | Incremento | Valor de arranque sugerido         |
| ----------------------------------------- | ---------- | ---------------------------------- |
| Modelo Whisper, pasada en vivo            | 2          | `base`                             |
| Modelo Whisper, pasada definitiva         | 2          | `small`                            |
| Umbral de energía para descartar silencio | 2          | Calibrar contra audio real         |
| Tamaño de bloque                          | 3          | ~1200 tokens                       |
| Pausa mínima para cortar bloque           | 3          | 1.2 s                              |
| Traslape entre bloques                    | 3          | 1 segmento o ~30 s                 |
| Concurrencia de peticiones                | 3          | 3, configurable de 1 a 6           |
| Reintentos por bloque                     | 3          | 3                                  |
| Timeout por petición                      | 3          | 60 s                               |
| Umbral léxico de intención                | 3          | Calibrar contra transcripción real |
| Tope de candidatos por bloque             | 3          | 6                                  |

El límite del proveedor no es el factor: DeepSeek permite 2500 conexiones concurrentes en Flash y 500 en Pro. El tope responde a la red móvil, la batería y el control de gasto.

---

## Reglas del roadmap

1. Un incremento no se especifica hasta que el anterior corre en un dispositivo físico.
2. Lo que se aprende en un incremento se escribe aquí antes de especificar el siguiente.
3. Si un incremento revela que la constitución está equivocada, se enmienda la constitución, no se ignora.
4. El orden puede cambiar; lo que no cambia es que cada incremento sea vertical y termine en algo ejecutable.
