/// The tiles reached by a wave from one board position.
class SudokuCompletion {
  SudokuCompletion({
    required this.origin,
    required Set<int> cells,
    this.wholeBoard = false,
  }) : cells = Set.unmodifiable(cells);

  final int origin;
  final Set<int> cells;
  final bool wholeBoard;

  factory SudokuCompletion.fromPosition({
    required int origin,
    bool wholeBoard = false,
  }) {
    // The final move produces only the board wave, never an extra block wave.
    if (wholeBoard) {
      return SudokuCompletion(
        origin: origin,
        cells: {for (var i = 0; i < 81; i++) i},
        wholeBoard: true,
      );
    }
    final row = origin ~/ 9;
    final column = origin % 9;
    return SudokuCompletion(
      origin: origin,
      cells: {
        for (var c = 0; c < 9; c++) row * 9 + c,
        for (var r = 0; r < 9; r++) r * 9 + column,
        for (var r = row ~/ 3 * 3; r < row ~/ 3 * 3 + 3; r++)
          for (var c = column ~/ 3 * 3; c < column ~/ 3 * 3 + 3; c++) r * 9 + c,
      },
    );
  }
}
