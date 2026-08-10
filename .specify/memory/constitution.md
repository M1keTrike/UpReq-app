<!--
Sync Impact Report
- Version change: (template, sin versión) → 1.0.0
- Adopción inicial de la constitución a partir de constitution-input.md (contenido trasladado
  íntegramente, sin resumir, reordenar ni suavizar).
- Modified principles: n/a (no existían principios previos; la plantilla estaba sin rellenar)
- Added sections:
  - Propósito y Alcance
  - Core Principles: I. Plataforma y Arquitectura; II. Captura y Transcripción; III. LLM;
    IV. Requisitos y Procedencia; V. Iteración y Medición; VI. Exportación
  - Calidad (puertas de calidad)
  - Prohibiciones
  - Governance
- Removed sections: n/a
- Templates requiring updates: los templates dependientes leen la constitución en tiempo de
  ejecución; no se modifican desde este comando.
- Follow-up TODOs: ninguno
-->

# Constitución de up-req

## Propósito y Alcance

Aplicación móvil personal, monousuario y sin servidor, para el levantamiento de requerimientos
de software en campo. Gestiona proyectos, interesados y sesiones de elicitación; graba y
transcribe entrevistas en el dispositivo; extrae requisitos con apoyo de un LLM; itera sobre
ellos con recomendaciones aplicables; mide el avance del levantamiento en un tablero; y exporta
SRS (ISO/IEC/IEEE 29148), backlog y matriz de trazabilidad como archivos locales. Toda la
funcionalidad opera sin conexión salvo las llamadas explícitas al LLM.

## Core Principles

### I. Plataforma y Arquitectura

- Cliente e interfaz: Flutter 3.44.7 con Dart 3.12.1, Material 3, navegación con go_router.
  Objetivo Android 10+ e iOS 16+. No existe backend propio, cuentas, login, roles ni
  sincronización en la nube.
- Riverpod moderno y estado de pantalla: flutter_riverpod 3.4.2, riverpod_annotation 4.0.6,
  riverpod_generator 4.0.8 y riverpod_lint sobre custom_lint activo en CI. Todo provider se
  declara con @riverpod y se genera con build_runner; el estado mutable vive solo en Notifier y
  AsyncNotifier generados; autoDispose por defecto y keepAlive justificado en el código;
  ref.watch solo en build, ref.listen para efectos, ref.read solo en callbacks; escrituras
  expuestas con @mutation. Cada pantalla consume un único provider que devuelve AsyncValue\<T>
  o una clase sealed inmutable, y resuelve de forma exhaustiva cargando, datos, vacío y error.
- Arquitectura limpia por feature: lib/features/\<feature>/{domain,data,presentation} y lib/core
  para lo compartido. domain contiene entidades puras, contratos de repositorio y un caso de uso
  por operación, sin importar Flutter ni infraestructura. data contiene DTOs, mappers, la fuente
  local drift, el transcriptor y el cliente LLM. presentation contiene pantallas, widgets y
  providers. La dependencia apunta siempre hacia domain y ninguna feature importa carpetas
  internas de otra.
- Persistencia: SQLite mediante drift 2.34.3 como única fuente de verdad, con esquema versionado
  y migraciones explícitas. Audio e imágenes en el sandbox de la app. Respaldo y restauración
  mediante exportación e importación de un archivo local cifrado, iniciada por el usuario.

### II. Captura y Transcripción

- Grabación con record en WAV de 16 kHz, mono, un canal. Transcripción en el dispositivo con
  whisper_ggml 2.6.0 sobre whisper.cpp 1.9.1, en dos pasadas: en vivo con el modelo base durante
  la sesión para orientar el etiquetado, y definitiva con el modelo small al cerrarla, siempre
  con withSegments activo y lang fijo en 'es'. El glosario del proyecto se inyecta como
  initialPrompt. Los segmentos con fromTs y toTs son la unidad de evidencia: todo requisito
  extraído queda anclado al segmento que lo originó. La inferencia corre en un isolate y nunca
  bloquea la interfaz. El audio jamás sale del dispositivo.

### III. LLM

- Contrato de red: cliente HTTP con dio contra la base URL https://api.deepseek.com en formato
  OpenAI, endpoint /chat/completions. Quedan descartados el formato Anthropic y la Responses
  API. Modelo deepseek-v4-flash para extracción y deepseek-v4-pro para análisis, recomendaciones
  y consolidación, referenciados siempre por su alias y nunca por su build fechado; ambos
  identificadores son configurables desde ajustes. El modo pensante viene activo por defecto y
  debe desactivarse explícitamente en las llamadas de extracción por bloque; se conserva activo
  en consolidación, recomendaciones y detección de conflictos. Nunca se envía el parámetro
  user_id. Toda respuesta se solicita con salida JSON y se valida contra esquema antes de
  mapearse a dominio; una respuesta que no valide se descarta y cuenta como intento fallido.
  Timeout de 60 s, reintento con backoff exponencial y máximo tres intentos. Sin red la app
  funciona completa y las peticiones quedan encoladas localmente.
- Segmentación y envío: la transcripción nunca se envía completa, aunque el contexto del modelo
  lo permita, porque el troceado es lo que garantiza exhaustividad en la extracción. El pipeline
  es filtrar por ventanas de marcas del analista y por puntuación léxica de intención, agrupar
  los segmentos de Whisper en bloques cortando solo en pausas naturales, con traslape entre
  bloques consecutivos. Extracción con deepseek-v4-flash sin modo pensante, un bloque por
  petición, con concurrencia acotada y configurable desde ajustes; el tope responde a la red
  móvil, la batería y el control de gasto, no al límite del proveedor. Consolidación con
  deepseek-v4-pro recibiendo únicamente la lista de candidatos, nunca la transcripción. Cada
  bloque se persiste con hash de contenido, estado, número de intentos y respuesta cruda; un
  bloque ya procesado no se reenvía y un bloque fallido tras agotar sus intentos se marca sin
  detener la cola. Un HTTP 429 pausa la cola completa y reduce la concurrencia efectiva durante
  el resto del lote, en lugar de reintentar el bloque de forma aislada.

### IV. Requisitos y Procedencia

- Reglas de dominio invariables: todo requisito almacena ID, tipo (funcional o de calidad
  ISO/IEC 25010), evidencia de origen, prioridad MoSCoW, criterios de aceptación en Gherkin,
  estado y versión. No se persiste un requisito sin al menos una evidencia vinculada. Todo
  cambio genera una versión nueva, nunca una sobrescritura.
- Procedencia por campo: cada campo almacena su origen (declarado, inferido, generado,
  confirmado), la evidencia o recomendación que lo respalda y la fecha. Un requisito no tiene
  origen único: se deriva del conjunto de sus campos. La interfaz distingue cada estado con
  color, icono, etiqueta textual y estilo de borde de forma simultánea, nunca solo con color.
  Tocar la marca abre el segmento de audio de origen si es declarado o confirmado, y la
  justificación del modelo si es generado.
- Promoción a confirmado: todo campo generado pendiente se agrega automáticamente al guion de
  la siguiente sesión como punto a validar. Un campo solo pasa de generado a confirmado
  enlazando evidencia nueva capturada en sesión.

### V. Iteración y Medición

- Recomendaciones: el motor analiza el conjunto de requisitos y genera cuatro tipos: calidad
  (ambigüedad, no verificable, requisito compuesto, criterios incompletos), cobertura
  (categorías de ISO/IEC 25010 sin representar, flujos alternos, casos borde), conflicto
  (contradicción, duplicado, dependencia no declarada) y enfoque técnico (opciones de
  implementación con sus restricciones y riesgos). Se ejecuta con deepseek-v4-pro en modo
  pensante sobre la lista de requisitos, nunca sobre transcripciones. Las tres primeras
  producen parche; la cuarta produce una nota de diseño vinculada, no una modificación del
  texto del requisito.
- Recomendación como parche: se persiste con tipo, justificación, requisitos afectados,
  confianza y un parche estructurado campo por campo con valor anterior y valor propuesto.
  Estados: propuesta, aceptada, editada, descartada, revertida.
- Antes y después: aplicar un parche crea una versión nueva de cada requisito afectado,
  enlazada al ID de la recomendación, dentro de una única transacción de drift y sin borrar la
  versión previa. La pantalla de comparación muestra el diff campo por campo y el delta que
  provocaría en las métricas globales. Revertir restaura la versión anterior y marca la
  recomendación como revertida.
- Tablero global: todas las métricas se calculan localmente en SQL sobre drift y nunca las
  produce el LLM. Cobertura calculada por separado para contenido con respaldo y sin respaldo,
  calidad (índice de ambigüedad léxica, no verificables, huérfanos), distribución (por
  categoría ISO/IEC 25010, por prioridad MoSCoW, por interesado), volatilidad (versiones
  acumuladas por requisito), saturación (requisitos nuevos por sesión en el tiempo) e índice de
  procedencia (porcentaje de la especificación con evidencia real). Cada cálculo se guarda como
  instantánea fechada para graficar la evolución y aislar el efecto de cada recomendación
  aceptada.

### VI. Exportación

- El reparto entre cuerpo y anexo lo decide el caso de uso BuildSrsExport en domain, como
  función pura sobre la lista de requisitos y una política de exportación; el renderizador solo
  imprime la estructura que recibe. Un requisito con enunciado principal generado se exporta
  completo en el anexo de propuestas. Un requisito respaldado con campos generados se exporta
  en el cuerpo omitiendo esos campos e imprimiendo en su lugar una nota explícita del hueco con
  referencia a la propuesta correspondiente. Cada entrada del anexo conserva el ID de la
  recomendación, el modelo que la generó y la fecha. Existen dos perfiles: entregable, donde la
  exclusión no es configurable, y trabajo interno, que marca cada propuesta en el texto y
  estampa marca de agua de borrador. El perfil forma parte del nombre del archivo. Antes de
  generar, la app muestra el conteo de requisitos que irían al cuerpo sin criterios validados y
  exige confirmación explícita si es mayor que cero.

## Calidad

- Casos de uso y Notifier se prueban con ProviderContainer y overrides. El cliente LLM y el
  transcriptor siempre se sustituyen por dobles de prueba y ninguna prueba llama a la API real
  ni carga un modelo Whisper. BuildSrsExport se prueba como función pura con casos de cada
  combinación de procedencia. Widgets con flutter_test, flujos con integration_test. Cobertura
  mínima 80% en domain. Lint con flutter_lints y riverpod_lint. CI en GitHub Actions bloquea el
  merge si falla lint, código generado desactualizado, pruebas o cobertura.

## Prohibiciones

- Tecnología y arquitectura: backend propio, base de datos remota, servicio de sincronización,
  cuentas de usuario, roles o cualquier función multiusuario; React Native, Ionic, Capacitor,
  Cordova o WebView para pantallas de producto; BLoC, GetX, MobX, Redux y el paquete provider;
  API heredada de Riverpod (StateProvider, StateNotifierProvider, ChangeNotifierProvider,
  flutter_riverpod/legacy.dart); providers escritos a mano sin @riverpod; setState o
  StatefulWidget para estado de pantalla, salvo controladores de UI puros; banderas isLoading o
  hasError en lugar de AsyncValue o sealed; widgets que importen drift, dio o DTOs; archivos de
  domain que importen package:flutter; Firebase en cualquier variante; ORM distinto de drift;
  SQL crudo fuera de data; singletons globales mutables; dependencias sin null safety, sin
  mantenimiento en los últimos 12 meses o con licencia GPL/AGPL.
- Red, datos y privacidad: cualquier petición a un host distinto de api.deepseek.com, con una
  única excepción declarada, la descarga del modelo GGML desde el host de modelos configurado,
  iniciada manualmente por el usuario desde ajustes y ejecutada una sola vez por modelo; envío
  de audio, imágenes o archivos al LLM; envío de cualquier texto sin confirmación explícita del
  usuario en esa acción; uso de un build fechado del modelo en lugar de su alias; envío del
  parámetro user_id; SDK de analítica, publicidad, telemetría o rastreo; la API key en el
  repositorio, en un --dart-define versionado o embebida en el binario, ya que se captura en
  ajustes y se guarda en flutter_secure_storage respaldado por Keystore y Keychain.
- Iteración, procedencia y exportación: persistir salida del LLM como requisito sin
  confirmación explícita; persistir una recomendación de calidad, cobertura o conflicto sin
  parche aplicable; aceptar recomendaciones en lote sin revisión individual; que el LLM escriba
  directamente en la base de datos; calcular métricas del tablero con el LLM; que el motor de
  recomendaciones genere contenido con origen distinto de generado; cambiar la procedencia de
  un campo manualmente sin evidencia asociada; que cualquier generador de documentos consulte
  la procedencia por su cuenta en lugar de recibir la estructura ya repartida; bloquear la
  interfaz esperando al LLM o al transcriptor; eliminar versiones anteriores de un requisito,
  recomendaciones descartadas, requisitos o evidencia, ya que todo borrado es lógico con
  bitácora local.

## Governance

- Supremacía: esta constitución prevalece sobre cualquier otra práctica, guía o convención del
  proyecto. Toda especificación, plan, tarea e implementación DEBE verificarse contra ella; un
  conflicto se resuelve a favor de la constitución o mediante una enmienda formal.
- Enmiendas: toda modificación se realiza mediante `/speckit-constitution`, DEBE documentarse en
  el Sync Impact Report al inicio de este archivo y actualizar la línea de versión. No se
  permiten ediciones informales del texto.
- Versionado semántico: MAJOR para eliminaciones o redefiniciones incompatibles de principios o
  prohibiciones; MINOR para principios o secciones nuevas o ampliaciones materiales; PATCH para
  aclaraciones y correcciones de redacción sin cambio semántico.
- Revisión de cumplimiento: cada revisión de código y cada puerta de CI descrita en la sección
  Calidad verifican el cumplimiento de los principios y prohibiciones aquí definidos. Cualquier
  desviación DEBE justificarse por escrito o corregirse antes del merge.

**Version**: 1.0.0 | **Ratified**: 2026-08-10 | **Last Amended**: 2026-08-10
