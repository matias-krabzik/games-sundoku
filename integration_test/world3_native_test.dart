import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/domain/scoring/adventure_challenge.dart';
import 'package:sundoku/domain/tutorial/challenge_lesson.dart';
import 'package:sundoku/screens/challenge_tutorial_screen.dart';
import 'package:sundoku/screens/first_experience_screen.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/challenge_lives.dart';
import 'package:sundoku/widgets/game_feedback_scope.dart';
import 'package:sundoku/widgets/sudoku_board.dart';
import 'package:sundoku/widgets/tutorial_journey.dart';
import 'package:sundoku/widgets/world_completion_recap.dart';

import '../test/support/challenge_repository.dart';
import '../test/support/world3_baseline.dart';

// Native QA entrypoint. It never opens the player's disk or Playables store.
// Do not substitute tester.view.physicalSize: rotations must reach the platform.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final presentation = ValueNotifier((scale: 1.0, reduced: false));

  Future<void> frames(WidgetTester tester, [int milliseconds = 400]) async {
    for (var elapsed = 0; elapsed < milliseconds; elapsed += 50) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(tester.takeException(), isNull);
  }

  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
      await frames(tester, 100);
    }
    if (finder.evaluate().isEmpty) {
      await binding.takeScreenshot(
        'failure-${DateTime.now().millisecondsSinceEpoch}',
      );
    }
    expect(finder, findsOneWidget);
  }

  Finder keyed(String key) => find.byKey(ValueKey(key));

  Future<void> press(WidgetTester tester, String key) async {
    await waitFor(tester, keyed(key).hitTestable());
    await tester.tap(keyed(key));
    await frames(tester, 400);
  }

  Future<void> capture(WidgetTester tester, String name) async {
    await frames(tester);
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    final direction = size.width > size.height ? 'landscape' : 'portrait';
    debugPrint('W3 native: $name $size DPR ${tester.view.devicePixelRatio}');
    debugPrint(
      'W3 presentation: text=${presentation.value.scale}, reduced=${presentation.value.reduced}',
    );
    await binding.takeScreenshot('$name-$direction');
  }

  Future<void> rotate(WidgetTester tester, {required bool landscape}) async {
    await SystemChrome.setPreferredOrientations([
      landscape
          ? DeviceOrientation.landscapeLeft
          : DeviceOrientation.portraitUp,
    ]);
    for (var i = 0; i < 50; i++) {
      await frames(tester, 100);
      final size = tester.view.physicalSize;
      if ((size.width > size.height) == landscape) return;
    }
    fail(
      'The native window did not rotate; a synthetic viewport is not evidence.',
    );
  }

  Future<void> show(
    WidgetTester tester,
    GameRepository repo,
    Widget screen,
  ) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      GameFeedbackHost(
        repository: repo,
        output: const GameFeedback(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildSunDokuTheme(),
          builder: (context, child) => ValueListenableBuilder(
            valueListenable: presentation,
            child: child,
            builder: (context, value, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(value.scale),
                disableAnimations: value.reduced,
              ),
              child: child!,
            ),
          ),
          home: screen,
        ),
      ),
    );
    await frames(tester, 800);
  }

  Future<void> showGame(
    WidgetTester tester,
    GameRepository repo, {
    String world = 'world-3',
    int level = 1,
  }) => show(
    tester,
    repo,
    FirstExperienceScreen(
      repository: repo,
      worldId: world,
      levelNumber: level,
      showDeveloperControls: false,
    ),
  );

  FirstExperienceController flow(WidgetTester tester) =>
      tester.widget<TutorialJourney>(find.byType(TutorialJourney)).flow;

  Future<void> input(WidgetTester tester, int index, int number) async {
    await press(tester, 'sudoku-cell-$index');
    expect(
      flow(tester).gameCell,
      index,
      reason: 'Cell selection must finish before entering a number',
    );
    await press(tester, 'intro-number-$number');
    expect(flow(tester).boardValues[index], number);
  }

  Future<void> solve(WidgetTester tester) async {
    await frames(tester, 1200);
    final controller = flow(tester);
    expect(controller.readyToPlay, true);
    final solution = controller.puzzleDefinition!.solution;
    for (var i = 0; i < solution.length; i++) {
      if (controller.boardValues[i] != solution[i]) {
        await input(tester, i, solution[i]);
      }
    }
    await waitFor(tester, keyed('challenge-result'));
    expect(
      controller.puzzleProgress!.attempt!.result!.outcome,
      ChallengeOutcome.won,
    );
  }

  Future<void> nextRound(WidgetTester tester) async {
    if (find.text('Mostrar resultado').evaluate().isNotEmpty) {
      await press(tester, 'challenge-primary');
    }
    final previousRound = flow(tester).gameIndex;
    await press(tester, 'challenge-primary');
    await frames(tester, 1200);
    expect(flow(tester).gameIndex, previousRound + 1);
    expect(flow(tester).readyToPlay, true);
    expect(flow(tester).puzzleProgress!.mistakes, 0);
  }

  testWidgets('native artwork, real rotations, tutorial and accessibility', (
    tester,
  ) async {
    final repo = await challengeRepository(MemorySaveStore());
    await rotate(tester, landscape: false);
    for (final world in ['world-1', 'world-2']) {
      final legacyRepo = await openBaselineRepository(
        baselineSave(completedWorlds: world == 'world-1' ? 0 : 1),
      );
      await legacyRepo.recordDebugLights('$world/level-1', 3);
      await legacyRepo.saveModule('tutorials/notes/v1', {
        'step': 7,
        'completed': true,
      });
      await legacyRepo.startGeneratedLevel(2, worldId: world);
      await showGame(tester, legacyRepo, world: world, level: 2);
      await waitFor(tester, find.byType(SudokuBoard));
      await capture(tester, '$world-game');
      final board = tester.state(find.byType(SudokuBoard));
      await rotate(tester, landscape: true);
      expect(tester.state(find.byType(SudokuBoard)), same(board));
      await capture(tester, '$world-game');
      await rotate(tester, landscape: false);
      await tester.pumpWidget(const SizedBox());
      await legacyRepo.close();
    }

    var completed = false;
    await show(
      tester,
      repo,
      ChallengeTutorialScreen(
        repository: repo,
        onFinished: () async {
          completed = true;
        },
      ),
    );
    final board = tester.state(keyed('challenge-lesson-board'));
    for (var step = 0; step < 4; step++) {
      expect(find.text(ChallengeLesson.titles[step]), findsOneWidget);
      expect(tester.state(keyed('challenge-lesson-board')), same(board));
      await press(tester, 'challenge-lesson-next');
      if (step == 0) {
        await capture(tester, 'tutorial');
        presentation.value = (scale: 2.0, reduced: true);
        await rotate(tester, landscape: true);
        expect(keyed('challenge-lesson-next').hitTestable(), findsOneWidget);
        expect(tester.state(keyed('challenge-lesson-board')), same(board));
        await capture(tester, 'tutorial-large-text');
        presentation.value = (scale: 1.0, reduced: false);
        await rotate(tester, landscape: false);
      }
      await press(tester, 'challenge-lesson-next');
    }
    expect(completed, true);
    expect(repo.challengeTutorialCompleted, true);
    await tester.pumpWidget(const SizedBox());
    await repo.close();
  });

  testWidgets('three stars through taps, failed retry and restored attempt', (
    tester,
  ) async {
    final store = MemorySaveStore();
    var repo = await challengeRepository(store);
    await repo.saveModule(ChallengeLesson.key, {
      'version': 1,
      'completed': true,
      'step': 3,
    });
    final session = await repo.startGeneratedLevel(1, worldId: 'world-3');
    await rotate(tester, landscape: false);
    await showGame(tester, repo);
    await capture(tester, 'world-3-ready');
    await press(tester, 'challenge-primary');
    expect(tester.widget<ChallengeLives>(find.byType(ChallengeLives)).total, 3);
    await capture(tester, 'world-3-game');
    final originalBoard = tester.state(find.byType(SudokuBoard));
    await rotate(tester, landscape: true);
    expect(tester.state(find.byType(SudokuBoard)), same(originalBoard));
    await capture(tester, 'world-3-game');
    await rotate(tester, landscape: false);

    await solve(tester);
    // Tear down before the counter finishes; award must already be persisted.
    await flow(tester).flush();
    await tester.pumpWidget(const SizedBox());
    await repo.close();
    repo = await GameRepository.open(
      store,
      enableWorld3Challenges: true,
      now: () => baselineDate,
    );
    expect(repo.state.sessions[session.id]!.lights, 1);
    await showGame(tester, repo);
    await waitFor(tester, keyed('challenge-result'));
    await capture(tester, 'world-3-restored-result');
    await nextRound(tester);
    final previousPuzzle = flow(tester).puzzleDefinition!;
    final empty = flow(tester).boardValues.indexOf(null);
    for (var offset = 1; offset <= 3; offset++) {
      await input(
        tester,
        empty,
        (previousPuzzle.solution[empty] + offset - 1) % 9 + 1,
      );
    }
    await waitFor(tester, keyed('challenge-result'));
    expect(
      flow(tester).puzzleProgress!.attempt!.result!.outcome,
      ChallengeOutcome.outOfLives,
    );
    expect(repo.state.sessions[session.id]!.lights, 1);
    await frames(tester, 3000);
    await capture(tester, 'world-3-no-lives');
    await press(tester, 'challenge-primary');
    if (keyed('challenge-ready').evaluate().isNotEmpty) {
      await press(tester, 'challenge-primary');
    }
    expect(
      flow(tester).puzzleDefinition!.initial,
      isNot(previousPuzzle.initial),
    );
    final retryIndex = flow(tester).boardValues.indexOf(null);
    await input(
      tester,
      retryIndex,
      flow(tester).puzzleDefinition!.solution[retryIndex],
    );
    await press(tester, 'game-pause');
    await flow(tester).flush();
    final saved = flow(tester).puzzleProgress!.toJson();
    final retryPuzzle = flow(tester).puzzleDefinition!.toJson();
    await tester.pumpWidget(const SizedBox());
    await repo.close();
    repo = await GameRepository.open(
      store,
      enableWorld3Challenges: true,
      now: () => baselineDate,
    );
    await showGame(tester, repo);
    expect(flow(tester).puzzleProgress!.toJson(), saved);
    expect(flow(tester).puzzleDefinition!.toJson(), retryPuzzle);
    await press(tester, 'game-resume');
    await solve(tester);
    await frames(tester, 3000);
    await capture(tester, 'world-3-star-two');
    await nextRound(tester);
    await solve(tester);
    await frames(tester, 3000);
    expect(repo.state.sessions[session.id]!.lights, 3);
    await capture(tester, 'world-3-star-three');
    await rotate(tester, landscape: true);
    presentation.value = (scale: 2.0, reduced: true);
    await frames(tester);
    expect(keyed('challenge-primary').hitTestable(), findsOneWidget);
    await capture(tester, 'world-3-result-large-text');
    presentation.value = (scale: 1.0, reduced: false);
    await tester.pumpWidget(const SizedBox());
    await repo.close();
  });

  testWidgets('last level mistake, perfect retry and final recap', (
    tester,
  ) async {
    final repo = await challengeRepository(MemorySaveStore(), level: 30);
    await repo.saveModule(ChallengeLesson.key, {
      'version': 1,
      'completed': true,
      'step': 3,
    });
    await repo.startGeneratedLevel(30, worldId: 'world-3');
    await rotate(tester, landscape: false);
    await showGame(tester, repo, level: 30);
    await press(tester, 'challenge-primary');
    expect(tester.widget<ChallengeLives>(find.byType(ChallengeLives)).total, 1);
    expect(flow(tester).challengeRules!.allowsHints, false);
    final index = flow(tester).boardValues.indexOf(null);
    await input(
      tester,
      index,
      flow(tester).puzzleDefinition!.solution[index] % 9 + 1,
    );
    await waitFor(tester, keyed('challenge-result'));
    expect(
      flow(tester).puzzleProgress!.attempt!.result!.outcome,
      ChallengeOutcome.outOfLives,
    );
    await frames(tester, 3000);
    await press(tester, 'challenge-primary');
    if (keyed('challenge-ready').evaluate().isNotEmpty) {
      await press(tester, 'challenge-primary');
    }
    await solve(tester);
    expect(flow(tester).puzzleProgress!.mistakes, 0);
    await frames(tester, 3000);
    await capture(tester, 'world-3-perfect-30');

    // The recap is opened explicitly for visual QA; this is not an E11 claim.
    final context = tester.element(find.byType(TutorialJourney));
    final destination = showWorldCompletionRecap(
      context,
      repo.state.player,
      worldId: 'world-3',
    );
    await frames(tester);
    await press(tester, 'world-recap-story');
    await capture(tester, 'world-3-recap');
    await rotate(tester, landscape: true);
    presentation.value = (scale: 2.0, reduced: true);
    await frames(tester);
    expect(keyed('world-recap-map').hitTestable(), findsOneWidget);
    expect(keyed('world-recap-done').hitTestable(), findsOneWidget);
    await capture(tester, 'world-3-recap-large-text');
    await press(tester, 'world-recap-map');
    expect(await destination, WorldCompletionDestination.map);
    await tester.pumpWidget(const SizedBox());
    await repo.close();
    presentation.value = (scale: 1.0, reduced: false);
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  });
}
