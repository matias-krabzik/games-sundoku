import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/level_node.dart';
import 'package:sundoku/data/level_progress.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/widgets/map_level_button.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

int activeLevel(WidgetTester tester) => tester
    .widgetList<MapLevelButton>(find.byType(MapLevelButton))
    .singleWhere((button) => button.active)
    .level;

ScrollController scroll(WidgetTester tester) => tester
    .widget<SingleChildScrollView>(find.byKey(const ValueKey('world-scroll')))
    .controller!;

void desktopTestWidgets(String name, WidgetTesterCallback body) {
  testWidgets(name, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await body(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

void main() {
  for (final completed in [0, 5, 9, 10]) {
    desktopTestWidgets('map entry after $completed completed levels', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final progress = LevelProgress();
      for (var level = 1; level <= completed; level++) {
        await progress.recordResult(level, 3);
      }
      if (completed == 5) await progress.recordResult(6, 1);
      var opened = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MapScreen(
            progress: progress,
            showDeveloperControls: false,
            onOpenLevel: (_) async {
              opened++;
            },
          ),
        ),
      );
      await settle(tester);
      final expected = completed == 10 ? 1 : completed + 1;
      expect(activeLevel(tester), expected);
      final position = scroll(tester);
      final expectedOffset = (kMap1Nodes[expected - 1].x * 844 * 3 - 195).clamp(
        0.0,
        position.position.maxScrollExtent,
      );
      expect(position.offset, closeTo(expectedOffset, .1));
      expect(opened, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      progress.dispose();
    });
  }

  desktopTestWidgets(
    'return refocuses newest unlocked level after rewards, manual browsing stays put',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final progress = LevelProgress();
      for (var level = 1; level <= 4; level++) {
        await progress.recordResult(level, 3);
      }
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: MapScreen(progress: progress, showDeveloperControls: false),
        ),
      );
      await settle(tester);
      expect(activeLevel(tester), 5);
      await tester.tap(find.byKey(const ValueKey('map-previous')));
      await settle(tester);
      expect(activeLevel(tester), 4);
      await tester.pump(const Duration(seconds: 5));
      expect(activeLevel(tester), 4);
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      );
      await settle(tester);
      await progress.recordResult(5, 3);
      await progress.recordResult(6, 3);
      navigatorKey.currentState!.pop();
      await settle(tester);
      expect(activeLevel(tester), 7);
      expect(
        tester
            .widgetList<MapLevelButton>(find.byType(MapLevelButton))
            .singleWhere((b) => b.level == 6)
            .lights,
        3,
      );
      await tester.tap(find.byKey(const ValueKey('map-previous')));
      await settle(tester);
      expect(activeLevel(tester), 6);
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      );
      await settle(tester);
      navigatorKey.currentState!.pop();
      await settle(tester);
      expect(activeLevel(tester), 7);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      progress.dispose();
    },
  );

  desktopTestWidgets(
    'completed map retains selected level and position on return',
    (tester) async {
      final progress = LevelProgress();
      for (var level = 1; level <= 10; level++) {
        await progress.recordResult(level, 3);
      }
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: MapScreen(progress: progress, showDeveloperControls: false),
        ),
      );
      await settle(tester);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const ValueKey('map-next')));
        await settle(tester);
      }
      final offset = scroll(tester).offset;
      expect(activeLevel(tester), 4);
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      );
      await settle(tester);
      navigatorKey.currentState!.pop();
      await settle(tester);
      expect(activeLevel(tester), 4);
      expect(scroll(tester).offset, offset);
      await tester.pumpWidget(const SizedBox());
      progress.dispose();
    },
  );
}
