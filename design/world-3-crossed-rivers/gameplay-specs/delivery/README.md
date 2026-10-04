# W3-06 · Informe de validación

Fecha: 04/10/2026. Implementación evaluada: `69bf530`; comparación: `219713f`.
Estado: regresión automática cerrada y builds Playables/iOS aprobados; validación visual en simuladores y host YouTube pendiente.

## Resultado real

- `flutter test --reporter expanded`: **460 aprobadas, cero fallos** tras las
  correcciones de esta revisión. Ninguna prueba se omitió.
- Primera ejecución: 444 aprobadas y 16 fallidas, reproducidas en una copia
  aislada de `219713f`. Se conservaron los logs originales para trazabilidad.
- `flutter analyze --no-pub`: cuatro infos preexistentes, ningún error o warning.
  Dos `use_super_parameters` en map_ambient_motion.dart, y dos
  `curly_braces_in_flow_control_structures` en ese archivo y map_parallax_scene.dart.
- `python3 tool/build_youtube_playables.py`: compilación y validación del paquete
  aprobadas. ZIP: 122,9 MiB, 140 archivos, 152,0 MiB sin compresión.
- Navegador local: se observó home, acceso Aventura e introducción de reglas.
  Es un smoke test en memoria, no una validación del host de YouTube.

[Suite final aprobada](validation/final-full-tests.txt) · [Primera ejecución](validation/full-tests.txt) · [Comparación base](validation/baseline-tests.txt) ·
[Comparación mapa](validation/baseline-map-tests.txt) · [Análisis](validation/analysis.txt) ·
[Compilación](validation/playables-build.txt).

## Fallos anteriores resueltos

| Suite | Fallos | Evidencia |
| --- | ---: | --- |
| widget_test.dart | 5 | Expectativas de nombres de niveles y tamaño mínimo de controles del mapa. |
| level_unlock_test.dart | 3 | Expectativas de texto de nombres de niveles. |
| tutorial_journey_widget_test.dart | 6 | Selección de grupos, disponibilidad de navegación y secuencia de animaciones. |
| widgets/configurable_map_test.dart | 2 | Escala de insecto al toque cercano y selección tras redimensionar. |

Las pruebas se actualizaron al contrato vigente, sin eliminar los recorridos:
«Nivel N» en el pie, santuario visible pero bloqueado, nodos fuera de la ventana
verificados por su nivel y escape radial sin crecimiento para toques cercanos.
El crecimiento corresponde a pulsaciones directas, ya cubiertas por la suite de
movimiento. Los controles de borrado/ayuda se verifican centrados como conjunto,
con su límite de tamaño, sin imponer que tengan el mismo borde que los números.

Los tutoriales comprueban «Siguiente» en dos pulsaciones, espera de la transición
geométrica del tablero, recorrido automático de grupos, conservación del mismo
board y repaso sin escrituras. Se conservó el flujo real de resolver tres sudokus.
La disponibilidad del botón ya no se interpreta como fin de la explicación:
permanece habilitado para completar las animaciones.

Se corrigió un defecto real de layout: la fila compacta del mapa medía 44 px y
comprimía las flechas previstas de 48 px. Ahora reserva 48 px; la prueba de
pantalla 320×568, giro y texto ampliado conserva su mínimo de 48 px y pasó.
No se alteraron arte, parallax, fauna ni lógica de recompensas.

## Compilación nativa y escenario aislado

`flutter build ios --simulator --debug --target tool/validate_world3.dart`
compiló correctamente. [Log de Xcode](validation/ios-build.txt).
La entrada `tool/validate_world3.dart` abre el primer desafío con el repositorio
ficticio compartido y `MemorySaveStore`, sin leer ni escribir el perfil local.
Se puede ejecutar con `flutter run -t tool/validate_world3.dart -d <simulator>`.
No es el entrypoint de producción ni modifica `lib/main.dart`.

Los simuladores iPhone 18 Pro e iPad Pro 11-inch (M5) estaban iniciados, pero
la herramienta visual no expone Simulator: tanto `Simulator` como
`com.apple.iphonesimulator` devolvieron `Invalid app`, y el inventario de apps no
lo contiene. Por ello se acredita la compilación, no una revisión visual nativa.
No se instaló la variante QA ni se reemplazó la app del usuario.

## Cobertura y evidencia consolidada

- Reglas R y calibración: [calibración](../calibration/validation.md), suites
  adventure_challenge, adventure_calibration y challenge_scoring_contract.
- Guardado S: [persistencia](../persistence/README.md), challenge_persistence,
  challenge_session_controller y adaptador falso de Playables. Incluye
  escrituras fallidas, restauración, idempotencia y preservación de premios.
- Partida F y flujos E: [partida](../gameplay/README.md),
  world3_gameplay_widget_test, challenge_session_controller,
  challenge_debug_complete y world3_tutorial_widget_test. Las pruebas de
  resolución real y persistencia complementan el atajo DEV.
- Tutorial T: [introducción](../introduction/README.md), controlador y widgets
  específicos del mundo 3.
- Animación A: [resultados](../results/README.md), challenge_result_reveal y
  world3_result_capture; conteo, salto, accesibilidad, pausa y restauración.
- Reentrada: tras estrellas 1/2, mapa «Continuar» y ronda nueva «Jugar»;
  ronda iniciada conserva tablero y ofrece «Continuar». Fallo y tercera estrella
  conservan «Ver resultado». Pruebas de widgets y persistencia aprobadas.
- La suite incluye matriz de tamaños de W3 y texto 100/200 %, y verificaciones
  de redimensionado. Esto no sustituye la revisión en dispositivos.

La política sigue siendo `world3-challenge-v1`: 3/2/1 vidas, meta 85–100 %, plazo
120 s + 30 s por vacío y nivel 30 perfecto sin errores ni pistas. Los reintentos
regeneran el sudoku; reabrir conserva el intento. El contador lee el resultado
persistido y nunca concede premios. Sesiones heredadas conservan sus reglas.

## Pendientes para cerrar W3-06

1. Revisar el build actual en iPad de 11 pulgadas y teléfono vertical/horizontal,
   con capturas comparativas de mundos 1/2 y resumen final. Requiere acceso visual
   al simulador (no disponible en la herramienta de esta sesión) o revisión manual.
   No se usó un dispositivo físico.
2. Validar pausa/suspensión/restauración y descargas hasta gameReady en el host
   real/Test Suite de YouTube sobre HTTPS, según docs/youtube-playables.md.
   Requiere un destino HTTPS accesible y el host; compilar y probar el adaptador
   falso no certifica ese entorno. No se publicó ningún build.

No quedan specs de funcionalidad nuevos: W3-01–05 están implementados.
W3-06 permanece abierto por los puntos anteriores.
