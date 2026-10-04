# W3-05 · Contador, umbral y estrella

03/10/2026 · Base: `219713f` (introducción, corazones y nuevos sudokus al reintentar).

[Galería y videos](gallery.html) · [Victoria](won.mp4) · [Fallo por tiempo](failed.mp4).

## Comportamiento

El resultado confirmado se presenta con un contador de 1,5 segundos, una barra
continua y un marcador fijo de meta. La escala utiliza el mayor entre puntaje
perfecto, meta y resultado; muestra cuánto se supera el umbral. Las estrellas
anteriores permanecen encendidas. Solo una ronda aprobada enciende su nueva
estrella al cruzar la meta, con un pulso y los efectos existentes. La celebración
es finita y respeta suspensión, silencio y movimiento reducido.

Mostrar resultado termina el conteo; otro toque permite Continuar o Reintentar.
No hay avance automático. `JuicyPress` captura la acción al activar el botón:
si termina el conteo durante su animación de pulsación, ese toque sigue mostrando
el resultado en lugar de pasar accidentalmente a otra ronda.

El foco pasa al panel y el anuncio accesible contiene el resultado y meta finales,
sin leer cada incremento. Con movimiento reducido o navegación accesible se
muestra el final inmediatamente. Un resultado reabierto aparece completo, sin
repetir sonido. La presentación no escribe guardados ni otorga premios.

El tutorial conserva su secuencia didáctica, reutilizando `ChallengeAward` con
la misma escala y marcador. La tercera estrella sigue dando paso al resumen
existente después de Continuar, sin dos capas de victoria simultáneas.

## DEV

«Completar menos 1» prepara el desafío usando el motor real de puntuación:
reinicia errores, pistas y tiempo; reproduce una solución limpia y deja una
casilla editable. Al completarla se cumplen puntaje, vidas y plazo, también en
el nivel 30. No adelanta la estrella ni falsifica un resultado final. Repetir
el botón no acumula puntos. Las otras rondas permanecen intactas.

## Validación

- **96 pruebas aprobadas** en la regresión de resultado, tutorial, partida,
  persistencia, reloj, primera experiencia y navegación. [Log](validation/tests.txt).
- **22 pruebas aprobadas** tras el ajuste final de foco/accesibilidad, incluyendo
  un caso adicional de navegación accesible. [Log](validation/focus-tests.txt).
  Estas pasadas comparten casos; no se suman como cobertura única.
- `flutter analyze`: sin errores ni warnings; cuatro infos preexistentes de
  fauna/parallax. [Log](validation/analysis.txt). `git diff --check` limpio.
- Capturas y videos de widgets reales en 390×844, con arte y fuente del proyecto.
  Videos de 21 cuadros a 5 fps; secuencia determinista con reloj de prueba.
  Victoria preparada mediante DEV, fallo por tiempo después de preparar el
  tablero. Ambos resultados y el guardado se mantienen idénticos durante toda
  la presentación. Videos decodificados y cuadros revisados visualmente.
- Las pruebas existentes de partida cubren iPad/escritorio, horizontal, redimensión,
  acciones y texto al 200 %. No se afirma revisión manual de dispositivos físicos,
  VoiceOver real o del host de YouTube: corresponde a W3-06.

| Caso | Evidencia |
| --- | --- |
| A01 | Conteo monotónico, escala fija, un sonido al cruzar y pulso solo de la estrella nueva. |
| A02 | Meta exacta permanece apagada hasta el último frame. |
| A03–A04 | Fallo por puntaje, vidas o tiempo desde el repositorio; presentación rechaza celebrar cualquier resultado no aprobado, incluso sobre la meta. Condiciones perfectas protegidas por las pruebas de persistencia. |
| A05 | Cero puntos inmediato y un millón de puntos, sin overflow ni división por cero. |
| A06 | Primer toque revela, siguiente acción/teclado avanza; toque cercano al final no se convierte en Continuar. |
| A07 | Pausa congela conteo; redimensión conserva progreso; retorno no repite sonido; resultado reabierto está completo. |
| A08 | Movimiento reducido y navegación accesible no esperan animaciones. |
| A09 | Tercera estrella, resultado recuperable y resumen existentes verificados. |
| A10 | Tutorial usa el mismo componente de estrellas/barra; sus pruebas conservan el guardado real. |

## Reproducir

```sh
TUTORIAL_CAPTURE_DIR=/tmp/sundoku-w305-frames flutter test test/world3_result_capture_test.dart --reporter expanded
flutter test test/widgets/challenge_result_reveal_test.dart test/data/challenge_debug_complete_test.dart test/world3_gameplay_widget_test.dart
```

Separar los PNG `won-frame-*` y `failed-frame-*` en directorios distintos y usar
`../introduction/encode-video.swift` para codificar cada secuencia con AVFoundation.
No se versionan los cuadros temporales completos; sí los videos y capturas de hitos.

Siguiente etapa: **W3-06 · validación final y entrega**.
