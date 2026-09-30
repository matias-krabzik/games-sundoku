import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/crossed_rivers_map.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/level_progress.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/mock_world_navigation_service.dart';
import 'package:sundoku/data/world_catalog.dart';
import 'package:sundoku/models/map_ambient_motion.dart';
import 'package:sundoku/models/world_map_definition.dart';

void main() {
  test('Ríos Cruzados uses its complete, spacious 30-level map', () {
    final world = adventureWorld('world-3');
    expect(world.name, 'Ríos Cruzados');
    expect(world.levelCount, 30);
    expect(world.nodes.length, 30);
    expect(world.nodes.first.level, 1);
    expect(world.nodes.last.level, 30);
    expect(world.nodes.first.x, closeTo(130 / 8142, 1e-10));
    expect(world.nodes.last.x, closeTo(8000 / 8142, 1e-10));
    expect(world.nodes.last.y, closeTo(188 / 724, 1e-10));
    expect(world.map.sourceSize.width, 8142);
    expect(world.map.sourceSize.height, 724);
    expect(world.map.camera.strength, 0);
    expect(world.map.layers.map((layer) => layer.id), [
      'background',
      'terrain',
      'foreground',
    ]);
    expect(world.names.toSet().length, 30);
  });

  test('Ríos Cruzados keeps foreground registered to the terrain', () {
    final background = crossedRiversMap.layers.firstWhere(
      (layer) => layer.id == 'background',
    );
    final terrain = crossedRiversMap.layers.firstWhere(
      (layer) => layer.id == 'terrain',
    );
    final foreground = crossedRiversMap.layers.firstWhere(
      (layer) => layer.id == 'foreground',
    );

    // The distant layer supplies horizontal parallax. Foreground plants must
    // stay aligned with terrain across this unusually long panorama.
    expect(background.motion.scrollFactor, .9);
    expect(terrain.plane, MapLayerPlane.terrain);
    expect(foreground.motion.scrollFactor, 1);
    expect(400 * background.motion.scrollFactor, 360);
    expect(
      foreground.motion.offset(
        centeredScroll: 5500,
        inclination: Offset.zero,
        camera: 0,
        seconds: 0,
        scale: 1,
      ),
      Offset.zero,
    );
  });

  test('Ríos Cruzados has matching tree leaves and life over the water', () {
    final ambient = crossedRiversMap.ambient!;
    crossedRiversMap.validate();
    expect(ambient.beeCount, 0);
    expect(ambient.treeLeavesOnly, isTrue);
    expect(ambient.leafAssets, hasLength(3));
    expect(ambient.canopyLeafStyles, hasLength(ambient.canopies.length));
    expect(ambient.canopyLeafStyles.toSet(), {0, 1, 2});
    expect(ambient.petalAnchors, isNotEmpty);
    expect(ambient.creatures.map((creature) => creature.kind).toSet(), {
      MapCreatureKind.butterfly,
      MapCreatureKind.dragonfly,
      MapCreatureKind.mayfly,
      MapCreatureKind.fish,
    });
    expect(ambient.creatureWingAssets.keys.toSet(), {
      MapCreatureKind.butterfly,
      MapCreatureKind.dragonfly,
      MapCreatureKind.mayfly,
    });

    final motion = MapAmbientMotion(
      seed: 4,
      flowerAnchors: ambient.flowers,
      foregroundFlowers: ambient.foregroundFlowerCount,
      canopyAnchors: ambient.canopies,
      canopyLeafStyles: ambient.canopyLeafStyles,
      petalAnchors: ambient.petalAnchors,
      beeCount: ambient.beeCount,
      treeLeavesOnly: ambient.treeLeavesOnly,
      sourceSize: crossedRiversMap.sourceSize,
    )..setView(const Rect.fromLTWH(0, 0, 700, 724));
    expect(motion.bees, isEmpty);
    final greenLeaves = motion.leaves.where(
      (leaf) => leaf.kind == MapLeafKind.green,
    );
    expect(greenLeaves, isNotEmpty);
    expect(
      greenLeaves.every(
        (leaf) => ambient.canopies.any(
          (canopy) => (leaf.position - canopy).distance < 150,
        ),
      ),
      isTrue,
    );
  });

  test(
    'world and level states unlock in the same three-star sequence',
    () async {
      final repository = GameRepository.memory();
      addTearDown(repository.close);
      final navigation = MockWorldNavigationService(repository);
      final progress = LevelProgress(
        repository: repository,
        worldId: 'world-3',
      );
      addTearDown(progress.dispose);

      expect(navigation.isUnlocked('world-3'), isFalse);
      expect(progress.isUnlocked(1), isFalse);
      expect(progress.latestUnlocked, 1);
      expect(progress.unlockedCount, 0);
      expect(
        repository
            .state
            .levels[mapLevelId(1, worldId: 'world-3')]!
            .prerequisites,
        [for (var n = 1; n <= 20; n++) mapLevelId(n, worldId: 'world-2')],
      );

      for (var level = 1; level <= 10; level++) {
        await repository.recordDebugLights(mapLevelId(level), 3);
      }
      expect(navigation.isUnlocked('world-2'), isTrue);
      expect(navigation.isUnlocked('world-3'), isFalse);
      for (var level = 1; level <= 20; level++) {
        await repository.recordDebugLights(
          mapLevelId(level, worldId: 'world-2'),
          3,
        );
      }

      expect(repository.worldCompleted('world-2'), isTrue);
      expect(navigation.isUnlocked('world-3'), isTrue);
      expect(progress.isUnlocked(1), isTrue);
      expect(progress.isUnlocked(2), isFalse);
      await navigation.enterWorld('world-3');
      expect(repository.lastAdventureWorld, 'world-3');

      await progress.recordResult(1, 2);
      expect(progress.lightsFor(1), 2);
      expect(progress.isUnlocked(2), isFalse);

      final session = await repository.startGeneratedLevel(
        1,
        worldId: 'world-3',
      );
      expect(session.puzzles, hasLength(3));
      expect(
        session.puzzles.map((puzzle) => puzzle.puzzleId),
        repository.state.levels[mapLevelId(1, worldId: 'world-3')]!.puzzleIds,
      );
      final resumed = await repository.startGeneratedLevel(
        1,
        worldId: 'world-3',
      );
      expect(resumed.id, session.id);

      await progress.recordResult(1, 3);
      expect(progress.lightsFor(1), 3);
      expect(progress.isUnlocked(2), isTrue);
      expect(progress.unlockedCount, 2);
      for (var level = 2; level <= 30; level++) {
        await progress.recordResult(level, 3);
      }
      expect(progress.unlockedCount, 30);
      expect(progress.latestUnlocked, 30);
      expect(repository.worldCompleted('world-3'), isTrue);
      expect(progress.gateCelebrationPending, isFalse);

      await repository.resetDebugLevels({mapLevelId(20, worldId: 'world-2')});
      expect(repository.worldCompleted('world-2'), isFalse);
      expect(navigation.isUnlocked('world-3'), isFalse);
      expect(progress.unlockedCount, 0);
      expect(repository.lastAdventureWorld, 'world-1');
    },
  );
}
