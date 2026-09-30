# Capítulo 1: una invitación en el valle

> **Archivado para SunDoku 2.0 (19/09/2026).** Este documento describe el diseño o prototipo anterior. La versión 1.0 mantiene el juego simple: tutorial, sudokus, celebraciones y mapa, sin escenas narrativas. El código del prototipo se conserva como referencia en `prototipo-2.0/`, fuera de la aplicación.

Guion funcional del nivel 1. Primer paso del [plan de integración](plan-integracion.md), redactado para una implementación posterior.

Objetivo del capítulo: conocer el deseo de Doku, aprender las tres reglas sobre el tablero real, completar tres sudokus y comenzar el viaje hacia el desafío de Numa.

Los identificadores de este documento son referencias estables para relacionar escenas, lecciones y guardado. Los textos entre comillas son propuestas de texto final de UI. Los nombres de personajes funcionan como etiquetas de diálogo.

## Recorrido

Home → invitación de Numa → primer bloque con Tilo → tablero, filas y columnas → primera partida → primera escena de victoria → segunda partida → segunda escena de victoria → tercera partida → resumen → escena de cierre → nivel 2 o mapa.

Las explicaciones se integran con el flujo actual. El bloque central elegido, el tablero y la selección sobreviven a las transiciones. Las acciones amarillas permanecen en la zona inferior de SafeArea; el contenido usa el espacio superior.

## 0. Entrada desde la home

- Jugador nuevo: botón **«Aventura»**.
- Aventura iniciada: botón **«Continuar aventura»**.
- La primera entrada abre la invitación. La continuación futura recupera la escena, lección o partida pendiente; cuando no hay un paso activo, abre el mapa.
- La personalización del nombre queda disponible después del capítulo y desde el perfil. Los diálogos iniciales se dirigen al jugador sin necesitar su nombre.

El cambio de etiqueta ya está aplicado. La recuperación directa del paso pendiente pertenece a la implementación del flujo narrativo.

## 1. Invitación de Numa

**Escena:** `world-1/level-1/arrival`.

**Composición:** paisaje actual del valle, Doku y retrato independiente de Numa. Una tarjeta de diálogo por vez.

### Tarjeta 1 — Doku

> «¡Es Numa, la campeona del Gran Encuentro! Quiero aprender a jugar tan bien como ella. ¿Me acompañás?»

**Acción principal:** «Vamos juntos».

### Tarjeta 2 — Numa

> «Este cuaderno es para ustedes. Aprendan con los maestros del camino. Los espero en el Gran Encuentro con tres tableros preparados».

**Acción principal:** «Empezar el camino».

**Resultado:** se incorpora el Cuaderno del Camino. Su primera entrada en «Mi viaje» registra «Prepararnos para el desafío de Numa». La invitación queda disponible para releer.

Numa se despide. Tilo acompaña las siguientes acciones. El cuaderno se presenta mediante la tarjeta y su icono; no requiere abrir una pantalla de inventario antes de jugar.

**Omitir diálogo:** continúa a la lección del bloque, entrega el cuaderno y conserva la invitación como escena disponible. La entrega es un efecto único de la entrada al capítulo.

## 2. El primer bloque

**Lección:** `world-1/level-1/block`.

**Personaje:** Tilo.

**Texto de entrada:**

> «Soy Tilo. Empecemos con estas nueve casillas: poné los números del 1 al 9, una vez cada uno».

**Acción principal:** «Armar mi bloque».

Se presenta el bloque interactivo actual. El jugador elige el orden de los números y puede cambiarlo antes de confirmar. El contador conserva la información «{colocados} de 9».

**Ayuda breve durante la interacción:**

> «Tocá una casilla y elegí un número. Podés borrar para cambiarlo».

**Al completar:**

> «¡Ya armaste tu primer bloque! Ahora mirá de qué forma parte».

**Acción principal:** «Ver el tablero».

**Resultado:** se conserva exactamente el bloque elegido y se incorpora la ficha «Los bloques» a «Aprendido». Esta construcción inicial permite elegir el orden; las partidas siguientes se resuelven a partir de sus pistas.

## 3. El tablero se abre

**Lección:** `world-1/level-1/board`.

El bloque se integra en el centro del tablero completo con la transición actual.

**Tilo:**

> «Tu bloque es uno de los nueve del tablero. En cada bloque van del 1 al 9, sin repetir».

Se señala el bloque central y después uno de los vecinos. El tablero sigue siendo el mismo widget de juego.

**Acción principal:** «Ver las filas».

## 4. Las filas

**Lección:** `world-1/level-1/rows`.

Se recorre la fila central y se destaca uno de sus números.

**Tilo:**

> «Una fila cruza el tablero de lado a lado. También lleva del 1 al 9, sin repetir».

**Texto junto al ejemplo:**

> «Este {número} ya está en la fila. Acá no puede aparecer otro {número}».

`{número}` se obtiene del bloque del jugador. El ejemplo siempre coincide con el tablero visible.

**Acción principal:** «Ver las columnas».

**Resultado:** ficha «Las filas» disponible en el cuaderno al avanzar.

## 5. Las columnas

**Lección:** `world-1/level-1/columns`.

Se apaga el foco de la fila y se recorre la columna central.

**Tilo:**

> «Una columna va de arriba abajo. En ella también van del 1 al 9, sin repetir».

**Cierre de la explicación:**

> «Bloque, fila y columna. Vamos a mirar esas tres cosas para encontrar cada número».

**Acción principal:** «Jugar juntos».

**Resultado:** ficha «Las columnas» disponible en el cuaderno al avanzar. Las tres fichas de reglas quedan completas antes del primer sudoku.

## 6. Primera partida: encontrar una certeza

**Lección de entrada:** `world-1/level-1/first-game`.

El centro elegido permanece en el tablero. Se incorporan las pistas actuales y se conserva la primera partida de seis huecos.

**Tilo:**

> «Estos números son pistas y quedan fijos. Elegí una casilla vacía y busquemos qué número falta».

**Acción principal:** «Jugar».

Las primeras jugadas utilizan las ayudas del tablero actual. Sus mensajes se apoyan en deducciones comprobadas. Ejemplos de redacción:

- Antes de una colocación: «En esta fila queda un solo hueco. ¿Qué número falta?».
- Después de una colocación correcta: «¡Sí! Ahora esta fila tiene todos sus números».
- Ante una repetición: «Ya hay un {número} en esta fila. Miremos otra vez».

Cuando el grupo relevante es una columna o un bloque, el texto lo nombra correctamente. El juego sigue explicando los casos que ya reconoce su motor de ayuda.

**Entradas del cuaderno:** «Cómo jugar una casilla», «Borrar» y «Pedir ayuda», después de sus explicaciones correspondientes. Los controles básicos permanecen disponibles desde el comienzo.

## 7. Primera victoria: ya sabemos por qué

**Escena:** `world-1/level-1/after-round-1`.

Primero se guarda la victoria y se presenta la celebración actual con una estrella. Su acción pasa a ser «Continuar» y abre esta escena.

**Tarjeta única — Tilo:**

> «¡Primer sudoku completo! Aprendieron a mirar bloques, filas y columnas. En la próxima partida van a elegir por dónde empezar».

**Acción principal:** «Jugar el segundo».

**Registro en Mi viaje:** «Nuestra primera partida».

El mensaje reconoce haber completado el aprendizaje y el sudoku. Funciona también cuando el jugador pidió ayuda.

## 8. Segunda partida: elegir dónde mirar

Se conserva el segundo sudoku de doce huecos.

**Tilo, en la entrada de la partida:**

> «Buscá una fila, columna o bloque casi completo. Si te trabás, podés pedirme una pista».

El texto se presenta junto al tablero; la escena anterior ya contiene la acción para empezar. El reloj comienza al quedar habilitada la interacción de juego.

No se repiten las explicaciones de las tres reglas. La ayuda permanece contextual y el jugador elige su primera casilla.

## 9. Segunda victoria: una invitación que nos espera

**Escena:** `world-1/level-1/after-round-2`.

Celebración actual con la segunda estrella y acción «Continuar».

**Tarjeta 1 — Doku:**

> «¡Ya van dos! Numa dejó algo escrito en el cuaderno…»

**Acción principal:** «Leer la invitación».

**Tarjeta 2 — Invitación de Numa:**

> «Cada maestro del camino tiene algo para enseñarles. Guarden lo que descubran: lo van a necesitar cuando juguemos juntos».

**Acción principal:** «Jugar el tercero».

**Registro en Mi viaje:** «La invitación de Numa».

Numa aparece como autora de la nota, mediante su retrato y la etiqueta «Invitación de Numa». La escena no supone que haya regresado al valle.

## 10. Tercera partida: un paso propio

Se conserva el tercer sudoku de dieciocho huecos.

**Doku, en la entrada de la partida:**

> «Este lo empezamos nosotros. A nuestro ritmo. Tilo está cerca si necesitamos una pista».

Sin selección automática ni indicaciones sobre una respuesta antes de que el jugador pida ayuda. Se conserva el acompañamiento disponible.

## 11. Tercera victoria y resumen

Se guarda la tercera victoria y se presenta la celebración con tres estrellas, los tableros y el resumen actual de tiempos y puntos.

**Título:** «¡Primer nivel completo!».

**Texto:** «Tres sudokus resueltos. Nuestro viaje ya empezó».

**Acción principal:** «Continuar».

Abre la escena de cierre. El resumen no vuelve a mostrarse al terminar el diálogo.

## 12. Cierre: el camino sigue

**Escena:** `world-1/level-1/after-round-3`.

**Tarjeta 1 — Tilo:**

> «El camino sigue por el valle. Vamos a practicar hasta llegar al mirador. Allí les espera mi desafío».

**Acción principal:** «Seguir».

**Tarjeta 2 — Doku:**

> «Tenemos el cuaderno y nuestras primeras tres estrellas. ¡Vamos por el siguiente paso!».

**Acción principal:** «Siguiente nivel».

**Acción secundaria:** «Mapa».

**Registro en Mi viaje:** «El camino sigue». El objetivo actual pasa a ser «Llegar al mirador y superar el desafío de Tilo».

El nivel 2 conserva su nombre «Los primeros pasos». La escena no concede un sello de maestro: ese hito corresponde al nivel 10.

## 13. Primeras páginas del cuaderno

Estas fichas se incorporan automáticamente al completar las lecciones anteriores. Sus contenidos son accesibles desde «Aprendido».

| Ficha | Texto de consulta |
|---|---|
| Los bloques | «Un bloque tiene nueve casillas. En cada bloque van los números del 1 al 9, una vez cada uno». |
| Las filas | «Una fila cruza el tablero de lado a lado. En cada fila van del 1 al 9, sin repetir». |
| Las columnas | «Una columna va de arriba abajo. En cada columna van del 1 al 9, sin repetir». |
| Cómo jugar una casilla | «Tocá una casilla vacía y elegí un número. Las pistas que ya estaban en el tablero quedan fijas». |
| Borrar | «Elegí un número que hayas colocado y tocá Borrar para quitarlo». |
| Pedir ayuda | «Elegí una casilla vacía y tocá Ayuda. Mirá las casillas destacadas y seguí la explicación». |

En «Mi viaje» quedan la invitación inicial y las tres escenas de victoria. El lápiz para tomar notas se introduce en el mundo 2; el cuaderno del capítulo 1 funciona como registro del viaje y consulta de reglas.

La personalización opcional «¿Qué nombre ponemos en el cuaderno?» puede ofrecerse al abrirlo por primera vez después del nivel 1. Acciones: «Guardar» y «Ahora no». El perfil permite modificar el nombre más adelante.

## 14. Reanudación y navegación

- Guardar escena y tarjeta actual. Retomar un diálogo continúa en esa tarjeta.
- Guardar las victorias antes de abrir sus escenas. El guardado permite recuperar la escena pendiente aunque la app se cierre entre ambos momentos.
- Omitir una escena la deja disponible en el cuaderno y lleva a su siguiente acción de juego. Omitir texto de una lección conserva cualquier acción interactiva necesaria para continuar.
- «Ver el tablero», las reglas y las partidas comparten el estado del bloque central. Volver, redimensionar y reanudar no lo reemplazan.
- Abrir el cuaderno durante el juego pausa el reloj y conserva tablero y selección.
- Releer una escena o consultar una ficha no da estrellas ni altera la campaña.
- Los guardados anteriores continúan desde la lección o partida equivalente; las escenas previas quedan disponibles en el cuaderno.
- El guardado de una escena y el avance al siguiente sudoku se resuelven antes de iniciar el reloj de la nueva partida.

## 15. Recursos para producir después del guion

- Doku, fondo del valle, libro, superficies, botones y celebraciones: reutilizar recursos actuales.
- Numa: un retrato individual para la invitación y su nota. Expresión tranquila y atenta.
- Tilo: un retrato individual para sus lecciones y celebraciones. Expresión cercana y paciente.
- Los diálogos y las páginas del cuaderno se construyen con widgets y texto real. Los recursos nuevos se generan separados, con transparencia RGBA y siguiendo las instrucciones del proyecto.

## Criterio para dar el capítulo por integrado

Un jugador nuevo entiende que Doku quiere prepararse para Numa, construye su bloque, aprende las tres reglas, completa tres partidas, ve sus tres escenas, consulta lo aprendido y puede continuar al nivel 2. Al cerrar y volver, retoma el mismo estado. Esta condición se verificará cuando se implemente el guion.
