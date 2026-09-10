import '../domain/models/sudoku_definition.dart';
import 'level_node.dart';

String mapLevelId(int number) => 'world-1/level-$number';

final Map<String, LevelDefinition> initialLevelCatalog = Map.unmodifiable({
  for (final node in kMap1Nodes)
    mapLevelId(node.level): LevelDefinition(
      id: mapLevelId(node.level),
      worldId: 'world-1',
      puzzleIds: [
        for (var i = 1; i <= 3; i++) '${mapLevelId(node.level)}/sudoku-$i',
      ],
      prerequisites: [if (node.level > 1) mapLevelId(node.level - 1)],
    ),
});
