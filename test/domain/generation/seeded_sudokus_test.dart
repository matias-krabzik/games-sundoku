import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/domain/generation/seeded_sudokus.dart';

// Independent backtracking verifier, capped at two solutions.
int solutionCount(List<int?> source) {
  final cells = [...source];
  var count = 0;
  void visit() {
    var target = -1;
    List<int> choices = [];
    for (var i = 0; i < 81; i++) {
      if (cells[i] != null) continue;
      final options = <int>[];
      for (var n = 1; n <= 9; n++) {
        var allowed = true;
        for (var j = 0; j < 81; j++) {
          final sameUnit =
              i ~/ 9 == j ~/ 9 ||
              i % 9 == j % 9 ||
              (i ~/ 27 == j ~/ 27 && i % 9 ~/ 3 == j % 9 ~/ 3);
          if (sameUnit && cells[j] == n) allowed = false;
        }
        if (allowed) options.add(n);
      }
      if (options.isEmpty) return;
      if (target == -1 || options.length < choices.length) {
        target = i;
        choices = options;
      }
    }
    if (target == -1) {
      count++;
      return;
    }
    for (final n in choices) {
      cells[target] = n;
      visit();
      cells[target] = null;
      if (count >= 2) return;
    }
  }

  visit();
  return count;
}

void main() {
  test(
    'seeds reproduce definitions, with unique easy solutions and variety',
    () {
      final boards = <String>{};
      for (var i = 0; i < 100; i++) {
        final puzzle = SeededSudokus.create(
          id: 'puzzle',
          seed: 'player/level/$i',
        );
        final again = SeededSudokus.create(id: 'puzzle', seed: puzzle.seed);
        expect(again.toJson(), puzzle.toJson());
        expect(puzzle.initial.where((n) => n == null).length, 38);
        expect(solutionCount(puzzle.initial), 1, reason: 'seed $i');
        expect(
          SeededSudokus.solveWithSingles(
            puzzle.initial.map((n) => n ?? 0).toList(),
          ),
          puzzle.solution,
        );
        boards.add(puzzle.initial.join(','));
      }
      expect(boards.length, 100);
    },
  );
}
