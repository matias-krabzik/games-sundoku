import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/domain/models/game_session.dart';
import 'package:sundoku/domain/models/sudoku_definition.dart';
import 'package:sundoku/domain/scoring/adventure_challenge.dart';
import 'package:sundoku/domain/scoring/sudoku_scoring.dart';

import '../../fixtures.dart';
import '../../support/challenge_simulation.dart';

SudokuDefinition challengePuzzle({
  int level = 1,
  int empty = 16,
  String difficulty = 'easy',
}) => SudokuDefinition.fromJson({
  ...levelPuzzles().first.toJson(),
  'id': 'world-3/level-$level/sudoku-1',
  'difficulty': difficulty,
  'initial': [for (var i = 0; i < 16; i++) i < empty ? null : smallSolution[i]],
});

RoundChallengeRules rulesFor(SudokuDefinition puzzle, {int level = 1}) =>
    AdventureChallenges.forPuzzle(
      worldId: 'world-3',
      level: level,
      puzzle: puzzle,
    )!;

void main() {
  group('perfect reference score, independent totals', () {
    for (final entry in {
      'easy': 1,
      'normal': 3,
      'medium': 5,
      'hard': 7,
      'extreme': 11,
    }.entries) {
      test(
        '${entry.key}: excludes complete givens, rewards cells and groups once',
        () {
          // One empty: 11 + 2*53 + 79 + 307 = 503.
          // Two empties: 22 + 3*53 + 79 + 307 = 567.
          // Empty 4x4: 22 + 34 + 12*23 + 8*53 + 4*79 + 307 = 1379.
          for (final sample in {1: 503, 2: 567, 16: 1379}.entries) {
            final puzzle = challengePuzzle(
              empty: sample.key,
              difficulty: entry.key,
            );
            expect(
              SudokuScoring.perfectScore(puzzle),
              sample.value * entry.value,
            );
            for (final reverse in [false, true]) {
              final simulation = ChallengeSimulation(puzzle, rulesFor(puzzle))
                ..solve(reverse: reverse);
              expect(simulation.progress.points, sample.value * entry.value);
              expect(simulation.result.won, isTrue);
            }
          }
        },
      );
    }
    test('fully given boards are rejected by the definition', () {
      expect(() => challengePuzzle(empty: 0), throwsFormatException);
    });
  });

  test(
    'R01: boundaries, progressively tighter targets and board-specific clock',
    () {
      var previousProportion = 0;
      for (var level = 1; level <= 30; level++) {
        final puzzle = challengePuzzle(level: level);
        final rules = rulesFor(puzzle, level: level);
        expect(
          rules.initialLives,
          level <= 10
              ? 3
              : level <= 20
              ? 2
              : 1,
        );
        expect(rules.requiresNoMistakes, level == 30);
        expect(rules.allowsHints, level != 30);
        expect(rules.targetBasisPoints, greaterThan(previousProportion));
        expect(rules.targetPoints, inInclusiveRange(1, rules.perfectPoints));
        expect(rules.targetPoints == rules.perfectPoints, level == 30);
        expect(rules.timeLimitMs, 600000); // 2 minutes + 16 * 30 seconds.
        expect(rules.timePolicy, ChallengeTimePolicy.activeTimeLimit);
        expect(rules.version, 'world3-challenge-v1');
        expect(rules.scoringVersion, SudokuScoring.version);
        previousProportion = rules.targetBasisPoints;
      }
      expect(rulesFor(challengePuzzle(empty: 1)).timeLimitMs, 150000);
      expect(rulesFor(challengePuzzle()).targetPoints, 1173); // ceil(1379*.85)
      expect(
        rulesFor(challengePuzzle(level: 29, empty: 1), level: 29).targetPoints,
        502,
      );
    },
  );

  test(
    'R02–R05/R08: solved, threshold, lives and explicit hint conditions',
    () {
      for (final level in [1, 10, 11, 20, 21, 29, 30]) {
        final puzzle = challengePuzzle(level: level);
        final rules = rulesFor(puzzle, level: level);
        final solved = PuzzleProgress.initial(puzzle).copyWith(
          cells: puzzle.solution
              .map((value) => CellProgress(value: value))
              .toList(),
        );
        for (final offset in [-1, 0, 1]) {
          final result = rules.evaluate(
            puzzle,
            solved.copyWith(points: rules.targetPoints + offset),
          );
          expect(result.won, offset >= 0);
          expect(result.terminal, isTrue);
          expect(result.missingPoints, offset < 0 ? 1 : 0);
        }
        final highScore = solved.copyWith(points: rules.perfectPoints);
        expect(
          rules
              .evaluate(
                puzzle,
                PuzzleProgress.initial(puzzle)
                    .copyWith(points: rules.perfectPoints),
              )
              .outcome,
          ChallengeOutcome.inProgress,
        );
        expect(
          rules
              .evaluate(
                puzzle,
                highScore.copyWith(mistakes: rules.initialLives),
              )
              .outcome,
          ChallengeOutcome.outOfLives,
        );
        expect(rules.remainingLives(100), 0);
        expect(
          rules.evaluate(puzzle, highScore.copyWith(hintsUsed: 1)).won,
          level != 30,
        );
        if (level == 30) {
          expect(
            rules.evaluate(puzzle, highScore.copyWith(hintsUsed: 1)).outcome,
            ChallengeOutcome.hintsNotAllowed,
          );
          expect(
            rules.evaluate(puzzle, highScore.copyWith(mistakes: 1)).won,
            isFalse,
          );
          expect(
            rules
                .evaluate(
                  puzzle,
                  PuzzleProgress.initial(puzzle).copyWith(hintsUsed: 1),
                )
                .won,
            isFalse,
          );
        }
      }
    },
  );

  test(
    'R12: active deadline is exclusive, no speed bonus, never rescues failure',
    () {
      final puzzle = challengePuzzle();
      final rules = rulesFor(puzzle);
      final simulation = ChallengeSimulation(puzzle, rules)..solve();
      for (final elapsed in [
        0,
        rules.timeLimitMs - 1,
        rules.timeLimitMs,
        rules.timeLimitMs + 1,
      ]) {
        final board = simulation.progress.copyWith(elapsedMs: elapsed);
        expect(rules.evaluate(puzzle, board).won, elapsed < rules.timeLimitMs);
        expect(board.points, rules.perfectPoints);
      }
      final expired = rules.evaluate(
        puzzle,
        PuzzleProgress.initial(puzzle).copyWith(elapsedMs: rules.timeLimitMs),
      );
      expect(expired.outcome, ChallengeOutcome.outOfTime);
      expect(expired.terminal, isTrue);
      expect(expired.remainingTimeMs, 0);
      expect(rules.remainingTimeMs(rules.timeLimitMs + 10000), 0);
      expect(
        rules
            .evaluate(
              puzzle,
              simulation.progress.copyWith(mistakes: 3, elapsedMs: 1),
            )
            .won,
        isFalse,
      );
    },
  );

  test('R11: old worlds and quick play remain unrestricted', () {
    for (final world in ['world-1', 'world-2', 'quick-play']) {
      expect(
        AdventureChallenges.forPuzzle(
          worldId: world,
          level: 1,
          puzzle: levelPuzzles().first,
        ),
        isNull,
      );
    }
  });

  test(
    'invalid level, rules identity, progress and negative counters rejected',
    () {
      final puzzle = challengePuzzle();
      final rules = rulesFor(puzzle);
      for (final level in [0, 31]) {
        expect(() => rulesFor(puzzle, level: level), throwsRangeError);
      }
      expect(() => rulesFor(puzzle, level: 2), throwsArgumentError);
      expect(
        () => rules.evaluate(
          challengePuzzle(level: 2),
          PuzzleProgress.initial(puzzle),
        ),
        throwsArgumentError,
      );
      expect(
        () => rules.evaluate(
          puzzle,
          PuzzleProgress.initial(challengePuzzle(level: 2)),
        ),
        throwsFormatException,
      );
      expect(() => rules.remainingLives(-1), throwsRangeError);
      expect(() => rules.remainingTimeMs(-1), throwsRangeError);
    },
  );
}
