import '../models/game_session.dart';
import '../models/sudoku_definition.dart';
import '../scoring/adventure_challenge.dart';
import '../scoring/sudoku_scoring.dart';

/// Isolated teaching example; uses real scoring without a repository or rewards.
abstract final class ChallengeLesson {
  static const key = 'tutorials/world3-challenges/v1';
  static const titles = [
    'Resuelve a tiempo',
    'Alcanza la meta',
    'Cuida tus vidas',
    'Enciende tu estrella',
  ];
  static const texts = [
    'Completa el sudoku antes de que el reloj llegue a cero. Al pausar, el tiempo se detiene.',
    'Resuelve a tiempo y alcanza la meta. Las anotaciones son libres; las pistas cuestan puntos.',
    'Cada error cuesta una vida. Tendrás 3, luego 2 y al final 1. Se renuevan en cada sudoku.',
    'Al terminar contamos tus puntos para encender la estrella. El último nivel exige cero errores y cero pistas.',
  ];
  static const durations = [4200, 2400, 3000, 4200];
  static final solution = List.generate(
    81,
    (i) => (i ~/ 9 * 3 + i ~/ 27 + i % 9) % 9 + 1,
  );
  static final puzzle = SudokuDefinition(
    id: 'world-3/level-1/demo',
    difficulty: 'easy',
    seed: 'challenge-lesson-v1',
    generatorVersion: 'lesson-v1',
    initial: [for (var i = 0; i < 81; i++) i < 3 ? null : solution[i]],
    solution: solution,
  );
  static final rules = AdventureChallenges.forPuzzle(
    worldId: 'world-3',
    level: 1,
    puzzle: puzzle,
  )!;
  static PuzzleProgress _move(
    PuzzleProgress before,
    int index,
    int value, {
    bool error = false,
  }) {
    final cells = [...before.cells]..[index] = CellProgress(value: value);
    return SudokuScoring.move(
      puzzle: puzzle,
      before: before,
      after: before.copyWith(
        cells: cells,
        mistakes: before.mistakes + (error ? 1 : 0),
      ),
      index: index,
      hintUsed: false,
      isError: error,
    );
  }

  static final first = _move(PuzzleProgress.initial(puzzle), 0, solution[0]);
  static final mistake = _move(first, 1, solution[2], error: true);
  static final solved = _move(_move(mistake, 1, solution[1]), 2, solution[2]);

  static ChallengeDemoFrame frameAt(int step, double progress) {
    final t = progress.clamp(0.0, 1.0);
    final cells = [...puzzle.initial];
    if (step > 1 || step == 1 && t >= .5) cells[0] = solution[0];
    if (step == 2 && t >= .4 && t < .85) cells[1] = solution[2];
    if (step == 3) cells.setAll(0, solution);
    final counted = step == 3
        ? (solved.points * ((t - .12) / .75).clamp(0.0, 1.0)).round()
        : 0;
    return ChallengeDemoFrame(
      cells: cells,
      points: step == 3
          ? counted
          : step > 1
          ? first.points
          : step == 1
          ? (first.points * ((t - .5) / .4).clamp(0.0, 1.0)).round()
          : 0,
      lives: step > 2 || step == 2 && t >= .4 ? 2 : 3,
      timeMs:
          rules.timeLimitMs -
          (step == 0 ? (t.clamp(0.0, .5) * 8).floor() * 1000 : 4000),
      paused: step == 0 && t >= .5,
      error: step == 2 && t >= .4 && t < .85,
      earned: step == 3 && counted >= rules.targetPoints,
    );
  }
}

class ChallengeDemoFrame {
  const ChallengeDemoFrame({
    required this.cells,
    required this.points,
    required this.lives,
    required this.timeMs,
    required this.paused,
    required this.error,
    required this.earned,
  });
  final List<int?> cells;
  final int points, lives, timeMs;
  final bool paused, error, earned;
}
