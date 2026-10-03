import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/domain/generation/seeded_sudokus.dart';
import 'package:sundoku/domain/scoring/adventure_challenge.dart';
import 'package:sundoku/domain/scoring/sudoku_scoring.dart';

import '../generation/seeded_sudokus_test.dart' show solutionCount;
import '../../support/challenge_simulation.dart';

const profiles = [
  '00000000-0000-4000-8000-000000000001',
  '00000000-0000-4000-8000-000000000002',
  '00000000-0000-4000-8000-000000000003',
];

void main() {
  test('R09/R10/R12: 270 unique deterministic boards and playable score margins', () {
    final rows = <Map<String, Object?>>[];
    final scenarios = <String, void Function(ChallengeSimulation)>{
      'perfect': (s) => s.solve(),
      'reverse': (s) => s.solve(reverse: true),
      'errorEarly': (s) {
        s.enter(
          s.empty.first,
          s.puzzle.solution[s.empty.first] % s.puzzle.size + 1,
        );
        s.solve();
      },
      'errorLate': (s) {
        for (final i in s.empty.take(s.empty.length - 1)) {
          s.enter(i, s.puzzle.solution[i]);
        }
        s.enter(
          s.empty.last,
          s.puzzle.solution[s.empty.last] % s.puzzle.size + 1,
        );
        s.solve();
      },
      'hintAtZero': (s) {
        s.enter(s.empty.first, s.puzzle.solution[s.empty.first], hint: true);
        s.solve();
      },
      'hintEarly': (s) {
        for (final i in s.empty.take(6)) {
          s.enter(i, s.puzzle.solution[i]);
        }
        s.enter(s.empty[6], s.puzzle.solution[s.empty[6]], hint: true);
        s.solve();
      },
      'explanationOnly': (s) {
        for (final i in s.empty.take(6)) {
          s.enter(i, s.puzzle.solution[i]);
        }
        s.explain();
        s.solve();
      },
      'explanationAtZero': (s) {
        s.explain(index: s.empty.first);
        s.solve();
      },
      'hintCompletesRow': (s) {
        final row = s.empty.first ~/ s.puzzle.size;
        final cells = s.empty.where((i) => i ~/ s.puzzle.size == row).toList();
        for (final i in cells.take(cells.length - 1)) {
          s.enter(i, s.puzzle.solution[i]);
        }
        s.enter(cells.last, s.puzzle.solution[cells.last], hint: true);
        s.solve();
      },
      'hintLastCell': (s) {
        for (final i in s.empty.take(s.empty.length - 1)) {
          s.enter(i, s.puzzle.solution[i]);
        }
        s.enter(s.empty.last, s.puzzle.solution[s.empty.last], hint: true);
      },
      'justBeforeDeadline': (s) {
        s.progress = s.progress.copyWith(elapsedMs: s.rules.timeLimitMs - 1);
        s.solve();
      },
      'atDeadline': (s) {
        s.solve();
        s.progress = s.progress.copyWith(elapsedMs: s.rules.timeLimitMs);
      },
      'afterDeadline': (s) {
        s.solve();
        s.progress = s.progress.copyWith(elapsedMs: s.rules.timeLimitMs + 1);
      },
    };
    for (final profile in profiles) {
      for (var level = 1; level <= 30; level++) {
        for (var round = 1; round <= 3; round++) {
          final id = 'world-3/level-$level/sudoku-$round';
          final seed = '$profile/$id';
          final puzzle = SeededSudokus.create(id: id, seed: seed);
          expect(
            SeededSudokus.create(id: id, seed: seed).toJson(),
            puzzle.toJson(),
          );
          expect(solutionCount(puzzle.initial), 1, reason: seed);
          final rules = AdventureChallenges.forPuzzle(
            worldId: 'world-3',
            level: level,
            puzzle: puzzle,
          )!;
          expect(rules.timeLimitMs, 1260000);
          final results = <String, Object?>{};
          for (final scenario in scenarios.entries) {
            final simulation = ChallengeSimulation(puzzle, rules);
            scenario.value(simulation);
            final result = simulation.result;
            results[scenario.key] = {
              'points': simulation.progress.points,
              'mistakes': simulation.progress.mistakes,
              'hints': simulation.progress.hintsUsed,
              'elapsedMs': simulation.progress.elapsedMs,
              'solved': result.solved,
              'outcome': result.outcome.name,
            };
            expect(
              simulation.progress.points,
              inInclusiveRange(0, rules.perfectPoints),
            );
            if ([
              'perfect',
              'reverse',
              'justBeforeDeadline',
            ].contains(scenario.key)) {
              expect(result.won, isTrue, reason: '$seed ${scenario.key}');
              expect(simulation.progress.points, rules.perfectPoints);
            }
            if (['atDeadline', 'afterDeadline'].contains(scenario.key)) {
              expect(result.outcome, ChallengeOutcome.outOfTime);
            }
            if (level >= 21 && scenario.key.startsWith('error')) {
              expect(result.outcome, ChallengeOutcome.outOfLives);
            }
            if (level == 30 &&
                (scenario.key.startsWith('hint') ||
                    scenario.key.startsWith('explanation'))) {
              expect(result.outcome, ChallengeOutcome.hintsNotAllowed);
            }
            if (level == 1 &&
                [
                  'errorEarly',
                  'errorLate',
                  'hintAtZero',
                  'hintEarly',
                  'explanationOnly',
                ].contains(scenario.key)) {
              expect(
                result.won,
                isTrue,
                reason: 'Initial margin: $seed ${scenario.key}',
              );
            }
          }
          rows.add({
            'profile': profile,
            'level': level,
            'round': round,
            'seed': seed,
            'generatorVersion': puzzle.generatorVersion,
            'emptyCells': puzzle.initial.where((n) => n == null).length,
            'perfectPoints': rules.perfectPoints,
            'targetPoints': rules.targetPoints,
            'targetBasisPoints': rules.targetBasisPoints,
            'margin': rules.perfectPoints - rules.targetPoints,
            'relativeMargin':
                (rules.perfectPoints - rules.targetPoints) /
                rules.perfectPoints,
            'initialLives': rules.initialLives,
            'timeLimitMs': rules.timeLimitMs,
            'uniqueSolutions': 1,
            'scenarios': results,
          });
        }
      }
    }
    expect(rows, hasLength(270));
    final export = Platform.environment['W3_CALIBRATION_DIR'];
    if (export != null) {
      final directory = Directory(export)..createSync(recursive: true);
      File('${directory.path}/results.json').writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert({'rulesVersion': AdventureChallenges.version, 'scoringVersion': SudokuScoring.version, 'timePolicy': ChallengeTimePolicy.activeTimeLimit.name, 'rows': rows})}\n',
      );
      final report = StringBuffer('''# Calibración W3-01

Reglas `${AdventureChallenges.version}` · puntaje `${SudokuScoring.version}`.
270 tableros (3 perfiles sintéticos × 30 niveles × 3 rondas), con solución única
verificada por backtracking independiente y regeneración idéntica por seed.
${rows.length * scenarios.length} simulaciones usan el motor real de puntaje.
El simulador detiene las entradas ante un resultado terminal.

## Curva y resultados

P = referencia perfecta; meta = techo(P × proporción), limitada a P−1 antes del
nivel 30. El 30 requiere P, cero errores y cero pistas. No hay bonus de tiempo.
Todos los tableros actuales tienen 38 vacíos: límite inicial de **21 minutos de
tiempo activo por ronda** (2 minutos + 30 segundos por vacío). Al llegar a cero
se pierde el intento, incluso con puntaje suficiente. Pausa y segundo plano no
deben consumir tiempo; su conexión al vencimiento se implementará en W3-02/03.
Este plazo es balance inicial, pendiente de pruebas con jugadores.

Cada celda de escenarios cuenta aprobaciones sobre 9 tableros del nivel.
La ayuda que completa el tablero también pierde los premios de cierre, por eso
cuesta mucho más que los 77 puntos de la ayuda aislada.

| Nivel | Vidas | Meta % | P | Meta | Margen | Error temprano/tardío | Pista a cero/temprana | Explicación | Pista fila/final |
| --- | ---: | ---: | --- | --- | --- | --- | --- | --- | --- |
''');
      String span(Iterable<Map<String, Object?>> data, String key) {
        final values = data.map((r) => r[key] as int).toSet().toList()..sort();
        return values.length == 1
            ? '${values.first}'
            : '${values.first}–${values.last}';
      }

      for (var level = 1; level <= 30; level++) {
        final subset = rows.where((r) => r['level'] == level).toList();
        int wins(String scenario) => subset
            .where(
              (r) =>
                  ((r['scenarios'] as Map)[scenario] as Map)['outcome'] ==
                  'won',
            )
            .length;
        report.writeln(
          '| $level | ${subset.first['initialLives']} | ${((subset.first['targetBasisPoints'] as int) / 100).toStringAsFixed(1)} | ${span(subset, 'perfectPoints')} | ${span(subset, 'targetPoints')} | ${span(subset, 'margin')} | ${wins('errorEarly')}/${wins('errorLate')} | ${wins('hintAtZero')}/${wins('hintEarly')} | ${wins('explanationOnly')} | ${wins('hintCompletesRow')}/${wins('hintLastCell')} |',
        );
      }
      report.writeln('''

En las 270 rondas, resolución perfecta en ambos órdenes y 1 ms antes del límite:
aprobadas. A tiempo igual o superior al límite: rechazadas. Desde el nivel 21,
un error termina el intento; en el 30 todas las ayudas ensayadas lo invalidan.
Las ayudas del nivel 30 simulan historial inválido/importado; su bloqueo antes
de cobrar puntos se implementará en el repositorio y la UI, en W3-02/03.

Detalle por seed, versiones, puntajes y cada escenario: [results.json](results.json).
Las pruebas también incluyen explicación dirigida con puntaje cero. Con el
redondeo observado no hay mesetas de meta proporcional entre niveles; los
valores absolutos dependen de los grupos ya completos al inicio de cada tablero.

Reproducción desde la raíz del proyecto:

```sh
W3_CALIBRATION_DIR=design/world-3-crossed-rivers/gameplay-specs/calibration flutter test test/domain/scoring/adventure_calibration_test.dart
```

En los tableros ensayados, desde el nivel 22 una pista dirigida ya consume más
que el margen disponible, aunque siga permitida hasta el 29. Solo el 30 agrega
la prohibición explícita. Pedir una explicación sin casilla a cero puntos puede
no restar puntaje; por eso el 30 comprueba el historial además del total.

Estas simulaciones validan reglas y puntajes, no la dificultad humana ni la UI.
Las reglas todavía no se activan en las sesiones: persistencia, reloj del
controlador y presentación corresponden a W3-02–05.
''');
      File('${directory.path}/README.md').writeAsStringSync(report.toString());
    }
  });
}
