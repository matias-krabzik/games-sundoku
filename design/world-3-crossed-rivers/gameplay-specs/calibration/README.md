# Calibración W3-01

Reglas `world3-challenge-v1` · puntaje `sudoku-scoring-v1`.
270 tableros (3 perfiles sintéticos × 30 niveles × 3 rondas), con solución única
verificada por backtracking independiente y regeneración idéntica por seed.
3510 simulaciones usan el motor real de puntaje.
El simulador detiene las entradas ante un resultado terminal.

## Curva y resultados

P = referencia perfecta; meta = techo(P × proporción), limitada a P−1 antes del
nivel 30. El 30 requiere P, cero errores y cero pistas. No hay bonus de tiempo.
Todos los tableros actuales tienen 38 vacíos: límite inicial de **21 minutos de
tiempo activo por ronda** (2 minutos + 30 segundos por vacío). Al llegar a cero
se pierde el intento, incluso con puntaje suficiente. Pausa y segundo plano no
deben consumir tiempo; su conexión al vencimiento se implementará en W3-02/03.
Este plazo es balance inicial, pendiente de pruebas con jugadores.

Cada celda de escenarios cuenta aprobaciones sobre 9 tableros del nivel.
La ayuda que completa el tablero también pierde los premios de cierre, por eso
cuesta mucho más que los 77 puntos de la ayuda aislada.

| Nivel | Vidas | Meta % | P | Meta | Margen | Error temprano/tardío | Pista a cero/temprana | Explicación | Pista fila/final |
| --- | ---: | ---: | --- | --- | --- | --- | --- | --- | --- |
| 1 | 3 | 85.0 | 2810 | 2389 | 421 | 9/9 | 9/9 | 9 | 9/0 |
| 2 | 3 | 86.0 | 2731–2810 | 2349–2417 | 382–393 | 9/9 | 9/9 | 9 | 9/0 |
| 3 | 3 | 87.0 | 2810 | 2445 | 365 | 9/9 | 9/9 | 9 | 9/0 |
| 4 | 3 | 88.0 | 2810 | 2473 | 337 | 9/9 | 9/9 | 9 | 9/0 |
| 5 | 3 | 89.0 | 2731–2810 | 2431–2501 | 300–309 | 9/9 | 9/9 | 9 | 9/0 |
| 6 | 3 | 90.0 | 2810 | 2529 | 281 | 9/9 | 9/9 | 9 | 9/0 |
| 7 | 3 | 91.0 | 2810 | 2558 | 252 | 9/9 | 9/9 | 9 | 9/0 |
| 8 | 3 | 92.0 | 2810 | 2586 | 224 | 9/9 | 9/9 | 9 | 9/0 |
| 9 | 3 | 93.0 | 2731–2810 | 2540–2614 | 191–196 | 9/9 | 9/9 | 9 | 9/0 |
| 10 | 3 | 94.0 | 2810 | 2642 | 168 | 9/9 | 9/6 | 9 | 9/0 |
| 11 | 2 | 94.5 | 2810 | 2656 | 154 | 9/9 | 9/8 | 9 | 8/0 |
| 12 | 2 | 95.0 | 2810 | 2670 | 140 | 9/9 | 9/6 | 9 | 7/0 |
| 13 | 2 | 95.5 | 2810 | 2684 | 126 | 9/9 | 9/6 | 9 | 5/0 |
| 14 | 2 | 96.0 | 2757–2810 | 2647–2698 | 110–112 | 9/9 | 9/4 | 9 | 4/0 |
| 15 | 2 | 96.5 | 2757–2810 | 2661–2712 | 96–98 | 9/9 | 9/0 | 9 | 2/0 |
| 16 | 2 | 97.0 | 2731–2810 | 2650–2726 | 81–84 | 9/9 | 8/0 | 9 | 1/0 |
| 17 | 2 | 97.5 | 2757–2810 | 2689–2740 | 68–70 | 9/9 | 9/0 | 0 | 0/0 |
| 18 | 2 | 98.0 | 2810 | 2754 | 56 | 9/9 | 9/0 | 0 | 0/0 |
| 19 | 2 | 98.5 | 2810 | 2768 | 42 | 9/9 | 9/0 | 0 | 0/0 |
| 20 | 2 | 99.0 | 2810 | 2782 | 28 | 9/9 | 8/0 | 0 | 0/0 |
| 21 | 1 | 99.1 | 2757–2810 | 2733–2785 | 24–25 | 0/0 | 9/0 | 0 | 0/0 |
| 22 | 1 | 99.2 | 2678–2810 | 2657–2788 | 21–22 | 0/0 | 0/0 | 0 | 0/0 |
| 23 | 1 | 99.3 | 2757–2810 | 2738–2791 | 19 | 0/0 | 0/0 | 0 | 0/0 |
| 24 | 1 | 99.4 | 2757–2810 | 2741–2794 | 16 | 0/0 | 0/0 | 0 | 0/0 |
| 25 | 1 | 99.5 | 2731–2810 | 2718–2796 | 13–14 | 0/0 | 0/0 | 0 | 0/0 |
| 26 | 1 | 99.6 | 2810 | 2799 | 11 | 0/0 | 0/0 | 0 | 0/0 |
| 27 | 1 | 99.7 | 2810 | 2802 | 8 | 0/0 | 0/0 | 0 | 0/0 |
| 28 | 1 | 99.8 | 2810 | 2805 | 5 | 0/0 | 0/0 | 0 | 0/0 |
| 29 | 1 | 99.9 | 2757–2810 | 2755–2808 | 2 | 0/0 | 0/0 | 0 | 0/0 |
| 30 | 1 | 100.0 | 2810 | 2810 | 0 | 0/0 | 0/0 | 0 | 0/0 |

En las 270 rondas, resolución perfecta en ambos órdenes y 1 ms antes del límite:
aprobadas. A tiempo igual o superior al límite: rechazadas. Desde el nivel 21,
un error termina el intento; en el 30 todas las ayudas ensayadas lo invalidan.
Las ayudas del nivel 30 simulan historial inválido/importado; su bloqueo antes
de cobrar puntos se implementará en el repositorio y la UI, en W3-02/03.

Detalle por seed, versiones, puntajes y cada escenario: [results.json](results.json).
Las pruebas también incluyen explicación dirigida con puntaje cero. Con el
redondeo observado no hay mesetas de meta proporcional entre niveles; los
valores absolutos dependen de los grupos ya completos al inicio de cada tablero.

Reproducción desde la raíz del proyecto:

```sh
W3_CALIBRATION_DIR=design/world-3-crossed-rivers/gameplay-specs/calibration flutter test test/domain/scoring/adventure_calibration_test.dart
```

En los tableros ensayados, desde el nivel 22 una pista dirigida ya consume más
que el margen disponible, aunque siga permitida hasta el 29. Solo el 30 agrega
la prohibición explícita. Pedir una explicación sin casilla a cero puntos puede
no restar puntaje; por eso el 30 comprueba el historial además del total.

Estas simulaciones validan reglas y puntajes, no la dificultad humana ni la UI.
Las reglas todavía no se activan en las sesiones: persistencia, reloj del
controlador y presentación corresponden a W3-02–05.

