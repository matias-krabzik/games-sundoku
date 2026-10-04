import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/domain/models/game_save.dart';
import 'package:sundoku/domain/tutorial/challenge_lesson.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/screens/first_experience_screen.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/completed_level_popover.dart';
import 'package:sundoku/widgets/game_feedback_scope.dart';
import 'package:sundoku/widgets/gameplay_status_bar.dart';
import 'package:sundoku/widgets/challenge_lives.dart';
import 'package:sundoku/widgets/sudoku_board.dart';
import 'package:sundoku/widgets/sudoku_help.dart';
import 'package:sundoku/widgets/tutorial_journey.dart';
import 'package:sundoku/widgets/victory_particles.dart';

import 'support/challenge_repository.dart';
import 'tutorial_journey_widget_test.dart' as scene;

Future<void> showChallenge(
  WidgetTester tester,
  GameRepository repo, {
  int level = 1,
  double scale = 1,
}) async {
  if (!repo.challengeTutorialCompleted) {
    await repo.saveModule(ChallengeLesson.key, {
      'version': 1,
      'completed': true,
      'step': 3,
    });
  }
  await tester.pumpWidget(
    RepaintBoundary(
      key: scene.captureKey,
      child: GameFeedbackHost(
        output: const GameFeedback(),
        repository: repo,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildSunDokuTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: FirstExperienceScreen(
            repository: repo,
            worldId: 'world-3',
            levelNumber: level,
            showDeveloperControls: false,
          ),
        ),
      ),
    ),
  );
}

FirstExperienceController flowOf(WidgetTester tester) =>
    tester.widget<TutorialJourney>(find.byType(TutorialJourney)).flow;
Future<void> solveCurrent(GameRepository repo, String session) async {
  final saved = repo.state.sessions[session]!;
  final id = saved.nextPuzzleId!;
  final puzzle = repo.state.puzzles[id]!;
  for (var i = 0; i < puzzle.initial.length; i++) {
    if (puzzle.initial[i] == null) {
      await repo.setCell(session, id, i, puzzle.solution[i]);
    }
  }
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Baloo2',
    )..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'))).load();
  });

  for (final view in {
    'phone': const Size(390, 844),
    'ipad': const Size(834, 1210),
    'ipad-landscape': const Size(1210, 834),
    'desktop': const Size(1440, 900),
  }.entries) {
    testWidgets(
      '${view.key}: conditions, HUD, life loss, timeout, retry and win',
      (tester) async {
        scene.configure(tester);
        tester.view.physicalSize = view.value;
        final repo = await challengeRepository(MemorySaveStore());
        final preview = repo.previewChallenge(1, worldId: 'world-3')!;
        final session = await repo.startGeneratedLevel(1, worldId: 'world-3');
        expect(session.puzzles.first.attempt!.rules.toJson(), preview.toJson());
        await showChallenge(tester, repo);
        await scene.settle(tester);
        expect(find.byKey(const ValueKey('challenge-ready')), findsOneWidget);
        expect(flowOf(tester).readyToPlay, false);
        await scene.capture(tester, '${view.key}-ready');
        await scene.tap(
          tester,
          find.byKey(const ValueKey('challenge-primary')),
        );
        final flow = flowOf(tester);
        final state = tester.state(scene.board);
        final hud = tester.widget<GameplayStatusBar>(
          find.byType(GameplayStatusBar),
        );
        expect(hud.remainingLives, 3);
        expect(
          tester.widget<ChallengeLives>(find.byType(ChallengeLives)).total,
          3,
        );
        expect(find.text('3/3'), findsNothing);
        for (var heart = 0; heart < 3; heart++) {
          expect(
            tester
                .widget<Opacity>(find.byKey(ValueKey('challenge-heart-$heart')))
                .opacity,
            1,
          );
        }
        expect(hud.targetPoints, preview.targetPoints);
        expect(
          find.byKey(const ValueKey('game-unlimited-lives')),
          findsNothing,
        );
        await scene.capture(tester, '${view.key}-playing');
        final index = flow.boardValues.indexOf(null);
        flow.selectGameCell(index);
        await flow.placeGameNumber(
          flow.puzzleDefinition!.solution[index] % 9 + 1,
        );
        await scene.settle(tester);
        expect(
          tester
              .widget<GameplayStatusBar>(find.byType(GameplayStatusBar))
              .remainingLives,
          2,
        );
        expect(
          tester
              .widget<Opacity>(find.byKey(const ValueKey('challenge-heart-2')))
              .opacity,
          .22,
        );
        expect(
          tester
              .widget<Opacity>(find.byKey(const ValueKey('challenge-heart-1')))
              .opacity,
          1,
        );
        await scene.capture(tester, '${view.key}-life-lost');
        expect(tester.state(scene.board), same(state));
        expect(find.byKey(const ValueKey('challenge-result')), findsNothing);
        await flow.pauseGame();
        await repo.addElapsed(
          session.id,
          flow.puzzleProgress!.puzzleId,
          preview.timeLimitMs,
        );
        await scene.settle(tester);
        expect(find.text('Se acabó el tiempo'), findsOneWidget);
        expect(find.byType(VictoryParticles), findsNothing);
        expect(flow.readyToPlay, false);
        await scene.capture(tester, '${view.key}-timeout');
        final previousPuzzle = flow.puzzleDefinition!;
        await scene.tap(
          tester,
          find.byKey(const ValueKey('challenge-primary')),
        );
        expect(flow.puzzleDefinition!.initial, isNot(previousPuzzle.initial));
        expect(flow.puzzleDefinition!.solution, isNot(previousPuzzle.solution));
        expect(
          tester.widget<SudokuBoard>(scene.board).cells,
          flow.puzzleDefinition!.initial,
        );
        expect(flow.puzzleProgress!.attempt!.number, 2);
        expect(flow.puzzleProgress!.mistakes, 0);
        expect(flow.readyToPlay, true);
        await flow.pauseGame();
        await solveCurrent(repo, session.id);
        await scene.settle(tester);
        expect(find.text('¡Estrella conseguida!'), findsOneWidget);
        expect(repo.state.sessions[session.id]!.lights, 1);
        await scene.capture(tester, '${view.key}-won');
        await scene.tap(
          tester,
          find.byKey(const ValueKey('challenge-primary')),
        );
        expect(flow.gameIndex, 1);
        expect(flow.readyToPlay, true);
        expect(
          tester
              .widget<GameplayStatusBar>(find.byType(GameplayStatusBar))
              .remainingLives,
          3,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await scene.settle(tester);
        await repo.close();
      },
    );
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'challenge layout and panel actions fit resized windows at text $scale',
      (tester) async {
        scene.configure(tester);
        final repo = await challengeRepository(MemorySaveStore(), level: 30);
        await repo.startGeneratedLevel(30, worldId: 'world-3');
        await showChallenge(tester, repo, level: 30, scale: scale);
        await scene.settle(tester);
        expect(find.text('Sin errores ni pistas'), findsOneWidget);
        await scene.tap(
          tester,
          find.byKey(const ValueKey('challenge-primary')),
        );
        final flow = flowOf(tester);
        final state = tester.state(scene.board);
        final index = flow.boardValues.indexOf(null);
        flow.selectGameCell(index);
        await flow.flush();
        await scene.settle(tester);
        final help = tester.widget<SudokuHelpButton>(
          find.byType(SudokuHelpButton),
        );
        expect(help.onPressed, isNull);
        expect(help.disabledReason, 'Este desafío es sin pistas');
        expect(flow.notesAvailable, true);
        for (final size in [
          const Size(320, 568),
          const Size(390, 844),
          const Size(430, 932),
          const Size(568, 320),
          const Size(844, 390),
          const Size(768, 1024),
          const Size(1024, 1366),
          const Size(699, 900),
          const Size(700, 900),
          const Size(1024, 600),
          const Size(1920, 1080),
          const Size(700, 599),
          const Size(700, 600),
          const Size(834, 1210),
          const Size(1210, 834),
          const Size(1440, 900),
        ]) {
          tester.view.physicalSize = size;
          await scene.settle(tester);
          expect(tester.takeException(), isNull, reason: '$size');
          expect(tester.state(scene.board), same(state));
          final board = tester.getRect(scene.board);
          final number = tester.getRect(
            find.byKey(const ValueKey('intro-number-1')),
          );
          expect(number.top, greaterThan(board.bottom));
          expect(
            board.width,
            lessThanOrEqualTo(
              size.width >= 700 && size.height >= 600 ? 540 : 430,
            ),
          );
          expect(number.width, lessThanOrEqualTo(54));
          expect(find.byKey(const ValueKey('intro-scroll')), findsNothing);
        }
        await flow.placeGameNumber(
          flow.puzzleDefinition!.solution[index] % 9 + 1,
        );
        await scene.settle(tester);
        expect(find.text('Te quedaste sin vidas'), findsOneWidget);
        expect(find.byType(VictoryParticles), findsNothing);
        for (final size in [
          const Size(320, 568),
          const Size(568, 320),
          const Size(834, 1210),
        ]) {
          tester.view.physicalSize = size;
          await scene.settle(tester);
          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const ValueKey('challenge-primary')).hitTestable(),
            findsOneWidget,
          );
        }
        await tester.pumpWidget(const SizedBox());
        await scene.settle(tester);
        await repo.close();
      },
    );
  }

  for (final size in [
    const Size(390, 844),
    const Size(834, 1210),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'normal motion: last move, pause, restored failure and retry at $size',
      (tester) async {
        scene.configure(tester, reduced: false);
        tester.view.physicalSize = size;
        final store = MemorySaveStore();
        var repo = await challengeRepository(store);
        final session = await repo.startGeneratedLevel(1, worldId: 'world-3');
        final puzzle = repo.state.puzzles[session.nextPuzzleId]!;
        final empty = [
          for (var i = 0; i < 81; i++)
            if (!puzzle.isFixed(i)) i,
        ];
        // Real repository moves, leaving the terminal move for the screen controller.
        for (final i in empty.take(empty.length - 1)) {
          await repo.setCell(session.id, puzzle.id, i, puzzle.solution[i]);
        }
        await showChallenge(tester, repo);
        await scene.settle(tester);
        await scene.tap(
          tester,
          find.byKey(const ValueKey('challenge-primary')),
        );
        var flow = flowOf(tester);
        await scene.tap(tester, find.byKey(const ValueKey('game-pause')));
        final remaining = flow.displayTimeMs;
        await tester.pump(const Duration(seconds: 10));
        expect(flow.displayTimeMs, remaining);
        expect(flow.readyToPlay, false);
        await scene.tap(tester, find.byKey(const ValueKey('game-pause')));
        flow.selectGameCell(empty.last);
        await flow.placeGameNumber(puzzle.solution[empty.last]);
        await scene.settle(tester);
        expect(find.text('¡Estrella conseguida!'), findsOneWidget);
        expect(find.byType(VictoryParticles), findsNothing);
        await scene.tap(
          tester,
          find.byKey(const ValueKey('challenge-primary')),
        );
        expect(flow.gameIndex, 1);
        await flow.pauseGame();
        await repo.addElapsed(
          session.id,
          flow.puzzleDefinition!.id,
          flow.challengeRules!.timeLimitMs,
        );
        await scene.settle(tester);
        final attempt = flow.puzzleProgress!.attempt!.id;
        final cells = flow.boardValues;
        flow.selectGameCell(0);
        await flow.placeGameNumber(1);
        expect(flow.boardValues, cells);
        await tester.pumpWidget(const SizedBox());
        await scene.settle(tester);
        await repo.close();
        repo = await GameRepository.open(store, enableWorld3Challenges: true);
        await repo.startGeneratedLevel(1, worldId: 'world-3');
        await showChallenge(tester, repo);
        await scene.settle(tester);
        flow = flowOf(tester);
        expect(flow.puzzleProgress!.attempt!.id, attempt);
        expect(flow.gameIndex, 1);
        expect(flow.session!.lights, 1);
        expect(find.text('Se acabó el tiempo'), findsOneWidget);
        await scene.tap(
          tester,
          find.byKey(const ValueKey('challenge-primary')),
        );
        expect(flow.readyToPlay, true);
        expect(flow.session!.lights, 1);
        expect(flow.puzzleProgress!.attempt!.number, 2);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await scene.settle(tester);
        await repo.close();
      },
    );
  }

  testWidgets(
    'third star has its own result; reopen preserves it; acknowledge leads to existing final summary',
    (tester) async {
      scene.configure(tester);
      final repo = await challengeRepository(MemorySaveStore(), level: 30);
      final session = await repo.startGeneratedLevel(30, worldId: 'world-3');
      await showChallenge(tester, repo, level: 30);
      await scene.settle(tester);
      await scene.tap(tester, find.byKey(const ValueKey('challenge-primary')));
      for (var i = 0; i < 3; i++) {
        await flowOf(tester).pauseGame();
        await solveCurrent(repo, session.id);
        await scene.settle(tester);
        expect(find.byKey(const ValueKey('challenge-result')), findsOneWidget);
        expect(flowOf(tester).step, FirstExperienceStep.challengeResult);
        if (i < 2) {
          await scene.tap(
            tester,
            find.byKey(const ValueKey('challenge-primary')),
          );
        }
      }
      await tester.pumpWidget(const SizedBox());
      await scene.settle(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LevelSummaryCard(
                level: 30,
                worldId: 'world-3',
                lights: 3,
                session: repo.state.sessions[session.id],
                record: LevelRecord(bestLights: 3),
                onContinue: () {},
                onOk: () {},
              ),
            ),
          ),
        ),
      );
      await scene.settle(tester);
      expect(find.text('RÍOS CRUZADOS'), findsOneWidget);
      expect(find.text('Ver resultado').hitTestable(), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await scene.settle(tester);
      final resumed = await repo.startGeneratedLevel(30, worldId: 'world-3');
      expect(resumed.id, session.id);
      await showChallenge(tester, repo, level: 30);
      await scene.settle(tester);
      expect(find.byKey(const ValueKey('challenge-result')), findsOneWidget);
      await scene.tap(tester, find.byKey(const ValueKey('challenge-primary')));
      expect(flowOf(tester).step, FirstExperienceStep.complete);
      expect(find.text('¡Lo completaste todo!'), findsOneWidget);
      expect(find.textContaining('Siguiente nivel'), findsNothing);
      expect(repo.worldCompleted('world-3'), true);
      await expectLater(
        repo.startGeneratedLevel(30, worldId: 'world-3'),
        throwsStateError,
      );
      await tester.pumpWidget(const SizedBox());
      await scene.settle(tester);
      await repo.close();
    },
  );

  testWidgets(
    'map summary shows exact next-round conditions and score failure is retryable',
    (tester) async {
      scene.configure(tester);
      final repo = await challengeRepository(MemorySaveStore());
      final rules = repo.previewChallenge(1, worldId: 'world-3')!;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildSunDokuTheme(),
          home: Scaffold(
            body: SafeArea(
              child: LevelSummaryCard(
                level: 1,
                worldId: 'world-3',
                lights: 0,
                session: null,
                record: LevelRecord(),
                challenge: rules,
                onContinue: () {},
                onOk: () {},
              ),
            ),
          ),
        ),
      );
      await scene.settle(tester);
      expect(
        find.textContaining('Meta: ${rules.targetPoints} puntos'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('level-summary-play')).hitTestable(),
        findsOneWidget,
      );
      final session = await repo.startGeneratedLevel(1, worldId: 'world-3');
      final id = session.nextPuzzleId!;
      final puzzle = repo.state.puzzles[id]!;
      final empty = [
        for (var i = 0; i < 81; i++)
          if (!puzzle.isFixed(i)) i,
      ];
      for (final i in empty.take(empty.length - 1)) {
        await repo.setCell(session.id, id, i, puzzle.solution[i]);
      }
      await repo.useHint(session.id, id, empty.last);
      await showChallenge(tester, repo);
      await scene.settle(tester);
      expect(find.text('Faltaron algunos puntos'), findsOneWidget);
      expect(repo.state.sessions[session.id]!.lights, 0);
      expect(find.byType(VictoryParticles), findsNothing);
      await scene.tap(tester, find.byKey(const ValueKey('challenge-primary')));
      expect(flowOf(tester).readyToPlay, true);
      await tester.pumpWidget(const SizedBox());
      await scene.settle(tester);
      await repo.close();
    },
  );
}
