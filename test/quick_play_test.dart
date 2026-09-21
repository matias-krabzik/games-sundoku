import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/save_codec.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/domain/generation/seeded_sudokus.dart';
import 'package:sundoku/domain/models/game_session.dart';
import 'package:sundoku/domain/models/quick_play_difficulty.dart';
import 'package:sundoku/screens/quick_play_screen.dart';
import 'package:sundoku/screens/home_screen.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/tutorial_journey.dart';

import 'tutorial_journey_widget_test.dart' as scene;
import 'domain/generation/seeded_sudokus_test.dart' show solutionCount;

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Baloo2',
    )..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  test(
    'each quick difficulty produces a unique puzzle and matching score tier',
    () {
      for (final difficulty in QuickPlayDifficulty.values) {
        final puzzle = SeededSudokus.create(
          id: difficulty.name,
          seed: 'quick-test',
          difficulty: difficulty,
        );
        expect(puzzle.difficulty, difficulty.name);
        expect(
          puzzle.initial.where((n) => n == null).length,
          difficulty.emptyCells,
        );
        expect(solutionCount(puzzle.initial), 1);
        expect(
          SeededSudokus.create(
            id: difficulty.name,
            seed: 'quick-test',
            difficulty: difficulty,
          ).toJson(),
          puzzle.toJson(),
        );
        if (difficulty == QuickPlayDifficulty.hard ||
            difficulty == QuickPlayDifficulty.extreme) {
          expect(
            SeededSudokus.solveWithSingles(
              puzzle.initial.map((n) => n ?? 0).toList(),
            ),
            isNull,
          );
        }
      }
    },
  );

  test(
    'quick games persist separately and finish after exactly one board',
    () async {
      final repo = GameRepository.memory();
      addTearDown(repo.close);
      final normal = await repo.startQuickPlay(QuickPlayDifficulty.normal);
      await expectLater(
        repo.startQuickPlay(QuickPlayDifficulty.hard),
        throwsStateError,
      );
      expect(normal.puzzles.length, 1);
      expect(
        (await repo.startQuickPlay(QuickPlayDifficulty.normal)).id,
        normal.id,
      );
      final flow = FirstExperienceController(
        repo,
        quickPlayDifficulty: QuickPlayDifficulty.normal,
      );
      await flow.resumeGame();
      final puzzle = flow.puzzleDefinition!;
      final empty = puzzle.initial.indexOf(null);
      flow.selectGameCell(empty);
      await flow.placeGameNumber(puzzle.solution[empty]);
      await repo.addElapsed(normal.id, puzzle.id, 7200000);
      await flow.pauseGame();
      await flow.flush();
      final snapshot = const SaveCodec().decode(
        const SaveCodec().encode(repo.state),
      );
      expect(
        snapshot.sessions[normal.id]!.puzzles.single.cells[empty].value,
        puzzle.solution[empty],
      );
      expect(
        snapshot.sessions[normal.id]!.elapsedMs,
        greaterThanOrEqualTo(7200000),
      );
      expect(snapshot.sessions[normal.id]!.points, greaterThan(0));
      flow.dispose();

      final resumed = FirstExperienceController(
        repo,
        quickPlayDifficulty: QuickPlayDifficulty.normal,
      );
      await resumed.resumeGame();
      expect(resumed.boardValues[empty], puzzle.solution[empty]);
      for (var i = 0; i < 81; i++) {
        if (resumed.boardValues[i] != null) continue;
        resumed.selectGameCell(i);
        await resumed.placeGameNumber(puzzle.solution[i]);
      }
      expect(resumed.step, FirstExperienceStep.complete);
      expect(resumed.session!.status, PlayStatus.completed);
      expect(resumed.session!.puzzles.length, 1);
      expect(repo.state.progress[mapLevelId(1)], isNull);
      expect(repo.state.isUnlocked(mapLevelId(2)), false);
      expect(repo.pendingQuickPlay(QuickPlayDifficulty.normal), isNull);
      resumed.dispose();
      final next = await repo.startQuickPlay(QuickPlayDifficulty.normal);
      expect(next.id, isNot(normal.id));
      expect(next.puzzles.single.puzzleId, isNot(puzzle.id));
      final nextPuzzle = repo.state.puzzles[next.puzzles.single.puzzleId]!;
      final nextCell = nextPuzzle.initial.indexOf(null);
      await repo.activatePuzzle(next.id, nextPuzzle.id);
      await repo.setCell(
        next.id,
        nextPuzzle.id,
        nextCell,
        nextPuzzle.solution[nextCell],
      );
      expect(repo.pendingQuickGame!.points, greaterThan(0));
      final replacement = await repo.startQuickPlay(
        QuickPlayDifficulty.hard,
        replacePending: true,
      );
      expect(repo.state.sessions.containsKey(next.id), false);
      expect(
        repo.state.puzzles.containsKey(next.puzzles.single.puzzleId),
        false,
      );
      expect(repo.pendingQuickGame!.id, replacement.id);
      expect(repo.pendingQuickGame!.points, 0);
      expect(repo.state.progress.containsKey(next.levelId), false);
      expect(repo.pendingQuickPlay(QuickPlayDifficulty.normal), isNull);
      expect(repo.state.sessions.containsKey(normal.id), true);
      repo.state.validate();
    },
  );

  testWidgets(
    'selection saves choice until Play and opens one resumable sudoku',
    (tester) async {
      scene.configure(tester);
      final snapshot = (await tester.runAsync(() async {
        final repository = GameRepository.memory();
        await repository.startQuickPlay(QuickPlayDifficulty.hard);
        final data = const SaveCodec().encode(
          repository.state.copyWith(revision: 0),
        );
        await repository.close();
        return data;
      }))!;
      final store = MemorySaveStore();
      await store.write(snapshot, expectedRevision: -1);
      final repo = await GameRepository.open(store);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildSunDokuTheme(),
          home: Builder(
            builder: (context) => HomeScreen(
              quickPlayUnlocked: true,
              onQuickPlay: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RepaintBoundary(
                    key: scene.captureKey,
                    child: QuickPlayScreen(repository: repo),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await scene.settle(tester);
      await scene.tap(tester, find.byKey(const ValueKey('home-quick-play')));
      await scene.capture(tester, 'quick-play-selection');
      for (final difficulty in QuickPlayDifficulty.values) {
        expect(
          find.byKey(ValueKey('quick-difficulty-${difficulty.name}')),
          findsOneWidget,
        );
      }
      expect(find.text('Continuar'), findsOneWidget);
      await scene.tap(
        tester,
        find.byKey(const ValueKey('quick-difficulty-hard')),
      );
      expect(find.text('Continuar'), findsOneWidget);
      expect(find.byType(TutorialJourney), findsNothing);
      await scene.tap(tester, find.byKey(const ValueKey('quick-play-start')));
      final flow = tester
          .widget<TutorialJourney>(find.byType(TutorialJourney))
          .flow;
      expect(flow.isQuickPlay, true);
      expect(flow.quickPlayDifficulty, QuickPlayDifficulty.hard);
      expect(flow.readyToPlay, true);
      expect(find.text('Ronda 1 de 3'), findsNothing);
      final index = flow.boardValues.indexOf(null);
      flow.selectGameCell(index);
      await flow.placeGameNumber(flow.puzzleDefinition!.solution[index]);
      await scene.settle(tester);
      await scene.tap(tester, find.byKey(const ValueKey('game-back')));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(QuickPlayScreen), findsNothing);
      await scene.tap(tester, find.byKey(const ValueKey('home-quick-play')));
      expect(find.text('Continuar'), findsOneWidget);
      final sessionId = repo.pendingQuickGame!.id;
      final points = repo.pendingQuickGame!.points;
      await scene.tap(
        tester,
        find.byKey(const ValueKey('quick-difficulty-normal')),
      );
      await scene.tap(tester, find.byKey(const ValueKey('quick-play-start')));
      expect(
        find.textContaining('Perderás la partida rápida pendiente'),
        findsOneWidget,
      );
      await scene.tap(
        tester,
        find.byKey(const ValueKey('quick-replace-cancel')),
      );
      expect(repo.pendingQuickGame!.id, sessionId);
      expect(repo.pendingQuickGame!.points, points);
      await scene.tap(
        tester,
        find.byKey(const ValueKey('quick-difficulty-hard')),
      );
      await scene.tap(tester, find.byKey(const ValueKey('quick-play-start')));
      final resumed = tester
          .widget<TutorialJourney>(find.byType(TutorialJourney))
          .flow;
      expect(
        resumed.boardValues[index],
        resumed.puzzleDefinition!.solution[index],
      );
      expect(resumed.readyToPlay, true);
      await resumed.debugFillExceptOne();
      final last = resumed.boardValues.indexOf(null);
      resumed.selectGameCell(last);
      await resumed.placeGameNumber(resumed.puzzleDefinition!.solution[last]);
      await scene.settle(tester);
      expect(find.text('¡Partida completada!'), findsOneWidget);
      expect(find.text('Siguiente nivel 2'), findsNothing);
      expect(find.text('El nivel 2 ya está abierto.'), findsNothing);
      expect(find.text('Volver').hitTestable(), findsOneWidget);
      await scene.tap(tester, find.text('Volver'));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await scene.settle(tester);
      await repo.close();
    },
  );

  testWidgets(
    'difficulty selection adapts to small, wide and enlarged text windows',
    (tester) async {
      scene.configure(tester);
      final repo = GameRepository.memory();
      for (final size in [
        const Size(390, 844),
        const Size(320, 568),
        const Size(844, 390),
        const Size(834, 1194),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildSunDokuTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: QuickPlayScreen(repository: repo),
          ),
        );
        await scene.settle(tester);
        expect(
          find.byKey(const ValueKey('quick-play-start')).hitTestable(),
          findsOneWidget,
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('quick-difficulty-extreme')),
        );
        await scene.settle(tester);
        expect(
          find.byKey(const ValueKey('quick-difficulty-extreme')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
      await scene.settle(tester);
      await repo.close();
    },
  );
}
