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

## Formato compartido de los tutoriales

Referencia vigente para nuevos tutoriales y sus agregados: «Reglas del sudoku». Aplicado también a «El lápiz de las ideas».

- **Títulos por paso:** una frase concreta para cada explicación, dentro de `TutorialLessonTitle`. Usa la misma superficie crema y dorada, márgenes y letra que reglas: Baloo 2, azul `#082A62`, peso 800, 22 px (18 px con texto ampliado). El progreso segmentado va encima. No sustituir los títulos por el nombre genérico del tutorial y un contador.
- **Explicaciones:** reutilizar `TutorialLessonCard`, con Baloo 2 de 20 px, peso 800, azul `#082A62`, interlineado 1,3 y alineación centrada. Conserva el panel, padding y escritura de `TutorialStory`. El límite de ancho se comparte en `GameLayout.maxTutorialTextWidth` (470 px). No reducir la letra, el peso o el padding para hacer caber una lección nueva; permitir desplazamiento central cuando haga falta.
- **Orden en anotaciones:** progreso y título arriba; tablero, controles de demostración y explicación debajo; «Siguiente» y «Saltar tutorial» abajo, dentro de `SafeArea`. La explicación continúa debajo en horizontal.
- **Navegación:** las lecciones no añaden los botones de Volver, Pausa o Configuración de la partida o del mapa. Conservar la navegación de historias por gestos/teclado y la acción explícita para saltar el tutorial.
- **Siguiente en dos pulsaciones:** si quedan entrada, escritura o demostración pendientes, la primera pulsación las completa en el paso actual. No guarda otro paso ni abre la práctica. La siguiente pulsación avanza. Esto se aplica también a «Practicar» y «Terminar repaso» al final. Una pulsación con todo completo avanza directamente; no exigir siempre dos.
- **Avance automático en todos los tutoriales:** reglas, anotaciones y desafíos comparten `TutorialAutoAdvance`. Cada paso espera el final real de la escritura y de la demostración, más dos segundos de lectura. Con movimiento reducido se añade el tiempo de lectura del texto que aparece de golpe. Cuando el jugador usa «Siguiente» para completar una animación, ese paso espera otra pulsación y cancela su avance automático pendiente. La última explicación siempre espera una acción para abrir la práctica o terminar el repaso. Al volver a un paso se reinicia su pausa; una ruta cubierta, la app en segundo plano o Playables en pausa suspenden el avance. Con navegación accesible el avance es manual.
- **Continuidad:** conservar el tablero, las casillas sin cambios y los controles de una misma escena. No volver a ejecutar su aparición ni cambiar claves por cada explicación. Reservar el espacio del texto para que su longitud no mueva ni redimensione el tablero. Animar solo los cambios didácticos.
- **Accesibilidad y estado:** respetar texto ampliado, movimiento reducido, suspensión de la app y redimensionado. Los botones inferiores deben permanecer accesibles. Las animaciones no modifican partidas, puntos, estrellas ni el progreso guardado; el repaso no escribe sobre una partida.

Estas pautas prevalecen sobre las propuestas históricas de los mundos. Reusar los componentes compartidos también al agregar títulos, explicaciones, controles o pasos nuevos.

## Validación reproducible

`test/domain/tutorial_sudokus_test.dart` comprueba cuarenta órdenes del bloque, solución única con un solucionador independiente y deducciones de un solo grupo hasta completar los tres tableros.

`test/controllers/tutorial_journey_test.dart` cubre las seis historias, retroceso, conservación del borrador, migraciones, vista previa, reducción de ayuda, reanudación, escritura fallida y recompensas.

`test/tutorial_journey_widget_test.dart` verifica avance automático de las explicaciones, espera explícita antes de jugar, gestos y teclado en navegación accesible, los tres sudokus sobre el mismo tablero, navegación final, tamaños compactos, horizontal y texto al doble. `test/widgets/tutorial_presentation_test.dart` cubre la pausa compartida, cancelación y suspensión del avance. `TUTORIAL_CAPTURE_DIR` guarda capturas del render de Flutter con datos de prueba; no son capturas tomadas en un teléfono ni modifican su progreso.
