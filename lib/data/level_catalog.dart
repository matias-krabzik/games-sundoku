import '../domain/models/sudoku_definition.dart';
import 'world_catalog.dart';

String mapLevelId(int number, {String worldId = 'world-1'}) =>
    '$worldId/level-$number';

final Map<String, LevelDefinition> initialLevelCatalog = Map.unmodifiable({
  for (final world in adventureWorlds.values)
    for (final node in world.nodes)
      mapLevelId(node.level, worldId: world.id): LevelDefinition(
        id: mapLevelId(node.level, worldId: world.id),
        worldId: world.id,
        puzzleIds: [
          for (var i = 1; i <= 3; i++)
            '${mapLevelId(node.level, worldId: world.id)}/sudoku-$i',
        ],
        prerequisites: [
          if (node.level > 1) mapLevelId(node.level - 1, worldId: world.id),
          if (world.number > 1 && node.level == 1)
            for (final previousWorld in adventureWorlds.values.where(
              (candidate) => candidate.number == world.number - 1,
            ))
              for (final previous in previousWorld.nodes)
                mapLevelId(previous.level, worldId: previousWorld.id),
        ],
      ),
});
