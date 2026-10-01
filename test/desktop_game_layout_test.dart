import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/domain/tutorial/tutorial_sudokus.dart';
import 'package:sundoku/widgets/game_layout.dart';
import 'package:sundoku/widgets/sudoku_board.dart';
import 'package:sundoku/widgets/sudoku_help.dart';
import 'package:sundoku/widgets/tutorial_block_controls.dart';

import 'tutorial_journey_widget_test.dart' as scene;

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Baloo2',
    )..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'))).load();
  });

  for (final platform in [TargetPlatform.macOS, TargetPlatform.android]) {
    testWidgets(
      'large game layout and phone resize preserve play ($platform)',
      (tester) async {
        scene.configure(tester);
        debugDefaultTargetPlatformOverride = platform;
        try {
          tester.view.physicalSize = const Size(1024, 768);
          final repo = GameRepository.memory();
          final definitions = TutorialSudokus.create(scene.center);
          final session = await repo.startOrResumeLevel(
            mapLevelId(1),
            definitions: definitions,
            moduleKey: FirstExperienceController.moduleKey,
            moduleData: {
              'step': 'playing',
              'gameIndex': 0,
              'cells': scene.center,
              'briefingAccepted': true,
            },
          );
          await scene.show(tester, repo);
          await scene.settle(tester);
          if (platform == TargetPlatform.macOS) {
            await scene.capture(tester, 'desktop-game-1024x768');
          }
          final first = find.byKey(const ValueKey('intro-number-1'));
          final ninth = find.byKey(const ValueKey('intro-number-9'));
          final boardRect = tester.getRect(scene.board);
          final firstRect = tester.getRect(first);
          expect(
            firstRect.width,
            closeTo(GameLayout.boardCellSize(boardRect.width), .1),
          );
          final ninthRect = tester.getRect(ninth);
          expect(boardRect.center.dx, closeTo(512, 1));
          expect(firstRect.top, greaterThan(boardRect.bottom));
          expect(ninthRect.top, closeTo(firstRect.top, .1));
          expect(ninthRect.left, greaterThan(firstRect.right));
          expect((firstRect.left + ninthRect.right) / 2, closeTo(512, 1));
          expect(firstRect.width, lessThanOrEqualTo(GameLayout.controlSize));
          expect(
            boardRect.width,
            lessThanOrEqualTo(GameLayout.maxPlayBoardSize + .1),
          );
          final clear = tester.getRect(
            find.byKey(const ValueKey('intro-clear')),
          );
          final help = tester.getRect(find.byKey(const ValueKey('game-help')));
          expect(clear.top, greaterThan(firstRect.bottom));
          expect(help.top, greaterThan(ninthRect.bottom));
          expect(clear.width, lessThanOrEqualTo(52));
          expect(help.width, lessThanOrEqualTo(GameLayout.controlSize));
          expect(
            find.byKey(const ValueKey('desktop-play-group')),
            findsOneWidget,
          );
          final header = tester.getRect(
            find.byKey(const ValueKey('intro-header')),
          );
          final back = tester.getRect(find.byKey(const ValueKey('game-back')));
          final pause = tester.getRect(
            find.byKey(const ValueKey('game-pause')),
          );
          final settings = tester.getRect(
            find.byKey(const ValueKey('game-settings')),
          );
          // The round artwork extends a few pixels beyond its button box.
          expect(back.left, inInclusiveRange(16, 21));
          expect(back.top, inInclusiveRange(16, 26));
          expect(settings.right, inInclusiveRange(1024 - 21, 1024 - 16));
          expect(pause.right, lessThan(settings.left));
          expect(settings.left - pause.right, lessThanOrEqualTo(16));
          expect(pause.center.dy, closeTo(settings.center.dy, .1));
          expect(pause.width, closeTo(pause.height, .1));
          expect(pause.width, closeTo(settings.width, .1));
          expect(header.center.dx, closeTo(512, 1));
          expect(header.width, lessThanOrEqualTo(340.1));
          expect(header.left, greaterThan(back.right));
          expect(header.right, lessThan(pause.left));
          final status = find.byKey(const ValueKey('game-status-panel'));
          expect(status, findsOneWidget);
          final statusRect = tester.getRect(status);
          expect(statusRect.height, greaterThanOrEqualTo(70));
          expect(statusRect.center.dx, closeTo(512, 1));
          for (final key in [
            'game-unlimited-lives',
            'game-score',
            'game-timer',
          ]) {
            expect(
              find.descendant(of: status, matching: find.byKey(ValueKey(key))),
              findsOneWidget,
            );
          }
          final livesRect = tester.getRect(
            find.byKey(const ValueKey('game-unlimited-lives')),
          );
          final scoreRect = tester.getRect(
            find.byKey(const ValueKey('game-score')),
          );
          final timerRect = tester.getRect(
            find.byKey(const ValueKey('game-timer')),
          );
          expect(livesRect.center.dy, closeTo(statusRect.center.dy, 5));
          expect(scoreRect.center.dy, closeTo(statusRect.center.dy, 5));
          expect(timerRect.center.dy, closeTo(statusRect.center.dy, 5));
          expect(livesRect.right, lessThan(scoreRect.left));
          expect(scoreRect.right, lessThan(timerRect.left));
          expect(
            find.descendant(
              of: status,
              matching: find.byKey(const ValueKey('game-pause')),
            ),
            findsNothing,
          );
          if (platform == TargetPlatform.macOS) {
            for (final (size, name) in [
              (const Size(768, 1024), 'ipad-game-768x1024'),
              (const Size(834, 1210), 'ipad-game-834x1210'),
              (const Size(1210, 834), 'ipad-game-1210x834'),
              (const Size(390, 844), 'mobile-game-390x844'),
            ]) {
              tester.view.physicalSize = size;
              await scene.settle(tester);
              await scene.capture(tester, name);
            }
            tester.view.physicalSize = const Size(1024, 768);
            await scene.settle(tester);
          }
          final index = definitions.first.initial.indexOf(null);
          await scene.tap(tester, find.byKey(ValueKey('sudoku-cell-$index')));
          await scene.tap(tester, find.byKey(const ValueKey('game-help')));
          expect(find.byType(SudokuHelpCard), findsOneWidget);
          if (platform == TargetPlatform.macOS) {
            await scene.capture(tester, 'desktop-game-help');
          }
          await scene.tap(tester, find.byKey(const ValueKey('game-help')));
          expect(find.byType(SudokuHelpCard), findsNothing);
          final originalState = tester.state(scene.board);
          double? narrowBoardWidth;
          double? regularPhoneBoardWidth;
          double? shortLandscapeBoardWidth;
          double? ipadLandscapeBoardWidth;
          final ipadBoardWidths = <Size, double>{};
          for (final size in [
            const Size(960, 720),
            const Size(1280, 960),
            const Size(768, 1024),
            const Size(834, 1210),
            const Size(1210, 834),
            const Size(600, 500),
            const Size(320, 568),
            const Size(390, 844),
            const Size(568, 320),
            const Size(844, 390),
            const Size(1024, 768),
          ]) {
            tester.view.physicalSize = size;
            await scene.settle(tester);
            final large = GameLayout.useLargePlayLayout(size);
            expect(tester.state(scene.board), same(originalState));
            expect(
              tester.widget<SudokuBoard>(scene.board).selectedIndex,
              index,
            );
            expect(find.byType(SudokuHelpCard), findsNothing);
            expect(
              find.byKey(const ValueKey('desktop-play-group')),
              large ? findsOneWidget : findsNothing,
            );
            expect(
              find.byKey(const ValueKey('game-status-panel')),
              large ? findsOneWidget : findsNothing,
            );
            final resizedBoard = tester.getRect(scene.board);
            final resizedFirst = tester.getRect(first);
            final resizedNinth = tester.getRect(ninth);
            final resizedClear = tester.getRect(
              find.byKey(const ValueKey('intro-clear')),
            );
            final resizedHelp = tester.getRect(
              find.byKey(const ValueKey('game-help')),
            );
            final sideMargin = math.max(24.0, size.width * .08);
            expect(find.byKey(const ValueKey('intro-scroll')), findsNothing);
            expect(resizedBoard.left, greaterThanOrEqualTo(sideMargin - 1));
            expect(
              resizedBoard.right,
              lessThanOrEqualTo(size.width - sideMargin + 1),
            );
            expect(resizedFirst.left, greaterThanOrEqualTo(sideMargin - 1));
            expect(
              resizedNinth.right,
              lessThanOrEqualTo(size.width - sideMargin + 1),
            );
            for (final rect in [
              resizedBoard,
              resizedFirst,
              resizedNinth,
              resizedClear,
              resizedHelp,
            ]) {
              expect(rect.top, greaterThanOrEqualTo(-1));
              expect(rect.bottom, lessThanOrEqualTo(size.height + 1));
            }
            expect(
              resizedFirst.width,
              closeTo(GameLayout.boardCellSize(resizedBoard.width), .1),
            );
            expect(resizedFirst.width, lessThanOrEqualTo(54.1));
            expect(resizedClear.width, lessThanOrEqualTo(52.1));
            expect(resizedBoard.center.dx, closeTo(size.width / 2, 1));
            expect(resizedFirst.top, greaterThan(resizedBoard.bottom));
            expect(resizedNinth.top, closeTo(resizedFirst.top, .1));
            expect(
              tester
                  .widget<TutorialNumberTray>(find.byType(TutorialNumberTray))
                  .horizontal,
              true,
            );
            final resizedPause = tester.getRect(
              find.byKey(const ValueKey('game-pause')),
            );
            final resizedSettings = tester.getRect(
              find.byKey(const ValueKey('game-settings')),
            );
            final resizedTimer = tester.getRect(
              find.byKey(const ValueKey('game-timer')),
            );
            if (large) {
              expect(resizedPause.right, lessThan(resizedSettings.left));
              expect(
                resizedPause.center.dy,
                closeTo(resizedSettings.center.dy, .1),
              );
              expect(
                resizedBoard.width,
                lessThanOrEqualTo(GameLayout.maxPlayBoardSize + .1),
              );
              expect(
                tester
                    .getRect(find.byKey(const ValueKey('game-status-panel')))
                    .height,
                greaterThanOrEqualTo(70),
              );
            } else {
              expect(resizedPause.left, greaterThan(resizedTimer.right));
              expect(resizedPause.top, greaterThan(resizedSettings.bottom));
            }
            if (size == const Size(320, 568)) {
              narrowBoardWidth = resizedBoard.width;
            }
            if (size == const Size(390, 844)) {
              regularPhoneBoardWidth = resizedBoard.width;
            }
            if (size == const Size(768, 1024) ||
                size == const Size(834, 1210)) {
              ipadBoardWidths[size] = resizedBoard.width;
              expect(resizedBoard.width, inInclusiveRange(500, 540.1));
              expect(resizedBoard.left, greaterThanOrEqualTo(80));
              expect(size.width - resizedBoard.right, greaterThanOrEqualTo(80));
            }
            if (size == const Size(1210, 834)) {
              ipadLandscapeBoardWidth = resizedBoard.width;
              expect(resizedBoard.width, greaterThan(430));
              expect(resizedBoard.width, lessThanOrEqualTo(540.1));
            }
            if (size == const Size(844, 390)) {
              shortLandscapeBoardWidth = resizedBoard.width;
              expect(resizedBoard.width, greaterThanOrEqualTo(150));
              if (platform == TargetPlatform.macOS) {
                await scene.capture(tester, 'landscape-game-844x390');
              }
            }
            expect(
              tester.getRect(find.byKey(const ValueKey('game-back'))).left,
              large || (size.width < 700 && size.height < 900)
                  ? inInclusiveRange(16, 21)
                  : closeTo(32, .1),
            );
            expect(tester.takeException(), isNull);
          }
          expect(narrowBoardWidth, isNotNull);
          expect(regularPhoneBoardWidth, isNotNull);
          expect(shortLandscapeBoardWidth, isNotNull);
          expect(ipadLandscapeBoardWidth, isNotNull);
          expect(regularPhoneBoardWidth!, greaterThan(narrowBoardWidth!));
          expect(shortLandscapeBoardWidth!, lessThan(GameLayout.maxBoardSize));
          expect(ipadBoardWidths, hasLength(2));
          for (final width in ipadBoardWidths.values) {
            expect(width, greaterThan(regularPhoneBoardWidth * 1.5));
          }
          await scene.tap(tester, find.byKey(const ValueKey('game-help')));
          expect(find.byType(SudokuHelpCard), findsOneWidget);
          for (final size in [
            const Size(390, 844),
            const Size(844, 390),
            const Size(1024, 768),
            const Size(768, 1024),
            const Size(834, 1210),
            const Size(1210, 834),
          ]) {
            tester.view.physicalSize = size;
            await scene.settle(tester);
            expect(find.byKey(const ValueKey('intro-scroll')), findsNothing);
            final boardWithHelp = tester.getRect(scene.board);
            final helpCard = tester.getRect(find.byType(SudokuHelpCard));
            final lastNumber = tester.getRect(ninth);
            if (size == const Size(844, 390)) {
              expect(boardWithHelp.width, greaterThanOrEqualTo(150));
              if (platform == TargetPlatform.macOS) {
                await scene.capture(tester, 'landscape-game-help-844x390');
              }
            }
            expect(boardWithHelp.top, greaterThanOrEqualTo(-1));
            expect(boardWithHelp.bottom, lessThanOrEqualTo(size.height + 1));
            expect(lastNumber.bottom, lessThanOrEqualTo(size.height + 1));
            expect(helpCard.top, greaterThanOrEqualTo(-1));
            expect(helpCard.bottom, lessThanOrEqualTo(size.height + 1));
            expect(tester.takeException(), isNull);
          }
          await scene.tap(tester, find.byKey(const ValueKey('game-help')));
          final value = definitions.first.solution[index];
          await scene.tap(tester, find.byKey(ValueKey('intro-number-$value')));
          expect(
            repo.state.sessions[session.id]!.puzzles.first.cells[index].value,
            value,
          );
          await tester.pumpWidget(const SizedBox());
          await scene.settle(tester);
          await repo.close();
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  }
}
