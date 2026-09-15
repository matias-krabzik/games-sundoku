# Niveles 2–10: Valle del Sol

Cada nivel contiene tres sudokus fáciles y se desbloquea con las tres estrellas del anterior. Solo el nivel 1 permite repetir una partida completada. Vidas y ayudas siguen siendo ilimitadas durante los diez primeros niveles.

## Generación y guardado

`SeededSudokus` usa una seed por jugador, nivel y sudoku (el identificador del jugador es un UUID aleatorio). El generador `easy-singles-v1` tiene un PRNG estable entre plataformas. Construye una solución aleatoria y retira hasta 38 fichas, aceptando cada retiro únicamente cuando el tablero todavía puede resolverse con candidatos únicos o posiciones únicas. Estas deducciones forzadas garantizan solución única y no requieren notas ni adivinar.

La primera apertura guarda las tres definiciones completas, sus seeds y la partida en una sola operación. Al retomar se usan las definiciones guardadas, sin regenerarlas, incluso si más adelante se incorpora otra versión del generador. Cada entrada, borrado, ayuda utilizada y selección se guarda. El tablero y sus animaciones reutilizan el flujo de juego existente; el módulo de cada nivel está separado del tutorial.

## Tiempo y pausa

Cada sudoku tiene su propio reloj. Solo cuenta juego activo: se detiene en pausa, al abrir ajustes, al salir del juego, al pasar la app a segundo plano y al completar un tablero. La siguiente partida empieza a contar cuando termina la animación de entrada. El tiempo se guarda con cada movimiento, al pausar y mediante un checkpoint cada segundo. El cierre solicitado por el sistema espera el guardado; una terminación forzada puede perder como máximo el intervalo de reloj aún no guardado, sin alterar movimientos ya confirmados.

La pausa desenfoca el tablero, desactiva números y ayudas y muestra «Continuar». Una partida que ya había comenzado se abre pausada. Volver a primer plano no la reanuda automáticamente. El resumen final usa una tabla de widgets Flutter: tres filas con estrellas y tiempos alineados, encabezados «Sudoku» y «Tiempo», y una franja dorada con el tiempo total. Reutiliza la superficie `goldCreamPanel` y las estrellas del mapa, conservando el fade de la celebración. Los valores se calculan desde los milisegundos guardados; no forman parte de una imagen.

## Verificación

- 100 seeds: reproducibilidad, variedad, 38 huecos, resolución con reglas básicas y solución única comprobada con un segundo solver independiente.
- Completar los 27 sudokus de los niveles 2–10, desbloqueos y rechazo de repetición.
- Reabrir el guardado conservando fichas, errores, selección, seed, ayudas y tiempos.
- Pausa, ciclo de vida, escrituras fallidas y cierre de la app.
- UI móvil y escritorio, redimensionado, navegación, transiciones de victoria y resumen.

Las capturas se generan ejecutando `TUTORIAL_CAPTURE_DIR=/tmp/sundoku-generated-levels flutter test test/generated_game_widget_test.dart`.
