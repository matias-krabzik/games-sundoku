import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sundoku/app.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/screens/home_screen.dart';
import 'package:sundoku/screens/map_screen.dart';

Future<void> _bootToHome(WidgetTester tester) async {
  await tester.pumpWidget(const SunDokuApp(feedback: GameFeedback()));
  await tester.pump(const Duration(seconds: 3)); // wait out the splash
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _openMap(WidgetTester tester) async {
  await _bootToHome(tester);
  await tester.tap(find.text('Jugar'));
  await _finishMapTransition(tester);
}

// The selected level now keeps a light shimmering while the map is visible.
Future<void> _finishMapTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
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
      await tester.tap(find.byTooltip('Nivel siguiente'));
      await tester.pump(const Duration(milliseconds: 100));
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

  testWidgets('splash advances to the home screen', (tester) async {
    await tester.pumpWidget(const SunDokuApp(feedback: GameFeedback()));
    expect(find.byType(HomeScreen), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Jugar'), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
  });

  testWidgets('settings button opens settings', (tester) async {
    await _bootToHome(tester);
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Configuración'), findsOneWidget);
  });

  testWidgets('play opens the map and a level shows a toast', (tester) async {
    await _openMap(tester);
    expect(find.byType(MapScreen), findsOneWidget);

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
    IconButton arrow(IconData i) =>
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, i));
    expect(arrow(Icons.chevron_left_rounded).onPressed, isNull);
    expect(arrow(Icons.chevron_right_rounded).onPressed, isNotNull);

    for (int level = 2; level <= 10; level++) {
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await _finishMapTransition(tester);
      expect(find.text('Nivel $level de 10'), findsOneWidget);
      expect(
        find.byKey(ValueKey('level-$level-label')).hitTestable(),
        findsOneWidget,
      );
    }
    expect(find.text('11'), findsNothing);
    expect(arrow(Icons.chevron_right_rounded).onPressed, isNull);

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
    expect(arrow(Icons.chevron_left_rounded).onPressed, isNotNull);
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await _finishMapTransition(tester);
    expect(find.text('Nivel 9 de 10'), findsOneWidget);
  });
}
