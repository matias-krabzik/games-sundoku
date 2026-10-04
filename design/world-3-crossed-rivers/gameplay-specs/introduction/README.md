# W3-04 · Introducción y repaso

03/10/2026 · Base: `397f880`. Flutter 3.47.2 / Dart 3.13.2, macOS.

[Galería de los cuatro pasos](gallery.html) · [Video de Siguiente](next-demo.mp4).

## Integración

Cuatro demostraciones automáticas explican reloj, puntos/meta, vidas y estrella.
Cada explicación avanza con una acción explícita. «Siguiente» termina primero
la aparición, la escritura y la demostración pendientes; otra pulsación avanza.
No se pide resolver casillas. La demostración usa el cálculo real de puntos en
un sudoku didáctico, sin escribir jugadas ni premios en el repositorio.

La primera entrada desde Aventura, santuario, mapa o enlace autorizado enseña
las reglas antes de jugar. La ruta `/world-3/introduction` respeta el desbloqueo.
El módulo `tutorials/world3-challenges/v1` guarda paso y reconocimiento; una
escritura fallida permite reintentar. Una sesión heredada sigue sin interrupción;
la siguiente sesión con desafíos recibe la lección pendiente.

«Tu cuaderno → Los desafíos» permite repasar después de desbloquear el mundo 3.
El repaso no modifica la partida ni reconoce una primera introducción pendiente.
El selector del cuaderno desplaza su contenido cuando falta altura y conserva
Cerrar accesible.

Reutiliza `TutorialPresentation`, `TutorialStory`, `TutorialActivity`, título,
card y progreso segmentado. Explicación debajo, ancho máximo de 470 px, misma
instancia y posición del tablero entre pasos. Fondo compuesto con las capas
existentes de Ríos Cruzados; superficies, estrellas, iconos y botones existentes.
Los remates, iconos y el contador de demostración quedan dentro de la tarjeta,
separados con la misma línea dorada de la bienvenida. `ChallengeLives` comparte
los corazones individuales con la partida: tres, dos o uno según el tramo,
y los perdidos se atenúan.

El componente de estrellas `ChallengeAward` es compartido con el resultado real
estático de W3-03. W3-05 seguirá con su animación en partidas reales.

## Validación

- **66 pruebas aprobadas**: introducción, controladores, partidas de desafíos,
  partida generada, santuario, puerta del mundo, anotaciones, presentación,
  navegación del tutorial y partida rápida. [Log](validation/tests.txt).
- Capturas de los cuatro pasos en 390×844, 834×1210, 1210×834 y 1440×900.
  Widgets reales con Baloo 2 y arte del proyecto, a escala de píxel 1.
- Redimensionado en siete tamaños, incluido 320×568 y 568×320, con texto al
  200 %, sin overflow y con acciones accesibles. El contenido central puede
  desplazarse cuando falta altura, tal como requieren las lecciones.
- Video generado con 51 capturas consecutivas del widget real, a cinco cuadros
  por segundo. Primera pulsación a 1,6 s: termina el paso 1. Segunda a 3,2 s:
  avanza al paso 2, que escribe y coloca el número automáticamente.
  [Prueba de captura](validation/motion.txt).
- `flutter analyze`: sin errores ni warnings nuevos; solo cuatro infos previos
  en fauna/parallax. [Log](validation/analysis.txt). `git diff --check` limpio.

| Caso | Evidencia automatizada |
| --- | --- |
| T01 | Aventura, santuario, entrada directa al juego y enlace; solo una introducción. Enlace bloqueado no abre el mundo. |
| T02 | Cuatro pasos sin entrada en tablero, final explícito y sin crear sesiones. |
| T03 | Primera pulsación completa animaciones, segunda avanza; video de widget. |
| T04 | Misma instancia y rectángulo del tablero en los cuatro pasos y tamaños nominales. |
| T05 | Reabrir repositorio restaura paso; rotación y texto 200 % conservan estado y acciones. |
| T06 | Reconocimiento persistido; fallo visible y reintento; regreso al mapa sin repetir. |
| T07 | Repaso directo y desde cuaderno dejan el guardado completo idéntico, con partida real activa. |
| T08 | Movimiento reducido y `accessibleNavigation` muestran estado final sin espera; segundo plano congela demostración. |
| T09 | Componentes compartidos, explicación debajo y máximo 470 px; regresión de anotaciones y presentación. |
| T10 | Fixture de sesión heredada entra sin lección; siguiente desafío recibe introducción. |

## Reproducir

```sh
W3_LESSON_CAPTURE_DIR="$PWD/design/world-3-crossed-rivers/gameplay-specs/introduction/captures" flutter test test/world3_tutorial_widget_test.dart --reporter expanded
```

Para exportar el clip en macOS, con un destino nuevo:

```sh
swift -module-cache-path /tmp/sundoku-swift-cache design/world-3-crossed-rivers/gameplay-specs/introduction/encode-video.swift design/world-3-crossed-rivers/gameplay-specs/introduction/captures/motion /tmp/sundoku-introduction.mp4
```

Los cuadros temporales del video no se versionan. Las capturas nominales y el
MP4 sí quedan en esta carpeta. El codificador del sistema puede requerir acceso
fuera del sandbox de desarrollo.

## Alcance

Revisión visual realizada sobre capturas y cuadros decodificados del video.
Estas pruebas no equivalen a validar VoiceOver real, dispositivo físico,
simulador iOS o host real de YouTube Playables. W3-06 conserva esas validaciones.
El contador animado en partidas reales corresponde a W3-05 y sigue pendiente.

## Ajuste visual de corazones y tarjeta

38 pruebas de partida, tutorial y componentes compartidos aprobadas tras el
ajuste. [Log](validation/hearts-tests.txt). Capturas de partida con tres vidas
y después de un error añadidas a la galería.

Tras compactar el remate y conservar su semántica, 24 pruebas de tutoriales
y presentación aprobadas de nuevo. [Log](validation/card-final-tests.txt).
