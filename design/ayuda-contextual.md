# Ayuda contextual y aprendizaje progresivo

## Decisión confirmada

- Las notas (anotaciones de posibles números dentro de una casilla) se introducirán en el próximo mundo, Mundo 2. No enseñarlas ni incorporarlas como herramienta del Mundo 1.

## Propuesta para revisar, sin implementar

- Botón de ayuda disponible al seleccionar una casilla, vacía, fija o completada por el jugador.
- Analizar el tablero visible y ofrecer una explicación lógica de qué mirar; no revelar la solución sin justificarla.
- Atenuar el tablero salvo las casillas y grupos relevantes. Mostrar el mensaje debajo de la botonera de números, con desplazamiento si fuera necesario.
- Dar una sola pista breve por vez. Priorizar errores que invaliden la deducción, luego el grupo con una sola casilla vacía y después deducciones por descarte o por ubicación única.
- Distinguir un valor que no genera repeticiones de un valor cuya corrección puede demostrarse.
- Si la selección no tiene una deducción sencilla, ofrecer otra casilla útil sin mover la selección automáticamente ni recomendar adivinar.
- Contemplar casillas fijas, valores ingresados, conflictos por repetición, falta de candidatos, deducciones simples, ausencia de una pista sencilla y tablero completo.
- Mensajes y comportamiento concretos pendientes de revisión con el usuario.

## Implementación inicial

- `lib/domain/help/sudoku_help.dart`: motor sin dependencias de Flutter. Recibe únicamente el tablero visible, la selección y las pistas fijas, nunca la solución. Recorre `SudokuHelpRule` en orden y usa la primera coincidencia.
- Cada regla devuelve `SudokuHelpTip` con un identificador, un mensaje y `focusIndices`. Para añadir un caso, implementar `evaluate` y registrarlo en `SudokuHelpEngine.rules`; no cambiar el panel ni los controles.
- Primera regla: `LastEmptyBlockRule`. Selección vacía, ocho números distintos en su bloque y sin contradicciones visibles en la fila o columna implicadas. Ilumina el bloque y pregunta qué falta sin revelar el número.
- Las selecciones sin una regla aplicable reciben una explicación neutral, sin oscurecer el tablero ni afirmar que una respuesta es correcta.
- El botón se habilita únicamente al seleccionar una casilla vacía durante el juego. Las casillas con números fijos o ingresados mantienen la ayuda deshabilitada; al borrar un número vuelve a habilitarse. La ayuda se cierra con su botón, al cambiar de selección, editar o dejar el juego; no modifica números ni progreso.
- El panel usa `UiSurface.goldCreamPanel`, el botón usa las superficies compartidas y el texto se dibuja con `Text`. El foco se calcula con las mismas medidas que el tablero y atenúa con un tono cálido. Se conserva el scroll en pantallas pequeñas y se respeta movimiento reducido.

## Reglas añadidas

Orden de prioridad del motor:

1. Tablero completo y válido: felicitación con todo el tablero visible.
2. Repeticiones en los grupos de la selección: revisar las fichas colocadas; las pistas fijas no se presentan como editables.
3. Casilla vacía sin posibilidades: revisar las zonas implicadas, sin culpar a una ficha sin pruebas.
4. Número fijo: explicar su función e iluminar sus grupos y los números iguales.
5. Último hueco de un bloque, una fila o una columna, en ese orden.
6. Única posibilidad al combinar fila, columna y bloque.
7. Único lugar para un número dentro de un bloque, una fila o una columna. El foco incluye el grupo y las zonas que descartan otros huecos.
8. Número ingresado: retirar virtualmente el valor y buscar una justificación con las reglas anteriores. Si no existe, indicar únicamente que no se repite, sin certificar su corrección.
9. Otra zona sencilla: proponer un grupo con un hueco, buscando primero cerca de la selección. No cambia la selección ni coloca números.
10. Sin deducción sencilla: invitar a revisar otra casilla, sin adivinar.

`deducedValue` conserva la conclusión lógica para verificar reglas y justificar fichas ya colocadas. El panel no lo muestra automáticamente ni lo ingresa. Los mensajes de ubicación única sí mencionan el número cuya ubicación se está investigando y explican por qué se descartan otros lugares. Las demás pistas de casillas vacías invitan a descubrirlo.

## Resaltado de números mencionados

- `SudokuHelpTip.emphasizedNumber` identifica el número que el mensaje menciona explícitamente: ubicación única en bloque/fila/columna, repetición, pista fija y revisión de números ingresados.
- El tablero reutiliza la animación y el color de coincidencias para todas sus apariciones, incluso cuando la selección está vacía. Esas fichas quedan visibles fuera de las zonas atenuadas. Cambiar de ayuda o cerrarla actualiza/restaura el resaltado.
- No derivar el resaltado de `deducedValue`: las preguntas sobre el número que falta y las deducciones por descarte deben seguir permitiendo descubrir la respuesta.
- El panel de ayuda mantiene texto centrado y no incluye X; la bombilla permite cerrarlo.

## Conexiones animadas

- Los bloques 3×3 no se recorren con una línea: sus nueve fichas dan juntas un saltito suave de 380 ms. Las filas y columnas conservan sus trazos.

- Cada regla puede aportar `traces` (recorridos por índices del tablero) y `arrivalIndex` (casilla que recibe el pulso final). `sudoku_help_motion.dart` ofrece conexiones dentro de un grupo y recorridos para filas, columnas y bloques; no dibuja relaciones diagonales.
- Ubicación única: los trazos parten de los números que bloquean otros huecos y llegan a esos huecos descartados. Al terminar, pulsa la casilla disponible. No se dibuja una conexión falsa entre un número y una casilla donde ese mismo número sí puede ir.
- Último hueco y descarte: recorridos por los grupos relevantes hacia la selección. Repeticiones: conexiones entre las coincidencias. Pistas fijas: recorridos desde el número hacia sus grupos. Otra zona sencilla: recorrido local hacia su hueco, sin mover la selección.
- La capa `SudokuHelpTrails` usa las posiciones reales del tablero. Los trazos cálidos se dibujan por turnos, se desvanecen y dejan el resaltado original. La animación no bloquea entradas ni modifica el progreso.
- Cerrar o cambiar la ayuda cancela los trazos; abrirla de nuevo permite repetirlos. Cambiar el tamaño o reconstruir el mismo contenido no reinicia la animación. Con movimiento reducido se conserva solo el foco estático.
