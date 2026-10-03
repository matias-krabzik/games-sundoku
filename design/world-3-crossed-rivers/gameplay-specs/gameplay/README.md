# W3-03 · Partida y navegación

03/10/2026 · Base de trabajo: `10635db`. Flutter 3.47.2 / Dart 3.13.2, macOS.

Implementado el flujo visible con resultado estático. La app habilita desafíos
para **sesiones nuevas** del mundo 3. Sesiones heredadas, mundos 1/2 y partida
rápida conservan sus reglas. La introducción guiada (W3-04), el contador animado
(W3-05) y la validación final de plataformas (W3-06) siguen pendientes.

## Para revisar

[Abrir galería de partida, resultados y comparaciones](gallery.html).

| Vista | Partida | Victoria | Fallo por tiempo |
| --- | --- | --- | --- |
| Teléfono · 390×844 | [Ver](captures/phone-playing.png) | [Ver](captures/phone-won.png) | [Ver](captures/phone-timeout.png) |
| iPad vertical · 834×1210 | [Ver](captures/ipad-playing.png) | [Ver](captures/ipad-won.png) | [Ver](captures/ipad-timeout.png) |
| iPad horizontal · 1210×834 | [Ver](captures/ipad-landscape-playing.png) | [Ver](captures/ipad-landscape-won.png) | [Ver](captures/ipad-landscape-timeout.png) |
| Escritorio · 1440×900 | [Ver](captures/desktop-playing.png) | [Ver](captures/desktop-won.png) | [Ver](captures/desktop-timeout.png) |

Son capturas de widgets reales, con fuentes/arte existentes y datos sintéticos.
Los resultados se preparan mediante jugadas del repositorio, sin espera humana;
por eso una victoria puede mostrar 00:00. Nuevas capturas a pixel ratio 2;
comparaciones heredadas a ratio 1. Las dimensiones indicadas son píxeles lógicos.

## Comportamiento integrado

- El resumen del mapa muestra vidas por ronda, meta y plazo antes de Jugar.
  El panel inicial confirma estas condiciones con el reloj detenido.
- HUD: corazón y vidas restantes/iniciales, puntos/meta y tiempo restante. Mantiene
  la reacción visual del puntaje y la barra cerca del tablero.
- Fallos por vidas, tiempo o meta insuficiente bloquean la entrada y presentan
  Reintentar. Reinicia solo esa ronda y conserva las estrellas anteriores.
- Victoria de ronda 1/2 → Continuar inicia la siguiente con vidas renovadas.
  La tercera estrella tiene su propio resultado antes del resumen existente.
- Al volver al mapa, un resultado pendiente ofrece Ver resultado. La tercera
  victoria se puede recuperar incluso si el nivel ya quedó completado. Tras
  reconocerla, el nivel vuelve a impedir repetición; no aparece nivel 31.
- Nivel 30: condición visible, ayuda deshabilitada con explicación accesible,
  anotaciones disponibles. Modal con semántica de ruta y fondo no interactivo.
- Sin arte nuevo: paneles nine-patch, botones amarillos, estrellas, Baloo 2 y azul
  compartidos. Los textos y acciones son widgets independientes.

## Responsive y conservación visual

Se probó la matriz de **16 tamaños** de W3-06 con texto al 100 % y 200 %,
redimensionando una misma partida con selección activa. El tablero conserva su
estado, los números permanecen debajo y no hay scroll de partida ni overflow.
Las acciones del resultado siguen accesibles en pequeño, horizontal y iPad.
Movimiento normal probado en 390×844, 834×1210 y 1440×900; reducido en la matriz.

La integración reveló que el espacio de anotaciones se estimaba por cantidad
fija de líneas. Ahora se mide con su ancho, escala y estilo heredado reales.
Se incluye el padding de herramientas en el presupuesto de altura; en horizontal
estrecho la información contextual aprovecha el lateral. La ayuda usa el mismo
criterio de medición. Esto también corrige el fallo previo de ayuda en 320×568
con texto 1.6; [captura](captures/ayuda-320-texto-grande.png). En ese caso extremo
el tablero se reduce para conservar texto y controles en pantalla; su ergonomía
requiere revisión manual en dispositivo dentro de W3-06.

Los máximos siguen siendo 430/540 para tablero y 54 para números. Se revisaron
capturas de teléfono, iPad vertical/horizontal y escritorio, más mundos 1/2.
Las tres referencias de partida en teléfono son idénticas pixel a pixel a W3-00.
En iPad/escritorio las diferencias de las sesiones heredadas quedan en la zona
de números/herramientas; tablero, HUD y encabezado conservan posición y tamaño.

## Validación

- **113 pruebas aprobadas**, incluidas 11 nuevas de widgets de desafíos y regresión
  de persistencia, controladores, resúmenes, mapas, tutoriales, rápida, notas,
  ayuda contextual, puntuación y adaptador Playables. [Log](validation/tests.txt).
- **9 pruebas/capturas de referencia aprobadas**, una por mundo y tamaño nominal.
  [Log](validation/legacy-captures.txt). Total de esta validación: **122 pruebas**.
- `flutter analyze`: sin errores ni warnings; cuatro infos preexistentes en
  `map_ambient_motion.dart` y `map_parallax_scene.dart`. [Log](validation/analysis.txt).
- Formato aplicado a cambios Dart y `git diff --check` sin errores.

| Casos W3-03 | Evidencia |
| --- | --- |
| F01 | Vista de condiciones y reglas congeladas coinciden; resumen del mapa antes de iniciar. |
| F02 | Error resta vida; HUD sincronizado y misma instancia del tablero. |
| F03–F04 | Fallos por vidas, tiempo y puntos; sin partículas de victoria; reintento operativo. |
| F05 | Tres victorias, vidas renovadas, resultado de la tercera antes del resumen final. |
| F06 | Nivel 30 sin ayuda, explicación accesible y lápiz disponible. |
| F07 | Redimensionado estable; pausa; cerrar/reabrir repositorio recupera fallo de ronda 2 con estrella previa. |
| F08 | Suites `summit_gate_test` y `world_gate_test`: acceso y prerrequisitos conservados. |
| F09 | Resultado final recuperable desde resumen; cierre del mundo sin nivel 31 ni replay. |
| F10 | Suites de partida generada, rápida, layout, tutoriales y nueve referencias visuales heredadas. |
| F11 | Cuenta regresiva y pausa visibles; controlador prueba vencimiento autónomo, límite exacto y suspensión Playables. |

Las jugadas terminales con movimiento normal se realizan mediante
`FirstExperienceController`, además de las pruebas de repositorio. No dependen
del menú DEV. Guardados de prueba aislados; no se modificó el perfil del usuario.

## Reproducir las capturas

Desde la raíz del proyecto:

```sh
TUTORIAL_CAPTURE_DIR="$PWD/design/world-3-crossed-rivers/gameplay-specs/gameplay/captures" flutter test test/world3_gameplay_widget_test.dart --reporter expanded
W3_BASELINE_CAPTURE_DIR="$PWD/design/world-3-crossed-rivers/gameplay-specs/gameplay/legacy-captures" flutter test test/world3_baseline_capture_test.dart --name 'world-[123]-game' --reporter expanded
flutter analyze
git diff --check
```

La lista de suites de regresión está en el log; las pruebas nuevas están en
`test/world3_gameplay_widget_test.dart`. La ayuda ampliada se captura ejecutando
`test/contextual_help_widget_test.dart` con `TUTORIAL_CAPTURE_DIR`.

## Límites y siguiente etapa

No se declara validada la ejecución en simulador iOS, dispositivo físico ni host
real de YouTube Playables: aquí se comprobaron widgets y adaptadores con pruebas
automatizadas. W3-06 mantiene esas comprobaciones, además de lector de pantalla
y ergonomía de controles con texto ampliado. No se ejecutó toda la suite del
repositorio; siguen registrados los fallos históricos de títulos en `level_unlock_test`.

Próximo spec: [W3-04 · Introducción y repaso](../04-introduccion.md).
