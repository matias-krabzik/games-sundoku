import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/widgets/game_round_stars.dart';
import 'package:sundoku/widgets/map_art.dart';

Widget host({
  int currentRound = 0,
  Set<int> completedRounds = const {},
  bool animate = true,
  bool reducedMotion = false,
  bool accessibleNavigation = false,
  bool tickerEnabled = true,
  double width = 156,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: MediaQueryData(
      disableAnimations: reducedMotion,
      accessibleNavigation: accessibleNavigation,
      textScaler: TextScaler.linear(2),
    ),
    child: TickerMode(
      enabled: tickerEnabled,
      child: Center(
        child: SizedBox(
          width: width,
          height: 54,
          child: GameRoundStars(
            levelNumber: 1,
            currentRound: currentRound,
            completedRounds: completedRounds,
            animate: animate,
          ),
        ),
      ),
    ),
  ),
);

Finder star(int index) => find.byKey(ValueKey('game-round-star-$index'));

List<double> motion(WidgetTester tester, String key) => List.of(
  tester.widget<Transform>(find.byKey(ValueKey(key))).transform.storage,
);

void main() {
  testWidgets(
    'round progress shrinks other stars while preserving the current star size',
    (tester) async {
      final semantics = tester.ensureSemantics();
      List<double>? positions;
      for (var current = 0; current < 3; current++) {
        await tester.pumpWidget(
          host(
            currentRound: current,
            completedRounds: {for (var i = 0; i < current; i++) i},
            animate: false,
          ),
        );
        expect(find.byType(MapIcon), findsNWidgets(3));
        for (var index = 0; index < 3; index++) {
          final icon = tester.widget<MapIcon>(star(index));
          expect(
            icon.glyph,
            index < current ? MapGlyph.goldStar : MapGlyph.emptyStar,
          );
          expect(icon.size, closeTo(index == current ? 39.6 : 30.6, .001));
        }
        final centers = [
          for (var i = 0; i < 3; i++) tester.getCenter(star(i)).dx,
        ];
        positions ??= centers;
        expect(centers, positions);
        expect(
          find.bySemanticsLabel(
            'Nivel 1. Ronda ${current + 1} de 3. $current de 3 estrellas ganadas',
          ),
          findsOneWidget,
        );
      }
      await tester.pumpWidget(
        host(currentRound: 2, completedRounds: const {0}, animate: false),
      );
      expect(tester.widget<MapIcon>(star(1)).glyph, MapGlyph.emptyStar);
      semantics.dispose();
    },
  );

  testWidgets('only the current star sways and pausing returns it to rest', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pump();
    final initialRotation = motion(tester, 'game-current-star-sway');
    final initialOffset = motion(tester, 'game-current-star-float');
    final otherStars = [tester.getRect(star(1)), tester.getRect(star(2))];
    await tester.pump(const Duration(milliseconds: 600));
    expect(motion(tester, 'game-current-star-sway'), isNot(initialRotation));
    expect(motion(tester, 'game-current-star-float'), isNot(initialOffset));
    expect([tester.getRect(star(1)), tester.getRect(star(2))], otherStars);
    expect(tester.widget<MapIcon>(star(0)).size, closeTo(39.6, .001));

    await tester.pumpWidget(host(animate: false));
    expect(motion(tester, 'game-current-star-sway'), initialRotation);
    expect(motion(tester, 'game-current-star-float'), initialOffset);
    await tester.pump(const Duration(seconds: 3));
    expect(motion(tester, 'game-current-star-sway'), initialRotation);
  });

  testWidgets(
    'reduced motion and hidden routes stop the sway but keep the larger star',
    (tester) async {
      await tester.pumpWidget(host());
      await tester.pump();
      final neutral = motion(tester, 'game-current-star-sway');
      await tester.pump(const Duration(milliseconds: 600));
      expect(motion(tester, 'game-current-star-sway'), isNot(neutral));
      for (final scene in [
        host(reducedMotion: true),
        host(accessibleNavigation: true),
        host(tickerEnabled: false),
      ]) {
        await tester.pumpWidget(scene);
        await tester.pump(const Duration(seconds: 3));
        expect(motion(tester, 'game-current-star-sway'), neutral);
        expect(tester.widget<MapIcon>(star(0)).size, closeTo(39.6, .001));
      }
      await tester.pumpWidget(host());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(motion(tester, 'game-current-star-sway'), isNot(neutral));
    },
  );

  testWidgets('a completed current round turns gold and stops moving', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pump();
    final neutral = motion(tester, 'game-current-star-sway');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpWidget(host(completedRounds: const {0}));
    expect(tester.widget<MapIcon>(star(0)).glyph, MapGlyph.goldStar);
    await tester.pump(const Duration(seconds: 3));
    expect(motion(tester, 'game-current-star-sway'), neutral);
  });

  testWidgets(
    'three stars fit a small phone header without clipping or changing the scale ratio',
    (tester) async {
      await tester.pumpWidget(host(width: 86, currentRound: 1, animate: false));
      final row = tester.getRect(
        find.byKey(const ValueKey('game-round-stars')),
      );
      expect(row.width, closeTo(86, .001));
      final regular = tester.widget<MapIcon>(star(0)).size;
      expect(
        tester.widget<MapIcon>(star(1)).size,
        closeTo(regular * 1.1 / .85, .001),
      );
      expect(tester.widget<MapIcon>(star(1)).size, closeTo(20, .001));
      for (var index = 0; index < 3; index++) {
        final rect = tester.getRect(star(index));
        expect(rect.left, greaterThanOrEqualTo(row.left));
        expect(rect.right, lessThanOrEqualTo(row.right));
      }
      expect(tester.takeException(), isNull);
    },
  );
}
