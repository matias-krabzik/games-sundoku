import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/app.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/routes.dart';
import 'package:sundoku/screens/first_experience_screen.dart';
import 'package:sundoku/screens/home_screen.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/screens/quick_play_screen.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/quick_play_unlock_cue.dart';
import 'package:sundoku/widgets/tutorial_journey.dart';
import 'package:sundoku/widgets/world_journey_route.dart';

import 'tutorial_journey_widget_test.dart' as scene;

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Baloo2',
    )..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'))).load();
  });

  for (final returnToMap in [false, true]) {
    testWidgets(
      'finishing world one discovers quick play once, via map: $returnToMap',
      (tester) async {
        scene.configure(tester);
        final repo = GameRepository.memory();
        await repo.completeDebugWorldExceptLastPuzzle();
        await tester.pumpWidget(
          RepaintBoundary(
            key: scene.captureKey,
            child: SunDokuApp(repository: repo, feedback: const GameFeedback()),
          ),
        );
        await tester.pump(const Duration(seconds: 3));
        await scene.settle(tester);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byKey(const ValueKey('home-quick-play')), findsNothing);
        await scene.tap(tester, find.byKey(const ValueKey('home-play')));
        final navigator = Navigator.of(tester.element(find.byType(MapScreen)));
        unawaited(
          navigator.push(
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: AppRoutes.game),
              builder: (_) =>
                  FirstExperienceScreen(repository: repo, levelNumber: 10),
            ),
          ),
        );
        await scene.settle(tester);
        final flow = tester
            .widget<TutorialJourney>(find.byType(TutorialJourney))
            .flow;
        expect(flow.gameIndex, 2);
        await flow.resumeGame();
        await flow.debugFillExceptOne();
        final last = flow.boardValues.indexOf(null);
        expect(last, greaterThanOrEqualTo(0));
        flow.selectGameCell(last);
        await flow.placeGameNumber(flow.puzzleDefinition!.solution[last]);
        await scene.settle(tester);
        expect(repo.quickPlayUnlocked, isTrue);
        expect(
          repo.shouldCelebrateQuickPlay,
          isTrue,
          reason: 'Home is still covered',
        );
        await scene.waitForAction(tester, scene.next);
        await scene.tap(tester, scene.next);
        expect(
          find.byKey(const ValueKey('world-completion-recap')),
          findsOneWidget,
        );
        await scene.tap(
          tester,
          find.byKey(
            ValueKey(returnToMap ? 'world-recap-map' : 'world-recap-done'),
          ),
        );
        if (returnToMap) {
          expect(find.byType(MapScreen), findsOneWidget);
          expect(find.byType(FirstExperienceScreen), findsNothing);
          expect(repo.shouldCelebrateQuickPlay, isTrue);
          Navigator.of(tester.element(find.byType(MapScreen))).pop();
          await scene.settle(tester);
        }
        await repo.flush();
        await scene.settle(tester);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(MapScreen, skipOffstage: false), findsNothing);
        expect(
          Navigator.of(tester.element(find.byType(HomeScreen))).canPop(),
          isFalse,
        );
        expect(find.text('¡Nuevo!'), findsOneWidget);
        expect(
          find.text('¡Elige la dificultad y sigue jugando!'),
          findsNothing,
        );
        expect(repo.shouldCelebrateQuickPlay, isFalse);
        expect(repo.quickPlayIsNew, isTrue);
        await scene.capture(tester, 'home-quick-play-unlocked');
        final quick = find.byKey(const ValueKey('home-quick-play'));
        final adventure = find.byKey(const ValueKey('home-play'));
        expect(
          tester.getBottomLeft(quick).dy,
          lessThan(tester.getTopLeft(adventure).dy),
        );
        await scene.tap(tester, quick);
        expect(find.byType(QuickPlayScreen), findsOneWidget);
        expect(repo.quickPlayIsNew, isFalse);
        Navigator.of(tester.element(find.byType(QuickPlayScreen))).pop();
        await scene.settle(tester);
        expect(find.text('¡Nuevo!'), findsNothing);
        expect(
          find.byKey(const ValueKey('home-quick-play-hint')),
          findsNothing,
        );
        expect(
          tester.getBottomLeft(quick).dy,
          lessThan(tester.getTopLeft(adventure).dy),
        );
        await tester.pumpWidget(const SizedBox());
        await scene.settle(tester);
        await repo.close();
      },
    );
  }

  testWidgets(
    'unlock pulse waits for arrival, runs once and respects reduced motion',
    (tester) async {
      scene.configure(tester, reduced: false);
      var celebrations = 0;
      Widget cue({bool celebrate = true}) => Scaffold(
        body: Center(
          child: QuickPlayUnlockCue(
            isNew: true,
            celebrate: celebrate,
            onCelebrated: () => celebrations++,
            child: const SizedBox(width: 220, height: 70),
          ),
        ),
      );
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(navigator.push(WorldJourneyRoute(builder: (_) => cue())));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      expect(celebrations, 0);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(celebrations, 1);
      final pulse = find.byKey(const ValueKey('home-quick-play-pulse'));
      expect(
        tester.widget<Transform>(pulse).transform.storage[0],
        greaterThan(1),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(tester.widget<Transform>(pulse).transform.storage[0], 1);
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const Scaffold()),
        ),
      );
      await scene.settle(tester);
      navigator.pop();
      await scene.settle(tester);
      expect(celebrations, 1);
      expect(tester.widget<Transform>(pulse).transform.storage[0], 1);

      await tester.pumpWidget(const SizedBox());
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      await tester.pumpWidget(MaterialApp(home: cue()));
      await scene.settle(tester);
      expect(celebrations, 2);
      expect(tester.widget<Transform>(pulse).transform.storage[0], 1);
      expect(find.text('¡Nuevo!'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await scene.settle(tester);
    },
  );

  testWidgets(
    'new quick play stays above adventure at every size and text scale',
    (tester) async {
      scene.configure(tester);
      for (final scale in [1.0, 2.0]) {
        for (final size in [
          const Size(320, 568),
          const Size(390, 844),
          const Size(844, 390),
          const Size(834, 1194),
          const Size(1194, 834),
        ]) {
          tester.view.physicalSize = size;
          await tester.pumpWidget(
            RepaintBoundary(
              key: scene.captureKey,
              child: MaterialApp(
                theme: buildSunDokuTheme(),
                debugShowCheckedModeBanner: false,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: const HomeScreen(
                  hasStarted: true,
                  availableLevel: 10,
                  unlockedLevels: 10,
                  quickPlayUnlocked: true,
                  quickPlayIsNew: true,
                ),
              ),
            ),
          );
          await scene.settle(tester);
          final quick = find.byKey(const ValueKey('home-quick-play'));
          final adventure = find.byKey(const ValueKey('home-play'));
          expect(
            tester.getBottomLeft(quick).dy,
            lessThan(tester.getTopLeft(adventure).dy),
          );
          if (scale == 1) {
            await scene.capture(tester, 'home-unlock-${size.width.toInt()}');
          }
          for (final finder in [quick, adventure]) {
            await tester.ensureVisible(finder);
            await scene.settle(tester);
            expect(finder.hitTestable(), findsOneWidget);
          }
          expect(
            find.byKey(const ValueKey('home-settings')).hitTestable(),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull, reason: '$size, scale $scale');
        }
      }
      await tester.pumpWidget(const SizedBox());
      await scene.settle(tester);
    },
  );
}
