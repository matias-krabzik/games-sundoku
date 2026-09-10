import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/domain/models/sudoku_definition.dart';

const smallSolution = [1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1];

List<SudokuDefinition> levelPuzzles([int level = 1]) => [
  for (var i = 1; i <= 3; i++)
    SudokuDefinition(
      id: '${mapLevelId(level)}/sudoku-$i',
      difficulty: 'easy',
      seed: '$level-$i',
      generatorVersion: 'test-v1',
      size: 4,
      boxRows: 2,
      boxColumns: 2,
      initial: [null, null, ...smallSolution.skip(2)],
      solution: smallSolution,
    ),
];
