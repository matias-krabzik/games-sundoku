import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/widgets/world_journey_route.dart';

void main() {
  for (final reduced in [false, true]) {
    testWidgets('journey enters and returns, reduced motion: $reduced', (
      tester,
    ) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(body: Text('Home')),
        ),
      );
      final route = WorldJourneyRoute(
        reduceMotion: reduced,
        builder: (_) => const Scaffold(body: Text('Map')),
      );
      navigator.currentState!.push(route);
      await tester.pump();
      if (!reduced) {
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('Home'), findsOneWidget);
        final opacity = tester.widget<Opacity>(
          find
              .ancestor(of: find.text('Map'), matching: find.byType(Opacity))
              .first,
        );
        expect(opacity.opacity, 0);
        expect(
          tester
              .widget<Opacity>(
                find.byKey(const ValueKey('journey-cloud-opacity')),
              )
              .opacity,
          1,
        );
        await tester.pump(const Duration(milliseconds: 550));
        expect(
          tester
              .widget<Opacity>(
                find.byKey(const ValueKey('journey-cloud-opacity')),
              )
              .opacity,
          1,
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          tester
              .widget<Opacity>(
                find.byKey(const ValueKey('journey-cloud-opacity')),
              )
              .opacity,
          inExclusiveRange(0, 1),
        );
      }
      await tester.pumpAndSettle();
      expect(await route.entered, isTrue);
      expect(find.text('Map'), findsOneWidget);
      navigator.currentState!.pop();
      if (!reduced) {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(
          tester
              .widget<Opacity>(
                find.byKey(const ValueKey('journey-cloud-opacity')),
              )
              .opacity,
          1,
        );
        await tester.pump(const Duration(milliseconds: 850));
        expect(
          tester
              .widget<Opacity>(
                find.byKey(const ValueKey('journey-cloud-opacity')),
              )
              .opacity,
          inExclusiveRange(0, .6),
        );
      }
      await tester.pumpAndSettle();
      expect(find.text('Map'), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('interrupted arrival does not trigger the introduction', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const SizedBox()),
    );
    final route = WorldJourneyRoute(builder: (_) => const SizedBox());
    navigator.currentState!.push(route);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(await route.entered, isFalse);
    expect(tester.takeException(), isNull);
  });
}
