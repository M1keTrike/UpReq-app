# Feature Specification: Gestión de proyectos, interesados y sesiones de elicitación

**Feature Branch**: `001-proyectos-interesados-sesiones`

**Created**: 2026-08-10

**Status**: Draft

**Input**: User description: "Redacta la especificación del primer incremento tomando íntegramente el contenido de spec-01-input.md en la raíz del repositorio. Respeta el alcance declarado sin ampliarlo: no incluyas audio, transcripción, LLM, recomendaciones, tablero ni exportación."

Primer incremento de la aplicación: gestión de proyectos, interesados y sesiones de
elicitación. Este incremento NO incluye grabación de audio, transcripción, LLM,
recomendaciones, tablero ni exportación. Establece la estructura navegable y la base de
datos sobre la que se apoyarán los incrementos siguientes.

## Clarifications

### Session 2026-08-10

- Q: ¿Qué se puede hacer con un proyecto cerrado al consultarlo desde el filtro de cerrados? → A: Solo lectura mientras esté cerrado, con acción explícita de reabrir que lo devuelve a activos (asentada en bitácora)
- Q: ¿Cómo puede el usuario quitar de la vista una sesión de elicitación o un término del glosario que ya no quiere? → A: Baja lógica uniforme, igual que los puntos de guion (dejan de listarse, el registro se conserva y queda en bitácora), sin filtro para consultar los eliminados
- Q: Una vez que el usuario marca una sesión como cerrada, ¿qué sigue pudiendo cambiar en ella? → A: Avance ordenado planeada → en curso → cerrada sin retroceso; tras cerrar, el guion se sigue editando y marcando, pero los datos de cabecera (título, fecha, técnica, lugar, participantes) quedan fijos
- Q: ¿El usuario necesita poder ver la bitácora de bajas lógicas dentro de la aplicación, o basta con que quede registrada? → A: Visible por proyecto: pantalla de solo lectura dentro del detalle del proyecto, con fecha, operación y entidad afectada
- Q: ¿En qué plataformas debe quedar verificado este primer incremento antes de darlo por terminado? → A: Código compatible con ambas plataformas y sin dependencias exclusivas de Android, pero la verificación en dispositivo físico exigida en este incremento es solo Android

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Administrar proyectos (Priority: P1)

Un usuario único, sin login ni cuentas, administra varios proyectos de levantamiento de
requerimientos. Cada proyecto tiene nombre, cliente, descripción breve, fecha de creación y
estado (activo o cerrado). La pantalla inicial lista los proyectos activos, permite crear
uno nuevo, abrirlo, editarlo y cerrarlo lógicamente. Los proyectos cerrados pueden
consultarse desde el filtro de cerrados en modo solo lectura, y pueden reabrirse mediante
una acción explícita que los devuelve a la lista de activos y restituye la edición.

**Why this priority**: El proyecto es la raíz de todo el modelo: sin proyectos no existen
interesados, sesiones ni glosario. Es la porción mínima que ya entrega valor (organizar el
trabajo de campo por cliente) y la base navegable del resto del incremento.

**Independent Test**: Se prueba de forma aislada creando un proyecto desde la pantalla
inicial, editándolo, cerrándolo y verificando que desaparece de la lista de activos y
aparece bajo el filtro de cerrados con sus datos intactos, y reabriéndolo para comprobar
que vuelve a ser editable.

**Acceptance Scenarios**:

1. **Given** la aplicación recién instalada sin datos, **When** el usuario abre la pantalla
   inicial, **Then** ve el estado vacío que lo invita a crear el primer proyecto en lugar
   de un mensaje de ausencia.
2. **Given** la pantalla inicial, **When** el usuario crea un proyecto con nombre, cliente
   y descripción breve, **Then** el proyecto aparece en la lista de activos con su fecha de
   creación y estado activo.
3. **Given** un proyecto existente, **When** el usuario edita sus datos y guarda, **Then**
   los cambios persisten y se actualiza la fecha de última modificación.
4. **Given** un proyecto activo, **When** el usuario lo cierra, **Then** el proyecto se
   retira de la lista de activos sin eliminar sus datos, la operación queda asentada en la
   bitácora local y el proyecto puede consultarse desde el filtro de cerrados.
5. **Given** un proyecto cerrado abierto desde el filtro de cerrados, **When** el usuario
   consulta su detalle, interesados, sesiones, guiones o glosario, **Then** todo se muestra
   en solo lectura y ninguna acción de escritura está disponible.
6. **Given** un proyecto cerrado, **When** el usuario ejecuta la acción explícita de
   reabrir, **Then** el proyecto vuelve a la lista de activos, recupera la edición y la
   reapertura queda asentada en la bitácora local.
7. **Given** un formulario de proyecto con datos inválidos, **When** el usuario intenta
   guardar, **Then** la validación impide el guardado, señala el error y conserva lo
   escrito.
8. **Given** un proyecto con interesados, sesiones y términos de glosario registrados,
   **When** el usuario consulta el proyecto, **Then** ve el contador de cada uno de esos
   elementos asociados y el contador refleja las altas y bajas lógicas realizadas.

---

### User Story 2 - Registrar interesados del proyecto (Priority: P2)

Dentro de un proyecto, el usuario registra a los interesados de la organización. Cada
interesado tiene nombre, rol en la organización, área, nivel de influencia (alto, medio,
bajo), notas libres y estado activo o inactivo. Se listan, crean, editan y desactivan. Un
interesado pertenece a un solo proyecto.

**Why this priority**: Los interesados son el insumo directo de las sesiones (una sesión
referencia participantes) y el primer contenido real que el analista captura en campo tras
crear el proyecto.

**Independent Test**: Con un proyecto ya creado, se prueba agregando varios interesados,
editando uno, desactivando otro y verificando que la lista refleja los estados y que el
interesado desactivado conserva su registro.

**Acceptance Scenarios**:

1. **Given** un proyecto sin interesados, **When** el usuario abre la lista de interesados,
   **Then** ve el estado vacío que lo invita a crear el primero.
2. **Given** un proyecto abierto, **When** el usuario crea un interesado con nombre, rol,
   área y nivel de influencia, **Then** el interesado aparece en la lista del proyecto con
   estado activo.
3. **Given** un interesado existente, **When** el usuario lo desactiva, **Then** el
   registro se conserva con estado inactivo y la operación queda asentada en la bitácora
   local.
4. **Given** dos proyectos con interesados propios, **When** el usuario consulta los
   interesados de uno, **Then** solo ve los interesados de ese proyecto, nunca los del
   otro.

---

### User Story 3 - Planificar sesiones de elicitación con participantes (Priority: P3)

Dentro de un proyecto, el usuario registra sesiones de elicitación. Cada sesión tiene
título, fecha y hora, técnica empleada (entrevista abierta, entrevista estructurada,
taller, observación, revisión documental), lugar, estado (planeada, en curso, cerrada) y
notas libres. Una sesión referencia a uno o más interesados participantes del mismo
proyecto. El estado avanza en un solo sentido, de planeada a en curso y de ahí a cerrada;
cerrar una sesión fija sus datos de cabecera y deja el guion abierto a seguir trabajándose.

**Why this priority**: La sesión es la unidad de trabajo de campo y el contenedor del guion
(historia 4). Requiere que existan proyecto e interesados, por eso va después.

**Independent Test**: Con un proyecto y al menos dos interesados creados, se prueba creando
una sesión que referencie a ambos, cambiando su estado de planeada a en curso y a cerrada,
y verificando que los participantes listados pertenecen al proyecto.

**Acceptance Scenarios**:

1. **Given** un proyecto con interesados registrados, **When** el usuario crea una sesión
   con título, fecha y hora, técnica, lugar y al menos un participante, **Then** la sesión
   aparece en la lista de sesiones del proyecto en estado planeada.
2. **Given** el formulario de sesión, **When** el usuario elige participantes, **Then**
   solo puede seleccionar interesados del mismo proyecto.
3. **Given** una sesión planeada, **When** el usuario cambia su estado a en curso y luego a
   cerrada, **Then** cada cambio persiste y actualiza la fecha de última modificación.
4. **Given** una sesión en curso o cerrada, **When** el usuario intenta devolverla a un
   estado anterior, **Then** la aplicación no ofrece esa transición.
5. **Given** una sesión cerrada, **When** el usuario abre su detalle, **Then** título,
   fecha y hora, técnica, lugar y participantes se muestran fijos y no editables, mientras
   que las notas libres y el guion siguen siendo editables.
6. **Given** una sesión sin participantes seleccionados, **When** el usuario intenta
   guardarla, **Then** la validación impide el guardado, señala que debe referenciar al
   menos un interesado y conserva lo escrito.
7. **Given** una sesión existente, **When** el usuario la elimina, **Then** la eliminación
   es lógica: la sesión deja de listarse, su registro y el de su guion se conservan y la
   operación queda asentada en la bitácora local.

---

### User Story 4 - Armar y trabajar el guion de la sesión (Priority: P4)

Cada sesión tiene un guion: una lista ordenada de puntos a tratar, cada uno con texto,
estado (pendiente, cubierto, omitido) y posición. Los puntos se agregan, editan, reordenan
y marcan durante o después de la sesión. El guion es la estructura que en incrementos
posteriores recibirá automáticamente los campos generados pendientes de validar.

**Why this priority**: El guion da el valor operativo durante la entrevista (qué tratar y
qué quedó cubierto) y es la pieza que los incrementos futuros alimentarán; depende de que
exista la sesión.

**Independent Test**: Con una sesión creada, se prueba agregando cinco puntos, reordenando
dos de ellos, marcando dos como cubiertos y uno como omitido, y verificando que el orden y
los estados persisten.

**Acceptance Scenarios**:

1. **Given** una sesión sin puntos de guion, **When** el usuario abre el guion, **Then** ve
   el estado vacío que lo invita a agregar el primer punto.
2. **Given** un guion con varios puntos, **When** el usuario reordena un punto, **Then** la
   nueva posición persiste y el resto de los puntos conserva un orden coherente.
3. **Given** un punto pendiente, **When** el usuario lo marca como cubierto u omitido
   durante o después de la sesión, **Then** el estado persiste.
4. **Given** un punto del guion, **When** el usuario lo elimina, **Then** la eliminación es
   lógica: el registro se conserva, deja de mostrarse en el guion y la operación queda
   asentada en la bitácora local.
5. **Given** una sesión con puntos de guion en distintos estados, **When** el usuario
   consulta la sesión, **Then** ve el contador de sus puntos por estado (pendiente,
   cubierto, omitido) y el contador se actualiza al marcar o eliminar puntos.

---

### User Story 5 - Mantener el glosario del proyecto (Priority: P5)

Cada proyecto tiene un glosario de términos del dominio: término, definición y notas. Se
lista alfabéticamente y se edita libremente. En incrementos posteriores este glosario
alimentará el initialPrompt del transcriptor.

**Why this priority**: Aporta valor de documentación desde el primer incremento, pero
ninguna otra pieza de este incremento depende de él.

**Independent Test**: Con un proyecto creado, se prueba agregando varios términos en orden
no alfabético y verificando que la lista los muestra alfabéticamente y que la edición libre
persiste.

**Acceptance Scenarios**:

1. **Given** un proyecto sin términos, **When** el usuario abre el glosario, **Then** ve el
   estado vacío que lo invita a agregar el primer término.
2. **Given** términos capturados en cualquier orden, **When** el usuario consulta el
   glosario, **Then** la lista se muestra ordenada alfabéticamente por término.
3. **Given** un término existente, **When** el usuario edita su definición o sus notas,
   **Then** los cambios persisten y se actualiza la fecha de última modificación.
4. **Given** un término existente, **When** el usuario lo elimina, **Then** la eliminación
   es lógica: el término deja de listarse, su registro se conserva y la operación queda
   asentada en la bitácora local.

---

### User Story 6 - Consultar la bitácora del proyecto (Priority: P6)

Dentro de un proyecto, el usuario consulta una pantalla de bitácora en solo lectura que
lista las operaciones lógicas ocurridas en ese proyecto: cierre y reapertura del propio
proyecto, desactivación de interesados y eliminación de sesiones, puntos de guion y
términos del glosario. Cada asiento muestra fecha, operación y entidad afectada.

**Why this priority**: Da transparencia sobre qué se retiró de la vista y cuándo, pero
ninguna otra pieza del incremento depende de ella y su valor aparece solo una vez que
existen bajas registradas.

**Independent Test**: Con un proyecto que ya tuvo un interesado desactivado y un punto de
guion eliminado, se abre la bitácora y se verifica que ambos asientos aparecen con su fecha
y operación, y que la pantalla no ofrece ninguna acción de escritura.

**Acceptance Scenarios**:

1. **Given** un proyecto sin operaciones lógicas registradas, **When** el usuario abre la
   bitácora, **Then** ve un estado vacío que explica que aún no hay operaciones asentadas.
2. **Given** un proyecto con varias operaciones lógicas registradas, **When** el usuario
   abre la bitácora, **Then** ve cada asiento con fecha, operación y entidad afectada,
   ordenados del más reciente al más antiguo.
3. **Given** la pantalla de bitácora, **When** el usuario la recorre, **Then** no encuentra
   ninguna acción que modifique o elimine asientos.

---

### Edge Cases

- ¿Qué pasa cuando el usuario cierra un proyecto que tiene sesiones en estado planeada o en
  curso? El cierre es lógico y no altera las sesiones; todo queda consultable en solo
  lectura desde el filtro de cerrados hasta que el proyecto se reabra.
- ¿Qué pasa cuando el usuario desactiva un interesado que participa en sesiones existentes?
  La participación histórica se conserva; el interesado inactivo no se ofrece para nuevas
  sesiones.
- ¿Qué pasa si el usuario detecta un error en el título o la fecha de una sesión que ya
  cerró? La cabecera está fija: la corrección exige registrar una sesión nueva y eliminar
  lógicamente la equivocada.
- ¿Qué pasa cuando el usuario elimina una sesión que ya tiene puntos de guion? La
  eliminación es lógica y arrastra al guion fuera de la vista, sin destruir ningún
  registro.
- ¿Qué pasa si la validación de un formulario falla a mitad de la captura? El formulario
  señala el error y conserva todo lo escrito, sin descartar la captura.
- ¿Qué pasa al reordenar puntos del guion de forma repetida o hacia posiciones extremas
  (primero/último)? Las posiciones resultantes se mantienen coherentes y sin duplicados.
- ¿Qué pasa cuando la aplicación se cierra de forma inesperada? Al reabrirla, toda la
  información guardada persiste.
- ¿Qué pasa si el dispositivo no tiene conexión a internet? Nada cambia: este incremento no
  realiza ninguna petición de red y toda la funcionalidad opera igual.
- ¿Qué pasa cuando una pantalla no puede cargar sus datos? Muestra su situación de error de
  forma explícita, distinta de la situación vacía.

## Requirements *(mandatory)*

### Functional Requirements

#### Proyectos

- **FR-001**: El sistema MUST permitir a un usuario único, sin login ni cuentas,
  administrar varios proyectos.
- **FR-002**: Cada proyecto MUST almacenar nombre, cliente, descripción breve, fecha de
  creación y estado (activo o cerrado).
- **FR-003**: La pantalla inicial MUST listar los proyectos activos y permitir crear uno
  nuevo, abrirlo, editarlo y cerrarlo lógicamente.
- **FR-004**: Cerrar un proyecto MUST retirarlo de la lista de activos sin eliminar sus
  datos, y el proyecto MUST poder consultarse desde el filtro de cerrados.
- **FR-004a**: Mientras un proyecto esté cerrado, el sistema MUST impedir toda escritura
  sobre él y sobre sus interesados, sesiones, guiones y glosario: se consulta en modo solo
  lectura.
- **FR-004b**: El sistema MUST ofrecer una acción explícita de reapertura que devuelve el
  proyecto al estado activo y restituye la edición; la reapertura MUST quedar asentada en
  la bitácora local con fecha y operación.

#### Interesados

- **FR-005**: El sistema MUST permitir registrar interesados dentro de un proyecto, con
  nombre, rol en la organización, área, nivel de influencia (alto, medio, bajo), notas
  libres y estado activo o inactivo.
- **FR-006**: El sistema MUST permitir listar, crear, editar y desactivar interesados.
- **FR-007**: Un interesado MUST pertenecer a un solo proyecto.

#### Sesiones de elicitación

- **FR-008**: El sistema MUST permitir registrar sesiones de elicitación dentro de un
  proyecto, con título, fecha y hora, técnica empleada (entrevista abierta, entrevista
  estructurada, taller, observación, revisión documental), lugar, estado (planeada, en
  curso, cerrada) y notas libres.
- **FR-008a**: El estado de una sesión MUST avanzar únicamente en el orden planeada → en
  curso → cerrada, sin retroceso ni reapertura.
- **FR-008b**: Cerrar una sesión MUST fijar sus datos de cabecera (título, fecha y hora,
  técnica, lugar y participantes) e impedir su edición posterior. Las notas libres y el
  guion MUST seguir siendo editables después del cierre.
- **FR-009**: Una sesión MUST referenciar a uno o más interesados participantes del mismo
  proyecto; no se admite guardar una sesión sin participantes ni con participantes de otro
  proyecto.

#### Guion de sesión

- **FR-010**: Cada sesión MUST tener un guion: una lista ordenada de puntos a tratar, cada
  uno con texto, estado (pendiente, cubierto, omitido) y posición.
- **FR-011**: El sistema MUST permitir agregar, editar, reordenar y marcar los puntos del
  guion durante o después de la sesión, incluso cuando la sesión ya esté cerrada, siempre
  que el proyecto siga activo.

#### Glosario

- **FR-012**: Cada proyecto MUST tener un glosario de términos del dominio con término,
  definición y notas, listado alfabéticamente y editable libremente.

#### Contadores

- **FR-013**: Cada proyecto MUST mostrar un contador de sus elementos asociados y cada
  sesión MUST mostrar un contador de los suyos, para dar sensación de avance sin necesitar
  aún el tablero de métricas.

#### Reglas de datos

- **FR-014**: Ninguna entidad MUST borrarse físicamente. Cerrar un proyecto, desactivar un
  interesado o eliminar un punto del guion MUST ser operaciones lógicas que conservan el
  registro.
- **FR-014a**: El sistema MUST permitir eliminar lógicamente una sesión de elicitación y un
  término del glosario, con el mismo tratamiento que un punto del guion: dejan de listarse,
  el registro se conserva y la operación queda asentada en la bitácora local. La consulta
  de sesiones y términos ya eliminados queda fuera del alcance de este incremento.
- **FR-015**: Toda operación lógica de cierre, desactivación o eliminación MUST quedar
  asentada en una bitácora local con fecha y operación.
- **FR-015a**: Cada proyecto MUST ofrecer, dentro de su detalle, una pantalla de bitácora
  en solo lectura que liste los asientos de ese proyecto con fecha, operación y entidad
  afectada, ordenados del más reciente al más antiguo. La pantalla MUST no ofrecer ninguna
  acción que modifique o elimine asientos.
- **FR-016**: Todas las entidades MUST llevar identificador propio, fecha de creación y
  fecha de última modificación.
- **FR-017**: La base de datos MUST arrancar en la versión 1 del esquema, con la migración
  inicial declarada explícitamente aunque no haya migraciones previas.
- **FR-018**: Los datos de un proyecto MUST no mezclarse nunca con los de otro: toda
  consulta MUST filtrarse por proyecto.

#### Comportamiento esperado

- **FR-019**: La aplicación MUST funcionar por completo sin conexión a internet; este
  incremento MUST no realizar ninguna petición de red.
- **FR-020**: Toda pantalla MUST resolver de forma explícita sus cuatro situaciones:
  cargando, con datos, vacía y con error. La pantalla vacía MUST invitar a crear el primer
  elemento en lugar de mostrar un mensaje de ausencia. La única excepción es la bitácora,
  que por ser de solo lectura MUST explicar en su estado vacío que aún no hay operaciones
  asentadas.
- **FR-021**: La navegación MUST ser jerárquica: lista de proyectos, detalle de proyecto
  con acceso a interesados, sesiones, glosario y bitácora, y detalle de sesión con su
  guion.
- **FR-022**: Los formularios MUST validar antes de guardar y MUST conservar lo escrito si
  la validación falla.
- **FR-023**: El incremento MUST construirse sin capacidades ni dependencias exclusivas de
  una sola plataforma, de modo que siga siendo compatible con el objetivo de producto
  Android 10+ e iOS 16+. La verificación en dispositivo físico exigida por este incremento
  MUST ser únicamente Android.

### Key Entities

- **Proyecto**: Unidad raíz de trabajo. Atributos: nombre, cliente, descripción breve,
  fecha de creación, estado (activo o cerrado), más identificador, fecha de creación y
  fecha de última modificación comunes a toda entidad. Contiene interesados, sesiones,
  glosario y bitácora.
- **Interesado**: Persona de la organización relevante para el levantamiento. Atributos:
  nombre, rol en la organización, área, nivel de influencia (alto, medio, bajo), notas
  libres, estado (activo o inactivo). Pertenece a un solo proyecto.
- **Sesión de elicitación**: Encuentro de levantamiento. Atributos: título, fecha y hora,
  técnica empleada (entrevista abierta, entrevista estructurada, taller, observación,
  revisión documental), lugar, estado (planeada, en curso, cerrada), notas libres.
  Pertenece a un proyecto y referencia a uno o más interesados participantes del mismo
  proyecto. Su estado avanza en un solo sentido y el cierre fija los datos de cabecera.
- **Punto de guion**: Elemento de la lista ordenada de puntos a tratar de una sesión.
  Atributos: texto, estado (pendiente, cubierto, omitido), posición. Pertenece a una
  sesión.
- **Término de glosario**: Entrada del glosario de dominio de un proyecto. Atributos:
  término, definición, notas. Pertenece a un proyecto.
- **Registro de bitácora**: Asiento local que documenta cada operación lógica de cierre,
  reapertura, desactivación o eliminación, con fecha, operación realizada y entidad
  afectada. Pertenece a un proyecto y se consulta en solo lectura desde su detalle.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El usuario puede crear un proyecto, agregarle tres interesados, crear una
  sesión que referencie a dos de ellos, armar un guion de cinco puntos, reordenarlos y
  marcar dos como cubiertos, completando el flujo de punta a punta sin errores.
- **SC-002**: Al cerrar y volver a abrir la aplicación, el 100% de la información capturada
  persiste sin pérdida.
- **SC-003**: Cerrar un proyecto lo retira de la lista de activos sin eliminar sus datos, y
  el proyecto puede consultarse desde el filtro de cerrados con toda su información.
- **SC-004**: La aplicación se instala y opera en un dispositivo Android físico sin
  conexión a internet, con toda la funcionalidad del incremento disponible. Esta es la
  única verificación en dispositivo físico exigida por el incremento; iOS queda cubierto
  por la compatibilidad del código, sin prueba en dispositivo.
- **SC-005**: En cada listado del incremento (proyectos, interesados, sesiones, guion,
  glosario), la primera visita sin datos muestra la invitación a crear el primer elemento,
  y el usuario logra crearlo desde esa misma pantalla en un solo flujo.
- **SC-006**: Ninguna operación de cierre, reapertura, desactivación o eliminación produce
  pérdida de registros: el 100% de esas operaciones queda asentado en la bitácora local y
  el usuario puede verificar cada una en la bitácora del proyecto correspondiente.

## Assumptions

- El nombre del proyecto, el nombre del interesado, el título de la sesión, el texto del
  punto de guion y el término del glosario son los campos mínimos obligatorios de cada
  formulario; el resto de los campos descriptivos (cliente, descripción, área, notas,
  lugar, definición) admiten quedar vacíos salvo donde el insumo indica lo contrario.
- Los interesados inactivos dejan de ofrecerse como participantes para sesiones nuevas,
  pero su participación en sesiones ya registradas se conserva.
- Los contadores de elementos asociados se interpretan así: el proyecto cuenta sus
  interesados, sesiones y términos de glosario; la sesión cuenta sus puntos de guion por
  estado. No constituyen tablero de métricas ni cálculo histórico alguno.
- La lista alfabética del glosario ordena por el campo término, sin distinción de
  mayúsculas ni acentos.
- La aplicación opera en un único dispositivo y no comparte datos con otros dispositivos;
  no hay sincronización de ningún tipo, conforme al alcance monousuario y sin servidor.
- El incremento no fija metas propias de rendimiento ni de volumen de datos: se asumen las
  expectativas habituales de una aplicación móvil local, con volúmenes acordes al trabajo
  de un solo analista (decenas de proyectos, cientos de sesiones y puntos de guion).
- Quedan explícitamente fuera de este incremento: grabación de audio, transcripción, LLM,
  recomendaciones, tablero de métricas y exportación de documentos.
