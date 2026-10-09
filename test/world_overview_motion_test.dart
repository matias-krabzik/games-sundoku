import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/world_overview.dart';
import 'package:sundoku/playables/playables_runtime.dart';
import 'package:sundoku/widgets/world_overview_scene.dart';

import 'playables/playables_integration_test.dart' show FakePlayablesSdk;

Future<void> frames(WidgetTester tester, [int count = 20]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 33));
  }
}

Future<void> showOverview(WidgetTester tester, {bool reduced = false}) async {
  tester.view.physicalSize = const Size(834, 1210);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(834, 1210),
          disableAnimations: reduced,
        ),
        child: const WorldOverviewScene(
          overview: WorldOverview(false),
          protectedRects: [],
          lockedWorlds: {'world-2', 'world-3'},
          child: SizedBox.expand(),
        ),
      ),
    ),
  );
  await frames(tester);
}

void main() {
  testWidgets(
    'ambient water, clouds and animals stop off-route and in background',
    (tester) async {
      await showOverview(tester);
      final state = tester.state<WorldOverviewSceneState>(
        find.byType(WorldOverviewScene),
      );
      expect(state.isAnimating, isTrue);
      final initial = state.seconds;
      final butterfly = state.motion.creatures.first;
      final before = state.motion.creaturePose(butterfly).position;
      await frames(tester);
      expect(state.seconds, greaterThan(initial));
      expect(state.motion.creaturePose(butterfly).position, isNot(before));
      final navigator = Navigator.of(
        tester.element(find.byType(WorldOverviewScene)),
      );
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Ajustes')),
          ),
        ),
      );
      await frames(tester);
      expect(state.isAnimating, isFalse);
      final covered = state.seconds;
      await frames(tester);
      expect(state.seconds, covered);
      navigator.pop();
      await frames(tester);
      expect(state.isAnimating, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final paused = state.seconds;
      await frames(tester);
      expect(state.seconds, paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await frames(tester);
      expect(state.seconds, greaterThan(paused));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('reduced motion leaves a stable, fully visible map', (
    tester,
  ) async {
    await showOverview(tester, reduced: true);
    final state = tester.state<WorldOverviewSceneState>(
      find.byType(WorldOverviewScene),
    );
    expect(state.isAnimating, isFalse);
    await frames(tester);
    expect(state.seconds, 0);
    expect(find.byType(Image), findsNWidgets(3));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('YouTube pause also suspends overview effects', (tester) async {
    final sdk = FakePlayablesSdk();
    final runtime = PlayablesRuntime(sdk);
    PlayablesRuntime.active = runtime;
    await showOverview(tester);
    final state = tester.state<WorldOverviewSceneState>(
      find.byType(WorldOverviewScene),
    );
    sdk.pause();
    await tester.pump();
    final paused = state.seconds;
    await frames(tester);
    expect(state.isAnimating, isFalse);
    expect(state.seconds, paused);
    sdk.resume();
    await frames(tester);
    expect(state.seconds, greaterThan(paused));
    await tester.pumpWidget(const SizedBox());
    runtime.dispose();
  });

  testWidgets(
    'touches use shared radial leaf reactions and fish remain in water',
    (tester) async {
      await showOverview(tester);
      final state = tester.state<WorldOverviewSceneState>(
        find.byType(WorldOverviewScene),
      );
      const overview = WorldOverview(false);
      const size = Size(834, 1210);
      final image = overview.imageRect(size);
      final scale = image.width / overview.sourceSize.width;
      final leaf = state.motion.leaves.firstWhere(
        (leaf) => (const Offset(40, 40) & const Size(754, 1130)).contains(
          image.topLeft + leaf.position * scale,
        ),
      );
      final touch =
          image.topLeft + (leaf.position - const Offset(40, 40)) * scale;
      await tester.tapAt(touch);
      expect(leaf.impulse.dx, greaterThan(0));
      expect(leaf.impulse.dy, greaterThan(0));
      final fish = state.motion.creatures.last;
      final pond = Rect.fromCenter(
        center: fish.center,
        width: fish.travel.dx * 2 + .01,
        height: fish.travel.dy * 2 + .01,
      );
      await tester.tapAt(
        image.topLeft + state.motion.creaturePose(fish).position * scale,
      );
      for (var i = 0; i < 150; i++) {
        await frames(tester, 1);
        expect(pond.contains(state.motion.creaturePose(fish).position), isTrue);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
