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
import 'package:sundoku/widgets/game_layout.dart';
import 'package:sundoku/widgets/score_feedback.dart';

import 'tutorial_journey_widget_test.dart' as scene;

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Baloo2',
    )..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'))).load();
  });

  for (final textScale in [1.0, 2.0]) {
    testWidgets(
      'device matrix respects safe areas and fits at text $textScale',
      (tester) async {
        scene.configure(tester);
        addTearDown(tester.view.resetPadding);
        final repo = GameRepository.memory();
        await repo.recordDebugLights(mapLevelId(1), 3);
        await repo.startGeneratedLevel(2);
        await scene.show(tester, repo, levelNumber: 2, textScale: textScale);
        await scene.settle(tester);
        final state = tester.state(scene.board);
        for (final size in [
          const Size(320, 568),
          const Size(360, 640),
          const Size(390, 844),
          const Size(430, 932),
          const Size(568, 320),
          const Size(640, 360),
          const Size(844, 390),
          const Size(932, 430),
          const Size(600, 960),
          const Size(699, 900),
          const Size(700, 900),
          const Size(768, 1024),
          const Size(834, 1210),
          const Size(1024, 1366),
          const Size(1210, 834),
          const Size(1366, 1024),
          const Size(700, 599),
          const Size(700, 600),
          const Size(1024, 600),
          const Size(1440, 900),
          const Size(1920, 1080),
        ]) {
          tester.view.physicalSize = size;
          final landscape = size.width > size.height;
          final padding = landscape
              ? const FakeViewPadding(left: 44, right: 20, bottom: 21)
              : const FakeViewPadding(top: 24, bottom: 20);
          tester.view.padding = padding;
          await scene.settle(tester);
          final safe = Rect.fromLTRB(
            padding.left,
            padding.top,
            size.width - padding.right,
            size.height - padding.bottom,
          );
          final board = tester.getRect(scene.board);
          final status = tester.getRect(
            find.byKey(const ValueKey('game-status-slot')),
          );
          expect(board.top - status.bottom, closeTo(12, .1));
          expect(tester.state(scene.board), same(state));
          expect(find.byKey(const ValueKey('intro-scroll')), findsNothing);
          expect(board.center.dx, closeTo(safe.center.dx, 1), reason: '$size');
          expect(
            board.left - safe.left,
            greaterThanOrEqualTo(safe.width * .08 - 1),
          );
          final first = tester.getRect(
            find.byKey(const ValueKey('intro-number-1')),
          );
          final ninth = tester.getRect(
            find.byKey(const ValueKey('intro-number-9')),
          );
          expect(first.top, greaterThan(board.bottom));
          expect(ninth.top, closeTo(first.top, .1));
          expect(first.width, lessThanOrEqualTo(54));
          for (final rect in [
            board,
            first,
            ninth,
            for (final key in [
              'intro-clear',
              'game-help',
              'game-back',
              'game-settings',
              'game-pause',
            ])
              tester.getRect(find.byKey(ValueKey(key))),
          ]) {
            expect(
              rect.left,
              greaterThanOrEqualTo(safe.left - 1),
              reason: '$size $rect',
            );
            expect(
              rect.right,
              lessThanOrEqualTo(safe.right + 1),
              reason: '$size $rect',
            );
            expect(
              rect.top,
              greaterThanOrEqualTo(safe.top - 1),
              reason: '$size $rect',
            );
            expect(
              rect.bottom,
              lessThanOrEqualTo(safe.bottom + 1),
              reason: '$size $rect',
            );
          }
          expect(tester.takeException(), isNull, reason: '$size');
        }
        await tester.pumpWidget(const SizedBox());
        await scene.settle(tester);
        await repo.close();
      },
    );
  }

  testWidgets('mobile board and number row fit without scrolling', (
    tester,
  ) async {
    scene.configure(tester);
    final repo = GameRepository.memory();
    await repo.recordDebugLights(mapLevelId(1), 3);
    await repo.startGeneratedLevel(2);
    await scene.show(tester, repo, levelNumber: 2);
    await scene.settle(tester);
    final board = find.byType(PausableGameBoard);
    final number = find.byKey(const ValueKey('intro-number-1'));
    final normalWidth = tester.getRect(board).width;
    for (final size in [
      const Size(390, 844),
      const Size(390, 568),
      const Size(320, 568),
    ]) {
      tester.view.physicalSize = size;
      await scene.settle(tester);
      final boardRect = tester.getRect(board);
      final firstNumber = tester.getRect(number);
      final lastNumber = tester.getRect(
        find.byKey(const ValueKey('intro-number-9')),
      );
      final erase = tester.getRect(find.byKey(const ValueKey('intro-clear')));
      final help = tester.getRect(find.byKey(const ValueKey('game-help')));
      expect(find.byKey(const ValueKey('intro-scroll')), findsNothing);
      expect(boardRect.width, lessThanOrEqualTo(430));
      expect(boardRect.left, greaterThanOrEqualTo(size.width * .08 - 1));
      expect(boardRect.right, lessThanOrEqualTo(size.width * .92 + 1));
      expect(firstNumber.top, greaterThan(boardRect.bottom));
      expect(lastNumber.top, closeTo(firstNumber.top, .1));
      for (final rect in [boardRect, firstNumber, lastNumber, erase, help]) {
        expect(rect.top, greaterThanOrEqualTo(-1));
        expect(rect.bottom, lessThanOrEqualTo(size.height + 1));
      }
      expect(number.hitTestable(), findsOneWidget);
    }
    expect(tester.getRect(board).width, lessThan(normalWidth));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await scene.settle(tester);
    await repo.close();
  });

  testWidgets('generated game fills iPad without scrolling or losing play', (
    tester,
  ) async {
    scene.configure(tester);
    tester.view.physicalSize = const Size(834, 1210);
    final repo = GameRepository.memory();
    await repo.recordDebugLights(mapLevelId(1), 3);
    await repo.startGeneratedLevel(2);
    await scene.show(tester, repo, levelNumber: 2);
    await scene.settle(tester);

    final flow = tester
        .widget<TutorialJourney>(find.byType(TutorialJourney))
        .flow;
    final cell = flow.boardValues.indexOf(null);
    await scene.tap(tester, find.byKey(ValueKey('sudoku-cell-$cell')));
    final originalBoardState = tester.state(scene.board);
    final originalValues = flow.boardValues;

    for (final size in [
      const Size(834, 1210),
      const Size(768, 1024),
      const Size(1210, 834),
      const Size(390, 844),
      const Size(834, 1210),
    ]) {
      tester.view.physicalSize = size;
      await scene.settle(tester);
      final board = tester.getRect(scene.board);
      final first = tester.getRect(
        find.byKey(const ValueKey('intro-number-1')),
      );
      final ninth = tester.getRect(
        find.byKey(const ValueKey('intro-number-9')),
      );
      final clear = tester.getRect(find.byKey(const ValueKey('intro-clear')));
      final help = tester.getRect(find.byKey(const ValueKey('game-help')));
      final back = tester.getRect(find.byKey(const ValueKey('game-back')));
      final settings = tester.getRect(
        find.byKey(const ValueKey('game-settings')),
      );
      final pause = tester.getRect(find.byKey(const ValueKey('game-pause')));
      final timer = tester.getRect(find.byKey(const ValueKey('game-timer')));

      expect(find.byKey(const ValueKey('intro-scroll')), findsNothing);
      expect(tester.state(scene.board), same(originalBoardState));
      expect(tester.widget<SudokuBoard>(scene.board).selectedIndex, cell);
      expect(flow.boardValues, originalValues);
      expect(board.center.dx, closeTo(size.width / 2, 1));
      expect(first.top, greaterThan(board.bottom));
      expect(ninth.top, closeTo(first.top, .1));
      expect(first.width, lessThanOrEqualTo(GameLayout.controlSize + .1));
      expect(clear.width, lessThanOrEqualTo(52.1));
      for (final rect in [
        board,
        first,
        ninth,
        clear,
        help,
        back,
        settings,
        pause,
        timer,
      ]) {
        expect(rect.top, greaterThanOrEqualTo(-1));
        expect(rect.bottom, lessThanOrEqualTo(size.height + 1));
      }
      if (size.width >= 700) {
        if (size.height > size.width) {
          expect(board.width, inInclusiveRange(500, 540.1));
        } else {
          expect(board.width, inInclusiveRange(430.1, 540.1));
          await scene.capture(tester, 'generated-game-ipad-1210x834');
        }
        expect(board.left, greaterThanOrEqualTo(80));
        expect(size.width - board.right, greaterThanOrEqualTo(80));
        expect(find.byKey(const ValueKey('game-status-panel')), findsOneWidget);
        expect(pause.right, lessThan(settings.left));
      } else {
        expect(board.width, lessThan(400));
        expect(find.byKey(const ValueKey('game-status-panel')), findsNothing);
      }
      expect(tester.takeException(), isNull);
    }

    await scene.capture(tester, 'generated-game-ipad-834x1210');
    await tester.pumpWidget(const SizedBox());
    await scene.settle(tester);
    await repo.close();
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
          final title = tester.getRect(find.text('Ronda 1 de 3'));
          final back = tester.getRect(find.byKey(const ValueKey('game-back')));
          final settings = tester.getRect(
            find.byKey(const ValueKey('game-settings')),
          );
          final pause = tester.getRect(
            find.byKey(const ValueKey('game-pause')),
          );
          final header = tester.getRect(
            find.byKey(const ValueKey('intro-header')),
          );
          if (desktop) {
            expect(
              title.center.dx,
              closeTo(tester.view.physicalSize.width / 2, 1),
            );
            expect(title.left, greaterThanOrEqualTo(back.right));
            expect(title.right, lessThanOrEqualTo(pause.left));
            expect(header.center.dy, closeTo(back.center.dy, 3));
            expect(pause.right, lessThan(settings.left));
            expect(settings.left - pause.right, lessThanOrEqualTo(16));
            expect(pause.center.dy, closeTo(settings.center.dy, .1));
            expect(pause.size, settings.size);
            expect(find.byType(GamePauseButton), findsOneWidget);
          } else {
            expect(title.left, greaterThanOrEqualTo(back.right));
            expect(title.right, lessThanOrEqualTo(settings.left));
            expect(header.center.dy, closeTo(back.center.dy, 3));
            expect(
              pause.left,
              greaterThan(
                tester.getRect(find.byKey(const ValueKey('game-timer'))).right,
              ),
            );
            expect(pause.top, greaterThan(settings.bottom));
            expect(find.byType(GamePauseButton), findsNothing);
          }
          expect(tester.widget<Text>(find.text('Ronda 1 de 3')).maxLines, 1);
          expect(
            find.byKey(const ValueKey('intro-header-rays-left')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('intro-header-rays-right')),
            findsNothing,
          );
          expect(find.byKey(const ValueKey('game-timer')), findsOneWidget);
          expect(
            find.byKey(const ValueKey('game-unlimited-lives')),
            findsOneWidget,
          );
          final status = find.byKey(const ValueKey('game-status-panel'));
          expect(status, desktop ? findsOneWidget : findsNothing);
          if (desktop) {
            for (final key in [
              'game-unlimited-lives',
              'game-score',
              'game-timer',
            ]) {
              expect(
                find.descendant(
                  of: status,
                  matching: find.byKey(ValueKey(key)),
                ),
                findsOneWidget,
              );
            }
            expect(
              find.descendant(
                of: status,
                matching: find.byKey(const ValueKey('game-pause')),
              ),
              findsNothing,
            );
          }
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
          expect(find.byKey(const ValueKey('game-play-icon')), findsOneWidget);
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
          await scene.tap(tester, find.byKey(const ValueKey('game-pause')));
          expect(flow.readyToPlay, true);
          expect(find.byKey(const ValueKey('game-play-icon')), findsNothing);
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
      tester
          .widgetList<MapLevelButton>(find.byType(MapLevelButton))
          .singleWhere((button) => button.level == 2)
          .onTap();
      await scene.settle(tester);
      expect(find.text('¡Completado!'), findsOneWidget);
      await scene.tap(tester, find.byKey(const ValueKey('level-summary-ok')));

      tester
          .widgetList<MapLevelButton>(find.byType(MapLevelButton))
          .singleWhere((button) => button.level == 4)
          .onTap();
      await scene.settle(tester);
      expect(find.byKey(const ValueKey('level-summary')), findsNothing);

      tester
          .widgetList<MapLevelButton>(find.byType(MapLevelButton))
          .singleWhere((button) => button.level == 3)
          .onTap();
      await scene.settle(tester);
      expect(find.text('En progreso'), findsOneWidget);
      expect(opened, isEmpty);
      await scene.tap(tester, find.byKey(const ValueKey('level-summary-play')));
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
          expect(find.byKey(const ValueKey('intro-header')), findsNothing);
          expect(
            find.byKey(const ValueKey('intro-header-rays-left')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('intro-header-rays-right')),
            findsNothing,
          );
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
      expect(find.text('¡Juego 2 completado!'), findsOneWidget);
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
      expect(
        tester
            .widget<SudokuTimeSummary>(find.byType(SudokuTimeSummary))
            .message,
        '¡Conseguiste las tres estrellas! El siguiente juego ya está desbloqueado.',
      );
      await tester.pump(const Duration(seconds: 10));
      await scene.capture(tester, 'level-2-summary');
      tester.view.physicalSize = const Size(390, 844);
      await scene.settle(tester);
      await tester.ensureVisible(find.byType(SudokuTimeSummary));
      await scene.capture(tester, 'level-2-summary-mobile');
      expect(find.text('Volver al mapa').hitTestable(), findsOneWidget);
      expect(find.text('Siguiente juego').hitTestable(), findsOneWidget);
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
        expect(find.byKey(const ValueKey('reward-doku-fade')), findsNothing);
        expect(find.text('Volver al mapa').hitTestable(), findsOneWidget);
        expect(find.text('Siguiente juego').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      tester.view.physicalSize = const Size(360, 640);
      await scene.show(tester, repo, levelNumber: 2, textScale: 2);
      await scene.settle(tester);
      expect(find.text('Siguiente juego').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await scene.capture(tester, 'summary-small-large-text');
      await scene.tap(tester, find.text('Siguiente juego'));
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump();
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
