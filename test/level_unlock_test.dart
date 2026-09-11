import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/app.dart';
import 'package:sundoku/data/level_progress.dart';
import 'package:sundoku/screens/map_screen.dart';

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

void main() {
  testWidgets(
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

  testWidgets(
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
      await tester.tap(find.byTooltip('Nivel anterior'));
      await finishNavigation(tester);
      await tester.tap(find.byTooltip('Reiniciar nivel'));
      await tester.pump();
      expect(progress.lightsFor(1), 0);
      expect(progress.isUnlocked(2), isFalse);
    },
  );

  testWidgets('leaving during delivery cancels unearned score', (tester) async {
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

  testWidgets(
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
      await tester.tap(find.text('Jugar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Simular 3 puntos y abrir siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Nivel 2 de 10'), findsOneWidget);
      expect(find.text('0/3 puntos obtenidos'), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      expect(find.text('2 de 10'), findsOneWidget);
      await tester.tap(find.text('Jugar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Nivel siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('0/3 puntos obtenidos'), findsOneWidget);
    },
  );
}
