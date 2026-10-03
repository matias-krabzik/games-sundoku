# W3-00 · Base, alcance y decisiones

Depende de: nada. Siguiente: [W3-01](01-reglas-y-calibracion.md).

Estado al 03/10/2026: referencia técnica preparada. Ver [informe y capturas](baseline/README.md).
D06 resuelta durante W3-01: el usuario eligió un límite de tiempo para la estrella.

## Objetivo

Fijar la referencia funcional y visual antes de modificar el comportamiento.
Registrar las decisiones pendientes sin convertir propuestas en reglas aprobadas.

## Hechos comprobados en el código

| Área | Estado actual | Consecuencia |
| --- | --- | --- |
| Catálogo | `world-3` tiene 30 niveles y tres rondas por nivel. Mundo 2 tiene 20 niveles. | Conservar IDs, cantidades y prerrequisitos; no copiar cifras históricas del bosque. |
| Generación | `startGeneratedLevel` deriva la seed del perfil y del puzzle; conserva definiciones registradas. | No existe un único lote universal de 90 tableros. Calibrar por definición real y probar varios perfiles. |
| Finalización | `_editCell` marca `completed` al resolver; `GameSession.lights` cuenta esos estados. | Separar tablero resuelto, resultado aprobado y presentación del resultado. |
| Puntaje | Aciertos, rachas y grupos suman; pistas cuestan 77; error corta racha. | No asumir que un error resta puntos ni que el puntaje máximo prueba ausencia de errores. |
| Vidas | `GameplayStatusBar` muestra corazón e infinito. | Parametrizar el componente compartido, manteniendo el modo anterior. |
| Reloj | Se guarda tiempo activo; no hay bonificación ni límite. | Su efecto nuevo requiere decisión explícita. |
| Guardado | Repositorio serializa escrituras y publica después de confirmarlas. | Vida, resultado, estrella y desbloqueo deben confirmarse juntos. |
| Reintento | Existe `debugRestartPuzzle`, de uso DEV. | Crear un comando de producción; no exponer el reinicio DEV. |
| Repetición | Los niveles de aventura completados no se pueden repetir, salvo la práctica del mundo 1. | Reintentar una ronda fallida no habilita repetir niveles ya ganados. |

## Decisiones

| ID | Estado | Decisión / tarea |
| --- | --- | --- |
| D01 | Acordado | Tres sudokus por nivel; una estrella por sudoku aprobado. |
| D02 | Acordado en el plan | Vidas por sudoku: 3/2/1; se renuevan al cambiar o reintentar ronda. |
| D03 | Acordado | Meta progresiva en los 30 niveles; partida perfecta explícita solo en el 30. |
| D04 | Acordado | Notas libres; pistas disponibles antes del 30, sujetas a su costo en puntos. |
| D05 | Acordado | Tutorial inicial y contador final con barra y umbral. |
| D06 | Acordado por el usuario el 03/10/2026 | Límite de tiempo activo para ganar la estrella, sin bonus de rapidez. Al llegar a cero, fallo; pausas y segundo plano excluidos. |
| D07 | Balance inicial de implementación | Curva 85–100 % y tiempo de 120 s + 30 s por vacío, justificados/documentados en W3-01. Ajustables tras pruebas de juego. |

D06 queda cerrada con la respuesta «Prefiero un límite de tiempo para ganar la
estrella». El reloj mantiene pausa real, exclusión de segundo plano y detención
antes del resultado. No depende de la duración de las animaciones.

El límite es exclusivo: con límite de 21:00, una solución válida a 20:59.999
aprueba; a 21:00.000 falla. El puntaje es el del motor actual, sin bonus.
Al vencer, el intento falla incluso si aún hay vidas o puntos suficientes.
Una solución sin errores ni pistas también debe terminar antes del plazo.
El valor numérico inicial se documenta en W3-01 como balance de implementación,
no como duración aprobada mediante pruebas con jugadores.

## Referencia antes de editar

1. Registrar commit, versión de Flutter, plataforma y dimensiones de capturas.
2. Ejecutar los grupos de regresión relevantes de W3-06; distinguir fallos previos.
3. Capturar partida, tutorial de reglas, tutorial de anotaciones, resumen de ronda
   y de nivel en teléfono, iPad y escritorio. Incluir partida de mundos 1 y 2.
4. Guardar fixtures reproducibles: perfil nuevo, mundo 2 completado, mundo 3 con
   una/dos estrellas, sesión en curso y mundo 3 ya terminado.
5. Documentar la navegación real: puerta de mundo, selección de nivel, ronda,
   resultado, siguiente ronda, resumen final y regreso al mapa.

Las referencias visuales deben salir de widgets reales o de la app. No generar
mockups para sustituir capturas de regresión. Los fixtures no deben contener
datos personales y las pruebas deben usar almacenamiento aislado del usuario.

## Archivos de referencia

- `lib/data/world_catalog.dart`, `lib/data/level_catalog.dart`.
- `lib/data/repositories/game_repository.dart` y `lib/domain/models/game_session.dart`.
- `lib/domain/scoring/sudoku_scoring.dart` y `lib/domain/generation/seeded_sudokus.dart`.
- `lib/controllers/game_session_controller.dart`, `lib/controllers/first_experience_controller.dart`.
- `lib/screens/first_experience_screen.dart`, `lib/screens/notes_tutorial_screen.dart`.
- `lib/widgets/gameplay_status_bar.dart`, `lib/widgets/game_layout.dart`.
- `lib/widgets/completed_level_popover.dart`, `lib/widgets/sudoku_time_summary.dart`.

Las rutas son referencias existentes, no una lista obligatoria de archivos a editar.
Evitar refactorizaciones ajenas a este cambio.

## Cierre

- [x] Referencia visual y guardados de prueba disponibles.
- [x] D06 documentada antes de cerrar W3-01 y el guion de W3-04.
- [x] Diferencias previstas y alcance de la regresión identificados.
- [x] Ningún cambio incidental en mapa, arte, otros mundos o dependencias.
