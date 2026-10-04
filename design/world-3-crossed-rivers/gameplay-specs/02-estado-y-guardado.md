# W3-02 · Estado, guardado y reintentos

Depende de: [W3-01](01-reglas-y-calibracion.md). Siguiente: [W3-03](03-partida-y-navegacion.md).

## Contrato de estado

Representar el resultado de la ronda de forma explícita y separarlo de la
presentación. Estados conceptuales: en curso, pausada, aprobada, fallida por vidas,
fallida por tiempo y resuelta sin alcanzar la meta. El modelo concreto puede reutilizar estructuras
actuales, pero un tablero resuelto sin aprobación no puede contarse como estrella.

Guardar por intento de ronda:

- Identidad del intento y referencia a sesión, ronda y definición del sudoku.
- Instantánea versionada de reglas: vidas iniciales, meta, referencia perfecta,
  restricciones, política de tiempo y límite en milisegundos. No recalcularla al reabrir.
- Vidas restantes o su derivación validada desde vidas iniciales y errores;
  evitar dos fuentes de verdad que puedan divergir.
- Tablero, notas, racha, historial de premios, errores, pistas y tiempo activo.
- Resultado final estable: puntaje/desglose, motivo(s), aprobación y finalización.
- Estado mínimo para retomar un resultado pendiente y avanzar una sola vez.

Conservar la distinción entre resultado confirmado y resultado presentado. La
animación no escribe puntajes intermedios ni concede estrellas. Al guardarse la
jugada final, resultado, estrella, récord y desbloqueos se confirman atómicamente;
la presentación solo revela ese resultado.

## Transiciones

| Desde | Evento | Hacia / efecto |
| --- | --- | --- |
| En curso | Acierto que no completa | Sigue en curso, puntos guardados. |
| En curso | Error con vidas restantes | Resta una vida; sigue en curso. |
| En curso | Última vida perdida | Resultado fallido; reloj y entrada detenidos. |
| En curso | Tiempo activo alcanza el límite | Resultado fallido por tiempo; reloj y entrada detenidos, sin estrella. |
| En curso | Última casilla correcta, cumple reglas | Resultado aprobado pendiente de presentación; una estrella. |
| En curso | Última casilla correcta, no cumple reglas | Resultado fallido con motivo; ninguna estrella. |
| Resultado | Continuar, resultado aprobado | Confirma presentación e inicia próxima ronda o resumen final, una sola vez. |
| Resultado fallido | Reintentar | Nuevo sudoku de esa ronda, vidas completas y contadores a cero. |
| Cualquiera | Escritura rechazada | Conserva último estado confirmado; recuperación visible, sin premio o pérdida local anticipada. |

Actualizar las invariantes de `PuzzleProgress`, `GameSession.lights`,
`nextPuzzleId`, `canResume`, `_playable`, `_replaceBoard` y el avance del
controlador. No basta con ocultar la estrella en el widget. La tercera ronda
fallida no completa la sesión; no desbloquea el nivel siguiente ni cierra el mundo.

## Reintentos y récords

- Crear una operación de producción para reintentar la ronda fallida. Nunca
  utilizar `debugRestartPuzzle` como acción del jugador.
- Mantener las rondas ya aprobadas de la misma sesión con sus puntos y tiempos.
- Generar un sudoku nuevo al reintentar: cambian pistas y solución, manteniendo
  la dificultad y las condiciones del nivel. Recalcular la meta a partir del
  puntaje perfecto del nuevo tablero y el porcentaje exigido por ese nivel.
  Guardar definición e intento juntos. Reabrir conserva ese mismo intento;
  únicamente Reintentar genera otro. Esta corrección reemplaza la decisión
  inicial de conservar el sudoku para evitar respuestas memorizadas.
- Descartar el progreso jugable del intento fallido al reiniciarlo. Si se guarda
  historial de fallos, no sumarlo a los puntos premiados ni a las estrellas.
- El resumen usa los intentos aprobados, uno por ronda. Un resultado fallido no
  mejora el récord de nivel completado. Reintentar no duplica totales históricos.
- Mantener el bloqueo actual de repetición de niveles ganados. Esta funcionalidad
  solo incorpora el reintento de rondas fallidas; no añade «Volver a jugar» a los
  niveles completados del mundo 3 ni cambia la excepción de práctica del mundo 1.
- Reintentar con doble toque genera un único intento. Volver al mapa y regresar
  no restaura vidas de un intento activo ni reinicia automáticamente un fallo.

## Compatibilidad

Los guardados anteriores conservan estrellas, récords, mundos abiertos, perfil,
notas, ayudas desbloqueadas y celebraciones. No recalificar resultados anteriores.

Una sesión del mundo 3 iniciada antes de esta funcionalidad conserva sus reglas
previas durante toda esa sesión, incluidas las rondas restantes. Las reglas nuevas
se aplican al comenzar una sesión nueva; no exigir al continuar puntos que ya no
se pueden obtener. Los mundos 1 y 2 y la partida rápida mantienen sus reglas.

Definir un marcador explícito de sesión heredada. Una nueva sesión que pierda sus
reglas por corrupción no debe convertirse silenciosamente en una sesión libre.
La migración es idempotente, conserva campos desconocidos y sigue `SaveCodec`.
Si se requiere cambiar esquema, documentar versión y migración; no borrar datos
incompatibles ni sobrescribir guardados de una versión futura.

Aplicar la misma semántica en SQLite, web/IndexedDB y el adaptador de YouTube
Playables. Respetar las garantías actuales de cada adaptador y los fallos de
escritura/concurrencia. No depender del reloj de pared para sumar tiempo cerrado.

Al acumular tiempo o recibir una entrada, evaluar el vencimiento antes de aceptar
una jugada. Serializar la última jugada y el tick para resolver la frontera sin
una estrella tardía. A tiempo igual al límite se falla. Pausa o suspensión debe
confirmar el tramo activo pendiente; si vence en ese tramo, conserva el fallo.
Reabrir un intento vencido no restaura plazo. Reintentar sí reinicia su contador,
con una definición nueva y el mismo límite para los sudokus actuales de 38 vacíos. El fallo se guarda atómicamente como
cualquier otro resultado y detiene futuras entradas.

## Reanudación durante el resultado

Si la app se cierra después de confirmar el resultado y antes de terminar la
animación, reabrir el resultado pendiente desde una presentación estable (se
permite mostrarlo ya completo). No volver a conceder la estrella ni iniciar otra
ronda por un callback atrasado. Un resultado ya reconocido no vuelve a bloquear
el avance. La pausa o suspensión durante una partida no altera vidas ni meta.

## Pruebas y aceptación

| ID | Caso | Resultado |
| --- | --- | --- |
| S01 | Reabrir con una vida consumida, notas y pista | Estado idéntico, meta/reglas intactas. |
| S02 | Completar debajo de la meta | Sin estrella, sin avance ni desbloqueo. |
| S03 | Última vida y toques encolados | Un fallo; entradas posteriores rechazadas. |
| S04 | Fallar ronda 2 y reintentar | Ronda 1 intacta; solo ronda 2 empieza de cero con sudoku distinto. |
| S05 | Fallar ronda 3 | Nivel y mundo siguen sin completar. |
| S06 | Fallo al guardar jugada final o pérdida de vida | Sin recompensa/pérdida no confirmada; reintento seguro. |
| S07 | Cerrar antes/durante/después del contador | Un premio y una continuación como máximo. |
| S08 | Doble Reintentar / Continuar | Una transición; no duplica rondas ni sesiones. |
| S09 | Guardados antiguos parciales y completos | Conserva todo el progreso y aplica política heredada. |
| S10 | Repetir migración y campos desconocidos | Sin pérdida de datos ni metas reiniciadas. |
| S11 | Intentar repetir un nivel ya ganado / importar récord anterior | Repetición rechazada; récord preservado sin duplicación. |
| S12 | SQLite, codec web y Playables | Mismo resultado serializado/restaurado, sin bypass de reglas. |
| S13 | Vencimiento, última jugada concurrente y reapertura | Un fallo a tiempo igual/superior; sin estrella tardía ni plazo restaurado. |
| S14 | Pausa, segundo plano y fallo de guardado del vencimiento | Solo tiempo activo; resultado publicado tras guardado, recuperable sin duplicar. |

Usar `test/data/game_repository_test.dart`,
`test/controllers/game_session_controller_test.dart`, `test/domain/game_models_test.dart`
y `test/playables/playables_integration_test.dart` como puntos de extensión.
Usar almacenamiento temporal; nunca modificar el guardado real para simular fallos.

## Cierre

- [x] Transiciones y rechazos implementados en dominio/repositorio.
- [x] S01–S14 verificados, incluida reapertura real y fallos de escritura.
- [x] Sesiones heredadas y nuevas distinguibles sin perder progreso.
- [x] UI todavía no requiere una animación para guardar o avanzar correctamente.

## Implementación de esta etapa

Cerrada el 03/10/2026; [pruebas y alcance](persistence/README.md).

- JSON de guardado en versión 2, con migración automática 1→2. Las sesiones
  anteriores reciben `rulesMode: legacy`; todas sus rondas mantienen las reglas
  originales, incluidas las que aún no empezaron. Los campos desconocidos se
  conservan. La versión física de SQLite permanece en 1 (mismo payload JSON).
- `rulesMode: challenge` exige `RoundAttempt` en cada ronda, con reglas inmutables,
  token, número de intento, token anterior y resultado opcional. Perder esos
  campos o importar un resultado incoherente rechaza el guardado, sin reemplazarlo.
- `PlayStatus.failed` pertenece al tablero fallido. La sesión queda pausada y
  recuperable; `pendingResult` conserva la presentación pendiente y `nextPuzzleId`
  bloquea el avance. Una sesión completada también puede tener su último resultado
  pendiente, accesible por su ID aunque no admita repetir el nivel.
- `acknowledgeRoundResult` reconoce una victoria usando su token; deja disponible
  la siguiente ronda. El controlador la activa cuando la UI esté lista, para no
  consumir tiempo durante la transición. Repetir el reconocimiento no avanza otra
  ronda ni concede otro premio. `retryRound` reinicia exclusivamente el fallo
  actual con un sudoku nuevo y las condiciones del mismo nivel; las llamadas
  repetidas son inocuas.
- `GameSessionController` confirma el tramo de tiempo antes de cada entrada y
  programa un vencimiento dedicado, independiente del checkpoint periódico.
  A cero guarda el fallo y detiene reloj/entrada; pausa y suspensión no cuentan.
- `enableWorld3Challenges` controla solo la creación de sesiones nuevas. En esta
  etapa permanece desactivado por defecto; los snapshots existentes siempre se
  respetan aun si se reabre con el flag desactivado. W3-03 conectará el flujo visible.
