import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/level_progress.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/widgets/map_level_button.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/domain/models/game_session.dart';
import 'package:sundoku/widgets/sudoku_board.dart';
import 'package:sundoku/widgets/tutorial_journey.dart';
import 'package:sundoku/widgets/sudoku_time_summary.dart';
import 'package:sundoku/widgets/game_pause.dart';
import 'package:sundoku/widgets/score_feedback.dart';

import 'tutorial_journey_widget_test.dart' as scene;

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Baloo2',
    )..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'))).load();
  });

  testWidgets(
    'a saved correct move updates score and launches the board popup',
    (tester) async {
      scene.configure(tester, reduced: false);
      final repo = GameRepository.memory();
      await repo.recordDebugLights(mapLevelId(1), 3);
      await repo.startGeneratedLevel(2);
      await scene.show(tester, repo, levelNumber: 2);
      await scene.settle(tester);
      final flow = tester
          .widget<TutorialJourney>(find.byType(TutorialJourney))
          .flow;
      final target = flow.boardValues.indexOf(null);
      flow.selectGameCell(target);
      await flow.placeGameNumber(flow.puzzleDefinition!.solution[target]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('11 pts'), findsOneWidget);
      expect(find.text('+11'), findsOneWidget);
      final livesX = tester
          .getCenter(find.byKey(const ValueKey('game-unlimited-lives')))
          .dx;
      final scoreX = tester
          .getCenter(find.byKey(const ValueKey('game-score')))
          .dx;
      final timeX = tester
          .getCenter(find.byKey(const ValueKey('game-timer')))
          .dx;
      expect(scoreX, greaterThan(livesX));
      expect(scoreX, lessThan(timeX));
      await scene.capture(
        tester,
        'game-scoring-popup',
        settleAnimations: false,
      );
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('+11'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await scene.settle(tester);
      await repo.close();
    },
  );

  for (final desktop in [true, false]) {
    testWidgets(
      'generated game pause, resize, exit and restore desktop=$desktop',
      (tester) async {
        scene.configure(tester);
        debugDefaultTargetPlatformOverride = desktop
            ? TargetPlatform.macOS
            : TargetPlatform.android;
        try {
          tester.view.physicalSize = desktop
              ? const Size(1024, 768)
              : const Size(390, 844);
          final repo = GameRepository.memory();
          await repo.recordDebugLights(mapLevelId(1), 3);
          final session = await repo.startGeneratedLevel(2);
          await scene.show(tester, repo, levelNumber: 2, withParentRoute: true);
          await scene.tap(tester, find.text('Abrir tutorial'));
          expect(find.text('Ronda 1 de 3'), findsOneWidget);
          expect(find.byKey(const ValueKey('game-timer')), findsOneWidget);
          expect(
            find.byKey(const ValueKey('game-unlimited-lives')),
            findsOneWidget,
          );
          expect(find.byKey(const ValueKey('game-resume')), findsNothing);
          final flow = tester
              .widget<TutorialJourney>(find.byType(TutorialJourney))
              .flow;
          final cell = flow.boardValues.indexOf(null);
          await scene.tap(tester, find.byKey(ValueKey('sudoku-cell-$cell')));
          final number = flow.puzzleDefinition!.solution[cell];
          await scene.tap(tester, find.byKey(ValueKey('intro-number-$number')));
          expect(flow.boardValues[cell], number);
          await scene.capture(
            tester,
            desktop ? 'level-2-desktop' : 'level-2-mobile',
          );
          await scene.tap(tester, find.byKey(const ValueKey('game-pause')));
          expect(find.text('En pausa'), findsOneWidget);
          expect(
            tester
                .widget<ImageFiltered>(
                  find.byKey(const ValueKey('game-board-blur')),
                )
                .enabled,
            true,
          );
          expect(flow.readyToPlay, false);
          final elapsed = flow.elapsedMs;
          await tester.pump(const Duration(seconds: 10));
          expect(flow.elapsedMs, elapsed);
          final state = tester.state(scene.board);
          for (final size in [
            const Size(960, 720),
            const Size(390, 844),
            const Size(844, 390),
          ]) {
            tester.view.physicalSize = size;
            await scene.settle(tester);
            expect(tester.state(scene.board), same(state));
            expect(tester.widget<SudokuBoard>(scene.board).selectedIndex, cell);
            expect(tester.takeException(), isNull);
          }
          tester.view.physicalSize = desktop
              ? const Size(1024, 768)
              : const Size(390, 844);
          await scene.settle(tester);
          await scene.capture(
            tester,
            desktop ? 'level-2-paused-desktop' : 'level-2-paused-mobile',
          );
          await scene.tap(tester, find.byKey(const ValueKey('game-resume')));
          expect(flow.readyToPlay, true);
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          await scene.settle(tester);
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await scene.settle(tester);
          expect(flow.isPaused, true);
          await scene.tap(tester, find.byKey(const ValueKey('game-back')));
          expect(find.text('Abrir tutorial'), findsOneWidget);
          expect(repo.state.sessions[session.id]!.status, PlayStatus.paused);
          await scene.tap(tester, find.text('Abrir tutorial'));
          final restored = tester
              .widget<TutorialJourney>(find.byType(TutorialJourney))
              .flow;
          expect(restored.isPaused, true);
          expect(restored.boardValues[cell], number);
          expect(restored.gameCell, cell);
          await tester.pumpWidget(const SizedBox());
          await scene.settle(tester);
          await repo.close();
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  }

  testWidgets('pause remains usable with enlarged text in a small window', (
    tester,
  ) async {
    scene.configure(tester);
    tester.view.physicalSize = const Size(360, 640);
    final repo = GameRepository.memory();
    await repo.recordDebugLights(mapLevelId(1), 3);
    await repo.startGeneratedLevel(2);
    await scene.show(tester, repo, levelNumber: 2, textScale: 2);
    await scene.settle(tester);
    await scene.tap(tester, find.byKey(const ValueKey('game-pause')));
    expect(tester.takeException(), isNull);
    await scene.tap(tester, find.byKey(const ValueKey('game-resume')));
    expect(find.text('En pausa'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await scene.settle(tester);
    await repo.close();
  });

  testWidgets(
    'map opens an unfinished generated level but never a completed or locked one',
    (tester) async {
      scene.configure(tester);
      final repo = GameRepository.memory();
      await repo.recordDebugLights(mapLevelId(1), 3);
      await repo.recordDebugLights(mapLevelId(2), 3);
      final progress = LevelProgress(repository: repo);
      final opened = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: MapScreen(
            progress: progress,
            showDeveloperControls: false,
            onOpenLevel: (number) async {
              opened.add(number);
            },
          ),
        ),
      );
      await scene.settle(tester);
      for (final level in [2, 4, 3]) {
        tester
            .widgetList<MapLevelButton>(find.byType(MapLevelButton))
            .singleWhere((button) => button.level == level)
            .onTap();
        await scene.settle(tester);
      }
      expect(opened, [3]);
      await tester.pumpWidget(const SizedBox());
      await scene.settle(tester);
      progress.dispose();
      await repo.close();
    },
  );

  testWidgets(
    'three wins keep existing transitions and show the total summary',
    (tester) async {
      scene.configure(tester, reduced: false);
      tester.view.physicalSize = const Size(1024, 768);
      final repo = GameRepository.memory();
      await repo.recordDebugLights(mapLevelId(1), 3);
      final session = await repo.startGeneratedLevel(2);
      await scene.show(
        tester,
        repo,
        levelNumber: 2,
        showDeveloperControls: true,
      );
      await scene.settle(tester);
      final flow = tester
          .widget<TutorialJourney>(find.byType(TutorialJourney))
          .flow;
      for (var index = 0; index < 3; index++) {
        await flow.debugFillExceptOne();
        await scene.settle(tester);
        await repo.addElapsed(session.id, flow.puzzleDefinition!.id, 60000);
        final target = flow.boardValues.indexOf(null);
        flow.selectGameCell(target);
        await flow.placeGameNumber(flow.puzzleDefinition!.solution[target]);
        for (var frame = 0; frame < 50; frame++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull);
        if (index < 2) {
          await scene.tap(
            tester,
            find.text(index == 0 ? 'Vamos al segundo' : 'Vamos al tercero'),
          );
          await scene.settle(tester);
          expect(flow.gameIndex, index + 1);
          expect(flow.readyToPlay, true);
          expect(find.text('En pausa'), findsNothing);
        }
      }
      expect(find.text('¡Completaste el nivel 2!'), findsOneWidget);
      expect(flow.step, FirstExperienceStep.complete);
      expect(repo.state.isUnlocked(mapLevelId(3)), true);
      expect(find.byType(SudokuTimeSummary), findsOneWidget);
      for (var index = 0; index < 3; index++) {
        expect(
          tester
              .widget<Text>(
                find.byKey(ValueKey('summary-sudoku-${index + 1}-time')),
              )
              .data,
          formatPlayTime(flow.session!.puzzles[index].elapsedMs),
        );
      }
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('summary-total-time')))
            .data,
        formatPlayTime(flow.session!.elapsedMs),
      );
      expect(find.text('El nivel 3 ya está abierto.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
      await scene.capture(tester, 'level-2-summary');
      tester.view.physicalSize = const Size(390, 844);
      await scene.settle(tester);
      await tester.ensureVisible(find.byType(SudokuTimeSummary));
      await scene.capture(tester, 'level-2-summary-mobile');
      expect(find.text('Mapa!').hitTestable(), findsOneWidget);
      expect(find.text('Siguiente nivel 3').hitTestable(), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('summary-total-points')))
            .data,
        formatScore(flow.session!.points),
      );
      for (final size in [
        const Size(360, 640),
        const Size(844, 390),
        const Size(320, 568),
      ]) {
        tester.view.physicalSize = size;
        await scene.settle(tester);
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(find.byKey(const ValueKey('reward-doku-fade')), findsNothing);
        expect(find.text('Mapa!').hitTestable(), findsOneWidget);
        expect(find.text('Siguiente nivel 3').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      tester.view.physicalSize = const Size(360, 640);
      await scene.show(tester, repo, levelNumber: 2, textScale: 2);
      await scene.settle(tester);
      expect(find.text('Siguiente nivel 3').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await scene.capture(tester, 'summary-small-large-text');
      await scene.tap(tester, find.text('Siguiente nivel 3'));
      expect(find.text('Ronda 1 de 3'), findsOneWidget);
      expect(
        tester
            .widget<TutorialJourney>(find.byType(TutorialJourney))
            .flow
            .levelNumber,
        3,
      );
      expect(
        tester
            .widget<TutorialJourney>(find.byType(TutorialJourney))
            .flow
            .readyToPlay,
        true,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await scene.settle(tester);
      await repo.close();
    },
  );
}
