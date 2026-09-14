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

import 'tutorial_journey_widget_test.dart' as scene;

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Baloo2',
    )..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'))).load();
  });

  for (final desktop in [true, false]) {
    testWidgets(
      'game keypad layout and resize preserve play (desktop=$desktop)',
      (tester) async {
        scene.configure(tester);
        debugDefaultTargetPlatformOverride = desktop
            ? TargetPlatform.macOS
            : TargetPlatform.android;
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
          final first = find.byKey(const ValueKey('intro-number-1'));
          final fourth = find.byKey(const ValueKey('intro-number-4'));
          final ninth = find.byKey(const ValueKey('intro-number-9'));
          final boardRect = tester.getRect(scene.board);
          if (desktop) {
            final firstRect = tester.getRect(first);
            final ninthRect = tester.getRect(ninth);
            expect(
              firstRect.left - boardRect.right,
              closeTo(GameLayout.desktopBoardGap, 1),
            );
            expect(firstRect.top, lessThan(tester.getTopLeft(fourth).dy));
            expect(firstRect.left, closeTo(tester.getTopLeft(fourth).dx, .1));
            expect((boardRect.left + ninthRect.right) / 2, closeTo(512, 1));
            expect(firstRect.width, lessThanOrEqualTo(GameLayout.controlSize));
            expect(boardRect.width, lessThanOrEqualTo(GameLayout.maxBoardSize));
            await scene.capture(tester, 'desktop-game-1024x768');
          } else {
            expect(tester.getTopLeft(first).dy, greaterThan(boardRect.bottom));
            expect(tester.getTopLeft(ninth).dy, tester.getTopLeft(first).dy);
            expect(
              find.byKey(const ValueKey('desktop-play-group')),
              findsNothing,
            );
          }
          final index = definitions.first.initial.indexOf(null);
          await scene.tap(tester, find.byKey(ValueKey('sudoku-cell-$index')));
          await scene.tap(tester, find.byKey(const ValueKey('game-help')));
          expect(find.byType(SudokuHelpCard), findsOneWidget);
          if (desktop) await scene.capture(tester, 'desktop-game-help');
          final originalState = tester.state(scene.board);
          for (final size
              in desktop
                  ? [
                      const Size(960, 720),
                      const Size(1280, 960),
                      const Size(600, 500),
                      const Size(1024, 768),
                    ]
                  : [const Size(390, 844), const Size(844, 390)]) {
            tester.view.physicalSize = size;
            await scene.settle(tester);
            expect(tester.state(scene.board), same(originalState));
            expect(
              tester.widget<SudokuBoard>(scene.board).selectedIndex,
              index,
            );
            expect(find.byType(SudokuHelpCard), findsOneWidget);
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
