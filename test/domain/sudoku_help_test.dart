import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/domain/help/sudoku_help.dart';
import 'package:sundoku/domain/tutorial/tutorial_sudokus.dart';

class _ExtraRule implements SudokuHelpRule {
  @override
  SudokuHelpTip? evaluate(SudokuHelpContext context) => SudokuHelpTip(
    ruleId: 'extension',
    message: 'Otra regla',
    focusIndices: {context.selectedIndex},
  );
}

void main() {
  final solution = List.generate(
    81,
    (i) => (i ~/ 9 * 3 + i ~/ 27 + i % 9) % 9 + 1,
  );
  const engine = SudokuHelpEngine();
  SudokuHelpTip explain(
    List<int?> cells,
    int selected, {
    Set<int> fixed = const {},
  }) => engine.explain(
    SudokuHelpContext(
      cells: cells,
      selectedIndex: selected,
      fixedIndices: fixed,
    ),
  );
  List<int?> holes(List<int> indices) => [
    for (var i = 0; i < 81; i++) indices.contains(i) ? null : solution[i],
  ];
  List<int?> board(String values) =>
      values.split('').map((s) => s == '0' ? null : int.parse(s)).toList();

  test('screenshot selection r6c3 recognizes the single missing row value', () {
    final cells = board(
      '703541060'
      '692783451'
      '541692803'
      '927835146'
      '000416297'
      '410927385'
      '278354619'
      '354169708'
      '169078500',
    );
    final tip = explain(cells, 47);
    expect(tip.ruleId, 'last-empty-row');
    expect(tip.deducedValue, 6);
    expect(tip.focusIndices, {45, 46, 47, 48, 49, 50, 51, 52, 53});
  });

  test('finds the one empty cell in every position of all nine blocks', () {
    for (var selected = 0; selected < 81; selected++) {
      final cells = holes([selected]);
      final before = [...cells];
      final tip = explain(cells, selected);
      expect(tip.ruleId, 'last-empty-block');
      expect(tip.focusIndices, groupCells(selected, SudokuGroup.block).toSet());
      expect(tip.message, isNot(contains('${solution[selected]}')));
      expect(tip.deducedValue, solution[selected]);
      expect(tip.emphasizedNumber, isNull);
      expect(tip.arrivalIndex, selected);
      expect(cells, before);
    }
  });

  test('uses a single gap in the row or column when the block has several', () {
    final row = explain(holes([0, 9]), 0);
    expect(row.ruleId, 'last-empty-row');
    expect(row.focusIndices, groupCells(0, SudokuGroup.row).toSet());
    expect(row.message, contains('de lado a lado'));
    expect(row.emphasizedNumber, isNull);
    final column = explain(holes([0, 1]), 0);
    expect(column.ruleId, 'last-empty-column');
    expect(column.focusIndices, groupCells(0, SudokuGroup.column).toSet());
    expect(column.message, contains('de arriba abajo'));
    expect(column.emphasizedNumber, isNull);
  });

  test(
    'combines all three groups only when no single group is almost full',
    () {
      final cells = holes([0, 1, 9]);
      for (final group in SudokuGroup.values) {
        expect(
          groupCells(0, group).where((i) => cells[i] == null).length,
          greaterThan(1),
        );
      }
      final tip = explain(cells, 0);
      expect(tip.ruleId, 'only-candidate');
      expect(tip.emphasizedNumber, isNull);
      expect(tip.deducedValue, 1);
      expect(tip.focusIndices.length, 21);
    },
  );

  test('finds unique places in blocks, rows and columns with evidence', () {
    final fixtures = [
      (
        '003050009000709000709003456000500000507001000801000007000008010070002005910000070',
        6,
        SudokuGroup.block,
      ),
      (
        '003450700056089103000000406034060891500001000000200500000000000000000000910300600',
        0,
        SudokuGroup.row,
      ),
      (
        '003050009000709000709003456000500000507001000801000007000008010070002005910000070',
        32,
        SudokuGroup.column,
      ),
    ];
    for (final (values, index, group) in fixtures) {
      final cells = board(values);
      expect(candidates(cells, index).length, greaterThan(1));
      final tip = explain(cells, index);
      expect(tip.ruleId, 'only-place-${group.name}');
      expect(tip.emphasizedNumber, solution[index]);
      expect(tip.arrivalIndex, index);
      expect(tip.traces, isNotEmpty);
      for (final trace in tip.traces) {
        expect(cells[trace.cells.first], tip.emphasizedNumber);
        expect(cells[trace.cells.last], isNull);
        expect(trace.cells.last, isNot(index));
        expect(
          candidates(cells, trace.cells.last),
          isNot(contains(tip.emphasizedNumber)),
        );
      }
      expect(tip.deducedValue, solution[index]);
      expect(tip.focusIndices, containsAll(groupCells(index, group)));
      expect(tip.focusIndices.any((i) => cells[i] == tip.deducedValue), isTrue);
      // Every other hole is visibly ruled out for the suggested number.
      for (final other in groupCells(index, group)) {
        if (other != index && cells[other] == null) {
          expect(candidates(cells, other), isNot(contains(tip.deducedValue)));
        }
      }
    }
  });

  test(
    'repetitions outrank every deduction, including on fixed selections',
    () {
      for (final other in [10, 3, 27]) {
        final cells = List<int?>.filled(81, null)
          ..[0] = 1
          ..[other] = 1;
        for (final selected in [0, 1]) {
          final tip = explain(cells, selected, fixed: {0});
          // For index 1, the distant column conflict is not locally relevant.
          if (other == 27 && selected == 1) continue;
          expect(tip.ruleId, 'repeated-number');
          expect(tip.emphasizedNumber, 1);
          expect(tip.focusIndices, containsAll([0, other]));
          expect(tip.deducedValue, isNull);
          expect(tip.message, contains('se repite'));
        }
      }
    },
  );

  test(
    'detects an empty cell with no possibility even without repetitions',
    () {
      final cells = List<int?>.filled(81, null);
      for (var i = 1; i < 9; i++) {
        cells[i] = i + 1;
      }
      cells[9] = 1;
      final tip = explain(cells, 0);
      expect(tip.ruleId, 'no-candidate');
      expect(tip.focusIndices.length, 21);
      expect(tip.deducedValue, isNull);
    },
  );

  test(
    'fixed values teach the constraints and illuminate matching numbers',
    () {
      final cells = List<int?>.filled(81, null)
        ..[0] = 1
        ..[40] = 1;
      final tip = explain(cells, 0, fixed: {0});
      expect(tip.ruleId, 'fixed-number');
      expect(tip.emphasizedNumber, 1);
      expect(tip.message, contains('venía con el tablero'));
      expect(tip.focusIndices, containsAll([0, 40]));
      expect(tip.deducedValue, isNull);
    },
  );

  test(
    'explains a justified entry but does not certify merely legal entries',
    () {
      final proven = explain(holes([80]), 0);
      expect(proven.ruleId, 'justified-entry');
      expect(proven.emphasizedNumber, 1);
      expect(
        proven.message,
        contains('único número que faltaba en este cuadro'),
      );
      final cells = List<int?>.filled(81, null)..[0] = 1;
      final unproven = explain(cells, 0);
      expect(unproven.ruleId, 'unproven-entry');
      expect(unproven.emphasizedNumber, 1);
      expect(unproven.message, contains('sigamos buscando pistas'));
      expect(unproven.deducedValue, isNull);
    },
  );

  test('suggests another nearly complete group without moving or filling', () {
    final cells = List<int?>.filled(81, null);
    for (var i = 0; i < 8; i++) {
      cells[72 + i] = i + 1;
    }
    final before = [...cells];
    final context = SudokuHelpContext(cells: cells, selectedIndex: 0);
    final tip = engine.explain(context);
    expect(tip.ruleId, 'nearby-easy-group');
    expect(tip.focusIndices, groupCells(80, SudokuGroup.row).toSet());
    expect(context.selectedIndex, 0);
    expect(cells, before);
    expect(tip.deducedValue, isNull);
  });

  test(
    'no simple deduction is explained honestly, without recommending guessing',
    () {
      final tip = explain(List.filled(81, null), 0);
      expect(tip.ruleId, 'no-simple-tip');
      expect(tip.message, contains('No hace falta adivinar'));
      expect(tip.deducedValue, isNull);
    },
  );

  test('celebrates a full valid board, never just any full board', () {
    expect(explain(solution, 0).ruleId, 'completed-board');
    expect(explain(solution, 0).focusIndices.length, 81);
    final invalid = <int?>[...solution]..[80] = solution[79];
    expect(explain(invalid, 0).ruleId, isNot('completed-board'));
  });

  test('deductions remain sound on randomized partial valid boards', () {
    final random = Random(74);
    for (var sample = 0; sample < 40; sample++) {
      final cells = <int?>[
        for (final value in solution) random.nextDouble() < .45 ? value : null,
      ];
      final before = [...cells];
      for (var index = 0; index < 81; index++) {
        final tip = explain(cells, index);
        for (final trace in tip.traces) {
          expect(trace.cells, isNotEmpty);
          if (trace.isBlockHop) {
            expect(
              trace.cells.toSet(),
              groupCells(trace.cells.first, SudokuGroup.block).toSet(),
            );
            expect(tip.focusIndices, containsAll(trace.cells));
            continue;
          }
          for (var step = 1; step < trace.cells.length; step++) {
            final a = trace.cells[step - 1];
            final b = trace.cells[step];
            expect(
              a ~/ 9 == b ~/ 9 || a % 9 == b % 9,
              isTrue,
              reason: '${tip.ruleId} must not imply a diagonal rule',
            );
            final delta = a ~/ 9 == b ~/ 9
                ? (b > a ? 1 : -1)
                : (b > a ? 9 : -9);
            for (var cell = a; cell != b; cell += delta) {
              expect(
                tip.focusIndices,
                contains(cell),
                reason: '${tip.ruleId} leaves its evidence',
              );
            }
            expect(tip.focusIndices, contains(b));
          }
        }
        if (tip.deducedValue != null) {
          expect(
            tip.deducedValue,
            solution[index],
            reason: '${tip.ruleId} at $index',
          );
        }
        expect(tip.focusIndices.every((i) => i >= 0 && i < 81), isTrue);
      }
      expect(cells, before);
    }
  });

  test('adding a rule only requires registering it in priority order', () {
    final extended = SudokuHelpEngine(
      rules: [_ExtraRule(), const LastEmptyBlockRule()],
    );
    final tip = extended.explain(
      SudokuHelpContext(cells: holes([0]), selectedIndex: 0),
    );
    expect(tip.ruleId, 'extension');
    expect(tip.focusIndices, {0});
  });
}
