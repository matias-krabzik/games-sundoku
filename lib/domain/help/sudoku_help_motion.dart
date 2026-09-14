import '../tutorial/tutorial_sudokus.dart';

/// A logical connection expressed in board positions, independent of pixels.
class SudokuHelpTrace {
  SudokuHelpTrace(Iterable<int> cells, {this.isBlockHop = false})
    : cells = List.unmodifiable(cells);
  final List<int> cells;
  final bool isBlockHop;
}

/// Only routes inside a shared row, column or block are allowed.
SudokuHelpTrace connectHelpCells(int source, int target) {
  final shared = SudokuGroup.values.any(
    (group) => groupCells(source, group).contains(target),
  );
  if (!shared) {
    throw ArgumentError('Help connections must share a sudoku group.');
  }
  return SudokuHelpTrace([
    source,
    if (source ~/ 9 != target ~/ 9 && source % 9 != target % 9)
      source ~/ 9 * 9 + target % 9,
    if (target != source) target,
  ]);
}

/// Scan a group toward its relevant cell without introducing diagonal rules.
List<SudokuHelpTrace> scanHelpGroup(int target, SudokuGroup group) {
  final indices = groupCells(target, group);
  if (group != SudokuGroup.block) {
    return [
      for (final edge in [indices.first, indices.last])
        if (edge != target) connectHelpCells(edge, target),
    ];
  }
  return [SudokuHelpTrace(indices, isBlockHop: true)];
}

List<SudokuHelpTrace> scanHelpPeers(int target) => [
  for (final group in [SudokuGroup.row, SudokuGroup.column, SudokuGroup.block])
    ...scanHelpGroup(target, group),
];

int helpMotionMilliseconds(List<SudokuHelpTrace> traces) =>
    180 + traces.length * 380 + 700;
String helpMotionSignature(List<SudokuHelpTrace> traces) => traces
    .map((trace) => '${trace.isBlockHop}:${trace.cells.join(",")}')
    .join(';');
