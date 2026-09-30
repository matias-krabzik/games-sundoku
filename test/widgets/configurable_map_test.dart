import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/level_node.dart';
import 'package:sundoku/data/level_progress.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/spring_forest_map.dart';
import 'package:sundoku/data/world_catalog.dart';
import 'package:sundoku/models/map_ambient_motion.dart';
import 'package:sundoku/models/world_map_definition.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/widgets/map_ambient_painter.dart';
import 'package:sundoku/widgets/map_layout.dart';
import 'package:sundoku/widgets/map_level_button.dart';
import 'package:sundoku/widgets/map_parallax_scene.dart';

const customMap = WorldMapDefinition(
  sourceSize: Size(3200, 800),
  path: [Offset(.1, .8), Offset(.9, .2)],
  camera: MapCameraDefinition(targetY: .5, strength: .4, maxTravel: .06),
  layers: [
    MapLayerDefinition(
      id: 'horizon',
      asset: 'assets/images/map/layers/sky.png',
      motion: MapLayerMotion(scrollFactor: .3),
    ),
    MapLayerDefinition(
      id: 'walkway',
      asset: 'assets/images/map/layers/terrain.png',
      plane: MapLayerPlane.terrain,
    ),
    MapLayerDefinition(
      id: 'nearby',
      asset: 'assets/images/map/layers/foreground.png',
      plane: MapLayerPlane.foreground,
      motion: MapLayerMotion(scrollFactor: 1.2),
    ),
  ],
);

void main() {
  test(
    'level count is driven by names, preserving valley positions and saved IDs',
    () {
      final valley = adventureWorld('world-1');
      final forest = adventureWorld('world-2');
      expect(valley.nodes, kMap1Nodes);
      expect(forest.levelCount, 20);
      expect(forest.nodes.length, forest.names.length);
      expect(forest.nodes.first.level, 1);
      expect(forest.nodes.last.level, 20);
      expect(forest.nodes.first.x, closeTo(springForestPath.first.dx, 1e-10));
      expect(forest.nodes.last.x, closeTo(springForestPath.last.dx, 1e-10));
      final custom = AdventureWorld(
        id: 'example',
        number: 3,
        name: 'Example',
        names: ['One', 'Two', 'Three'],
        map: customMap,
      );
      expect(custom.nodes.length, 3);
      expect(custom.nodes[1].x, closeTo(.5, 1e-10));
      expect(custom.nodes[1].y, closeTo(.5, 1e-10));
      expect(customMap.nodesFor(1).single.x, .1);
      expect(() => customMap.nodesFor(0), throwsArgumentError);
      expect(
        () => AdventureWorld(
          id: 'bad',
          number: 4,
          name: 'Bad',
          names: ['One'],
          nodes: kMap1Nodes,
          map: customMap,
        ),
        throwsArgumentError,
      );
    },
  );

  test('camera follows the configured path rather than the valley', () {
    const world = Size(3200, 800), viewport = Size(400, 800);
    final left = pathCameraOffset(0, viewport, world, customMap);
    final right = pathCameraOffset(2800, viewport, world, customMap);
    expect(left, -48);
    expect(right, 48);
    expect(
      pathCameraOffset(1400, viewport, world, customMap),
      closeTo(0, 1e-9),
    );
  });

  test(
    'worlds one and two follow the route vertically during horizontal scroll',
    () {
      const viewport = Size(390, 844);
      for (final worldId in ['world-1', 'world-2']) {
        final map = adventureWorld(worldId).map;
        final world = MapLayout(
          viewport,
          map,
          adventureWorld(worldId).nodes,
        ).worldSize;
        final start = pathCameraOffset(0, viewport, world, map);
        final end = pathCameraOffset(
          world.width - viewport.width,
          viewport,
          world,
          map,
        );

        expect(map.camera.strength, greaterThan(0), reason: worldId);
        expect((start - end).abs(), greaterThan(1), reason: worldId);
      }

      final map3 = adventureWorld('world-3').map;
      final world3 = MapLayout(
        viewport,
        map3,
        adventureWorld('world-3').nodes,
      ).worldSize;
      expect(map3.camera.strength, 0);
      expect(pathCameraOffset(0, viewport, world3, map3), 0);
      expect(
        pathCameraOffset(world3.width - viewport.width, viewport, world3, map3),
        0,
      );
    },
  );

  testWidgets('Ríos Cruzados loads every ambient sprite', (tester) async {
    final ambient = adventureWorld('world-3').map.ambient!;
    final art = MapAmbientArt(
      leafAssets: ambient.leafAssets,
      petalAsset: ambient.petalAsset,
      creatureAssets: ambient.creatureAssets,
      creatureWingAssets: ambient.creatureWingAssets,
    );
    addTearDown(art.dispose);
    await tester.runAsync(art.load);
    expect(art.leaves, hasLength(3));
    expect(art.petal, isNotNull);
    expect(art.creatures.keys.toSet(), MapCreatureKind.values.toSet());
    expect(art.creatureWings.keys.toSet(), {
      MapCreatureKind.butterfly,
      MapCreatureKind.dragonfly,
      MapCreatureKind.mayfly,
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping near a world-three insect starts its escape', (
    tester,
  ) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MapParallaxScene(
          definition: adventureWorld('world-3').map,
          scroll: scroll,
          worldSize: const Size(8142, 724),
          child: SingleChildScrollView(
            controller: scroll,
            scrollDirection: Axis.horizontal,
            child: const SizedBox(width: 8142, height: 724),
          ),
        ),
      ),
    );
    await tester.pump();
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<MapAmbientPainter>()
        .firstWhere((paint) => paint.depth == MapLeafDepth.air);
    final creature = painter.motion.creatures.first;
    final pose = painter.motion.creaturePose(creature);
    final point = painter.origin + pose.position * painter.scale;
    // The tap lands beyond the butterfly sprite, on the surrounding map.
    await tester.tapAt(point + const Offset(65, 0));
    await tester.pump();
    expect(painter.motion.creaturePose(creature).startled, isTrue);
    await tester.pump(const Duration(milliseconds: 180));
    expect(painter.motion.creaturePose(creature).visualScale, greaterThan(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test('dense worlds retain touch targets and source aspect ratio in small windows', () {
    for (final world in [
      adventureWorld('world-2'),
      adventureWorld('world-3'),
    ]) {
      for (final viewport in [
        const Size(390, 640),
        const Size(844, 240),
        const Size(320, 320),
      ]) {
        final layout = MapLayout(viewport, world.map, world.nodes);
        expect(
          layout.worldSize.aspectRatio,
          closeTo(world.map.aspectRatio, 1e-10),
        );
        expect(layout.nodeSize, greaterThanOrEqualTo(48));
        for (var i = 1; i < world.nodes.length; i++) {
          final a = world.nodes[i - 1], b = world.nodes[i];
          final distance = Offset(
            (a.x - b.x) * layout.worldSize.width,
            (a.y - b.y) * layout.worldSize.height,
          ).distance;
          expect(
            distance,
            greaterThanOrEqualTo(
              layout.nodeSize * world.map.markerSeparation - .001,
            ),
            reason: '${world.name}, ${viewport.width}×${viewport.height}',
          );
        }
      }
    }
  });

  testWidgets(
    'arbitrary layer names, count, speeds and dimensions use one renderer',
    (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MapParallaxScene(
            definition: customMap,
            scroll: scroll,
            worldSize: const Size(3200, 800),
            child: SingleChildScrollView(
              controller: scroll,
              scrollDirection: Axis.horizontal,
              child: const SizedBox(width: 3200, height: 800),
            ),
          ),
        ),
      );
      await tester.pump();
      Finder layer(String id) => find.byKey(ValueKey('map-layer-$id'));
      final start = {
        for (final id in ['horizon', 'walkway', 'nearby'])
          id: tester.getTopLeft(layer(id)).dx,
      };
      expect(find.byKey(const ValueKey('map-layer-clouds')), findsNothing);
      expect(
        tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .where((w) => w.painter is MapAmbientPainter),
        isEmpty,
      );
      expect(tester.getSize(layer('walkway')), const Size(3200, 800));
      scroll.jumpTo(400);
      await tester.pump();
      expect(
        tester.getTopLeft(layer('horizon')).dx - start['horizon']!,
        closeTo(-120, .01),
      );
      expect(
        tester.getTopLeft(layer('walkway')).dx - start['walkway']!,
        closeTo(-400, .01),
      );
      expect(
        tester.getTopLeft(layer('nearby')).dx - start['nearby']!,
        closeTo(-480, .01),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('20-level map keeps selection and saved progress when resized', (
    tester,
  ) async {
    final repo = GameRepository.memory();
    await repo.prepareDebugForest();
    final progress = LevelProgress(repository: repo, worldId: 'world-2');
    final before = repo.state.revision;
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in [
      const Size(390, 844),
      const Size(844, 390),
      const Size(320, 568),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: size, disableAnimations: true),
            child: MapScreen(progress: progress, showDeveloperControls: false),
          ),
        ),
      );
      for (var frame = 0; frame < 20; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(MapParallaxScene), findsOneWidget);
      expect(find.byType(MapLevelButton), findsNWidgets(20));
      expect(find.text('20'), findsOneWidget);
      expect(find.byKey(const ValueKey('map-world-gate')), findsNothing);
      final first = tester
          .widgetList<MapLevelButton>(find.byType(MapLevelButton))
          .first;
      expect(first.active, isTrue);
      expect(first.unlocked, isTrue);
      expect(tester.takeException(), isNull);
    }
    expect(repo.state.revision, before);
    await tester.pumpWidget(const SizedBox());
    progress.dispose();
    await repo.close();
  });
}
