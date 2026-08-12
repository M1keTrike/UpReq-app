# Feature Specification: Captura y transcripción de entrevistas

**Feature Branch**: `002-captura-transcripcion`

**Created**: 2026-08-11

**Status**: Draft

**Input**: User description: "Sí, adelante con el incremento 2"

## Clarifications

### Session 2026-08-11

- Q: El etiquetado en vivo necesita un conjunto fijo de tipos de marca, porque estas marcas
  definirán las ventanas de filtrado del incremento 3. ¿Qué tipos debería ofrecer la app? →
  A: Tres tipos: posible requisito, duda y cita textual.
- Q: Si la app se cierra a mitad de una grabación y el analista la reabre, ¿qué acción debe
  ofrecerle para resolver la grabación interrumpida? → A: Ambas opciones a elección:
  reanudar agregando al mismo audio, o cerrar conservando solo lo capturado hasta la
  interrupción.
- Q: Si el analista cierra una grabación interrumpida en vez de reanudarla pero la
  entrevista sigue en curso, ¿puede iniciar una grabación nueva para esa misma sesión? → A:
  Sí, como una grabación nueva independiente: la sesión pasa a tener varias grabaciones,
  cada una con sus propios segmentos de transcripción.
- Q: ¿Puede el analista editar o quitar una marca en vivo colocada por error? → A: Sí, puede
  editar el tipo o eliminarla lógicamente en cualquier momento después de colocarla, igual
  que el resto de las entidades del proyecto.
- Q: Si llega una llamada telefónica u otra interrupción del sistema operativo mientras la
  grabación está activa, sin que la app se cierre del todo, ¿qué debe hacer la aplicación? →
  A: Tratarla igual que un cierre inesperado: la grabación se pausa automáticamente y queda
  marcada como interrumpida, y el analista decide después si reanuda o cierra la toma.

Segundo incremento de la aplicación: grabación de entrevistas en el dispositivo, etiquetado
en vivo, transcripción local en dos pasadas y reproducción anclada a segmentos. Este
incremento NO incluye ninguna llamada al LLM: la transcripción se guarda pero nadie la
procesa todavía. Se apoya en la estructura de proyectos, interesados y sesiones construida
en el incremento 1.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Grabar una entrevista durante la sesión (Priority: P1)

Dentro de una sesión de elicitación en curso, el analista inicia la grabación de audio de
la entrevista. Mientras graba, la aplicación confirma visualmente que está grabando y
muestra el tiempo transcurrido. Al terminar la entrevista, el analista detiene la
grabación y el audio queda asociado a la sesión, listo para reproducirse. El audio nunca
sale del dispositivo.

**Why this priority**: Sin audio grabado no hay nada que etiquetar, transcribir ni
reproducir. Es la base de todo el incremento y ya aporta valor por sí sola como archivo de
la entrevista.

**Independent Test**: Con una sesión ya en curso, se prueba iniciando la grabación,
hablando unos segundos, deteniéndola, y verificando que el audio capturado queda asociado
a la sesión y puede reproducirse.

**Acceptance Scenarios**:

1. **Given** una sesión en curso sin grabación activa, **When** el analista inicia grabar,
   **Then** la aplicación confirma visualmente que está grabando y muestra el tiempo
   transcurrido.
2. **Given** una grabación en curso, **When** el analista la detiene, **Then** el audio
   capturado queda guardado y asociado a la sesión, disponible para reproducirse.
3. **Given** una sesión planeada que aún no pasó a en curso, **When** el analista abre su
   detalle, **Then** la opción de grabar no está disponible hasta que la sesión pase a en
   curso.
4. **Given** una sesión cerrada o un proyecto cerrado, **When** el analista abre su detalle,
   **Then** no se ofrece iniciar una grabación nueva.
5. **Given** el dispositivo sin permiso de micrófono concedido, **When** el analista intenta
   grabar, **Then** la aplicación señala el error de forma explícita y no inicia la
   grabación.

---

### User Story 2 - Etiquetar momentos relevantes en vivo (Priority: P2)

Mientras graba, el analista toca marcadores rápidos para señalar momentos relevantes de la
entrevista sin interrumpir la conversación. Cada marca guarda su tipo y el instante exacto
de la grabación en que se tocó. Si una marca quedó mal puesta, el analista puede corregir su
tipo o eliminarla lógicamente después, sin necesidad de que la grabación siga activa.

**Why this priority**: Mejora sustancialmente el valor de la grabación al guiar la revisión
posterior y el futuro filtrado de contenido, pero la grabación ya es útil sin esto.

**Independent Test**: Durante una grabación activa, se prueba tocando marcadores de
distinto tipo en distintos instantes, deteniendo la grabación, y verificando que cada marca
quedó con su tipo y su marca de tiempo correcta.

**Acceptance Scenarios**:

1. **Given** una grabación activa, **When** el analista toca un marcador, **Then** la marca
   se guarda con su tipo y el instante exacto de la grabación, sin detener ni interrumpir la
   captura de audio.
2. **Given** varias marcas colocadas durante una misma grabación, **When** el analista
   revisa la sesión, **Then** ve la lista de marcas ordenada por instante, cada una con su
   tipo.
3. **Given** una grabación detenida, **When** el analista intenta colocar una marca, **Then**
   la aplicación no lo permite: las marcas solo se colocan durante la captura activa.
4. **Given** una marca ya colocada, **When** el analista corrige su tipo o la elimina,
   **Then** el cambio persiste sin exigir que la grabación siga activa, y una marca
   eliminada deja de listarse conservando su registro.

---

### User Story 3 - Recuperar una grabación interrumpida (Priority: P3)

Si la aplicación se cierra de forma inesperada (batería agotada, error del sistema) a mitad
de una grabación, al reabrirla el analista no pierde el audio capturado hasta ese momento y
puede decidir cómo continuar. El mismo tratamiento aplica cuando el sistema operativo le
quita el micrófono a la aplicación sin cerrarla del todo, por ejemplo una llamada
telefónica entrante: la grabación se pausa automáticamente y queda marcada como
interrumpida, para que el analista decida después cómo continuar.

**Why this priority**: Protege el trabajo de campo, que es irrepetible — una entrevista no
se puede regrabar. Es crítico, pero depende de que la grabación básica (historia 1) ya
exista.

**Independent Test**: Se prueba por las dos causas de interrupción. Primero, iniciando una
grabación, forzando el cierre de la aplicación a mitad de la captura, reabriéndola y
verificando que el audio capturado hasta la interrupción se conservó y que la aplicación
ofrece cómo proceder. Después, repitiendo con una llamada entrante en lugar del cierre
forzado.

**Acceptance Scenarios**:

1. **Given** una grabación interrumpida por un cierre inesperado de la aplicación, **When**
   el analista la reabre, **Then** el audio capturado hasta el instante de la interrupción
   está intacto y accesible.
2. **Given** una grabación activa, **When** el sistema operativo le quita el micrófono a
   la aplicación sin cerrarla (por ejemplo, una llamada entrante), **Then** la grabación se
   pausa automáticamente, queda marcada como interrumpida y el audio capturado hasta ese
   momento se conserva íntegro.
3. **Given** una sesión con una grabación interrumpida, **When** el analista reabre la
   aplicación, **Then** la sesión señala explícitamente que su grabación quedó interrumpida
   y ofrece las dos acciones para resolverlo: reanudar agregando al mismo audio, o cerrar
   conservando solo lo capturado.
4. **Given** una grabación interrumpida que el analista cierra sin reanudarla, **When** la
   entrevista continúa, **Then** puede iniciar una grabación nueva para la misma sesión, y
   ambas grabaciones quedan listadas por separado con sus propios segmentos de
   transcripción.

---

### User Story 4 - Transcribir automáticamente la entrevista (Priority: P4)

La aplicación transcribe el audio en el dispositivo, sin conexión, en dos pasadas: una
orientativa que corre durante la sesión y ayuda al etiquetado en vivo, y otra definitiva y
más precisa que corre al cerrar la sesión. Ambas pasadas usan el glosario del proyecto como
apoyo para reconocer mejor los términos propios del dominio. El resultado de la pasada
definitiva queda organizado en segmentos, cada uno con su instante de inicio y de fin.

**Why this priority**: Es el propósito central del incremento, pero depende de que ya
exista audio grabado (historia 1) y de que el modelo de transcripción esté preparado
(historia 6).

**Independent Test**: Con una sesión que tiene audio grabado y el modelo de transcripción
ya descargado, se prueba cerrando la sesión y verificando que, al terminar el proceso, la
sesión cuenta con una transcripción organizada en segmentos con inicio y fin.

**Acceptance Scenarios**:

1. **Given** una sesión con audio grabado y el modelo de transcripción disponible, **When**
   la grabación está activa, **Then** la aplicación produce en segundo plano un avance de
   transcripción que no bloquea la interfaz ni interrumpe la grabación.
2. **Given** una sesión con audio grabado, **When** el analista la cierra, **Then** la
   aplicación ejecuta la pasada definitiva de transcripción y produce segmentos con inicio y
   fin que cubren el audio capturado.
3. **Given** un proyecto con términos de glosario definidos, **When** se transcribe una
   sesión de ese proyecto, **Then** el glosario se usa como apoyo para reconocer esos
   términos.
4. **Given** una sesión cerrada cuya transcripción definitiva todavía se está procesando,
   **When** el analista consulta la sesión, **Then** ve que la transcripción está en
   proceso, sin que la interfaz quede bloqueada esperándola.
5. **Given** el modelo de transcripción no descargado todavía, **When** se cierra una
   sesión con audio grabado, **Then** la transcripción queda pendiente hasta que el modelo
   esté disponible, sin perder el audio capturado.

---

### User Story 5 - Revisar la transcripción escuchando el segmento exacto (Priority: P5)

El analista lee el texto transcrito de la sesión y, al tocar un segmento, la reproducción
del audio salta directo a ese instante para confirmar que el texto es correcto.

**Why this priority**: Da confianza en la transcripción y prepara el terreno para que el
incremento 3 ancle evidencia a segmentos concretos, pero requiere que ya exista una
transcripción (historia 4).

**Independent Test**: Con una sesión ya transcrita, se prueba tocando distintos segmentos
del texto y verificando que la reproducción salta al segundo correspondiente en cada caso.

**Acceptance Scenarios**:

1. **Given** una sesión con transcripción definitiva disponible, **When** el analista toca
   un segmento del texto, **Then** la reproducción de audio salta al segundo de inicio de
   ese segmento.
2. **Given** el reproductor abierto en un segmento, **When** el audio avanza más allá del
   fin de ese segmento, **Then** el segmento que se está reproduciendo se resalta como
   activo.

---

### User Story 6 - Preparar el modelo de transcripción desde ajustes (Priority: P6)

Antes de poder transcribir, el analista descarga manualmente desde ajustes el modelo de
transcripción necesario. La descarga se hace una sola vez por modelo y es la única
operación de este incremento que requiere conexión a internet.

**Why this priority**: Es un requisito técnico habilitante más que una acción del flujo de
campo. Se prioriza al final porque se hace una sola vez y no compite en frecuencia con el
resto del trabajo.

**Independent Test**: Desde ajustes, se prueba iniciando la descarga del modelo,
verificando el progreso, y confirmando que al finalizar queda disponible para transcribir
sin que ninguna otra pantalla de la aplicación haya requerido conexión.

**Acceptance Scenarios**:

1. **Given** el modelo de transcripción no descargado, **When** el analista lo inicia desde
   ajustes, **Then** ve el progreso de la descarga.
2. **Given** una descarga completada, **When** el analista cierra una sesión con audio
   grabado, **Then** la transcripción definitiva puede ejecutarse sin pedir conexión de
   nuevo.
3. **Given** una descarga interrumpida por pérdida de conexión, **When** el analista vuelve
   a intentarla, **Then** la aplicación la retoma o la reinicia sin dejar un modelo a medio
   instalar utilizable.

---

### Edge Cases

- ¿Qué pasa si el analista graba sin haber descargado antes el modelo de transcripción? La
  grabación no depende del modelo: se captura igual y la transcripción queda pendiente
  hasta que el modelo esté disponible.
- ¿Qué pasa si se agota el almacenamiento del dispositivo a mitad de una grabación? La
  grabación se detiene conservando el audio capturado hasta ese punto y la aplicación
  informa el motivo.
- ¿Qué pasa si el analista cierra la sesión sin haber detenido la grabación manualmente? El
  cierre de la sesión detiene la grabación automáticamente antes de fijar sus datos.
- ¿Qué pasa si dos marcas de etiquetado en vivo caen en el mismo instante? Ambas se
  conservan de forma independiente; no hay deduplicación por instante.
- ¿Qué pasa si el glosario del proyecto está vacío al transcribir? La transcripción corre
  igual, sin ese apoyo adicional.
- ¿Qué pasa si el analista intenta reproducir un segmento antes de que la pasada definitiva
  haya terminado? Solo se puede reproducir el audio en bruto hasta que existan segmentos
  definitivos.
- ¿Qué pasa si el dispositivo no tiene conexión al intentar descargar el modelo? La
  descarga no comienza y la aplicación lo indica; el resto de la aplicación sigue operando
  sin conexión con normalidad.
- ¿Qué pasa si llega una llamada telefónica mientras se graba? Se trata igual que un cierre
  inesperado de la aplicación: la grabación se pausa automáticamente, queda marcada como
  interrumpida y el audio capturado hasta ese momento no se pierde.

## Requirements *(mandatory)*

### Functional Requirements

#### Grabación

- **FR-001**: El sistema MUST permitir iniciar y detener la grabación de audio de una
  sesión que esté en curso.
- **FR-002**: Mientras graba, el sistema MUST confirmar visualmente que la captura está
  activa y mostrar el tiempo transcurrido.
- **FR-003**: El sistema MUST asociar el audio grabado a la sesión de la que proviene y
  MUST no permitir iniciar una grabación en una sesión planeada, cerrada, o de un proyecto
  cerrado.
- **FR-003a**: Una sesión MUST poder tener más de una grabación — por ejemplo, cuando una
  grabación interrumpida se cierra sin reanudarse y el analista debe capturar el resto de
  la entrevista en una toma nueva. El sistema MUST listar todas las grabaciones de una
  sesión en orden cronológico, cada una con su propia transcripción y sus propios
  segmentos.
- **FR-004**: El sistema MUST señalar de forma explícita cuando el permiso de micrófono no
  está concedido y MUST no iniciar una grabación sin él.
- **FR-005**: Cerrar una sesión con una grabación todavía activa MUST detener la grabación
  automáticamente antes de fijar los datos de cierre.
- **FR-006**: El audio grabado MUST permanecer siempre en el dispositivo; el sistema MUST
  no transmitirlo a ningún servicio externo en este incremento.

#### Etiquetado en vivo

- **FR-007**: El sistema MUST permitir colocar marcas durante una grabación activa, cada
  una con un tipo — posible requisito, duda o cita textual — y el instante exacto de la
  grabación en que se colocó.
- **FR-008**: El sistema MUST listar las marcas de una sesión ordenadas por instante, cada
  una con su tipo visible.
- **FR-009**: El sistema MUST impedir colocar marcas cuando la grabación no está activa.
- **FR-009a**: El sistema MUST permitir editar el tipo de una marca existente y eliminarla
  lógicamente en cualquier momento, sin exigir que la grabación siga activa, siguiendo el
  mismo tratamiento de baja lógica del resto de las entidades del proyecto.

#### Recuperación de grabaciones interrumpidas

- **FR-010**: Si la aplicación se cierra de forma inesperada durante una grabación activa,
  o si el sistema operativo le quita el micrófono sin cerrarla (por ejemplo, una llamada
  entrante), el sistema MUST pausar la grabación, marcarla como interrumpida y conservar
  íntegro el audio capturado hasta ese instante.
- **FR-011**: Al reabrir la aplicación después de una interrupción, el sistema MUST señalar
  explícitamente qué sesión quedó con una grabación interrumpida y MUST ofrecer dos
  acciones a elección del analista: reanudar la captura agregando al mismo audio, o cerrar
  la grabación conservando solo lo capturado hasta la interrupción.

#### Transcripción

- **FR-012**: El sistema MUST ejecutar en el dispositivo, sin conexión, una pasada de
  transcripción orientativa mientras la grabación está activa, sin bloquear la interfaz ni
  interrumpir la captura de audio.
- **FR-013**: El sistema MUST ejecutar en el dispositivo, sin conexión, una pasada de
  transcripción definitiva al cerrar la sesión, produciendo segmentos de texto ordenados y
  sin solapamiento, cada uno con su instante de inicio y de fin. Los tramos sin habla no
  producen segmento: la transcripción no cubre necesariamente todo el audio capturado.
- **FR-014**: Ambas pasadas de transcripción MUST usar el glosario del proyecto como apoyo
  para reconocer sus términos propios cuando el glosario tenga contenido.
- **FR-015**: Mientras la pasada definitiva se procesa, el sistema MUST mostrar que está en
  curso sin bloquear el resto de la interfaz.
- **FR-016**: Si el modelo de transcripción no está disponible al cerrar una sesión con
  audio grabado, el sistema MUST conservar el audio y dejar la transcripción pendiente
  hasta que el modelo esté disponible.

#### Reproducción

- **FR-017**: El sistema MUST permitir reproducir el audio de una sesión de forma
  independiente de que exista o no transcripción.
- **FR-018**: Al tocar un segmento de la transcripción definitiva, el sistema MUST saltar
  la reproducción al instante de inicio de ese segmento.
- **FR-019**: Durante la reproducción, el sistema MUST resaltar el segmento que corresponde
  al instante que se está reproduciendo.

#### Modelo de transcripción

- **FR-020**: El sistema MUST permitir descargar el modelo de transcripción manualmente
  desde ajustes, mostrando el progreso de la descarga.
- **FR-021**: La descarga del modelo MUST ser la única operación de este incremento que
  requiere conexión a internet; ninguna otra pantalla MUST depender de la red.
- **FR-022**: Una descarga interrumpida MUST poder reintentarse sin dejar un modelo a medio
  instalar disponible para transcribir.

#### Reglas de datos y comportamiento esperado

- **FR-023**: El audio, las marcas en vivo y los segmentos de transcripción MUST seguir el
  mismo tratamiento de baja lógica que el resto de las entidades del proyecto: ninguno se
  borra físicamente desde la interfaz de este incremento.
- **FR-024**: Salvo la descarga manual del modelo de transcripción, la aplicación MUST
  funcionar por completo sin conexión a internet.
- **FR-025**: Toda pantalla de este incremento MUST resolver de forma explícita sus
  situaciones de cargando, con datos, vacía y con error, consistente con el patrón
  establecido en el incremento 1.

### Key Entities

- **Grabación de audio**: Captura de audio de una sesión. Atributos: ruta del archivo,
  duración, estado (activa, detenida, interrumpida). Pertenece a una sesión; una sesión
  puede tener varias grabaciones cuando una interrupción se cierra sin reanudarse y el
  analista abre una toma nueva para continuar la misma entrevista.
- **Marca en vivo**: Señal que el analista coloca durante una grabación activa. Atributos:
  tipo, instante dentro de la grabación. Pertenece a una grabación.
- **Segmento de transcripción**: Fragmento de texto transcrito con su instante de inicio y
  de fin. Es la unidad de evidencia que incrementos futuros usarán para anclar requisitos a
  su origen. Pertenece a una grabación.
- **Modelo de transcripción**: Recurso descargable necesario para transcribir. Atributos:
  identificador del modelo, estado de descarga (no descargado, descargando, disponible).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un analista puede grabar una entrevista completa, colocar al menos tres
  marcas en vivo de distinto tipo, cerrar la sesión y obtener su transcripción definitiva
  organizada en segmentos, completando el flujo de punta a punta sin conexión a internet
  salvo la descarga previa del modelo.
- **SC-002**: Al forzar el cierre de la aplicación a mitad de una grabación, el 100% del
  audio capturado hasta ese instante se conserva al reabrirla.
- **SC-003**: Tocar cualquier segmento de una transcripción hace que la reproducción salte
  de inmediato al instante correspondiente, sin necesidad de buscar manualmente en el
  audio.
- **SC-004**: La descarga del modelo de transcripción es la única operación de red que
  ejecuta la aplicación en este incremento; el resto de las pantallas opera igual con el
  dispositivo en modo avión.
- **SC-005**: La aplicación graba y transcribe una entrevista real en un dispositivo Android
  físico, con la pasada definitiva completándose sin bloquear la interfaz.

## Assumptions

- Cada grabación es una toma continua: no existe una acción de pausa manual independiente de
  la detención dentro de una misma toma; la única forma de retomar audio ya iniciado dentro
  de la misma toma es el flujo de recuperación de una grabación interrumpida por cierre
  inesperado (historia 3). Cuando el analista cierra una grabación interrumpida sin
  reanudarla, iniciar una toma nueva para la misma sesión es una grabación independiente, no
  una continuación de la anterior.
- La grabación solo está disponible mientras la sesión está en curso, reutilizando el estado
  de sesión ya definido en el incremento 1 (planeada → en curso → cerrada); no se agrega una
  transición automática que mueva la sesión a en curso al iniciar a grabar.
- El modelo usado en la pasada en vivo y el usado en la pasada definitiva son distintos entre
  sí, priorizando velocidad en la primera y precisión en la segunda; sus valores concretos
  son parámetros técnicos que se fijan y calibran en la planificación de este incremento, no
  en esta especificación.
- El avance de transcripción en vivo se usa como apoyo interno del etiquetado y no necesita
  mostrarse como texto corrido en pantalla durante la grabación; la lectura completa del
  texto transcrito ocurre en la revisión posterior (historia 5), sobre el resultado de la
  pasada definitiva.
- El umbral para descartar silencio y otros parámetros finos de captura y transcripción se
  calibran contra audio real durante este mismo incremento, conforme a lo declarado en el
  roadmap del proyecto, y no bloquean esta especificación.
- Los datos de esta funcionalidad heredan el aislamiento por proyecto y por sesión ya
  establecido en el incremento 1: nada de lo grabado o transcrito en una sesión es visible
  desde otra.
- Quedan explícitamente fuera de este incremento: cualquier llamada al LLM, extracción de
  requisitos, métricas y exportación.
