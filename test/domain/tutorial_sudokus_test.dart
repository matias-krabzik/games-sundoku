import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/domain/tutorial/tutorial_sudokus.dart';

// Independent solver: verifies uniqueness without using tutorial deductions.
int solutions(List<int?> input) {
  final board = [...input];
  int search() {
    int? target;
    var choices = <int>[];
    for (var i = 0; i < 81; i++) {
      if (board[i] != null) continue;
      final possible = <int>[];
      for (var n = 1; n <= 9; n++) {
        var allowed = true;
        for (var j = 0; j < 81; j++) {
          if (board[j] == n &&
              (i ~/ 9 == j ~/ 9 ||
                  i % 9 == j % 9 ||
                  (i ~/ 27 == j ~/ 27 && i % 9 ~/ 3 == j % 9 ~/ 3))) {
            allowed = false;
            break;
          }
        }
        if (allowed) possible.add(n);
      }
      if (target == null || possible.length < choices.length) {
        target = i;
        choices = possible;
      }
    }
    if (target == null) return 1;
    var count = 0;
    for (final n in choices) {
      board[target] = n;
      count += search();
      if (count >= 2) break;
    }
    board[target] = null;
    return count;
  }

  return search();
}

void main() {
  test(
    'all three puzzles preserve arbitrary center orders and have one solution',
    () {
      final random = Random(73);
      for (var example = 0; example < 40; example++) {
        final center = List.generate(9, (i) => i + 1)..shuffle(random);
        final games = TutorialSudokus.create(center);
        expect(games.map((g) => g.initial.where((n) => n == null).length), [
          6,
          12,
          18,
        ]);
        for (final game in games) {
          expect(
            TutorialSudokus.centerIndices.map((i) => game.initial[i]),
            center,
          );
          expect(
            TutorialSudokus.centerIndices.map((i) => game.solution[i]),
            center,
          );
          expect(solutions(game.initial), 1);
          final board = [...game.initial];
          while (board.contains(null)) {
            final hint = findTutorialHint(board);
            expect(
              hint,
              isNotNull,
              reason: 'Every remaining move needs a visible explanation',
            );
            expect(hint!.value, game.solution[hint.index]);
            expect(
              hint.group,
              isNotNull,
              reason: 'These first games use one-group deductions only',
            );
            expect(hint.cells.where((i) => board[i] == null), [hint.index]);
            board[hint.index] = hint.value;
          }
          expect(board, game.solution);
        }
      }
    },
  );

  test('first guided moves demonstrate a row, column, then block', () {
    final board = [
      ...TutorialSudokus.create([8, 3, 5, 4, 1, 6, 9, 2, 7]).first.initial,
    ];
    for (var step = 0; step < 6; step++) {
      final hint = findTutorialHint(
        board,
        preferredIndex: TutorialSudokus.guidedOrder[step],
        preferredGroup: TutorialSudokus.guidedGroups[step],
      );
      expect(hint!.index, TutorialSudokus.guidedOrder[step]);
      expect(hint.group, TutorialSudokus.guidedGroups[step]);
      board[hint.index] = hint.value;
    }
  });

  test('invalid central blocks are rejected before registering games', () {
    expect(() => TutorialSudokus.create([1, 2, 3]), throwsArgumentError);
    expect(
      () => TutorialSudokus.create([1, 2, 3, 4, 5, 6, 7, 8, 8]),
      throwsArgumentError,
    );
  });
}
