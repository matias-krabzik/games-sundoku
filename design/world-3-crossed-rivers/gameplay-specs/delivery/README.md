# W3-06 · Validación y entrega

07/10/2026 · Base evaluada: `620fcef` · Flutter 3.47.2 / Dart 3.13.2 · macOS / iOS 27.

**Estado: regresión automática y validación nativa aprobadas. El host real
YouTube sigue pendiente de una URL HTTPS o Dev Link.** No se declara terminado
W3-06 hasta verificar E12 y la descarga inicial en ese entorno.

[Galería nativa de iPad y teléfono](gallery.html) · [Informe anterior](2026-10-04.md).

## Resultado de esta revisión

- Suite completa: **472 pruebas aprobadas, cero fallos**. [Log final](validation/2026-10-07/final-full-tests.txt).
- La primera ejecución encontró una expectativa antigua del icono de inicio:
  esperaba `Icons.home_rounded`, reemplazado por el arte `MapIcon(MapGlyph.home)`.
  Se actualizó la expectativa conservando el recorrido de navegación y repaso.
  [Log inicial](validation/2026-10-07/full-tests.txt).
- Análisis: ningún error ni warning nuevo; permanecen cuatro infos anteriores
  (`use_super_parameters` × 2 y `curly_braces_in_flow_control_structures` × 2).
  [Análisis](validation/2026-10-07/analysis.txt).
- Build oficial Playables aprobado mediante `tool/build_youtube_playables.py`:
  **147 archivos, 163,5 MiB sin comprimir, ZIP 133,8 MiB**. El tamaño del ZIP no
  mide la descarga inicial hasta `gameReady`. [Build](validation/2026-10-07/playables-build.txt).
- Tres escenarios nativos aprobados en cada dispositivo (iPad y teléfono), con **34 capturas**.
- Build de integración iOS aprobado. [Build nativo](validation/2026-10-07/ios-build.txt).
- No se cambiaron `lib/`, el arte ni las reglas. Se añadieron el runner nativo,
  dependencias SDK de desarrollo, capturas y documentación de validación.

## Pruebas nativas reproducibles

`integration_test/world3_native_test.dart` ejecuta tres escenarios en la app
Flutter nativa. `test_driver/world3_native_driver.dart` guarda las capturas que
entrega el plugin oficial `integration_test`; no son capturas de widget headless.

| Dispositivo | Ventana lógica real | Evidencia |
| --- | --- | --- |
| iPad Pro 11″ (M5), iOS 27, DPR 2 | 834×1210 y 1210×834 | [Log](validation/2026-10-07/ipad-native.txt) · [Galería](gallery.html) |
| iPhone 18 Pro, iOS 27, DPR 3 | 402×874 y 874×402 | [Log](validation/2026-10-07/phone-native.txt) · [Galería](gallery.html) |

El runner exige que la ventana nativa cambie de orientación. No asigna
`tester.view.physicalSize`. El simulador emite avisos transitorios de orientación,
pero se comprueba el tamaño final y que el mismo tablero siga montado.

Escenarios:

1. Partidas de mundos 1/2 en ambas orientaciones; cuatro pasos automáticos de la
   introducción W3, mismo tablero, título y finalización persistida. Texto 200 %
   y movimiento reducido al girar; acción inferior siempre accesible.
2. Nivel 1: primera estrella mediante toques de casillas y números; desmontar y
   reabrir antes de terminar la presentación del resultado; premio único. Segunda
   ronda agotando vidas; reintento con otro sudoku; una jugada y pausa; cerrar y
   reabrir conservando exactamente sudoku y progreso; terminar las tres estrellas.
   Resultado final en horizontal con texto ampliado y acción accesible.
3. Nivel 30: un error pierde la única vida; reintento perfecto por toques, sin
   pistas y con cero errores. Capturas del resultado y del repaso final, también
   en horizontal con texto 200 %. El repaso se abre explícitamente para revisión
   visual; no se presenta ese acceso directo como ejecución nativa de E11.

Los sudokus de los escenarios 2/3 se resuelven a través de los controles visibles,
**sin completar con DEV ni escribir las respuestas directamente al repositorio**.
Solo la preparación de prerrequisitos y niveles anteriores es sintética.
Los toques esperan la animación de `JuicyPress` antes de comprobar su efecto.

El script `tool/validate_world3_native.py` copia el build a un directorio temporal,
le asigna el bundle separado `com.krabzik.games.sundoku.w3qa` y lo firma localmente
para el simulador. La copia QA exige pantalla completa para probar orientación en
iPad. El proyecto de producción conserva su configuración. El guardado usa
`MemorySaveStore`; el bundle y el contenedor del jugador no se sustituyen.

```sh
python3 tool/validate_world3_native.py --device <UDID-ipad> --output build/w3-native/ipad
python3 tool/validate_world3_native.py --skip-build --device <UDID-phone> --output build/w3-native/phone
```

`--skip-build` solo reutiliza el build de integración recién generado por el
primer comando. Las capturas mantienen su resolución nativa. No hubo dispositivo
físico ni revisión con VoiceOver. En teléfono horizontal el tablero es compacto
para conservar la partida sin scroll; tutorial y repaso permiten desplazar el
contenido central con las acciones fijas, especialmente al 200 %.

## Matriz consolidada

«Aprobado automático» acredita las suites indicadas; no convierte una simulación
del SDK en verificación del host real. Los logs de etapas previas conservan el
detalle de casos, calibración y fixtures.

| Grupo | Estado | Evidencia |
| --- | --- | --- |
| R01–R12 | Aprobado automático | [Calibración](../calibration/validation.md); `adventure_challenge_test`, `adventure_calibration_test`, `challenge_scoring_contract_test`. |
| S01–S14 | Aprobado automático | [Persistencia](../persistence/README.md); `challenge_persistence_test`, `challenge_session_controller_test`; reapertura SQLite y codec Playables. |
| F01–F11 | Aprobado automático | [Partida](../gameplay/README.md); `world3_gameplay_widget_test`; reentrada, vidas, pausa, retry, resultado y final. |
| T01–T10 | Aprobado automático | [Introducción](../introduction/README.md); `world3_tutorial_widget_test`, `challenge_tutorial_controller_test`; comprobación nativa adicional. |
| A01–A10 | Aprobado automático | [Resultados](../results/README.md); `challenge_result_reveal_test`, `world3_result_capture_test`; animación sin escrituras de premios. |
| E01 | Aprobado automático | `world_gate_test`, `summit_gate_test`, `world3_tutorial_widget_test`: prerrequisitos, tutorial único y entrada. |
| E02/E03/E08 | Aprobado automático y nativo | `world3_gameplay_widget_test`, `challenge_persistence_test` y escenario nativo de tres estrellas/retry/reapertura. |
| E04/E05/E07 | Aprobado automático | Reglas, calibración y contratos de puntuación; vidas por tramo, pista del 29 y comparación con meta. |
| E06 | Aprobado automático y nativo | Regla del 30, notas/ayuda y escenario nativo de error/reintento perfecto. |
| E09 | Aprobado automático | Fixtures W3 heredadas y migración: misma sesión conserva reglas, siguiente sesión adopta desafío. |
| E10 | Aprobado automático | Regresión completa: home, rápida, reglas, anotaciones y mapas; comparación visual nativa adicional de partidas 1/2. |
| E11 | Aprobado automático | `world3_gameplay_widget_test`: tercera estrella del 30, resultado recuperable, resumen final y ausencia de siguiente nivel/replay. |
| E12 | **Pendiente host real** | Adaptador falso aprobado; intento en Test Suite local sin eventos del SDK. Ver apartado siguiente. |
| E13 | Aprobado automático | `challenge_session_controller_test`: límite −1/0/+1 ms, expiración autónoma, pausa, restauración y retry. |

La matriz de 16 tamaños con texto 100/200 % y redimensionado sigue incluida en las
472 pruebas. La revisión nativa la complementa en dos dispositivos; no representa
todos los modelos ni sustituye una evaluación humana de ergonomía en hardware.

## YouTube: único bloqueo externo

Se abrió la [Test Suite oficial](https://developers.google.com/youtube/gaming/playables/test_suite)
y se intentó cargar el build actual desde `http://127.0.0.1:8769/`. El panel quedó
en **0/5 MUST, sin eventos SDK**; el servidor local no recibió solicitudes del
juego desde ese iframe. Por eso no se atribuye ese resultado a un fallo de la
lógica de SunDoku ni se certifica integración, transferencia o tiempo de arranque.
No se publicaron archivos ni se alteró la seguridad del navegador.

Para cerrar W3-06 falta un destino HTTPS accesible o Dev Link. En ese entorno:

- Verificar orden de carga SDK, `firstFrameReady`, `gameReady`, volumen transferido
  hasta `gameReady` y guardado cloud real dentro de límites.
- Ejecutar pausa/reanudación del host y suspensión/retorno durante partida W3;
  comprobar reloj detenido y recuperación del mismo intento, reglas y estrellas.
- Recargar con resultado guardado antes de la animación; comprobar premio único.

Procedimiento de build vigente: [YouTube Playables](../../../../docs/youtube-playables.md).
El paquete queda en `build/sundoku-youtube-playables.zip`, preparado para esa prueba.

## Contrato conservado

Política `world3-challenge-v1`: tres/dos/una vidas por tramo; meta 85–100 %;
plazo congelado de 120 s + 30 s por vacío, sin bonus de rapidez; solo el nivel 30
prohíbe expresamente errores y pistas. El contador presenta un resultado ya
persistido. Reintentar cambia el sudoku de esa ronda; reabrir conserva el intento.

[Reglas de puntuación](../../../scoring/rules.md) y
[guardado local](../../../../docs/guardado-local.md) ya documentan estos contratos,
incluidas las sesiones heredadas. El cierre del spec queda sin marcar hasta
completar la verificación externa pendiente.
