import '../models/sudoku_definition.dart';

/// Versioned, platform-independent generation. Removing a clue is accepted only
/// when naked/hidden singles still solve the entire board without guessing.
class SeededSudokus {
  static const version = 'easy-singles-v1';

  static SudokuDefinition create({required String id, required String seed}) {
    final random = _SeedRandom(seed);
    final solution = List<int>.filled(81, 0);
    bool fill() {
      var selected = -1;
      var choices = <int>[];
      for (var i = 0; i < 81; i++) {
        if (solution[i] != 0) continue;
        final values = candidates(solution, i);
        if (values.isEmpty) return false;
        if (selected == -1 || values.length < choices.length) {
          selected = i;
          choices = values;
        }
      }
      if (selected == -1) return true;
      random.shuffle(choices);
      for (final value in choices) {
        solution[selected] = value;
        if (fill()) return true;
      }
      solution[selected] = 0;
      return false;
    }

    if (!fill()) throw StateError('Could not generate a sudoku');
    final initial = [...solution];
    final order = List.generate(81, (i) => i);
    random.shuffle(order);
    var removed = 0;
    for (final index in order) {
      initial[index] = 0;
      if (solveWithSingles(initial) != null) {
        if (++removed == 38) break;
      } else {
        initial[index] = solution[index];
      }
    }
    return SudokuDefinition(
      id: id,
      difficulty: 'easy',
      seed: seed,
      generatorVersion: version,
      initial: initial.map((n) => n == 0 ? null : n).toList(),
      solution: solution,
    );
  }

  static final units = <List<int>>[
    for (var r = 0; r < 9; r++) [for (var c = 0; c < 9; c++) r * 9 + c],
    for (var c = 0; c < 9; c++) [for (var r = 0; r < 9; r++) r * 9 + c],
    for (var b = 0; b < 9; b++)
      [
        for (var r = 0; r < 3; r++)
          for (var c = 0; c < 3; c++) (b ~/ 3 * 3 + r) * 9 + b % 3 * 3 + c,
      ],
  ];

  static List<int> candidates(List<int> cells, int index) {
    final used = <int>{};
    for (var i = 0; i < 9; i++) {
      used.add(cells[index ~/ 9 * 9 + i]);
      used.add(cells[i * 9 + index % 9]);
      used.add(
        cells[(index ~/ 27 * 3 + i ~/ 3) * 9 + index % 9 ~/ 3 * 3 + i % 3],
      );
    }
    return [
      for (var n = 1; n <= 9; n++)
        if (!used.contains(n)) n,
    ];
  }

  /// Each placement is logically forced, proving uniqueness as well as ease.
  static List<int>? solveWithSingles(List<int> source) {
    final cells = [...source];
    while (cells.contains(0)) {
      final options = [
        for (var i = 0; i < 81; i++)
          cells[i] == 0 ? candidates(cells, i) : <int>[],
      ];
      var moved = false;
      for (var i = 0; i < 81; i++) {
        if (cells[i] == 0 && options[i].isEmpty) return null;
        if (options[i].length == 1) {
          cells[i] = options[i].single;
          moved = true;
          break;
        }
      }
      if (moved) continue;
      for (final unit in units) {
        for (var n = 1; n <= 9; n++) {
          final places = unit.where((i) => options[i].contains(n)).toList();
          if (places.length == 1) {
            cells[places.single] = n;
            moved = true;
            break;
          }
        }
        if (moved) break;
      }
      if (!moved) return null;
    }
    return cells;
  }
}

// Park–Miller arithmetic stays below JavaScript's exact integer limit. Avoid
// Dart Random/hashCode so persisted seeds reproduce on every supported target.
class _SeedRandom {
  _SeedRandom(String seed) {
    for (final code in seed.codeUnits) {
      _state = (_state * 31 + code) % 2147483647;
    }
    if (_state == 0) _state = 1;
  }
  int _state = 1;
  void shuffle(List<int> values) {
    for (var i = values.length - 1; i > 0; i--) {
      _state = _state * 16807 % 2147483647;
      final j = _state % (i + 1);
      final value = values[i];
      values[i] = values[j];
      values[j] = value;
    }
  }
}
