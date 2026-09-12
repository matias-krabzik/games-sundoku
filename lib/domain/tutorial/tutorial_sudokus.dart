import '../../data/level_catalog.dart';
import '../models/sudoku_definition.dart';

enum SudokuGroup { block, row, column }

extension SudokuGroupWords on SudokuGroup {
  String get nameForChild => switch (this) {
    SudokuGroup.block => 'bloque',
    SudokuGroup.row => 'fila',
    SudokuGroup.column => 'columna',
  };
  String get demonstrative => this == SudokuGroup.block ? 'este' : 'esta';
}

List<int> groupCells(int index, SudokuGroup group) => switch (group) {
  SudokuGroup.row => [for (var c = 0; c < 9; c++) index ~/ 9 * 9 + c],
  SudokuGroup.column => [for (var r = 0; r < 9; r++) r * 9 + index % 9],
  SudokuGroup.block => [
    for (var r = index ~/ 27 * 3; r < index ~/ 27 * 3 + 3; r++)
      for (var c = index % 9 ~/ 3 * 3; c < index % 9 ~/ 3 * 3 + 3; c++)
        r * 9 + c,
  ],
};

Set<int> candidates(List<int?> board, int index) {
  final used = {
    for (final kind in SudokuGroup.values)
      for (final peer in groupCells(index, kind))
        if (peer != index && board[peer] != null) board[peer]!,
  };
  return {
    for (var n = 1; n <= 9; n++)
      if (!used.contains(n)) n,
  };
}

class TutorialHint {
  const TutorialHint(this.index, this.value, this.group, this.cells);
  final int index;
  final int value;
  final SudokuGroup? group;
  final List<int> cells;

  String get invitation => group == null
      ? 'Mira la fila, la columna y el bloque de esta casilla.'
      : 'Mira ${group!.demonstrative} ${group!.nameForChild}. Falta un número.';
  String get explanation => group == null
      ? 'Aquí solo cabe el $value. Los otros números ya están cerca.'
      : 'En ${group!.demonstrative} ${group!.nameForChild} solo falta el $value.';
}

/// Deductions come from visible values, never from a prewritten answer string.
TutorialHint? findTutorialHint(
  List<int?> board, {
  int? preferredIndex,
  SudokuGroup? preferredGroup,
}) {
  final empty = [
    for (var i = 0; i < 81; i++)
      if (board[i] == null) i,
  ];
  if (preferredIndex != null && empty.remove(preferredIndex)) {
    empty.insert(0, preferredIndex);
  }
  for (final index in empty) {
    final groups = [
      ?preferredGroup,
      ...SudokuGroup.values.where((g) => g != preferredGroup),
    ];
    for (final group in groups) {
      final peers = groupCells(index, group);
      final missing = {for (var n = 1; n <= 9; n++) n}
        ..removeAll(peers.map((i) => board[i]).whereType<int>());
      if (peers.where((i) => board[i] == null).length == 1 &&
          missing.length == 1) {
        return TutorialHint(
          index,
          missing.single,
          group,
          List.unmodifiable(peers),
        );
      }
    }
  }
  for (final index in empty) {
    final possible = candidates(board, index);
    if (possible.length == 1) {
      return TutorialHint(
        index,
        possible.single,
        null,
        List.unmodifiable({
          for (final group in SudokuGroup.values) ...groupCells(index, group),
        }),
      );
    }
  }
  return null;
}

class TutorialSudokus {
  static const centerIndices = [30, 31, 32, 39, 40, 41, 48, 49, 50];
  static const guidedOrder = [11, 27, 70, 34, 67, 5];
  static const guidedGroups = [
    SudokuGroup.row,
    SudokuGroup.column,
    SudokuGroup.block,
    SudokuGroup.row,
    SudokuGroup.row,
    SudokuGroup.column,
  ];
  static const _solution =
      '692783541783541692541692783927835416835416927416927835278354169354169278169278354';
  static const _boards = [
    '69278.54178.541692541692783.278354.68354169274169278352783541693541.92.8169278354',
    '7.3541.6.6927834515416928.3927835146...41629741.9273852783546193541697.8169.785..',
    '2967....138.54.692..569278372983541.53.41692761.927835961.78.5445.16..78.7.354169',
  ];
  static const _rows = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8],
    [1, 0, 2, 3, 4, 5, 6, 7, 8],
    [0, 1, 2, 3, 4, 5, 8, 7, 6],
  ];
  static const _columns = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8],
    [0, 1, 2, 3, 4, 5, 7, 6, 8],
    [2, 1, 0, 3, 4, 5, 6, 7, 8],
  ];

  static List<SudokuDefinition> create(List<int> center) {
    if (center.length != 9 ||
        center.toSet().length != 9 ||
        center.any((n) => n < 1 || n > 9)) {
      throw ArgumentError('The central block needs each digit exactly once');
    }
    final rename = {
      for (var i = 0; i < 9; i++)
        int.parse(_solution[centerIndices[i]]): center[i],
    };
    return List.unmodifiable([
      for (var game = 0; game < 3; game++)
        SudokuDefinition(
          id: '${mapLevelId(1)}/sudoku-${game + 1}',
          difficulty: 'introduction',
          seed: center.join(),
          generatorVersion: 'first-experience-v1',
          initial: [
            for (final c in _boards[game].split(''))
              c == '.' ? null : rename[int.parse(c)],
          ],
          solution: [
            for (var r = 0; r < 9; r++)
              for (var c = 0; c < 9; c++)
                rename[int.parse(
                  _solution[_rows[game][r] * 9 + _columns[game][c]],
                )]!,
          ],
        ),
    ]);
  }
}
