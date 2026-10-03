# W3-01 · Reglas y calibración

Depende de: [W3-00](00-base-y-decisiones.md). Siguiente: [W3-02](02-estado-y-guardado.md).

## Contrato de reglas

Centralizar una política por mundo/nivel y una instantánea por intento. Debe
contener, como mínimo, versión, vidas iniciales, meta, puntaje perfecto de
referencia, política del tiempo y condiciones de errores/pistas. No repartir
comparaciones con números de nivel entre pantalla, controlador y repositorio.

- Niveles 1–10: 3 vidas. Niveles 11–20: 2. Niveles 21–30: 1.
- Un error es una nueva respuesta incorrecta según la solución, como en el motor
  actual. La misma entrada repetida sin cambiar la casilla no consume otra vida.
- Borrar no devuelve vidas. Volver a introducir un valor erróneo después de
  borrarlo es otra jugada y sí cuenta. Las notas nunca consumen vidas.
- Cero vidas termina el intento de inmediato; no admite más entradas ni pistas.
- Antes del 30 no hay un requisito independiente de cero errores ni cero pistas.
  Se aprueba con vidas restantes y puntaje suficiente. Desde el 21, la única vida
  implica por sí misma que no se puede cometer un error.
- En el 30 se comprueban explícitamente `mistakes == 0` y `hintsUsed == 0`.
  La ayuda se muestra deshabilitada con explicación «Este desafío es sin pistas»;
  el repositorio también rechaza su uso y no cobra puntos. Las anotaciones siguen disponibles.
- La igualdad con la meta cuenta como éxito. El tablero siempre debe estar resuelto.

Resultado aprobado = tablero resuelto + vidas restantes > 0 + puntos finales
computables >= meta + tiempo activo < límite + condiciones adicionales satisfechas. Una excepción de
persistencia no es un resultado perdido ni un error del jugador.

## Puntaje perfecto y margen

La meta se calcula sobre la definición inicial real de cada sudoku, no sobre un
valor fijo global ni sobre los puntos que todavía se pueden obtener a mitad de
partida. No cambiar pistas iniciales, solución, dificultad o seed para acomodar
una meta después de que el jugador inició.

Para el puntaje base actual, una resolución sin errores ni ayudas permite calcular:

- Aciertos de las N casillas inicialmente vacías: 11, 11, 17, 17, luego 23 cada una.
- 53 por cada fila/columna inicialmente incompleta que se completa.
- 79 por cada bloque inicialmente incompleto que se completa.
- 307 por completar el tablero jugable.
- Aplicar el multiplicador de la dificultad a la suma, igual que el motor.

Las casillas dadas y los grupos completos al inicio no generan premios. Contrastar
la fórmula con resoluciones a través de `SudokuScoring`, incluyendo distintos
órdenes de entrada. Definir o rechazar explícitamente tableros sin casillas vacías.

La curva de exigencia usa valores enteros versionados (por ejemplo, proporciones
en diezmilésimos con redondeo hacia arriba), para obtener el mismo resultado en
Dart nativo y web. Requisitos:

1. La proporción exigida crece de nivel a nivel, también dentro de cada tramo.
2. Los niveles 1–29 tienen meta positiva y menor que su referencia perfecta.
3. El nivel 30 exige la referencia perfecta y las comprobaciones explícitas.
4. Si el redondeo produce una meseta de un punto, registrarla en el informe; nunca
   permitir que un redondeo exija más puntos de los alcanzables.
5. Comparar proporciones/márgenes, no puntos absolutos de tableros distintos.
6. Mantener la misma política de nivel para sus tres rondas; la meta numérica puede
   variar según el tablero. No añadir dificultad extra por número de ronda.

## Política implementada y tiempo (D06)

`AdventureChallenges` selecciona reglas solo para `world-3`. La instantánea
`RoundChallengeRules` contiene identidades, versiones de reglas/puntaje, vidas,
meta, referencia perfecta, proporción, plazo y condiciones. No cambia una partida
existente. La activación y persistencia quedan para W3-02/03.

Versión `world3-challenge-v1`, proporciones enteras sobre 10 000:

- 1–10: 8500 + (nivel−1) × 100 (85–94 %).
- 11–20: 9450 + (nivel−11) × 50 (94,5–99 %).
- 21–29: 9910 + (nivel−21) × 10 (99,1–99,9 %).
- 30: 10 000 (100 %).

Meta = techo(perfecto × proporción / 10 000), limitada a perfecto−1 antes del
nivel 30 para conservar un margen aun con tableros pequeños. Los tableros sin
vacíos se rechazan por `SudokuDefinition`. La fórmula global no se modifica.

El usuario eligió límite de tiempo para la estrella, **sin bonus**. Plazo inicial:
120 000 ms + 30 000 ms × vacíos iniciales. Los 38 vacíos actuales dan 1 260 000 ms
(**21 minutos por ronda**). Es balance inicial pendiente de pruebas con jugadores;
no se ajusta durante el intento ni se reduce según la ronda. Solo tiempo activo.

Ejemplo con perfecto = 2810: nivel 1 exige 2389; nivel 10, 2642; nivel 20, 2782;
nivel 29, 2808; nivel 30, 2810. Resolver con 2810 a 20:59.999 aprueba; a 21:00.000
falla. Resolver temprano no añade puntos ni rescata cero vidas/pistas prohibidas.

`evaluate` comprueba tablero real y contadores. Prioridad de motivo determinante:
vidas, tiempo, condiciones perfectas, tablero incompleto y meta. No suma estrellas
ni cambia estados. En el 30 un error ya agota la única vida; el requisito explícito
queda también en la instantánea. Hints inválidos importados nunca aprueban.

Informe reproducible: [calibración](calibration/README.md), con resultados por seed
para 270 tableros y ayudas que afectan grupos completos, no solo el costo fijo.

## Calibración reproducible

Crear un informe con nivel, ronda, seed/perfil de prueba, versión del generador,
casillas vacías, puntaje perfecto, meta, margen absoluto/relativo y resultados de
los escenarios. Los tableros del mundo 3 dependen del perfil: validar al menos
tres perfiles sintéticos estables, con sus 90 rondas cada uno.

Simular resolución perfecta; error temprano/tardío seguido de corrección cuando
quedan vidas; una ayuda temprana; ayuda explicativa sin rellenar; ayuda con cero
puntos; ayuda que termina un grupo o el tablero. Esto determina cuánto margen
real concede la curva. No basta con dividir puntos por 77: las pistas también
excluyen premios de casillas y pueden excluir premios de grupos.

El inicio debe tolerar algunos intentos imperfectos compatibles con sus vidas.
Antes del 30, que una pista esté disponible no garantiza que permita aprobar.
El último nivel siempre debe ser aprobable con una solución correcta sin ayudas
bajo la política de tiempo acordada. Registrar evidencias de solución única y
mantener la versión actual del generador salvo necesidad demostrada.

## Pruebas y aceptación

| ID | Caso | Resultado |
| --- | --- | --- |
| R01 | Niveles 1, 10, 11, 20, 21, 29, 30 | Vidas y condición perfecta correctas, sin errores de límite. |
| R02 | Resuelto con meta−1, meta y meta+1 | Rechazo, aprobación, aprobación si las demás condiciones se cumplen. |
| R03 | Meta alcanzada con casillas vacías | Ninguna estrella; ronda sigue activa. |
| R04 | Cero vidas con puntos suficientes | Intento fallido. |
| R05 | Nivel 30 con error/pista históricos y puntos suficientes | No aprobar; verificar también con un estado importado de prueba. |
| R06 | Mismo error repetido / borrar y repetir | Una pérdida / nueva pérdida; nunca vidas negativas. |
| R07 | Notas, pausa, borrado y reingreso correcto | Sin pérdidas de vida ni premios duplicados. |
| R08 | Pista al inicio con cero puntos | Registra la ayuda; nunca evade la condición perfecta. |
| R09 | Perfecto con grupos completos al inicio y varios órdenes | Fórmula y motor coinciden. |
| R10 | Tres perfiles × 90 rondas | Metas alcanzables, curva documentada y resultados deterministas. |
| R11 | Mundos 1, 2 y partida rápida | Puntaje y vidas previos, sin nueva meta obligatoria. |
| R12 | Política de tiempo final | Antes del límite aprueba; a cero o después falla. Pausa/segundo plano no consumen tiempo activo, sin rescatar vidas o pistas inválidas. |

Extender `test/domain/scoring/sudoku_scoring_test.dart` solo para cambios reales
del motor; crear pruebas de la nueva política separadas. No probar exclusivamente
comparando una función nueva consigo misma: usar totales calculados de forma
independiente y sesiones reales del motor.

## Cierre

- [x] Política central y curva numérica versionadas.
- [x] D06 resuelta y ejemplos de cálculo incluidos.
- [x] Informe de balance disponible y R01–R12 cubiertos.
- [x] No se cambió la fórmula global del puntaje para forzar el balance del mundo 3.

Evidencia de cierre y alcance de R01–R12: [verificación](calibration/validation.md).
Los rechazos de entrada, guardado y reloj visual todavía se integran en W3-02/03.
