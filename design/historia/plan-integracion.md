# Plan: integrar la historia en el juego actual

> **Archivado para SunDoku 2.0 (19/09/2026).** Este documento describe el diseño o prototipo anterior. La versión 1.0 mantiene el juego simple: tutorial, sudokus, celebraciones y mapa, sin escenas narrativas. El código del prototipo se conserva como referencia en `prototipo-2.0/`, fuera de la aplicación.

Estado: propuesta de próximos pasos. Este documento planifica el trabajo; no implementa cambios en el juego.

Referencias: [Historia del Camino de los Números](camino-de-los-numeros.md) y [anexo de experiencia y habilidades](anexo-progresion.md).

## 1. Decisión de producto

Convertir el tutorial actual en el primer capítulo de la aventura. Sus explicaciones y ejercicios pasan a formar parte del encuentro entre Doku, Tilo, Numa y el jugador.

El botón del libro que hoy abre «Ver el tutorial» pasa a abrir el **Cuaderno del Camino**, con la etiqueta breve «Cuaderno». Allí quedan las reglas aprendidas, las herramientas obtenidas y los recuerdos del viaje.

Cada sudoku completado por primera vez en Aventura tiene una escena posterior. El primer alcance es el valle actual: diez niveles, tres partidas por nivel y treinta escenas de victoria. La partida rápida mantiene su flujo de práctica independiente.

## 2. Qué aprovechamos del juego actual

- El bloque inicial elegido por el jugador, su expansión y las explicaciones sobre filas y columnas en el tablero real.
- El flujo persistente de la primera experiencia y sus tres sudokus con ayuda decreciente.
- Las celebraciones de victoria, las estrellas, los tableros completados y el resumen del nivel.
- La navegación de escenas por pasos, con avance manual y adaptación a movimiento reducido.
- El acceso al repaso mediante el icono de libro del mapa.
- Las superficies ilustradas compartidas, los botones amarillos, Doku y el paisaje del valle.

Actualmente la primera visita a Jugar abre la introducción; las siguientes llevan al mapa. El controlador de primera experiencia también participa en los niveles generados y en partida rápida. La integración debe contemplar esos usos al incorporar el relato.

## 3. El nuevo comienzo

### Objetivo

Dar una motivación breve, permitir una primera interacción pronto y enseñar las reglas cuando el jugador las necesita.

La home conserva su función de entrada. «Jugar» inicia la aventura y, una vez empezada, puede presentarse como «Continuar». Al continuar se recupera la escena, lección o partida pendiente; si no hay nada pendiente, se abre el mapa.

La pregunta inicial por el nombre se propone como opcional después del primer nivel, al personalizar el cuaderno. El inicio de la aventura puede usar «compañero» y dejar el nombre editable desde el perfil.

### Guion funcional del nivel 1

| Momento | Qué ve o hace el jugador | Función narrativa y de aprendizaje |
|---|---|---|
| Entrada | Una escena breve de Doku y Numa. | Doku quiere jugar contra la campeona. Numa lo invita a prepararse recorriendo el camino. |
| Entrega del cuaderno | Numa le entrega el Cuaderno del Camino. | Presentar dónde quedará lo aprendido. Una o dos tarjetas en total para la entrada y esta entrega. |
| Primer bloque | Colocar los nueve números en el bloque actual. | Tilo propone empezar por algo pequeño. El jugador conserva su elección. |
| Tablero completo | Ver cómo el mismo bloque se integra en el sudoku. | Explicar bloques, filas y columnas con frases de Tilo y resaltados reales. |
| Primera partida | Completar el primer sudoku guiado. | Encontrar y justificar el número que falta. |
| Primera victoria | Celebración, estrella y escena breve con Tilo. | Reconocer el primer logro: «Encontraste el número y descubriste por qué iba ahí». |
| Segunda partida | Elegir dónde empezar con menos acompañamiento. | Aplicar las reglas con mayor iniciativa. |
| Segunda victoria | Celebración, estrella y escena breve con Numa. | Dar un motivo para seguir: en otras escuelas descubrirá distintas formas de mirar el tablero. |
| Tercera partida | Jugar con ayuda disponible a pedido. | Dar espacio a la autonomía. |
| Tercera victoria | Celebración con resumen y escena de cierre. | Doku y el jugador deciden comenzar el viaje por el valle. Se abre el nivel 2. |
| Salida | Elegir «Siguiente nivel» o «Mapa». | El cuaderno permite consultar las reglas que ya se enseñaron. |

Las reglas se expresan de forma directa dentro del diálogo. Por ejemplo: «En esta fila van del 1 al 9, sin repetir». El contexto narrativo acompaña la explicación.

La reseña histórica sobre el origen del sudoku puede conservarse como curiosidad opcional del cuaderno. La apertura principal presenta a Doku y su objetivo.

El primer nivel termina con sus tres estrellas. El primer sello de maestro se obtiene al completar el nivel 10 del valle.

## 4. Historia después de cada victoria

### Después de las partidas 1 y 2

Sudoku completado → guardado de la victoria → celebración y estrella → «Continuar» → escena → «Jugar la siguiente».

### Después de la partida 3

Sudoku completado → guardado de la victoria → celebración con resumen de nivel → «Continuar» → escena de cierre → «Siguiente nivel» o «Mapa».

El resumen aparece una sola vez. Todas las salidas hacia la siguiente partida o nivel consultan si hay una escena pendiente. Si el jugador vuelve al mapa antes de verla, queda guardada para continuar luego y disponible en el cuaderno.

### Ritmo de las escenas

- Una tarjeta es el caso habitual; dos cuando el diálogo necesita un intercambio.
- Como referencia editorial, alrededor de 15–35 palabras por tarjeta, ajustadas después de probarlas en pantalla pequeña.
- Una escena debe aportar un hecho, una intención, una relación entre personajes o un aprendizaje. Cada nivel tiene una pequeña situación que avanza a lo largo de sus tres victorias.
- Los hitos principales son la llegada al valle, el encuentro del nivel 5 y la despedida del nivel 10.
- Lectura y avance a voluntad del jugador, con opción de mostrar el texto completo y de omitir el diálogo.
- Omitir un diálogo conserva los resultados y deja la escena disponible para leer después. Las lecciones interactivas tienen su propio estado y se retoman en su acción pendiente.
- En repeticiones, las escenas ya cerradas no se imponen de nuevo. Se pueden releer en el cuaderno.

Los diálogos posteriores a tableros generados deben hablar de hechos comprobables: completar la partida, descubrir una región o avanzar en el viaje. Si una frase afirma que el jugador usó una técnica particular, esa acción tiene que estar verificada.

## 5. El Cuaderno del Camino

### Primera versión

El acceso del libro en el mapa se mantiene en su lugar y cambia de destino y etiqueta. Desde una partida, el cuaderno puede abrirse en el menú de pausa para conservar el espacio del tablero.

Se proponen dos secciones iniciales:

| Sección | Contenido | Momento de incorporación |
|---|---|---|
| Aprendido | Bloques, filas, columnas, cómo colocar y borrar, cómo pedir ayuda; después, herramientas y técnicas. | Al completar la explicación o acción correspondiente. |
| Mi viaje | Objetivo actual, escenas desbloqueadas y personajes conocidos. | Al llegar a sus momentos narrativos. |

Cada ficha de «Aprendido» tiene una explicación corta y un ejemplo. «Practicar» abre un ejercicio aislado, sin reiniciar el nivel de campaña ni otorgar premios duplicados. Una primera entrega puede ofrecer las fichas de consulta y añadir después los ejercicios.

En «Mi viaje», las escenas se ordenan por nivel y partida. Una escena omitida se distingue como disponible para leer; una escena futura permanece oculta. El progreso del valle y sus estrellas aprovechan los datos existentes.

Las anotaciones del cuaderno son automáticas y registran el aprendizaje. Las **notas** dentro de las casillas siguen siendo una herramienta de sudoku que se introduce en el mundo 2. Un espacio para escribir texto libre puede estudiarse más adelante.

Consultar el cuaderno durante una partida pausa el reloj. Cerrarlo vuelve al mismo tablero, selección y estado de pausa. El jugador reanuda explícitamente cuando corresponda.

## 6. Base necesaria para conectar las partes

Esta es una separación de responsabilidades para guiar la implementación posterior:

**Contenido de historia.** Un catálogo relaciona mundo, nivel y partida con sus escenas. Cada escena tiene una identidad estable, personajes, texto, contexto visual y una continuación definida. Las lecciones y las páginas del cuaderno se referencian por identidad, evitando copiar sus textos en distintos lugares.

**Progreso de aventura.** Registra la escena pendiente, la tarjeta actual, escenas leídas u omitidas, lecciones completadas, entradas del cuaderno y herramientas obtenidas. También conserva la versión del contenido necesaria para interpretar un guardado anterior.

**Partida de sudoku.** Conserva tableros, selección, notas cuando correspondan, estrellas, puntos, tiempo y guardado. La historia recibe el resultado persistido de una partida.

**Presentación.** Reutiliza el tablero y las superficies actuales para las escenas, las explicaciones y el cuaderno. Los personajes se componen como recursos independientes.

La finalización debe ser recuperable: una victoria guardada permite reconstruir su escena pendiente incluso si la app se cierra antes de mostrarla. Reanudar una escena no vuelve a dar estrellas ni futuros premios de experiencia. Cerrar una escena registra su resolución antes de comenzar la siguiente partida.

## 7. Orden de trabajo propuesto

### Paso 1. Cerrar el guion y el recorrido del nivel 1

**Entregables:** texto exacto de la apertura, diálogos que sustituyen las explicaciones actuales, tres escenas de victoria, acciones de cada pantalla y primeras fichas del cuaderno.

**Criterio de cierre:** se puede recorrer el nivel completo en un guion de pantallas y entender qué quiere Doku, qué hace el jugador y qué aprende en cada paso. El guion conserva el bloque elegido y todas las reglas necesarias.

### Paso 2. Preparar la base de escenas y su guardado

**Entregables posteriores de implementación:** catálogo inicial, progreso narrativo y conexión con la victoria y la continuación de la partida. Incorporar desde el principio la salida del tercer sudoku y el retorno desde el mapa.

**Criterio de cierre:** una escena puede aparecer después de cada ronda, omitirse, reanudarse tras cerrar la app y resolverse una sola vez sin repetir recompensas. Partida rápida conserva su comportamiento independiente.

### Paso 3. Convertir el nivel 1 en el primer capítulo

**Entregables posteriores de implementación:** nueva entrada de Aventura, diálogos de Numa y Tilo, aprendizaje integrado sobre el tablero, tres escenas de victoria y cierre hacia el nivel 2. Mover la solicitud de nombre al momento opcional definido.

**Criterio de cierre:** un jugador nuevo completa sus tres sudokus dentro de una aventura continua y puede explicar las reglas básicas. Al regresar continúa exactamente donde dejó el recorrido.

### Paso 4. Convertir el botón de tutorial en el Cuaderno

**Entregables posteriores de implementación:** nueva navegación del libro, secciones «Aprendido» y «Mi viaje», consulta de las reglas y relectura de escenas. Añadir acceso desde pausa.

**Criterio de cierre:** consultar el cuaderno y volver conserva la partida; sus contenidos corresponden al progreso real; el repaso no reinicia la campaña.

### Paso 5. Extender la historia a los diez niveles del valle

**Entregables:** veintisiete escenas adicionales, una pequeña situación por nivel, desarrollo de Tilo y desafío del mirador. Revisión editorial del conjunto para evitar repeticiones y adelantar la llegada al bosque.

**Criterio de cierre:** las treinta primeras victorias del valle tienen continuidad narrativa; el nivel 10 entrega el Sello de la Observación. Si el bosque aún no está disponible, su presentación indica el estado real del contenido y no ofrece una entrada jugable inexistente.

### Paso 6. Añadir experiencia y preparar el primer desbloqueo

**Entregables posteriores de implementación:** experiencia según el anexo, registro de premios únicos, rango y sello en el cuaderno, adaptación de progreso anterior y diseño de entrada al mundo 2.

El primer desbloqueo jugable será el lápiz y las notas al comenzar el bosque. Su implementación necesita una lección, controles, representación de candidatos, guardado y tableros adecuados.

**Criterio de cierre:** la experiencia refleja lo completado sin duplicarse, las estrellas conservan su significado y el lápiz se obtiene al aprender a usarlo. Las reglas y ayudas básicas del valle permanecen disponibles desde el inicio.

## 8. Primer objetivo de implementación

Completar los pasos 1–4 como una entrega revisable: **un inicio narrativo, el nivel 1 entero con sus tres escenas de victoria, continuidad guardada y un cuaderno básico accesible desde el mapa**.

Esta entrega permite evaluar el ritmo antes de escribir e integrar todas las escenas del valle. La experiencia numérica y el mundo 2 se incorporan sobre ese recorrido ya probado.

## 9. Recursos visuales para esa primera entrega

Reutilizar primero Doku, el fondo del valle, el icono de libro, las cards y los botones actuales. Probar la composición con esos recursos y con textos reales.

Para la versión final del capítulo se necesitan Numa y Tilo como personajes individuales con un pequeño conjunto de expresiones. Definir esas poses después del guion permite saber qué necesita cada escena. El cuaderno puede construirse con superficies existentes y su icono actual; una apariencia adicional de libreta es opcional.

Los nuevos recursos deben cumplir las reglas del proyecto: PNG RGBA con alfa real, arte separado por elemento, superficies vacías, texto con Flutter y composición responsive. Las acciones amarillas permanecen abajo en SafeArea; el contenido central usa el espacio superior y se desplaza cuando hace falta.

## 10. Guardados existentes y comprobaciones

### Jugadores que ya comenzaron

- Si hay una partida en curso, conservarla y continuar desde ella. Las escenas de victorias anteriores se habilitan en el cuaderno sin imponer una secuencia retrospectiva al abrir la app.
- Si la introducción quedó a medias, llevar su paso a la lección equivalente y conservar el bloque elegido, el tablero y la selección.
- Si se terminó el tutorial, habilitar las fichas de reglas básicas en el cuaderno.
- Si se completaron niveles, conservar sus estrellas, resultados y desbloqueos; calcular los XP correspondientes cuando se incorpore ese sistema.
- Mostrar una presentación breve del nuevo cuaderno cuando corresponda, con opción de volver a la partida.

### Casos a verificar al implementar

- Primera instalación: desde Jugar hasta la tercera victoria y el nivel 2.
- Cierre después de guardar una victoria y antes de presentar su escena.
- Cierre a mitad de una escena y regreso a la misma tarjeta.
- Continuación después de la tercera partida sin saltar accidentalmente el cierre narrativo.
- Omitir una escena, encontrarla en el cuaderno y continuar sin premios duplicados.
- Abrir un repaso desde una partida y regresar sin cambios en su estado.
- Retomar un guardado anterior, incluyendo tutorial incompleto y niveles completados.
- Mantener el comportamiento de partida rápida.
- Pantallas pequeñas, horizontal, texto ampliado, teclado y movimiento reducido.
- Bloque central y estado del tablero conservados al cambiar entre diálogo, lección y juego.

Las pruebas se concretarán durante cada cambio de implementación. En esta etapa el entregable es el plan y el siguiente trabajo propuesto es escribir el guion exacto del capítulo inicial.
