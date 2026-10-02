# Tutorial de anotaciones y textos

Estado: propuesta didáctica. Reglas de la herramienta: [01 · Producto](01-producto.md).

La interacción y la presentación de esta propuesta son históricas. La implementación actual usa demostraciones automáticas, títulos por paso y el formato compartido de reglas, con «Siguiente» que primero completa la animación. Consultar las [pautas vigentes de los tutoriales](../first-experience/implementacion.md#formato-compartido-de-los-tutoriales) antes de modificar o añadir UI.

## Ubicación y duración

La explicación comienza al entrar por primera vez al Bosque de Otoño, antes del juego 1. Después el jugador practica con el lápiz durante las tres rondas de ese juego. Al ganarlo se anuncia el desbloqueo permanente.

Se propone un tablero didáctico separado, construido con la UI real y resaltados interactivos. El jugador realiza las acciones; al terminar toca «Practicar» para empezar la primera ronda del juego 1. Las notas y valores de la demostración pertenecen a su copia de práctica y no se trasladan al sudoku del nivel. Esta separación permite enseñar antes del primer juego sin regalar puntos ni estrellas.

Objetivo de duración orientativo: 60–120 segundos a ritmo del jugador. El texto aparece escribiéndose; nunca avanza automáticamente por tiempo. Las frases propuestas deben comprobarse sobre el tablero finalmente seleccionado.

## Tablero preparado

El tablero didáctico usa una definición fija, versionada y validada antes de integrar el tutorial. Para describir el guion llamamos **A** a la casilla que admite 2 o 7 y **B** a otra casilla de su fila donde se puede deducir un 7. Esas letras no aparecen en la UI.

Requisitos verificables del contenido:

- A está vacía, es editable y sus candidatos legales son exactamente `{2, 7}` al inicio.
- B está vacía en la misma fila, es distinta de A y su 7 puede deducirse con una regla ya aprendida. No basta con que la solución guardada contenga un 7 allí.
- El guion explica esa deducción resaltando las pistas concretas que la justifican.
- Tras escribir el 7 en B, A solo admite el 2. El tutorial puede eliminar la nota 7 y escribir el 2 sin alterar ninguna pista fija.
- El sudoku tiene solución única y respeta las técnicas del tramo inicial. No es necesario completarlo para terminar la lección; basta realizar la secuencia enseñada.
- Guardar A, B, unidades y pistas resaltadas como metadatos del contenido. No buscarlas al azar durante la presentación.
- Las acciones del guion y el análisis de candidatos deben validarse juntos. Si se transforma el tablero, se transforman también las referencias y los textos; para la primera entrega se mantiene una variante fija.

Estas son condiciones de autoría, no la afirmación de que el tablero ya exista en el repositorio.

## Pasos de la primera ejecución

| Paso | Texto propuesto | Acción y señal visual | Cuándo puede avanzar |
| --- | --- | --- | --- |
| 1 · Observar | «Mira esta casilla. Aquí podrían ir un 2 o un 7. Todavía no sabemos cuál elegir.» | Resaltar A y mostrar sus relaciones con fila, columna y bloque, sin destapar la respuesta. | Texto y resaltado terminados. |
| 2 · Activar | «¡Vamos a recordarlos! Toca el lápiz para hacer anotaciones.» | Destacar el lápiz. El jugador lo activa. | Texto terminado y lápiz activo. |
| 3 · Guardar | «Toca el 2 y el 7. Los números pequeños guardan tus posibilidades.» | A permanece seleccionada. Ambos números aparecen en sus posiciones pequeñas. | A contiene las dos notas. Pulsaciones repetidas alternan notas normalmente. |
| 4 · Diferenciar | «Son anotaciones, no respuestas. Apaga el lápiz para escribir números grandes.» | Destacar el lápiz y el cambio de estado. | Lápiz desactivado. |
| 5 · Encontrar una pista | «Mira esta otra casilla. [Explicación breve de la deducción real.] Aquí va el 7. Colócalo.» | Seleccionar B y resaltar las pistas necesarias. El texto final reemplaza el fragmento entre corchetes. | El 7 de B está guardado. |
| 6 · Revisar | «¡Ya hay un 7 en esta fila! No puede ir otro en nuestra casilla. Activa el lápiz y toca su 7 para quitarlo.» | Volver a A, señalar B y la fila. El jugador activa el lápiz y quita la nota 7. | A conserva solo la nota 2. |
| 7 · Confirmar | «¡Nos queda el 2! Apaga el lápiz y coloca tu respuesta.» | El jugador vuelve al modo respuesta y escribe 2 en A. | A contiene el valor 2 y ninguna nota. |
| 8 · Practicar | «¡Ya sabes usar el lápiz! Ahora practiquemos en el primer juego. Al completarlo, podrás usar tus anotaciones cuando quieras.» | Retirar resaltados didácticos. Presentar el paso al juego 1. | Botón «Practicar». Guarda tutorial completado y abre la primera ronda. |

El paso 5 es el único texto pendiente del tablero concreto. No se publicará con corchetes ni se sustituirá por «porque sabemos la respuesta».

## Avance y errores

- Primera ejecución: bloquear «Siguiente» mientras se escribe o se anima y mientras falte la acción del paso. Su estado deshabilitado debe verse claramente.
- Los pasos de acción habilitan únicamente las casillas y controles pertinentes. Los toques fuera de ellos no consumen ayudas ni errores; el juego recuerda brevemente la acción esperada.
- Home/Volver y Ajustes permanecen accesibles: el tutorial puede interrumpirse y retomarse.
- No exigir velocidad, precisión de un gesto de arrastre ni sonido para avanzar.
- Con movimiento reducido, mostrar resaltados estáticos y texto completo; conservar solamente las condiciones de la acción.
- El texto siempre tiene padding. La zona principal se centra sobre el tablero y los botones de acción quedan abajo, dentro de `SafeArea`.
- No añadir chispas a los títulos ni indicaciones genéricas para tocar los lados de la pantalla.

## Tiempo, puntos y guardado

- El tablero didáctico no tiene cronómetro competitivo, puntos ni estrellas. El reloj normal empieza al entrar en la primera ronda del juego 1.
- Las notas nunca puntúan. Las colocaciones del tutorial tampoco otorgan premios, consumen ayudas ni alteran rachas de una partida real.
- El tutorial no cuenta entre las 63 rondas. Se producen 63 sudokus puntuables y una definición didáctica adicional. Las tres rondas del juego 1 sí conceden sus estrellas normalmente.
- Guardar paso estable, selección, modo lápiz y cambios en la copia del tablero didáctico. El paso que depende de una edición se confirma junto con esa edición; no guardar que se avanzó si la escritura falló.
- Al retomar, reconstruir los resaltados a partir del paso y verificar su condición contra el tablero guardado. Si la acción ya está hecha, permitir continuar sin repetirla.
- Se permite reiniciar la explicación en su copia de práctica; no se modifica una sesión del juego 1. Si se sale después de terminar el tutorial y antes de comenzar el juego, queda el juego 1 disponible sin repetir la explicación.
- Una falla de guardado muestra «No pudimos guardar. Toca Reintentar» y conserva el último estado confirmado. No marca el tutorial como completado.

## Agenda y repaso

La agenda reúne «Reglas del sudoku» y «Anotaciones». El segundo tema se habilita al terminar el tutorial de entrada, para poder repasarlo durante el primer juego. Antes de completar ese juego se indica que el lápiz está disponible allí para practicar.

El repaso de anotaciones usa otra copia aislada del tablero de ejemplo, sin puntos, estrellas ni escrituras sobre una partida real. Permite anterior/siguiente y saltar las esperas de animación. Completar el repaso no concede el desbloqueo permanente ni cambia las estrellas del primer juego.

Después de completar el tutorial obligatorio, reabrir el juego no lo repite. La agenda siempre permite consultarlo.

## Recordatorios posteriores

Usar como máximo una intervención breve al introducir un objetivo nuevo. El resto se enseña mediante el diseño del sudoku.

- Juego 4: «Si cambias de idea, toca otra vez una anotación para quitarla.»
- Juego 6: «Encontraste otro número. Revisa si cambia alguna de tus posibilidades.»
- Juego 8: «Mira también las columnas: allí tampoco se repiten números.»
- Juego 9: «Recuerda revisar el bloque de 3 × 3.»
- Juego 13: «Las anotaciones te ayudan a recordar. Comprueba la fila, la columna y el bloque antes de elegir.»

Los recordatorios tienen cierre claro y no deben encadenarse encima de la celebración de una ronda.
