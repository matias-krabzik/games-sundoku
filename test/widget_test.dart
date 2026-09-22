import 'package:sundoku/data/level_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sundoku/app.dart';
import 'package:sundoku/data/level_progress.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/screens/home_screen.dart';
import 'package:sundoku/screens/first_experience_screen.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/widgets/juicy_press.dart';
import 'package:sundoku/widgets/map_selection_light.dart';

Future<void> _bootToHome(WidgetTester tester) async {
  await tester.pumpWidget(const SunDokuApp(feedback: GameFeedback()));
  await tester.pump(const Duration(seconds: 3)); // wait out the splash
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  for (var frame = 0; frame < 20; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  final welcome = find.byKey(const ValueKey('profile-close'));
  if (welcome.evaluate().isNotEmpty) {
    await tester.tap(welcome);
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

Future<void> _openMap(WidgetTester tester) async {
  await _bootToHome(tester);
  await tester.tap(find.byKey(const ValueKey('home-play')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 200));
  await _finishMapTransition(tester);
  // A fresh installation now opens onboarding above the map.
  Navigator.of(tester.element(find.byType(FirstExperienceScreen))).pop();
  await _finishMapTransition(tester);
}

// The selected level now keeps a light shimmering while the map is visible.
Future<void> _finishMapTransition(WidgetTester tester) async {
  await tester.pump();
  for (var frame = 0; frame < 20; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

JuicyPress _mapArrow(WidgetTester tester, String key) =>
    tester.widget<JuicyPress>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(JuicyPress),
      ),
    );

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
  testWidgets('tall phones stack home actions on Android and iOS', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    try {
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        debugDefaultTargetPlatformOverride = platform;
        for (final size in [const Size(412, 915), const Size(430, 956)]) {
          tester.view.physicalSize = size;
          await tester.pumpWidget(
            MaterialApp(
              key: ValueKey('$platform-$size'),
              home: const HomeScreen(hasStarted: true, quickPlayUnlocked: true),
            ),
          );
          await tester.pump();
          final adventure = tester.getRect(
            find.byKey(const ValueKey('home-play')),
          );
          final quickPlay = tester.getRect(
            find.byKey(const ValueKey('home-quick-play')),
          );
          expect(adventure.bottom, lessThan(quickPlay.top));
          expect(adventure.center.dx, closeTo(quickPlay.center.dx, .1));
          expect(
            find.byKey(const ValueKey('home-play')).hitTestable(),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('home-quick-play')).hitTestable(),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        }
      }
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('quick play appears only after level one is complete', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    expect(find.text('Aventura'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-quick-play')), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(hasStarted: true, quickPlayUnlocked: true),
      ),
    );
    final quickPlay = find.byKey(const ValueKey('home-quick-play'));
    expect(quickPlay.hitTestable(), findsOneWidget);
    await tester.tap(quickPlay);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  _desktopTestWidgets(
    'large home places adventure and quick play side by side',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(768, 1024);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(hasStarted: true, quickPlayUnlocked: true),
        ),
      );
      await tester.pump();

      final adventure = tester.getRect(find.byKey(const ValueKey('home-play')));
      final quickPlay = tester.getRect(
        find.byKey(const ValueKey('home-quick-play')),
      );
      expect(adventure.top, closeTo(quickPlay.top, .1));
      expect(adventure.right, lessThan(quickPlay.left));
      expect(adventure.width, lessThan(quickPlay.width));
      expect(adventure.width + quickPlay.width, lessThan(620));
    },
  );

  _desktopTestWidgets(
    'home controls stay reachable with long names and rotation',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final size in [
        const Size(320, 568),
        const Size(568, 320),
        const Size(844, 390),
        const Size(768, 1024),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(
              playerName: 'Un nombre de jugador especialmente largo',
            ),
          ),
        );
        await tester.pump();
        for (final key in ['home-profile', 'home-settings', 'home-play']) {
          expect(find.byKey(ValueKey(key)).hitTestable(), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        final profile = tester.getTopLeft(
          find.byKey(const ValueKey('home-profile')),
        );
        final settings = tester.getTopLeft(
          find.byKey(const ValueKey('home-settings')),
        );
        expect(profile.dy, settings.dy);
        expect(profile.dx, lessThan(settings.dx));
        final largeWindow = size.width >= 700 || size.height >= 900;
        expect(profile.dx, closeTo(largeWindow ? 32 : 16, .1));
        expect(
          settings.dx + 54,
          closeTo(size.width - (largeWindow ? 32 : 16), .1),
        );
        expect(profile.dy, closeTo(largeWindow ? 24 : 8, .1));
        final logo = tester.getRect(find.byKey(const ValueKey('home-logo')));
        if (largeWindow) expect(logo.width, greaterThan(360));
        if (size.width <= size.height * 1.2 && largeWindow) {
          expect(logo.width, closeTo(size.width * .9, .1));
        }
      }
    },
  );

  _desktopTestWidgets('map light handles rapid selection and reduced motion', (
    tester,
  ) async {
    final reduceMotion = ValueNotifier(false);
    addTearDown(reduceMotion.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: reduceMotion,
          builder: (context, disabled, _) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: disabled),
            child: const MapScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    for (int i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('map-next')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Repeated input during the same spring must not trigger a second move.
      await tester.tap(find.byKey(const ValueKey('map-next')));
      await tester.pump(const Duration(milliseconds: 200));
    }
    await _finishMapTransition(tester);
    expect(find.text(kValleyLevelNames[3]), findsOneWidget);
    expect(tester.takeException(), isNull);

    reduceMotion.value = true;
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.tap(find.byKey(const ValueKey('map-next')));
    await tester.pumpAndSettle();
    expect(find.text(kValleyLevelNames[4]), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('map DEV menu offers world and specific level resets', (
    tester,
  ) async {
    final progress = LevelProgress();
    addTearDown(progress.dispose);
    await progress.recordResult(1, 3);
    await tester.pumpWidget(MaterialApp(home: MapScreen(progress: progress)));
    await _finishMapTransition(tester);

    await tester.tap(find.byKey(const ValueKey('dev-floating-button')));
    await _finishMapTransition(tester);
    expect(find.byKey(const ValueKey('dev-reset-world')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dev-complete-random-level')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('dev-reset-specific-level')));
    await _finishMapTransition(tester);
    expect(find.byKey(const ValueKey('dev-level-picker')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dev-reset-level-1')));
    await _finishMapTransition(tester);
    expect(progress.lightsFor(1), 0);
    await tester.tap(find.byKey(const ValueKey('dev-floating-button')));
    await _finishMapTransition(tester);
    await tester.tap(
      find.byKey(const ValueKey('dev-complete-world-except-last')),
    );
    await _finishMapTransition(tester);
    expect(progress.lightsFor(9), 3);
    expect(progress.lightsFor(10), 2);
    expect(
      progress.sessionFor(10)!.nextPuzzleId,
      progress.sessionFor(10)!.puzzles.last.puzzleId,
    );
  });

  _desktopTestWidgets(
    'map controls remain reachable with large text and rotation',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      var expectedLevel = 1;
      for (final size in [const Size(320, 568), const Size(568, 320)]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          const MaterialApp(home: MapScreen(showDeveloperControls: false)),
        );
        await _finishMapTransition(tester);
        expect(find.text('DEV'), findsNothing);
        expect(find.byTooltip('Simular 1 punto'), findsNothing);
        for (final key in ['map-back', 'map-previous', 'map-next']) {
          final control = find.byKey(ValueKey(key));
          expect(control.hitTestable(), findsOneWidget);
          final bounds = tester.getRect(control);
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.top, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(size.width));
          expect(bounds.bottom, lessThanOrEqualTo(size.height));
          expect(bounds.width, greaterThanOrEqualTo(48));
          expect(bounds.height, greaterThanOrEqualTo(48));
        }
        expect(find.text('MUNDO 1 · VALLE DEL SOL'), findsOneWidget);
        expect(find.text(kValleyLevelNames[expectedLevel - 1]), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('map-next')));
        await _finishMapTransition(tester);
        expectedLevel++;
        expect(find.text(kValleyLevelNames[expectedLevel - 1]), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  _desktopTestWidgets(
    'map navigation matches the home margins on large screens',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(768, 1024);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: MapScreen(showDeveloperControls: false)),
      );
      await _finishMapTransition(tester);

      final back = tester.getRect(find.byKey(const ValueKey('map-back')));
      final settings = tester.getRect(
        find.byKey(const ValueKey('map-settings')),
      );
      expect(back.left, closeTo(32, .1));
      expect(back.top, closeTo(24, .1));
      expect(settings.right, closeTo(768 - 32, .1));
      expect(settings.top, closeTo(24, .1));
    },
  );

  _desktopTestWidgets('splash advances to the home screen', (tester) async {
    await tester.pumpWidget(const SunDokuApp(feedback: GameFeedback()));
    expect(find.byType(HomeScreen), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Aventura'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-settings')), findsOneWidget);
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    _desktopTestWidgets(
      'mobile map hides arrows and lights locked selection on $platform',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        await _openMap(tester);
        expect(find.byKey(const ValueKey('map-previous')), findsNothing);
        expect(find.byKey(const ValueKey('map-next')), findsNothing);
        await tester.tap(find.byKey(const ValueKey('level-2-label')));
        await _finishMapTransition(tester);
        final light = tester.widget<MapSelectionLight>(
          find.byType(MapSelectionLight),
        );
        expect(light.level, 2);
        expect(light.enabled, isTrue);
        expect(light.scoreLevels, isNot(contains(2)));
        expect(find.text(kValleyLevelNames[1]), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
      },
    );
  }

  _desktopTestWidgets('settings button opens settings', (tester) async {
    await _bootToHome(tester);
    await tester.tap(find.byKey(const ValueKey('home-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Configuración'), findsOneWidget);
  });

  _desktopTestWidgets('play opens the map and a level shows a toast', (
    tester,
  ) async {
    await _openMap(tester);
    expect(find.byType(MapScreen), findsOneWidget);
    expect(find.text('DEV'), findsOneWidget);

    // Level 2 is visible beside the first node at the default test size.
    await tester.tap(find.byKey(const ValueKey('level-2-label')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Consigue 3 puntos en el nivel 1'), findsWidgets);

    await tester.pump(const Duration(seconds: 3)); // let the toast dismiss
  });

  _desktopTestWidgets(
    'all ten levels remain reachable after rotating a small phone',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _openMap(tester);
      await tester.drag(
        find.byKey(const ValueKey('dev-floating-button')),
        const Offset(-100, -200),
      );
      await tester.pump();

      // At level 1 the back arrow is disabled, forward is enabled.
      expect(_mapArrow(tester, 'map-previous').onPressed, isNull);
      expect(_mapArrow(tester, 'map-next').onPressed, isNotNull);

      for (int level = 2; level <= 10; level++) {
        await tester.tap(find.byKey(const ValueKey('map-next')));
        await _finishMapTransition(tester);
        expect(find.text(kValleyLevelNames[level - 1]), findsOneWidget);
        expect(
          find.byKey(ValueKey('level-$level-label')).hitTestable(),
          findsOneWidget,
        );
      }
      expect(find.text('11'), findsNothing);
      expect(_mapArrow(tester, 'map-next').onPressed, isNull);

      tester.view.physicalSize = const Size(844, 390);
      await _finishMapTransition(tester);
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('level-10-label')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('level-10-label')));
      await _finishMapTransition(tester);
      expect(find.text(kValleyLevelNames[9]), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));

      // Now the back arrow is usable again.
      expect(_mapArrow(tester, 'map-previous').onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('map-previous')));
      await _finishMapTransition(tester);
      expect(find.text(kValleyLevelNames[8]), findsOneWidget);
    },
  );
}
