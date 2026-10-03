# W3-00 · Referencia registrada

03/10/2026 · Base de aplicación: `a598639c36a3c88ab8de01f44da0746d688a6e45`.

La preparación técnica de W3-00 está realizada: capturas, guardados sintéticos,
pruebas de referencia y navegación documentados. Al capturar esta referencia,
D06 seguía pendiente y no había reglas ni contador nuevos implementados.

**Actualización durante W3-01:** el usuario eligió un límite de tiempo para ganar
la estrella. Ver [reglas y calibración](../01-reglas-y-calibracion.md). Las capturas,
fixtures y resultados siguientes se conservan como evidencia histórica.

## Evidencia visual

[Abrir galería de las 21 capturas](gallery.html).

| Pantalla existente | Teléfono | iPad (viewport) | Escritorio |
| --- | --- | --- | --- |
| Partida mundo 1 | [390×844](captures/phone-world-1-game.png) | [834×1210](captures/ipad-world-1-game.png) | [1440×900](captures/desktop-world-1-game.png) |
| Partida mundo 2 | [390×844](captures/phone-world-2-game.png) | [834×1210](captures/ipad-world-2-game.png) | [1440×900](captures/desktop-world-2-game.png) |
| Partida mundo 3 | [390×844](captures/phone-world-3-game.png) | [834×1210](captures/ipad-world-3-game.png) | [1440×900](captures/desktop-world-3-game.png) |
| Reglas · Las filas | [390×844](captures/phone-rules.png) | [834×1210](captures/ipad-rules.png) | [1440×900](captures/desktop-rules.png) |
| Anotaciones · La respuesta es el 2 | [390×844](captures/phone-notes.png) | [834×1210](captures/ipad-notes.png) | [1440×900](captures/desktop-notes.png) |
| Resultado de ronda | [390×844](captures/phone-round-result.png) | [834×1210](captures/ipad-round-result.png) | [1440×900](captures/desktop-round-result.png) |
| Resumen de nivel | [390×844](captures/phone-level-result.png) | [834×1210](captures/ipad-level-result.png) | [1440×900](captures/desktop-level-result.png) |

Renderizados con widgets reales, fuentes y recursos actuales: Flutter 3.47.2,
Dart 3.13.2, host macOS 26.6.2 arm64. Pixel ratio 1, escala de texto 1 y movimiento
reducido. Las dimensiones de iPad son una referencia de layout; estas imágenes
no provienen de un dispositivo físico ni de un simulador iOS. Tampoco sustituyen
la futura comprobación en el host de YouTube Playables.

Se revisaron visualmente muestras de los tres tamaños, las partidas de los tres
mundos, ambos tutoriales y ambos resultados. Las 21 capturas tienen verificación
automática de render sin excepciones. Las partidas conservan números debajo del
tablero y admiten una jugada después de la captura. Las reglas en escritorio
conservan su composición lateral actual; el nuevo tutorial seguirá el contrato de
texto inferior de W3-04, sin cambiar la lección anterior.

## Guardados reproducibles

[Siete fixtures y su documentación](../../../../test/fixtures/world3-baseline/README.md):
perfil nuevo, mundo 2 completo, una estrella, dos estrellas, ronda en curso,
nivel completado y mundo 3 completado. Perfil sintético, seed estable y reloj
fijado. Los prerrequisitos se preparan con registros sintéticos; las tres rondas
del nivel 1 del mundo 3 se resuelven mediante el repositorio real.

La tercera ronda conserva error y pista: prueba que la migración futura debe
respetar estrellas ya ganadas bajo las reglas anteriores. Los snapshots no
representan la aplicación anticipada de ninguna regla nueva.

## Validaciones ejecutadas

| Verificación | Resultado | Evidencia |
| --- | --- | --- |
| Análisis de aplicación antes de cambios | 0 errores, 0 warnings, 4 infos previos; salida 1 por infos. | [Salida](validation/analysis-before.txt) |
| Regresión seleccionada: 22 archivos | 130 aprobadas, 4 fallidas. | [Salida](validation/regression-before.txt) |
| Repetición aislada de dos archivos fallidos | 3 aprobadas, mismos 4 fallos. | [Salida](validation/known-failures-isolated.txt) |
| Exportación explícita de fixtures | 1 aprobada. | [Salida](validation/fixture-export.txt) |
| Restauración + capturas nuevas | 28 aprobadas: 7 guardados y 21 capturas. | [Salida](validation/captures-and-restore.txt) |
| Análisis final de los tres archivos nuevos | Sin errores, warnings ni infos. | [Salida](validation/new-tests-analysis.txt) |

Los cuatro infos se encuentran en `map_ambient_motion.dart` (39, 73, 455) y
`map_parallax_scene.dart` (430): dos sugerencias de superparámetros y dos de llaves.
No se modifican en esta etapa de referencia.

### Fallos conocidos anteriores a W3-01

| ID | Caso | Evidencia / alcance |
| --- | --- | --- |
| B01 | Tres pruebas de `level_unlock_test.dart`, líneas 105, 207, 234 | Esperan el texto «Los primeros pasos» y encuentran cero widgets. Las comprobaciones anteriores de estrellas/desbloqueo pasan en esos casos; falta revisar la expectativa de texto frente al mapa actual. |
| B02 | `contextual_help_widget_test.dart`, caso `small=true` | Al abrir ayuda en 320×568 con texto 1,6 aparece un RenderFlex overflow de 283 px. Problema real de layout de ayuda; requiere corrección antes de declarar completa la regresión responsive. |

Estos fallos se reprodujeron antes de modificar `lib/`, y también con concurrencia
1. No se desactivaron pruebas ni se ocultaron errores. W3-00 registra el estado;
la entrega final del mundo 3 no puede declarar la regresión íntegramente verde
sin resolver o delimitar con evidencia estos casos. El análisis de los tres
archivos de pruebas nuevos debe permanecer sin hallazgos.

## Navegación actual y límites a conservar

1. `lib/app.dart` crea `WorldJourneyRoute` y pasa el mundo al mapa. El santuario
   utiliza `_switchWorld` → `enterWorld` → `visitWorld`; se conserva el reemplazo
   de ruta y el último mundo visitado.
2. `MapScreen._focusLevel` abre `LevelSummaryRoute`; la acción afirmativa llama a
   `_openSelectedLevel`. Cancelar regresa al mapa sin iniciar otra sesión.
3. `_openAdventureGame` materializa/reanuda los tres sudokus y abre
   `FirstExperienceScreen`. El mundo 2 conserva su comprobación de anotaciones.
4. El repositorio hoy entrega una estrella al resolver. El controlador presenta
   celebración en las dos primeras rondas y resumen final en la tercera.
5. «Vamos al segundo/tercero» avanza dentro del flujo existente. Al finalizar,
   «Volver al mapa» y «Siguiente juego» mantienen sus destinos y condiciones.
6. Los niveles completados no se vuelven a jugar, salvo la práctica inicial del
   mundo 1. W3-02 añadirá retry de una ronda fallida, no replay de niveles ganados.

Esta navegación se contrastó con el código, las capturas y las pruebas existentes
de puerta, controladores y finalización. No se afirma haber realizado una sesión
manual completa en dispositivo físico en esta etapa.

## Cómo reproducir

Desde la raíz del proyecto:

```sh
flutter analyze
flutter test test/data/world3_baseline_test.dart
W3_BASELINE_CAPTURE_DIR=/tmp/sundoku-w3-captures flutter test test/world3_baseline_capture_test.dart
flutter test --concurrency=1 test/level_unlock_test.dart test/contextual_help_widget_test.dart
```

La selección de 22 archivos aparece en las cargas y nombres de la salida de
regresión. Incluye puntaje/modelos, repositorio/notas, controladores, mundos,
layout, tutoriales, partida rápida y adaptador Playables. No se ejecutó toda la
suite del proyecto ni se publica una certificación de plataformas a partir de ella.

Las capturas actuales y fixtures se congelan como referencia. Usar directorios
temporales para próximas comparaciones, sin sobrescribir la base. El
[manifiesto](manifest.json) registra dimensiones y SHA-256 de cada captura y fixture.

## Estado de cierre

- [x] Entorno, commit y referencia visual registrados.
- [x] Siete guardados de prueba y 28 verificaciones nuevas aprobadas.
- [x] Regresión previa ejecutada; fallos e infos identificados.
- [x] Flujo y límite de repetición contrastados con el código.
- [x] Sin cambios en `lib/`, arte, dependencias ni guardado del usuario.
- [x] D06: resuelta durante W3-01; límite de tiempo elegido por el usuario.

Consulta histórica: bonus de rapidez o límite para aprobar. Respuesta recibida:
«Prefiero un límite de tiempo para ganar la estrella».
