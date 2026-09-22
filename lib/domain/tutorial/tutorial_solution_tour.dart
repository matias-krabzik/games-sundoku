import 'tutorial_sudokus.dart';

/// Shared timing keeps each explanation alongside its tour of all nine groups.
class TutorialSolutionTour {
  const TutorialSolutionTour(this.progress);

  static const number = 5;
  static const duration = Duration(seconds: 22);
  final double progress;

  int get phase => progress >= 1
      ? 4
      : progress * 22 < 4
      ? 0
      : 1 + ((progress * 22 - 4) / 6).floor();

  bool get finished => phase == 4;

  String get message => switch (phase) {
    0 =>
      '¡Así se ve un Sudoku resuelto!\nVamos a buscar todos los números $number.',
    1 => 'Mira de lado a lado:\nhay un solo $number en cada fila.',
    2 => 'Ahora mira de arriba abajo:\nhay un solo $number en cada columna.',
    3 => '¡Y también hay un solo $number\ndentro de cada bloque de 3 × 3!',
    _ =>
      'El $number aparece nueve veces, pero solo una en cada fila, columna y bloque.\n¡Esta regla vale para todos los números del 1 al 9!',
  };

  List<int> get highlightedIndices {
    if (phase == 0 || finished) return const [];
    final group = ((progress * 22 - 4 - (phase - 1) * 6) / 6 * 9).floor().clamp(
      0,
      8,
    );
    return switch (phase) {
      1 => groupCells(group * 9, SudokuGroup.row),
      2 => groupCells(group, SudokuGroup.column),
      _ => groupCells(group ~/ 3 * 27 + group % 3 * 3, SudokuGroup.block),
    };
  }
}
