import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/world_catalog.dart';
import 'package:sundoku/widgets/curved_ribbon_title.dart';
import 'package:sundoku/widgets/world_destination.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Baloo2',
    )..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'))).load();
  });

  testWidgets(
    'curved titles stay inside the ribbon with long names and larger text',
    (tester) async {
      for (final name in [
        'Valle del Sol',
        'Bosque de la Cumbre',
        'Ríos Cruzados',
      ]) {
        for (final width in [220.0, 260.0, 330.0]) {
          for (final scale in [1.0, 2.0]) {
            await tester.pumpWidget(
              MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: Center(
                    child: SizedBox(
                      width: width,
                      height: 48,
                      child: CurvedRibbonTitle(text: name, fontSize: 32),
                    ),
                  ),
                ),
              ),
            );
            final title = tester.getRect(find.byType(CurvedRibbonTitle));
            for (final glyph in find.byType(Text).evaluate()) {
              final rect = tester.getRect(
                find.byElementPredicate((e) => e == glyph),
              );
              expect(rect.left, greaterThanOrEqualTo(title.left - 2));
              expect(rect.right, lessThanOrEqualTo(title.right + 2));
              expect(rect.top, greaterThanOrEqualTo(title.top - 2));
              expect(rect.bottom, lessThanOrEqualTo(title.bottom + 2));
            }
            expect(tester.takeException(), isNull);
          }
        }
      }
    },
  );

  testWidgets(
    'destination keeps live progress with one accessible action for all artwork',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var presses = 0;
      Future<void> show(int completed, int stars, bool unlocked) =>
          tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: Center(
                  child: SizedBox(
                    width: 350,
                    height: 350 * WorldDestinationGeometry.heightFactor,
                    child: WorldDestination(
                      world: adventureWorld('world-2'),
                      unlocked: unlocked,
                      highlighted: true,
                      completedLevels: completed,
                      stars: stars,
                      onPressed: () async {
                        presses++;
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
      await show(2, 7, true);
      expect(find.text('2 / 20'), findsOneWidget);
      expect(find.text('7 / 60'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Bosque de la Cumbre.*2 de 20 niveles')),
        findsOneWidget,
      );
      for (final key in ['world-medallion-world-2', 'world-ribbon-world-2']) {
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pump();
      }
      expect(presses, 2);
      await show(3, 10, true);
      expect(find.text('3 / 20'), findsOneWidget);
      expect(find.text('10 / 60'), findsOneWidget);
      await show(3, 10, false);
      await tester.tap(find.byKey(const ValueKey('choose-world-2')));
      await tester.pump();
      expect(presses, 2);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}
