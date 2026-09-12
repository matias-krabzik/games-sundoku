# Primera experiencia implementada

El nivel 1 se juega dentro de `FirstExperienceScreen`, sin cambiar de ruta entre historias y sudokus. Se reutilizan el fondo, Doku, los destellos, el pincel, las estrellas y las superficies nine-patch existentes. Todos los títulos, números y mensajes son texto de Flutter.

## Seis historias, al ritmo del jugador

La introducción explica una idea breve por historia. No exige completar ejercicios ni avanza con un temporizador. El progreso segmentado indica la historia actual.

| Historia | Explicación o acción |
| --- | --- |
| 1. Bienvenida | Doku aparece, se escribe la historia y aparece el consejo. «Siguiente» está disponible desde el principio. Al volver, la bienvenida se muestra completa. |
| 2. Un bloque | Un ejemplo completo muestra los números del 1 al 9, una vez cada uno. «Elegir el orden» abre el editor opcional. |
| 3. El tablero completo | El bloque queda en el centro; se explica que hay nueve bloques sin repeticiones. |
| 4. Las filas | El tablero real ilumina una fila de lado a lado y explica que sus números no se repiten. |
| 5. Las columnas | El mismo tablero ilumina una columna de arriba abajo, con la misma regla. |
| 6. Las pistas | Una vista previa del primer sudoku distingue las pistas de las casillas vacías. «Jugar» crea la sesión y empieza la guía. |

Se puede avanzar con «Siguiente», tocar el lado derecho o deslizar hacia la izquierda. Tocar el lado izquierdo o deslizar hacia la derecha vuelve a la historia anterior. El teclado permite usar las flechas izquierda/derecha y Espacio para avanzar; el lector de pantalla dispone de acciones equivalentes. Esperar o desplazar verticalmente el contenido no cambia de historia.

El bloque de ejemplo completa únicamente los huecos del borrador con los dígitos que faltan, respetando los números ya elegidos. El editor conserva la selección aleatoria de casillas vacías y permite salir con «Volver a la historia» sin completar las nueve. Avanzar desde la historia del bloque guarda su orden completo.

Tras resolver el primer y el segundo sudoku, la celebración lleva directamente a la siguiente partida. El tercero lleva al estado final: tres estrellas, nivel 2 disponible y acciones para volver al mapa o repasar las reglas.

## Ayuda que disminuye

- **Sudoku 1, seis huecos:** primero una fila, después una columna y después un bloque. En esos tres movimientos Doku explica qué número falta y espera «Seguir» después del acierto. En los restantes destaca qué mirar y deja encontrar la respuesta.
- **Sudoku 2, doce huecos:** el jugador elige la casilla. «Pista» señala un grupo con un único hueco; «Ver el número» explica cuál falta. Pedir ayuda nunca escribe la respuesta automáticamente.
- **Sudoku 3, dieciocho huecos:** mantiene esa ayuda opcional, con más casillas por completar. Se ajustaron cuatro posiciones de las pistas respecto de la lámina conceptual para que todas las ayudas se puedan resolver mirando un solo grupo.

Los tres tableros tienen solución única. Sus dígitos se renombran según el bloque del ejemplo o el orden elegido en el editor; ese bloque permanece idéntico en las tres partidas. Los errores señalan una repetición visible y no quitan estrellas. Las ayudas se calculan a partir de las casillas actuales.

## Guardado y presentación

- Las historias y el borrador guardan su paso. Los guardados de las antiguas lecciones se retoman en su historia equivalente, sin prácticas obligatorias; las introducciones antiguas de las partidas 2 y 3 retoman el juego.
- Solo «Jugar» en la sexta historia crea los tres sudokus, la sesión y su vínculo con el tutorial, en una operación. Una escritura fallida permite reintentar sin duplicar sesiones.
- Las partidas usan `GameSessionController` y `GameRepository`, incluido tiempo activo y reanudación. La guía durante el juego conserva su comportamiento anterior.
- Las estrellas se entregan al completar de verdad cada sudoku. La celebración se reconstruye desde ese resultado si se cierra la app antes de avanzar.
- Repasar las reglas conserva el bloque y las estrellas; no crea otra sesión.
- El tablero conserva su elemento Flutter al cambiar de paso o al girar la pantalla. Las pistas son inmutables; los números puestos por el jugador llevan una pequeña marca inferior.
- Los resaltados recorren las casillas una vez. Las animaciones nunca bloquean «Siguiente». Con movimiento reducido o navegación accesible, el contenido se muestra directamente.
- En pantallas pequeñas o con letra grande el contenido central se puede desplazar. El encabezado y la acción inferior permanecen en sus zonas seguras.

## Validación reproducible

`test/domain/tutorial_sudokus_test.dart` comprueba cuarenta órdenes del bloque, solución única con un solucionador independiente y deducciones de un solo grupo hasta completar los tres tableros.

`test/controllers/tutorial_journey_test.dart` cubre las seis historias, retroceso, conservación del borrador, migraciones, vista previa, reducción de ayuda, reanudación, escritura fallida y recompensas.

`test/tutorial_journey_widget_test.dart` verifica gestos y teclado, ausencia de avance automático, los tres sudokus sobre el mismo tablero, navegación final, tamaños compactos, horizontal y texto al doble. `TUTORIAL_CAPTURE_DIR` guarda capturas del render de Flutter con datos de prueba; no son capturas tomadas en un teléfono ni modifican su progreso.
