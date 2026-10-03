# Verificación de W3-01 · 03/10/2026

Base de aplicación `a598639`; Flutter 3.47.2 / Dart 3.13.2 en macOS, mismo
entorno que W3-00. Almacenamiento de pruebas aislado; sin usar el perfil real.

Implementados la política `AdventureChallenges`, la instantánea inmutable
`RoundChallengeRules`, evaluación pura del resultado y referencia perfecta de
`SudokuScoring`. La extracción de recompensas compartidas conserva exactamente
la fórmula global. No cambian generador, catálogo, UI, controladores ni repositorio.
La persistencia/activación de las reglas todavía corresponde a W3-02/03.

## Evidencia

- **15 pruebas nuevas aprobadas**, que incluyen 3510 escenarios en 270 tableros:
  [log](validation/rules-tests.txt).
- **71 pruebas existentes/de referencia aprobadas**:
  [log](validation/regression.txt). Cubren puntajes, modelos, repositorio,
  anotaciones, controladores/reloj, generación, mundo 3, puertas, siete fixtures
  heredadas y adaptador de Playables.
- **Análisis de todos los archivos de código modificados/nuevos sin incidencias**:
  [log](validation/analysis.txt).
- Exportación repetida tras añadir margen relativo al informe: **1 prueba
  aprobada**, los mismos 270 tableros y 3510 escenarios:
  [log](validation/calibration-export.txt).
- `git diff --check`: sin errores. Formato Dart aplicado a los seis archivos.

## Matriz de reglas

| Casos | Evidencia y alcance |
| --- | --- |
| R01 | `adventure_challenge_test`: 30 niveles, fronteras 10/11 y 20/21, condiciones del 30, redondeo y margen positivo. |
| R02–R05 | Tablero resuelto/no resuelto, meta−1/igual/+1, cero vidas y contadores históricos inválidos. |
| R06–R07 | `challenge_scoring_contract_test`: jugadas reales de repositorio, error repetido, borrar/repetir, notas, pausa, tiempo y ausencia de doble premio. |
| R08 | Pistas con cero puntos, explicación dirigida y condición explícita del 30, incluyendo historial importado. El bloqueo de la acción real es W3-02/03. |
| R09 | Totales independientes 503/567/1379, cinco dificultades, grupos dados completos y dos órdenes de resolución; contraste con motor y repositorio. |
| R10 | Tres perfiles × 90 rondas, regeneración determinista y solución única por verificador independiente; referencia/meta por definición real. |
| R11 | Política nula para mundos 1/2 y rápida; regresión existente conserva premios/guardados y excepciones actuales. |
| R12 | Milisegundo anterior, igualdad y posterior al límite; vencimiento sin resolver; ningún bonus. Pruebas existentes de controladores/Playables excluyen pausa y segundo plano del tiempo activo. La conexión entre tick, última jugada y fallo persistido se verifica en W3-02/03. |

Código de pruebas desde la raíz: `test/domain/scoring/adventure_challenge_test.dart`,
`test/domain/scoring/adventure_calibration_test.dart` y
`test/data/challenge_scoring_contract_test.dart`. El controlador de simulaciones
está en `test/support/challenge_simulation.dart` y usa el motor real de puntaje.
No simula la persistencia ni sustituye las pruebas de integración posteriores.

## Comandos ejecutados

```sh
flutter test test/domain/scoring/adventure_challenge_test.dart test/domain/scoring/adventure_calibration_test.dart test/data/challenge_scoring_contract_test.dart --reporter expanded
flutter test test/domain/scoring/sudoku_scoring_test.dart test/domain/game_models_test.dart test/data/game_repository_test.dart test/data/notes_test.dart test/controllers/game_session_controller_test.dart test/controllers/first_experience_controller_test.dart test/controllers/generated_levels_test.dart test/data/crossed_rivers_world_test.dart test/data/world_gate_test.dart test/data/world3_baseline_test.dart test/playables/playables_integration_test.dart --reporter expanded
flutter analyze lib/domain/scoring test/domain/scoring test/support/challenge_simulation.dart test/data/challenge_scoring_contract_test.dart
W3_CALIBRATION_DIR=design/world-3-crossed-rivers/gameplay-specs/calibration flutter test test/domain/scoring/adventure_calibration_test.dart --reporter expanded
git diff --check
```

## Límites de esta etapa

La curva y el plazo de 21 minutos son balance inicial, no una medida validada con
jugadores. Las metas consideran que una ayuda puede excluir premios de cierre;
los resultados concretos están en [el informe](README.md). Desde el 22 las pistas
dirigidas ensayadas superan el margen de puntos, aunque se permiten hasta el 29.

No hay cambios visibles ni nuevas capturas en W3-01. Se conservan las capturas y
fixtures de W3-00. No se repitió toda la suite visual: sus cuatro fallos previos
(tres expectativas de texto en `level_unlock_test` y overflow de ayuda en teléfono
pequeño) siguen registrados en [W3-00](../baseline/README.md), fuera de esta etapa.
Las cuatro sugerencias de lint globales previas tampoco fueron objeto del cambio.
No se declara validación nueva en dispositivo físico, simulador de iPad ni host
real de Playables; aquí se ejecutaron pruebas automatizadas de lógica/adaptador.
