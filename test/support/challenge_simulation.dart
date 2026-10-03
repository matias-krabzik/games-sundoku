import 'package:sundoku/domain/models/game_session.dart';
import 'package:sundoku/domain/models/sudoku_definition.dart';
import 'package:sundoku/domain/scoring/adventure_challenge.dart';
import 'package:sundoku/domain/scoring/sudoku_scoring.dart';

/// Calibration driver using the real scoring engine, without session activation.
class ChallengeSimulation {
  ChallengeSimulation(this.puzzle, this.rules)
    : progress = PuzzleProgress.initial(puzzle);

  final SudokuDefinition puzzle;
  final RoundChallengeRules rules;
  PuzzleProgress progress;

  ChallengeAssessment get result => rules.evaluate(puzzle, progress);
  List<int> get empty => [
    for (var i = 0; i < puzzle.initial.length; i++)
      if (puzzle.initial[i] == null) i,
  ];

  void enter(int index, int? value, {bool hint = false}) {
    if (result.terminal) return;
    final old = progress.cells[index];
    if (old.value == value && old.notes.isEmpty) return;
    final error = value != null && value != puzzle.solution[index];
    final cells = [...progress.cells]
      ..[index] = CellProgress(
        value: value,
        source: hint ? ValueSource.hint : ValueSource.player,
      );
    progress = SudokuScoring.move(
      puzzle: puzzle,
      before: progress,
      after: progress.copyWith(
        cells: cells,
        mistakes: progress.mistakes + (error && old.value != value ? 1 : 0),
      ),
      index: index,
      hintUsed: hint,
      isError: error,
    );
  }

  void explain({int? index}) {
    if (!result.terminal) {
      progress = SudokuScoring.hint(progress, puzzle, index: index);
    }
  }

  void solve({bool reverse = false}) {
    final order = reverse ? empty.reversed : empty;
    for (final index in order) {
      enter(index, puzzle.solution[index]);
    }
  }
}
