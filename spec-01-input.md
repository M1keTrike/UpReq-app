Primer incremento: gestión de proyectos, interesados y sesiones de elicitación. Este incremento NO incluye grabación de audio, transcripción, LLM, recomendaciones, tablero ni exportación. Establece la estructura navegable y la base de datos sobre la que se apoyarán los incrementos siguientes.

Alcance funcional:

- Un usuario único, sin login ni cuentas, administra varios proyectos. Cada proyecto tiene nombre, cliente, descripción breve, fecha de creación y estado (activo o cerrado). La pantalla inicial lista los proyectos activos, permite crear uno nuevo, abrirlo, editarlo y cerrarlo lógicamente.
- Dentro de un proyecto se registran interesados. Cada interesado tiene nombre, rol en la organización, área, nivel de influencia (alto, medio, bajo), notas libres y estado activo o inactivo. Se listan, crean, editan y desactivan. Un interesado pertenece a un solo proyecto.
- Dentro de un proyecto se registran sesiones de elicitación. Cada sesión tiene título, fecha y hora, técnica empleada (entrevista abierta, entrevista estructurada, taller, observación, revisión documental), lugar, estado (planeada, en curso, cerrada) y notas libres. Una sesión referencia a uno o más interesados participantes del mismo proyecto.
- Cada sesión tiene un guion: una lista ordenada de puntos a tratar, cada uno con texto, estado (pendiente, cubierto, omitido) y posición. Los puntos se agregan, editan, reordenan y marcan durante o después de la sesión. El guion es la estructura que en incrementos posteriores recibirá automáticamente los campos generados pendientes de validar.
- Cada proyecto tiene un glosario de términos del dominio: término, definición y notas. Se lista alfabéticamente y se edita libremente. En incrementos posteriores este glosario alimentará el initialPrompt del transcriptor.
- Cada sesión y cada proyecto muestran un contador de sus elementos asociados, para dar sensación de avance sin necesitar aún el tablero de métricas.

Reglas de datos:

- Ninguna entidad se borra físicamente. Cerrar un proyecto, desactivar un interesado o eliminar un punto del guion son operaciones lógicas que conservan el registro y quedan asentadas en una bitácora local con fecha y operación.
- Todas las entidades llevan identificador propio, fecha de creación y fecha de última modificación.
- La base de datos arranca en la versión 1 del esquema, con la migración inicial declarada explícitamente aunque no haya migraciones previas.
- Los datos de un proyecto nunca se mezclan con los de otro: toda consulta se filtra por proyecto.

Comportamiento esperado:

- La aplicación funciona por completo sin conexión a internet. Este incremento no realiza ninguna petición de red.
- Toda pantalla resuelve de forma explícita sus cuatro situaciones: cargando, con datos, vacía y con error. La pantalla vacía invita a crear el primer elemento en lugar de mostrar un mensaje de ausencia.
- La navegación es jerárquica: lista de proyectos, detalle de proyecto con acceso a interesados, sesiones y glosario, y detalle de sesión con su guion.
- Los formularios validan antes de guardar y conservan lo escrito si la validación falla.

Criterios de aceptación del incremento:

- Se puede crear un proyecto, agregarle tres interesados, crear una sesión que referencie a dos de ellos, armar un guion de cinco puntos, reordenarlos y marcar dos como cubiertos.
- Al cerrar y volver a abrir la aplicación, toda la información persiste.
- Cerrar un proyecto lo retira de la lista de activos sin eliminar sus datos, y puede consultarse desde el filtro de cerrados.
- La aplicación se instala y opera en un dispositivo Android físico sin conexión a internet.
