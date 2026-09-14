import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/domain/tutorial/tutorial_sudokus.dart';
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

  for (final small in [false, true]) {
    testWidgets(
      'contextual help selects a block and keeps play reachable (small=$small)',
      (tester) async {
        scene.configure(tester, reduced: small);
        tester.view.physicalSize = small
            ? const Size(320, 568)
            : const Size(575, 984);
        final repo = GameRepository.memory();

        final definitions = TutorialSudokus.create(scene.center);
        final definition = definitions.first;
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
        final index = definition.initial.indexOf(null);
        final block = groupCells(index, SudokuGroup.block).toSet();
        for (final other in block) {
          if (other != index && !definition.isFixed(other)) {
            await repo.setCell(
              session.id,
              definition.id,
              other,
              definition.solution[other],
            );
          }
        }
        await scene.show(tester, repo, textScale: small ? 1.6 : 1);
        final helpButton = find.byKey(const ValueKey('game-help'));
        final helpCard = find.byKey(const ValueKey('game-help-card'));
        expect(tester.widget<SudokuHelpButton>(helpButton).onPressed, isNull);
        await scene.tap(tester, find.byKey(ValueKey('sudoku-cell-$index')));
        await scene.tap(tester, helpButton);
        expect(tester.widget<SudokuBoard>(scene.board).helpFocusIndices, block);
        expect(
          find.text(
            'En este cuadro falta un solo número.\nMira cuáles están. ¿Cuál falta?',
          ),
          findsOneWidget,
        );
        expect(
          tester
              .widget<SudokuHelpSpotlight>(find.byType(SudokuHelpSpotlight))
              .areas
              .length,
          1,
        );
        await tester.ensureVisible(helpCard);
        await scene.settle(tester);
        await scene.capture(
          tester,
          small ? 'ayuda-320-texto-grande' : 'ayuda-bloque',
        );
        final saved =
            repo.state.sessions[session.id]!.puzzles.first.cells[index].value;
        expect(saved, isNull);
        expect(find.byKey(const ValueKey('game-help-close')), findsNothing);
        await scene.tap(tester, helpButton);
        expect(helpCard, findsNothing);
        expect(
          tester.widget<SudokuBoard>(scene.board).helpFocusIndices,
          isEmpty,
        );
        // Filled cells remain selectable, but cannot activate help.
        final fixed = definition.initial.indexWhere((value) => value != null);
        await scene.tap(tester, find.byKey(ValueKey('sudoku-cell-$fixed')));
        expect(tester.widget<SudokuHelpButton>(helpButton).onPressed, isNull);
        expect(helpCard, findsNothing);
        expect(
          tester.widget<SudokuBoard>(scene.board).helpFocusIndices,
          isEmpty,
        );
        await scene.tap(tester, find.byKey(ValueKey('sudoku-cell-$index')));
        expect(helpCard, findsNothing);
        await scene.tap(tester, helpButton);
        await scene.tap(
          tester,
          find.byKey(ValueKey('intro-number-${definition.solution[index]}')),
        );
        expect(helpCard, findsNothing);
        expect(
          repo.state.sessions[session.id]!.puzzles.first.cells[index].value,
          definition.solution[index],
        );
        expect(tester.widget<SudokuHelpButton>(helpButton).onPressed, isNull);
        await scene.tap(tester, find.byKey(ValueKey('sudoku-cell-$index')));
        expect(tester.widget<SudokuHelpButton>(helpButton).onPressed, isNull);
        expect(helpCard, findsNothing);
        await scene.tap(tester, find.byType(TutorialEraseButton));
        expect(
          tester.widget<SudokuHelpButton>(helpButton).onPressed,
          isNotNull,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await scene.settle(tester);
        await repo.close();
      },
    );
  }
}
