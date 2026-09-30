# Sistema de escenas de aventura

> **Archivado para SunDoku 2.0 (19/09/2026).** Este documento describe el diseño o prototipo anterior. La versión 1.0 mantiene el juego simple: tutorial, sudokus, celebraciones y mapa, sin escenas narrativas. El código del prototipo se conserva como referencia en `prototipo-2.0/`, fuera de la aplicación.

Primera versión implementada: escenas posteriores a las treinta victorias del valle. La nueva apertura, las lecciones de Tilo, el cuaderno y los premios de experiencia pertenecen a los siguientes pasos de [la lista de tareas](tareas.md).

## Recorrido

1. El jugador completa el sudoku. La victoria, la estrella y la escena pendiente se guardan juntas.
2. Aparece la celebración existente; en la tercera partida incluye el resumen del nivel.
3. «Continuar» abre la escena. Las tarjetas avanzan manualmente, permiten regresar a la anterior y conservan la página al salir.
4. «Omitir historia» cierra el diálogo y continúa el recorrido sin modificar los premios.
5. Después de las partidas 1 y 2 se abre el siguiente sudoku. Después de la tercera se puede elegir el siguiente nivel o el mapa. El nivel 10 termina en el mapa.

«Continuar aventura» recupera una escena pendiente. Si la lectura todavía no empezó, se muestra primero la celebración guardada; si ya empezó, se abre la tarjeta donde quedó. El mapa también permite retomar la escena del nivel seleccionado aunque exista otra pendiente en un nivel posterior.

Las escenas leídas u omitidas no reaparecen al repetir normalmente el nivel. Los guardados antiguos conservan su progreso y no generan escenas retrospectivas al abrirse. La relectura en el cuaderno se implementará con ese acceso. Partida rápida no genera escenas.

## Presentación provisional

Se reutiliza `assets/images/home-background.png` como imagen estática, junto con `UiSurfacePanel`, `TutorialStoryProgress`, `MapIcon` e `IllustratedActionButton`. Los diálogos y las etiquetas son widgets `Text`.

Cada escena define su fondo por separado para poder cambiar el arte después. El contenido central tiene desplazamiento cuando falta altura; la navegación permanece arriba y las acciones abajo, dentro de `SafeArea`.

## Probar cinemáticas con DEV

**Desde el mapa:** seleccionar un nivel desbloqueado → abrir DEV → «Nivel N: completar menos 1» → elegir la partida 1, 2 o 3. Se abre un intento de prueba con esa partida a una casilla de completarse. Las partidas anteriores de ese intento quedan completadas; las posteriores empiezan vacías. Completar la casilla activa la victoria real y su escena.

Esta acción reinicia el registro de escenas de ese nivel para poder repetir la prueba. Conserva los mejores resultados existentes y registra las estrellas previas necesarias para llegar a la partida elegida.

**Dentro del nivel:** DEV → «Completar menos 1» rellena el tablero actual y deja una casilla editable. Permite probar la próxima victoria mientras se recorre el nivel.

## Organización

- `lib/data/adventure_scene_catalog.dart`: guion, títulos e identificadores estables por nivel y partida.
- `lib/domain/models/adventure_scene.dart`: escena, diálogos y progreso de lectura.
- `lib/data/repositories/game_repository.dart`: guardado transaccional, reanudación y preparación DEV.
- `lib/controllers/adventure_scene_controller.dart`: avance, retroceso, omisión y recuperación ante errores al guardar.
- `lib/screens/adventure_scene_screen.dart`: composición responsive de las tarjetas.

El módulo de guardado `adventureStory` almacena versión, identificador de intento, página y estado (`pending`, `reading`, `read` o `skipped`). La lectura no otorga puntos ni estrellas. El sello mencionado al final del valle todavía es narrativo; su registro como premio pertenece al sistema de progresión.

## Verificación

Las 23 pruebas de escenas, guardado y niveles generados pasan. Cubren errores de escritura, reanudación, omisión, repetición sin premios duplicados, separación de partida rápida, acceso DEV, salida al mapa y continuidad al siguiente nivel. Se revisó la pantalla en 390×844, 320×568, 844×390 y 1024×768, incluyendo texto ampliado.

Análisis estático sin errores y hot reload completado en la app conectada. La ejecución de la suite completa terminó con 229 pruebas aprobadas y siete fallos de ayudas, geometría y navegación. Los siete fallos se reprodujeron en una copia temporal con las cinemáticas desactivadas: selección de ayuda, foco del mapa tras cinco niveles, separación del teclado en escritorio, dos comparaciones exactas de rectángulos animados, posición del tablero antes del briefing y ubicación del encabezado. La reanudación independiente por nivel y las dos regresiones de transiciones están incluidas en las 23 pruebas focalizadas posteriores.

La vuelta animada de una cinemática en iOS podía lanzar `RenderBox was not laid out`: el vuelo del tablero consultaba coordenadas globales durante la reconstrucción de una transformación de la ruta. Los vuelos ahora usan coordenadas locales del contenedor del juego y sus builders no consultan la geometría de la ruta. La prueba de iOS reprodujo el error antes del cambio y pasa después, junto con Android, incluyendo rotación durante la entrada del segundo y tercer sudoku. Las tres pruebas de celebración existentes también pasan; las dos comparaciones exactas de rectángulos conservan su fallo previo.
