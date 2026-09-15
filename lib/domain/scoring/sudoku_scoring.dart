import 'dart:math' as math;

import '../models/game_session.dart';
import '../models/score_progress.dart';
import '../models/sudoku_definition.dart';

enum ScoreDifficulty {
  easy(1),
  normal(3),
  medium(5),
  hard(7),
  extreme(11);

  const ScoreDifficulty(this.multiplier);
  final int multiplier;

  static ScoreDifficulty fromName(String name) => switch (name) {
    'normal' => normal,
    'medium' || 'medio' => medium,
    'hard' || 'difficult' || 'dificil' || 'difícil' => hard,
    'extreme' || 'extremo' || 'expert' => extreme,
    _ => easy, // Includes the introductory boards and existing easy saves.
  };
}

class SudokuScoring {
  static const hintCost = 77;

  static Set<int> _completed(
    SudokuDefinition puzzle,
    List<CellProgress> cells,
  ) {
    final size = puzzle.size;
    bool solved(Iterable<int> indices) =>
        indices.every((i) => cells[i].value == puzzle.solution[i]);
    return {
      for (var r = 0; r < size; r++)
        if (solved([for (var c = 0; c < size; c++) r * size + c])) r,
      for (var c = 0; c < size; c++)
        if (solved([for (var r = 0; r < size; r++) r * size + c])) size + c,
      for (var box = 0; box < size; box++)
        if (solved([
          for (var r = 0; r < puzzle.boxRows; r++)
            for (var c = 0; c < puzzle.boxColumns; c++)
              (box ~/ (size ~/ puzzle.boxColumns) * puzzle.boxRows + r) * size +
                  box % (size ~/ puzzle.boxColumns) * puzzle.boxColumns +
                  c,
        ]))
          size * 2 + box,
      if (solved(List.generate(cells.length, (i) => i))) size * 3,
    };
  }

  // Existing saves start tracking from their current board, without retroactive
  // awards for givens or moves made before scoring was introduced.
  static ScoreProgress _history(PuzzleProgress board, SudokuDefinition puzzle) {
    if (board.scoring.initialized) return board.scoring;
    return ScoreProgress(
      initialized: true,
      cells: {
        for (var i = 0; i < board.cells.length; i++)
          if (board.cells[i].value == puzzle.solution[i]) i,
      },
      zones: _completed(puzzle, board.cells),
      assisted: {
        for (var i = 0; i < board.cells.length; i++)
          if (board.cells[i].source == ValueSource.hint) i,
      },
    );
  }

  static PuzzleProgress hint(
    PuzzleProgress board,
    SudokuDefinition puzzle, {
    int? index,
  }) {
    final history = _history(board, puzzle);
    return board.copyWith(
      points: math.max(0, board.points - hintCost),
      hintsUsed: board.hintsUsed + 1,
      scoring: ScoreProgress(
        initialized: true,
        streak: history.streak,
        cells: history.cells,
        zones: history.zones,
        assisted: Set.unmodifiable({...history.assisted, ?index}),
      ),
    );
  }

  static PuzzleProgress move({
    required SudokuDefinition puzzle,
    required PuzzleProgress before,
    required PuzzleProgress after,
    required int index,
    required bool hintUsed,
    required bool isError,
  }) {
    final charged = hintUsed ? hint(before, puzzle, index: index) : before;
    final history = _history(charged, puzzle);
    final correct = after.cells[index].value == puzzle.solution[index];
    final eligible = correct && !hintUsed && !history.assisted.contains(index);
    final freshCell = eligible && !history.cells.contains(index);
    final streak = isError ? 0 : history.streak + (freshCell ? 1 : 0);
    final completed = _completed(puzzle, after.cells);
    final newZones = completed.difference(history.zones);
    var reward = freshCell
        ? (streak <= 2
              ? 11
              : streak <= 4
              ? 17
              : 23)
        : 0;
    if (eligible) {
      for (final zone in newZones) {
        reward += zone == puzzle.size * 3
            ? 307
            : zone >= puzzle.size * 2
            ? 79
            : 53;
      }
    }
    return after.copyWith(
      points:
          charged.points +
          reward * ScoreDifficulty.fromName(puzzle.difficulty).multiplier,
      hintsUsed: charged.hintsUsed,
      scoring: ScoreProgress(
        initialized: true,
        streak: streak,
        cells: Set.unmodifiable({...history.cells, if (correct) index}),
        zones: Set.unmodifiable({...history.zones, ...completed}),
        assisted: history.assisted,
      ),
    );
  }
}
