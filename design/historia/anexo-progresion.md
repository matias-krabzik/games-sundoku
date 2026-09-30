# Anexo: experiencia, herramientas y habilidades

> **Archivado para SunDoku 2.0 (19/09/2026).** Este documento describe el diseño o prototipo anterior. La versión 1.0 mantiene el juego simple: tutorial, sudokus, celebraciones y mapa, sin escenas narrativas. El código del prototipo se conserva como referencia en `prototipo-2.0/`, fuera de la aplicación.

Propuesta de diseño para [Doku y el Camino de los Números](camino-de-los-numeros.md).

## 1. Objetivo de la progresión

La experiencia expresa cuánto camino recorrieron Doku y el jugador. Las herramientas amplían lo que pueden hacer sobre el tablero. Las técnicas amplían lo que pueden comprender. Los encuentros con maestros permiten ponerlo en práctica.

El ciclo de cada aprendizaje es: descubrir una dificultad, recibir una explicación breve, probar el recurso sobre un tablero, practicar y superar el desafío del maestro.

Las herramientas se reciben al inicio de su enseñanza y permanecen disponibles después. El sello al final del mundo reconoce haber completado sus partidas.

## 2. Qué existe y qué se propone

El juego actual tiene un mundo de diez niveles, tres sudokus por nivel, tres estrellas vinculadas a su finalización y desbloqueo del siguiente nivel al completar las tres partidas. También tiene puntaje, guardado de progreso, borrado, pausa y ayuda contextual.

El [diseño de ayuda contextual](../ayuda-contextual.md) ya sitúa las notas en el mundo 2. El primer mundo se mantiene sin notas. Su ayuda ya contempla últimos huecos, candidatos únicos y ubicaciones únicas; esas deducciones básicas no se presentan aquí como funciones bloqueadas de mundos posteriores.

Este anexo propone experiencia, rangos, cuaderno, maestros y mundos adicionales. Su redacción no modifica el código ni las [reglas actuales de puntaje](../scoring/rules.md).

## 3. Experiencia: una recompensa permanente

### Valores iniciales para probar

| Acción | Experiencia | Frecuencia |
|---|---:|---|
| Completar un sudoku de la campaña | 20 XP | Una vez por sudoku |
| Completar las tres partidas de un nivel | 40 XP adicionales | Una vez por nivel |
| Repetir un sudoku o nivel ya completado | 0 XP adicional | Permite practicar y mejorar marcas |
| Completar una explicación, usar una ayuda o hacer una anotación | 0 XP adicional | Forma parte del aprendizaje |

Así, cada nivel completo entrega 100 XP; cada mundo de diez niveles, 1.000 XP; y la campaña de cinco mundos, 5.000 XP. Los niveles de maestros y el encuentro con Numa están incluidos en esos totales.

Un jugador que completó dos sudokus del primer nivel tiene 40 XP. Al completar el tercero recibe 20 XP por esa partida y 40 XP por cerrar el nivel: llega a 100 XP.

Los errores, las ayudas y las pausas no descuentan experiencia. El puntaje mantiene su función de medir la actuación en una partida; las estrellas siguen representando sudokus completados. La experiencia se presenta en el resumen y el cuaderno, evitando añadir otro contador permanente al tablero.

Las partidas rápidas conservan su función de práctica libre y no alteran los desbloqueos de campaña en esta propuesta. Cualquier experiencia futura fuera de la campaña requeriría revisar los umbrales y la regla de premios únicos.

### Rangos de Doku

| Experiencia acumulada | Rango | Hito narrativo |
|---:|---|---|
| 0–999 XP | Aprendiz del valle | Comienza el viaje con Tilo. |
| 1.000–1.999 XP | Explorador de posibilidades | Entra al bosque y aprende a tomar notas. |
| 2.000–2.999 XP | Tejedor de conexiones | Puede recorrer las escuelas de los ríos. |
| 3.000–3.999 XP | Buscador de patrones | Llega a las montañas gemelas. |
| 4.000–4.999 XP | Aspirante del Gran Encuentro | Accede a la ciudad y a la clasificación. |
| 5.000 XP | Maestro del Camino | Supera las tres pruebas de Numa. |

Estos rangos acompañan los hitos de campaña. Las habilidades requieren también su enseñanza específica: el rango habilita el capítulo y la lección enseña la herramienta.

## 4. Mapa de aprendizaje y desbloqueos

En cada mundo, el nivel 1 presenta su recurso principal; los niveles 2–4 lo practican; el nivel 5 incorpora una mejora o una combinación; los niveles 6–9 mezclan lo nuevo con conocimientos previos; y el nivel 10 contiene el encuentro con el maestro. El mundo 1 conserva su tutorial actual y el mundo 5 se centra en integración.

| Mundo y entrada | Aprendizaje central | Desbloqueo y momento | Encuentro final |
|---|---|---|---|
| 1. Valle del Sol · 0 XP | Filas, columnas, bloques; últimos huecos; observación y deducciones simples. | Cuaderno al comenzar. Ayuda básica, selección, resaltados actuales, borrado y pausa disponibles desde el inicio. | Tilo: encontrar un comienzo y continuar con las reglas básicas. |
| 2. Bosque de las Posibilidades · 1.000 XP + mundo 1 completo | Anotar candidatos y distinguir opciones de certezas. | Lápiz de posibilidades en N1; filtro de candidatos de la lupa en N5. | Vera: organizar notas y usarlas para completar las tres partidas. |
| 3. Ríos Cruzados · 2.000 XP + mundo 2 completo | Candidatos alineados entre bloque y fila o columna; actualización de notas. | Lección de conexiones y pincel en N1; limpieza automática opcional de notas en N5. | Rina: aprovechar eliminaciones entre regiones. |
| 4. Montañas Gemelas · 3.000 XP + mundo 3 completo | Parejas desnudas y combinación con deducciones anteriores. | Tizas para marcar relaciones y lección de parejas en N1; práctica mixta en N5. | Teo y Tea: reservar dos números en dos casillas y usar sus consecuencias. |
| 5. Ciudad de los Maestros · 4.000 XP + mundo 4 completo | Elegir técnicas, cambiar de foco y combinar deducciones. | Sección de preparación para el encuentro; tras ganar, revanchas y retos de maestros. | Numa: observación, conexiones y síntesis en tres fases. |

N1 y N5 se refieren a niveles dentro de cada mundo. Los umbrales de XP son los de entrada al mundo; la habilidad indicada en N5 se entrega al llegar a esa lección, después de completar los niveles anteriores.

La herramienta está disponible durante su primera explicación. Al realizar la acción guiada que demuestra su uso, se registra el desbloqueo permanente. Salir antes de terminar conserva la lección y el acceso provisional necesario para retomarla.

### Herramientas y límites de su función

**Lápiz de posibilidades.** Permite añadir y quitar candidatos de una casilla vacía. El jugador aprende a registrar posibilidades compatibles con las pistas. El nombre visible del control sigue siendo «Notas»; el lápiz aporta su identidad narrativa.

**Lupa del rastreador.** Extiende la observación a los candidatos: al elegir un número, destaca dónde aparece entre las notas. El resaltado básico que ya usa el juego permanece disponible desde el inicio. Esta mejora no señala por sí sola cuál es la respuesta.

**Pincel de descarte.** Presenta cómo eliminar candidatos descartados por una deducción. En la primera lección, el jugador realiza la eliminación explicada. La posterior limpieza automática opcional solo retira de las notas el número recién colocado en las casillas de su fila, columna y bloque; las eliminaciones por parejas o conexiones siguen requiriendo razonamiento o ayuda explicada. El pincel trabaja sobre notas; el borrado de valores conserva su control habitual.

**Tizas de colores.** Permiten marcar relaciones entre casillas o candidatos. Las marcas combinan color con contornos o símbolos para distinguirse también sin percepción del color. Sirven para organizar la observación y se pueden quitar libremente.

**Cuaderno de maestros.** Reúne técnicas, ejemplos interactivos breves, sellos y escenas. La ayuda contextual puede remitir a la página de la técnica que está explicando. Se conservan etiquetas funcionales claras: «Notas», «Resaltar», «Limpiar notas» y «Ayuda».

### Técnicas que aprende el jugador

| Técnica | Qué permite afirmar | Representación narrativa |
|---|---|---|
| Último hueco | En una región válida con ocho valores colocados, el número que falta completa la novena casilla. | Tilo enseña a elegir una zona pequeña donde empezar. |
| Candidato único | Una casilla tiene una sola posibilidad después de considerar fila, columna y bloque. | «La última posibilidad»: Doku aprende a justificar una colocación. |
| Ubicación única | Un número solo puede ir en una casilla de una región, aunque esa casilla parezca admitir otros números. | «El lugar escondido»: encontrar dónde tiene que estar un número. |
| Candidatos alineados | Si todos los candidatos de un número en un bloque están en una misma fila o columna, ese número se elimina del resto de esa línea fuera del bloque. | Rina conecta regiones como conecta las orillas de un río. |
| Pareja desnuda | Dos casillas de una misma región contienen exactamente los mismos dos candidatos. Ambos se eliminan de las otras casillas de esa región. | Teo y Tea enseñan el «pacto de los gemelos». |

Estas técnicas son razonamientos que el jugador puede aplicar libremente. Los desbloqueos incorporan enseñanza y apoyos visuales; una deducción correcta sigue siendo válida aunque el jugador la descubra antes de su lección.

Las explicaciones técnicas de [candidato único](https://sudoku.com/sudoku-rules/obvious-singles/), [ubicación única](https://sudoku.com/sudoku-rules/hidden-singles/), [candidatos alineados](https://sudoku.com/sudoku-rules/pointing-pairs/) y [parejas](https://sudoku.com/sudoku-rules/obvious-pairs/) sirven como referencias de las reglas. Los nombres, personajes y recompensas son propuestas originales para SunDoku.

## 5. Cómo se demuestra un aprendizaje

Cada lección tiene una acción concreta que se puede observar: escribir candidatos válidos en una casilla indicada, destacar un número, retirar un candidato justificadamente o identificar las dos casillas de una pareja.

Al terminar esa acción, el cuaderno registra «Técnica descubierta». Al completar el encuentro del maestro, registra «Desafío completado». Las demostraciones admiten explicación y reintento.

Completar un sudoku no permite saber por sí solo qué razonamiento usó el jugador. Para reconocer una técnica específica, la lección pide una acción breve y comprueba su justificación con el tablero visible. Las partidas ordinarias mantienen libertad de resolución.

Ejemplo del lápiz:

1. Vera presenta una casilla con dos posibilidades y explica cómo anotarlas.
2. El jugador escribe ambas notas. El lápiz queda incorporado al cuaderno.
3. Una colocación justificada en otra casilla descarta una de ellas.
4. El jugador vuelve a sus notas y completa la casilla.
5. Al terminar el sudoku recibe los 20 XP habituales y su estrella. La lección no añade una moneda o premio distinto.

## 6. Tres partidas por nivel

En un nivel de enseñanza, las tres partidas siguen la secuencia **descubrir, practicar y aplicar**. Una explicación puede aparecer al llegar a la posición concreta donde resulta útil.

En niveles posteriores, las tres partidas refuerzan y mezclan las técnicas conocidas. Cada nivel conserva un propósito narrativo breve: entrenar con un viajero, prepararse para el maestro o participar en una clasificación.

Los tableros se seleccionan por las deducciones que requieren y por la carga de observación. La cantidad de casillas vacías es una característica adicional, insuficiente por sí sola para fijar la dificultad.

Para cada tablero de campaña se debe verificar solución única, una ruta lógica con técnicas ya enseñadas y una dificultad adecuada a su posición. Las lecciones deben contener una oportunidad comprobada de usar la técnica presentada. Una ruta alternativa correcta del jugador también se acepta.

El generador actual del valle trabaja con deducciones simples. Los mundos de conexiones y parejas necesitarán ampliar la generación o usar un catálogo validado; este documento no da por disponibles esos tableros.

## 7. Diseño jugable del jefe final

### Condición de acceso

Completar los nueve primeros niveles de la Ciudad de los Maestros, además de los cuatro mundos anteriores: 4.900 XP. El nivel 10 contiene los tres sudokus de Numa.

### Tipo de encuentro

El «Duelo de las Tres Pruebas» consiste en superar los tableros preparados por Numa. Ella formula el desafío y establece su condición de victoria antes de comenzar. La presentación muestra el progreso real del jugador, la fase actual y las reacciones de la campeona.

La campaña usa esta modalidad de desafío. Una competencia simultánea contra un rival que resuelve su propio tablero sería una modalidad adicional, con reglas y comportamiento del oponente todavía por diseñar.

### Fases y dificultad

| Fase | Exigencia | Qué la hace desafiante | Reacción de Numa |
|---|---|---|---|
| 1. Saber mirar | Encontrar una ruta entre candidatos y ubicaciones únicas. | Oportunidades repartidas; el jugador elige dónde empezar. | «Encontraste tu primera pista. Seguí ese camino». |
| 2. Saber conectar | Aplicar conexiones entre regiones y parejas conocidas. | Encontrar y justificar eliminaciones antes de poder colocar. | «Esa conexión abrió el tablero». |
| 3. Encontrar tu camino | Combinar las técnicas de la campaña. | Cambiar de técnica y reconocer consecuencias sucesivas. | «Ahora estás eligiendo cómo resolverlo». |

El encuentro mantiene disponibles todas las herramientas obtenidas, las notas, el borrado y las ayudas. Las ayudas explican el razonamiento con el mismo cuidado que durante el viaje. La victoria de campaña depende de completar los tres tableros.

El tiempo se registra para la marca personal. No hay una cuenta regresiva en este encuentro. La dificultad procede de los tableros y de combinar técnicas conocidas.

Cada fase completada queda guardada. Pausar, salir o necesitar más de una sesión permite retomar el mismo tablero y la misma fase. Cualquier límite general de vidas de mundos futuros debe admitir reintentar la fase pendiente conservando las ya completadas.

### Victoria y recompensas

- Completar cada fase entrega su estrella y 20 XP, una sola vez.
- Completar la tercera entrega también los 40 XP de cierre del nivel: total de campaña, 5.000 XP.
- Se obtiene la Medalla del Camino y el rango Maestro del Camino.
- Se desbloquean el epílogo, las revanchas y una selección de retos de los maestros.

Numa reconoce la victoria con las mismas palabras aunque el jugador haya usado ayudas. Las revanchas pueden ofrecer marcas opcionales de puntaje, tiempo o autonomía, con sus condiciones explicadas al comenzar y registradas por separado.

## 8. Ejemplo de los diez niveles del valle

Este desglose conserva los nombres existentes y propone su función narrativa.

| Nivel | Nombre actual | Función en la historia |
|---:|---|---|
| 1 | La entrada del valle | Invitación de Numa y primera experiencia con el tablero. |
| 2 | Los primeros pasos | Tilo acompaña las primeras partidas fuera del tutorial. |
| 3 | La curva dorada | Elegir una zona casi completa para empezar. |
| 4 | Junto a la cerca | Practicar la observación de filas y columnas. |
| 5 | A la sombra del roble | Encuentro breve: aprender a detenerse y revisar. |
| 6 | Las piedras del camino | Relacionar las restricciones básicas de una casilla. |
| 7 | La subida soleada | Reconocer ubicaciones únicas en situaciones sencillas. |
| 8 | El recodo del valle | Cambiar de zona cuando una casilla no ofrece una deducción clara. |
| 9 | El último tramo | Entrenamiento con menos intervención de Tilo. |
| 10 | El mirador del sol | Tres pruebas de Tilo, primer sello y apertura del bosque. |

Al cerrar el valle, el jugador tiene 30 estrellas, 1.000 XP y el Sello de la Observación. La introducción de notas ocurre al comenzar el mundo 2.

## 9. Persistencia y alcance de implementación

La futura implementación necesita guardar experiencia concedida por sudoku y nivel, lecciones iniciadas y completadas, herramientas habilitadas, sellos, escenas vistas y fase de los encuentros. Reabrir un resumen, repetir una animación o completar de nuevo una partida no vuelve a conceder XP.

Para partidas guardadas anteriores a este sistema, se propone calcular una única vez la experiencia correspondiente a sudokus y niveles ya completados. La migración debe registrar esos premios como concedidos y preservar los resultados existentes. Las herramientas conservan sus condiciones de enseñanza.

El primer paso de producción puede limitarse al prólogo, los diálogos de Tilo y el cierre del valle. El bosque introduce después el primer desbloqueo jugable: las notas. La campaña completa y sus valores de experiencia siguen siendo una propuesta de diseño que se ajustará al probar el ritmo de aprendizaje.
