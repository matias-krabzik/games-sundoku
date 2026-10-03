# W3-02 · Persistencia, resultados y reintentos

03/10/2026 · Base: `10635db` (commit solicitado antes de continuar).
Flutter 3.47.2 / Dart 3.13.2, pruebas automatizadas en macOS.

**Actualización posterior:** W3-03 ya integra la interfaz; ver [informe actual](../gameplay/README.md). El estado siguiente describe el cierre de W3-02.

Estado: implementada la lógica y persistencia; **activación en la interfaz pendiente**.
Las reglas nuevas se ejercitan con `enableWorld3Challenges: true`. La app todavía
crea sesiones con reglas anteriores por defecto para no introducir fallos sin UI
de reintento. Las reglas de una sesión ya guardada prevalecen sobre ese flag.

## Cambios comprobados

- JSON v2 y migración 1→2: sesiones heredadas explícitas, sin cambiar estrellas,
  récords, definiciones, perfiles ni rondas pendientes. SQLite conserva esquema 1.
- Intento y reglas congelados por ronda; resultado persistente independiente de
  la animación. Guardados nuevos con reglas ausentes/incoherentes se rechazan.
- Última vida, tiempo agotado y puntaje insuficiente no conceden estrella. Los
  premios y el resultado se guardan juntos; errores de escritura no se publican.
- Reintento de producción con token: solo reinicia la ronda fallida, preserva
  rondas ganadas y no duplica acciones. Reconocer resultado libera la siguiente
  ronda una sola vez y nunca habilita repetir un nivel completado.
- Tiempo activo confirmado antes de jugadas, vencimiento sin requerir otro toque,
  pausa/segundo plano excluidos y checkpoint recuperable tras fallo de escritura.

## Pruebas

**117 pruebas aprobadas**, incluidas **19 nuevas** de persistencia/controlador,
las pruebas de W3-01 con 3510 escenarios y regresión de lógica, guardados, mundos,
Playables y layout de partida. [Log completo](validation/tests.txt).

**Análisis sin incidencias** en código afectado y pruebas nuevas.
[Log](validation/analysis.txt). Formato Dart aplicado; `git diff --check` sin errores.

| Spec | Evidencia nueva |
| --- | --- |
| S01 | Reapertura con error, notas, pista, tiempo y snapshot exacto, incluso con flag desactivado. |
| S02–S03 | Resuelto bajo meta; rechazo de todos los métodos de entrada tras fallo; última vida y jugada encolada. |
| S04–S05 | Fallo/reintento de segunda y tercera ronda; otras estrellas intactas, mundo bloqueado hasta aprobación final. |
| S06 | Fallos de escritura en última vida, última jugada, reintento y reconocimiento; estado publicado intacto. |
| S07–S08 | Reabrir resultado pendiente/reconocido, doble Continuar/Reintentar y callbacks antiguos sin saltar rondas. |
| S09 | Fixture real W3-00 continúa toda la sesión sin reglas nuevas; siguiente sesión recibe desafío. Los siete fixtures anteriores también pasan. |
| S10 | Codec idempotente y campos desconocidos conservados; reglas/resultado ausentes, vencidos, desparejos o versión futura rechazados. |
| S11 | Último nivel completado rechaza replay/retry; récord se conserva sin sumar intentos fallidos. |
| S12 | SQLite con archivo temporal cerrado/reabierto; codec común/web y Playables; store Playables con reapertura y fallo cloud/reintento. |
| S13 | Última jugada a límite−1 ms/igual/+1 ms, tick encolado y timer de vencimiento sin otro toque; reanudar no restaura plazo. |
| S14 | Pausa, ciclo de vida, suspensión SDK y fallo al guardar vencimiento; tiempo oculto excluido. |

Suites nuevas:
`test/data/challenge_persistence_test.dart` y
`test/controllers/challenge_session_controller_test.dart`, con
`test/support/challenge_repository.dart` para datos sintéticos aislados.

Regresión ejecutada: `test/domain/scoring`, modelos, repositorio, siete fixtures
W3-00, contrato de scoring, notas, controladores de partida/primera experiencia/
generación, mundo 3, puertas, Playables, `generated_game_widget_test` y
`desktop_game_layout_test`. Incluye tamaños de teléfono/iPad/escritorio, texto
ampliado, rotación y continuidad del flujo existente.

## Alcance y continuación

No se modificó arte ni widgets de presentación. No hay nuevas capturas en esta
etapa; las referencias W3-00 permanecen congeladas. Se probaron widgets y tamaños,
no dispositivos físicos ni un host real de YouTube. El codec web comparte modelo
con los otros adaptadores; no se ejecutó una reapertura de IndexedDB en navegador
en esta etapa. La matriz real de plataformas queda para W3-06.

Playables conserva su sincronización diferida: un fallo remoto queda pendiente
para `flush`, sin recalcular ni duplicar el resultado confirmado en memoria.
Esta entrega no convierte ese contrato en una confirmación remota síncrona.

W3-03 conectará resultado estático, Reintentar/Continuar, barra de vidas/meta/reloj
y navegación, usando estos comandos. W3-04/05 incorporarán introducción y animación.
Los cuatro fallos visuales preexistentes fuera de las suites seleccionadas siguen
registrados en [W3-00](../baseline/README.md); no se declara una suite global limpia.
