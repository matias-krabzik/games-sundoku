import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/app.dart';
import 'package:sundoku/data/level_progress.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/widgets/map_level_button.dart';
import 'package:sundoku/widgets/light_award_overlay.dart';
import 'package:sundoku/screens/first_experience_screen.dart';

Future<void> finishLight(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pump();
}

Future<void> finishNavigation(WidgetTester tester) async {
  await tester.pump();
  for (var frame = 0; frame < 10; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _desktopTestWidgets(String description, WidgetTesterCallback body) {
  testWidgets(description, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await body(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

void main() {
  _desktopTestWidgets(
    'saved rewards wait for return, scroll first and never award twice',
    (tester) async {
      final progress = LevelProgress();
      addTearDown(progress.dispose);
      await tester.pumpWidget(MaterialApp(home: MapScreen(progress: progress)));
      await tester.pump();
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const ValueKey('map-next')));
        await finishNavigation(tester);
      }
      final scroll = tester
          .widget<SingleChildScrollView>(
            find.byKey(const ValueKey('world-scroll')),
          )
          .controller!;
      final initialOffset = scroll.offset;
      expect(initialOffset, greaterThan(0));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Juego')),
        ),
      );
      await finishNavigation(tester);
      await progress.awardLight(1);
      await tester.pump();
      MapLevelButton marker(int level) => tester
          .widgetList<MapLevelButton>(
            find.byType(MapLevelButton, skipOffstage: false),
          )
          .singleWhere((button) => button.level == level);
      expect(marker(1).lights, 0);
      expect(progress.lightsFor(1), 1);
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(scroll.offset, lessThan(initialOffset));
      expect(marker(1).lights, 0);
      await tester.pump(const Duration(milliseconds: 400));
      expect(marker(1).lights, 0);
      await finishLight(tester);
      expect(marker(1).lights, 1);
      expect(progress.lightsFor(1), 1);
      expect(find.byType(LightAwardOverlay), findsNothing);
      navigator.push(MaterialPageRoute<void>(builder: (_) => const Scaffold()));
      await finishNavigation(tester);
      navigator.pop();
      await finishNavigation(tester);
      expect(find.byType(LightAwardOverlay), findsNothing);
      expect(marker(1).lights, 1);

      navigator.push(MaterialPageRoute<void>(builder: (_) => const Scaffold()));
      await finishNavigation(tester);
      await progress.recordResult(1, 3);
      await tester.pump();
      expect(marker(1).lights, 1);
      expect(marker(2).unlocked, isFalse);
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));
      await finishLight(tester);
      expect(marker(1).lights, 2);
      expect(marker(2).unlocked, isFalse);
      await finishLight(tester);
      await finishNavigation(tester);
      expect(marker(1).lights, 3);
      expect(marker(2).unlocked, isTrue);
      expect(find.text('Nivel 2 de 10'), findsOneWidget);
      expect(progress.lightsFor(1), 3);
      expect(tester.takeException(), isNull);
    },
  );

  _desktopTestWidgets(
    'score stars stay separated and centered above the level number',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MapScreen()));
      await tester.pump();

      final levelCenter = tester.getCenter(
        find.byKey(const ValueKey('level-1-label')),
      );
      final first = tester.getRect(
        find.byKey(const ValueKey('level-1-score-1')),
      );
      final middle = tester.getRect(
        find.byKey(const ValueKey('level-1-score-2')),
      );
      final third = tester.getRect(
        find.byKey(const ValueKey('level-1-score-3')),
      );

      expect(first.center.dy, lessThan(levelCenter.dy));
      expect(middle.center.dy, lessThan(first.center.dy));
      expect(third.center.dy, lessThan(levelCenter.dy));
      expect(first.center.dx, lessThan(levelCenter.dx));
      expect(third.center.dx, greaterThan(levelCenter.dx));
      expect(first.right, lessThanOrEqualTo(middle.left));
      expect(middle.right, lessThanOrEqualTo(third.left));
      expect(middle.center.dx, closeTo(levelCenter.dx, .1));
      expect(first.width, closeTo(third.width, .1));
      expect(first.height, closeTo(third.height, .1));
      expect(middle.width, greaterThan(first.width));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('level-1-score-1')),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('level-1-star-crest')), findsOneWidget);
      final levelImage = tester.widget<Image>(
        find.byKey(const ValueKey('level-1-label')),
      );
      final resizedNumber = levelImage.image as ResizeImage;
      expect(
        (resizedNumber.imageProvider as AssetImage).assetName,
        'assets/images/level-number-1.png',
      );
    },
  );

  test(
    'three points in the previous level unlock the next, without scoring it',
    () async {
      final progress = LevelProgress();
      addTearDown(progress.dispose);
      expect(progress.isUnlocked(1), isTrue);
      expect(progress.lightsFor(1), 0);
      await progress.awardLight(2);
      expect(progress.lightsFor(2), 0);
      for (int i = 1; i <= 3; i++) {
        await progress.awardLight(1);
        expect(progress.isUnlocked(2), i == 3);
      }
      await progress.awardLight(1);
      expect(progress.lightsFor(1), 3);
      expect(progress.lightsFor(2), 0);
      expect(progress.isUnlocked(3), isFalse);
      await progress.awardLight(2);
      await progress.resetLevel(1);
      expect(progress.isUnlocked(1), isTrue);
      expect(progress.isUnlocked(2), isFalse);
      expect(progress.lightsFor(2), 0);
    },
  );

  _desktopTestWidgets(
    'points land on the played level, then unlock and focus the next',
    (tester) async {
      final progress = LevelProgress();
      addTearDown(progress.dispose);
      await tester.pumpWidget(MaterialApp(home: MapScreen(progress: progress)));
      await tester.pump();
      expect(find.text('0/3 puntos obtenidos'), findsOneWidget);
      await tester.tap(find.byTooltip('Simular 1 punto'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(progress.lightsFor(1), 0);
      final awardButton = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Simular 1 punto',
      );
      expect(tester.widget<IconButton>(awardButton).onPressed, isNull);
      await tester.pump(const Duration(milliseconds: 500));
      expect(progress.lightsFor(1), 1);
      expect(progress.isUnlocked(2), isFalse);

      await tester.tap(find.byTooltip('Simular 3 puntos y abrir siguiente'));
      await finishLight(tester);
      expect(progress.lightsFor(1), 2);
      expect(progress.isUnlocked(2), isFalse);
      await finishLight(tester);
      expect(progress.lightsFor(1), 3);
      expect(progress.lightsFor(2), 0);
      expect(progress.isUnlocked(2), isTrue);
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.text('Nivel 2 de 10'), findsOneWidget);
      expect(find.text('0/3 puntos obtenidos'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('map-previous')));
      await finishNavigation(tester);
      await tester.tap(find.byTooltip('Reiniciar nivel'));
      await tester.pump();
      expect(progress.lightsFor(1), 0);
      expect(progress.isUnlocked(2), isFalse);
    },
  );

  _desktopTestWidgets('leaving during delivery cancels unearned score', (
    tester,
  ) async {
    final progress = LevelProgress();
    addTearDown(progress.dispose);
    await tester.pumpWidget(MaterialApp(home: MapScreen(progress: progress)));
    await tester.pump();
    await tester.tap(find.byTooltip('Simular 3 puntos y abrir siguiente'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    expect(progress.lightsFor(1), 0);
    expect(progress.isUnlocked(2), isFalse);
    expect(tester.takeException(), isNull);
  });

  _desktopTestWidgets(
    'reduced motion unlocks immediately and progress survives map reentry',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(const SunDokuApp());
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final welcome = find.byKey(const ValueKey('profile-close'));
      if (welcome.evaluate().isNotEmpty) {
        await tester.tap(welcome);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.tap(find.text('Jugar'));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(FirstExperienceScreen))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Simular 3 puntos y abrir siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Nivel 2 de 10'), findsOneWidget);
      expect(find.text('0/3 puntos obtenidos'), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.tap(find.byKey(const ValueKey('map-back')));
      await tester.pumpAndSettle();
      expect(find.text('2 de 10'), findsOneWidget);
      await tester.tap(find.text('Jugar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('map-next')));
      await tester.pumpAndSettle();
      expect(find.text('0/3 puntos obtenidos'), findsOneWidget);
    },
  );
}
