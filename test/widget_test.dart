import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sundoku/app.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/screens/home_screen.dart';
import 'package:sundoku/screens/first_experience_screen.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/widgets/juicy_press.dart';

Future<void> _bootToHome(WidgetTester tester) async {
  await tester.pumpWidget(const SunDokuApp(feedback: GameFeedback()));
  await tester.pump(const Duration(seconds: 3)); // wait out the splash
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  for (var frame = 0; frame < 10; frame++) {
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
  await tester.tap(find.text('Jugar'));
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
  for (var frame = 0; frame < 10; frame++) {
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

void main() {
  testWidgets('home controls stay reachable with long names and rotation', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final size in [
      const Size(320, 568),
      const Size(568, 320),
      const Size(844, 390),
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
    }
  });

  testWidgets('map light handles rapid selection and reduced motion', (
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
    expect(find.text('Nivel 4 de 10'), findsOneWidget);
    expect(tester.takeException(), isNull);

    reduceMotion.value = true;
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.tap(find.byTooltip('Nivel siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Nivel 5 de 10'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('map controls remain reachable with large text and rotation', (
    tester,
  ) async {
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
      expect(find.text('Valle del Sol'), findsOneWidget);
      expect(find.text('Nivel $expectedLevel de 10'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('map-next')));
      await _finishMapTransition(tester);
      expectedLevel++;
      expect(find.text('Nivel $expectedLevel de 10'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('splash advances to the home screen', (tester) async {
    await tester.pumpWidget(const SunDokuApp(feedback: GameFeedback()));
    expect(find.byType(HomeScreen), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Jugar'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-settings')), findsOneWidget);
  });

  testWidgets('settings button opens settings', (tester) async {
    await _bootToHome(tester);
    await tester.tap(find.byKey(const ValueKey('home-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Configuración'), findsOneWidget);
  });

  testWidgets('play opens the map and a level shows a toast', (tester) async {
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

  testWidgets('all ten levels remain reachable after rotating a small phone', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _openMap(tester);

    // At level 1 the back arrow is disabled, forward is enabled.
    expect(_mapArrow(tester, 'map-previous').onPressed, isNull);
    expect(_mapArrow(tester, 'map-next').onPressed, isNotNull);

    for (int level = 2; level <= 10; level++) {
      await tester.tap(find.byKey(const ValueKey('map-next')));
      await _finishMapTransition(tester);
      expect(find.text('Nivel $level de 10'), findsOneWidget);
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
    expect(find.text('Consigue 3 puntos en el nivel 9'), findsWidgets);
    await tester.pump(const Duration(seconds: 3));

    // Now the back arrow is usable again.
    expect(_mapArrow(tester, 'map-previous').onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('map-previous')));
    await _finishMapTransition(tester);
    expect(find.text('Nivel 9 de 10'), findsOneWidget);
  });
}
