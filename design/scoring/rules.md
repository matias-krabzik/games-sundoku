# Puntaje y resumen

- Aciertos nuevos de cada ronda: 11, 11, 17, 17 y 23 desde el quinto.
- Un error reinicia la racha sin quitar puntos. Esperar, pausar, borrar y tomar notas no la reinician. Borrar y reingresar una respuesta ya premiada no aumenta la racha.
- Completar fila o columna: 53; bloque: 79; tablero: 307. Los premios simultáneos se suman.
- Todo premio se multiplica según la dificultad del sudoku: fácil/introducción ×1, normal ×3, medio ×5, difícil ×7 y extremo ×11. El catálogo actual conserva sus dificultades existentes.
- Cada ayuda solicitada resta 77, sin multiplicador y con mínimo cero por ronda. Cerrar la ayuda es gratis. Tanto las ayudas que rellenan como las explicaciones marcan la casilla asistida: resolverla no suma ni aumenta la racha y no da los premios de las zonas que completa. Tampoco da el premio de tablero si es la última casilla.
- Casillas y zonas se registran una sola vez, incluso si luego se borran. La racha y el historial se guardan junto con los puntos de la ronda. Los guardados anteriores empiezan a puntuar desde su estado actual, sin puntos retroactivos.
- La barra muestra el puntaje de la ronda entre vidas y tiempo. Cada cambio muestra el importe total ganado o descontado junto a la jugada, subiendo y desapareciendo en un segundo; se omite el movimiento si el sistema solicita reducir animaciones.
- El resumen de nivel muestra Ronda, Puntos y Tiempo, más sus totales. No tiene scroll. Oculta primero a Doku y reduce u oculta las miniaturas si falta altura, manteniendo visibles resultados y acciones.
- Mapa! vuelve a la ruta anterior; Siguiente nivel X abre directamente el siguiente nivel pendiente y desbloqueado. Al terminar el nivel 10 solo queda Mapa!.
- Las sesiones heredadas mantienen su desbloqueo por tres rondas resueltas, incluso con cero puntos. Cada nivel conserva su mejor resultado completo; los reintentos no duplican el total histórico. Las nuevas reglas del mundo 3 se distinguen explícitamente por sesión.


## Mundo 3: desafíos y resultado animado (W3-03–05)

W3-01/02 implementan la política `world3-challenge-v1` y su guardado. W3-03 activa
las sesiones nuevas en la app con vidas, meta, cuenta regresiva y reintento.
La fórmula global de recompensas no cambia.
Las sesiones anteriores conservan sus reglas durante las tres rondas; los mundos
1, 2 y la partida rápida también mantienen el modo anterior.

Cada sudoku nuevo del mundo 3 guarda una referencia perfecta calculada desde sus
vacíos y grupos inicialmente incompletos, una meta progresiva del 85 al 100 %,
3/2/1 vidas por tramo de diez niveles y un plazo de 120 s + 30 s por vacío
(actualmente 21 minutos). Se gana resolviendo antes del límite, con vidas y meta
alcanzada. El nivel 30 exige además cero errores y cero pistas; sus ayudas se
rechazan antes de cobrar puntos. No hay bonus por rapidez.

Resolver debajo de la meta o agotar vidas/tiempo guarda un resultado fallido sin
estrella. Reintentar genera un sudoku distinto de la misma dificultad, recalibra su meta
y renueva vidas y tiempo; no acumula puntos de intentos fallidos. Reabrir una
partida conserva el tablero del intento guardado. La victoria se confirma al guardar, antes de cualquier contador
visual, y reconocer su presentación no vuelve a premiar.

[Calibración](../world-3-crossed-rivers/gameplay-specs/calibration/README.md) ·
[Persistencia y pruebas](../world-3-crossed-rivers/gameplay-specs/persistence/README.md).

[Flujo visible y capturas](../world-3-crossed-rivers/gameplay-specs/gameplay/README.md).

El contador de resultado representa el premio ya persistido: no calcula ni otorga
estrellas. Una pulsación completa la animación y otra continúa. Al salir al mapa
tras la primera o segunda victoria queda lista la ronda siguiente, sin activar
el reloj. Al entrar ofrece «Jugar» si es nueva o «Continuar» si ya empezó.
