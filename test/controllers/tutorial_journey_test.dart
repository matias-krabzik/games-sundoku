import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/domain/models/game_session.dart';
import 'package:sundoku/domain/tutorial/tutorial_sudokus.dart';

const center = [8, 3, 5, 4, 1, 6, 9, 2, 7];

class _FailingStore extends MemorySaveStore {
  bool fail = false;
  @override
  Future<void> write(String data, {required int expectedRevision}) async {
    if (fail) throw StateError('Disk full');
    await super.write(data, expectedRevision: expectedRevision);
  }
}

Future<FirstExperienceController> at(
  GameRepository repo,
  FirstExperienceStep step,
) async {
  await repo.saveModule(FirstExperienceController.moduleKey, {
    'step': step.name,
    'cells': center,
  });
  return FirstExperienceController(repo);
}

Future<void> enterGame(FirstExperienceController flow) async {
  expect(flow.step, FirstExperienceStep.givensIntroduction);
  await flow.advance();
  expect(flow.step, FirstExperienceStep.playing);
  expect(flow.readyToPlay, true);
}

Future<void> solve(FirstExperienceController flow) async {
  var attempts = 0;
  while (flow.step == FirstExperienceStep.playing && attempts++ < 81) {
    final target =
        flow.gameCell != null && flow.boardValues[flow.gameCell!] == null
        ? flow.gameCell!
        : flow.boardValues.indexOf(null);
    flow.selectGameCell(target);
    await flow.placeGameNumber(flow.puzzleDefinition!.solution[target]);
  }
  expect(
    flow.step,
    flow.gameIndex == 2
        ? FirstExperienceStep.complete
        : FirstExperienceStep.celebration,
  );
}

void main() {
  test('review starts at welcome and never changes a running game', () async {
    final repo = await GameRepository.open(MemorySaveStore());
    addTearDown(repo.close);
    final playing = await at(repo, FirstExperienceStep.givensIntroduction);
    addTearDown(playing.dispose);
    await enterGame(playing);
    final saved = repo.state;
    final review = FirstExperienceController(repo, reviewOnly: true);
    addTearDown(review.dispose);
    expect(review.step, FirstExperienceStep.welcome);
    for (var i = 1; i < tutorialStorySteps.length; i++) {
      await review.advance();
      expect(review.step, tutorialStorySteps[i]);
    }
    await review.advance();
    await review.previousStory();
    expect(review.step, FirstExperienceStep.columnRule);
    expect(repo.state, same(saved));
    expect(playing.step, FirstExperienceStep.playing);
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  test('six stories advance without exercises and can be reviewed without changing the board', () async {
    final repo = GameRepository.memory();
    addTearDown(repo.close);
    final flow = FirstExperienceController(repo);
    addTearDown(flow.dispose);
    const stories = [
      FirstExperienceStep.welcome,
      FirstExperienceStep.blockIntroduction,
      FirstExperienceStep.expansion,
      FirstExperienceStep.rowRule,
      FirstExperienceStep.columnRule,
      FirstExperienceStep.givensIntroduction,
    ];
    for (var index = 0; index < stories.length; index++) {
      expect(flow.step, stories[index]);
      expect(flow.isStory, true);
      expect(flow.storyIndex, index);
      expect(flow.storyCount, stories.length);
      expect(repo.state.sessions, isEmpty);
      expect(repo.state.puzzles, isEmpty);
      if (index < stories.length - 1) await flow.advance();
    }
    expect(flow.remaining, 6);
    final chosenCenter = [...flow.cells];
    final preview = [...flow.boardValues];
    expect(
      TutorialSudokus.centerIndices.map((index) => preview[index]),
      chosenCenter,
    );
    for (var index = stories.length - 2; index >= 0; index--) {
      await flow.previousStory();
      expect(flow.step, stories[index]);
      expect(flow.cells, chosenCenter);
      final restored = FirstExperienceController(repo);
      expect(restored.step, stories[index]);
      expect(restored.cells, chosenCenter);
      restored.dispose();
    }
    await flow.previousStory();
    expect(flow.step, FirstExperienceStep.welcome);
    for (var index = 0; index < stories.length - 1; index++) {
      await flow.advance();
    }
    expect(flow.boardValues, preview);
    expect(repo.state.sessions, isEmpty);
    expect(repo.state.totalLights, 0);
    await enterGame(flow);
    expect(flow.boardValues, preview);
    expect(flow.cells, chosenCenter);
  });

  test(
    'the block example fills only missing digits and commits them only on next',
    () async {
      final store = _FailingStore();
      final repo = await GameRepository.open(store);
      addTearDown(repo.close);
      const draft = <int?>[null, 9, null, 3, null, null, null, 1, null];
      await repo.saveModule(FirstExperienceController.moduleKey, {
        'step': 'blockIntroduction',
        'cells': draft,
      });
      final flow = FirstExperienceController(repo);
      addTearDown(flow.dispose);
      expect(flow.cells, draft);
      store.fail = true;
      await flow.advance();
      expect(flow.step, FirstExperienceStep.blockIntroduction);
      expect(flow.cells, draft);
      expect(flow.error, isNotNull);
      store.fail = false;
      await flow.advance();
      expect(flow.step, FirstExperienceStep.expansion);
      expect(flow.cells, unorderedEquals(List.generate(9, (i) => i + 1)));
      for (var index = 0; index < draft.length; index++) {
        if (draft[index] != null) expect(flow.cells[index], draft[index]);
      }
      final filled = [...flow.cells];
      await flow.previousStory();
      await flow.advance();
      expect(flow.cells, filled);
      expect(repo.state.sessions, isEmpty);
    },
  );

  test('old lesson saves resume at the equivalent story without losing the chosen block', () async {
    const migrated = {
      FirstExperienceStep.blocksRule: FirstExperienceStep.expansion,
      FirstExperienceStep.rowIntroduction: FirstExperienceStep.rowRule,
      FirstExperienceStep.rowPractice: FirstExperienceStep.rowRule,
      FirstExperienceStep.columnIntroduction: FirstExperienceStep.columnRule,
      FirstExperienceStep.columnPractice: FirstExperienceStep.columnRule,
      FirstExperienceStep.gameIntroduction:
          FirstExperienceStep.givensIntroduction,
      FirstExperienceStep.inputIntroduction:
          FirstExperienceStep.givensIntroduction,
    };
    for (final entry in migrated.entries) {
      final repo = GameRepository.memory();
      addTearDown(repo.close);
      final flow = await at(repo, entry.key);
      expect(flow.step, entry.value, reason: entry.key.name);
      expect(flow.cells, center);
      expect(flow.isStory, true);
      expect(flow.storyCount, 6);
      expect(repo.state.sessions, isEmpty);
      expect(repo.state.totalLights, 0);
      await flow.advance();
      expect(flow.step, isNot(entry.value));
      flow.dispose();
      await flow.flush();
    }
  });

  test('saved introductions for later games resume playing with the same session and rewards', () async {
    final repo = GameRepository.memory();
    addTearDown(repo.close);
    var flow = await at(repo, FirstExperienceStep.givensIntroduction);
    await enterGame(flow);
    final sessionId = flow.session!.id;
    for (var game = 1; game < 3; game++) {
      await solve(flow);
      await flow.advance();
      expect(flow.gameIndex, game);
      final values = [...flow.boardValues];
      flow.dispose();
      await flow.flush();
      for (final oldStep in [
        FirstExperienceStep.gameIntroduction,
        FirstExperienceStep.givensIntroduction,
        FirstExperienceStep.inputIntroduction,
      ]) {
        await repo.saveModule(FirstExperienceController.moduleKey, {
          'step': oldStep.name,
          'cells': center,
          'sessionId': sessionId,
          'gameIndex': game,
        });
        final migrated = FirstExperienceController(repo);
        expect(migrated.step, FirstExperienceStep.playing);
        expect(migrated.gameIndex, game);
        expect(migrated.session!.id, sessionId);
        expect(migrated.boardValues, values);
        expect(repo.state.totalLights, game);
        await migrated.resumeGame();
        expect(migrated.readyToPlay, true);
        expect(migrated.boardValues, values);
        expect(repo.state.sessions.length, 1);
        migrated.dispose();
        await migrated.flush();
      }
      flow = FirstExperienceController(repo);
      await flow.resumeGame();
    }
    flow.dispose();
    await flow.flush();
  });

  test(
    'replay starts fresh practice and preserves completion records',
    () async {
      final repo = GameRepository.memory();
      addTearDown(repo.close);
      final flow = await at(repo, FirstExperienceStep.givensIntroduction);
      await enterGame(flow);
      for (var game = 0; game < 3; game++) {
        await solve(flow);
        if (game < 2) await flow.advance();
      }
      final completedId = flow.session!.id;
      await flow.restartGames();
      flow.dispose();
      final replay = FirstExperienceController(repo);
      addTearDown(replay.dispose);
      await replay.resumeGame();
      expect(replay.step, FirstExperienceStep.playing);
      expect(replay.readyToPlay, isTrue);
      expect(replay.gameIndex, 0);
      expect(replay.remaining, 6);
      expect(replay.session!.id, isNot(completedId));
      expect(repo.state.sessions[completedId]!.status, PlayStatus.completed);
      expect(repo.state.totalLights, 3);
      expect(repo.state.isUnlocked(mapLevelId(2)), isTrue);
      await solve(replay);
      expect(repo.state.totalLights, 3);
    },
  );

  test('practice recovers a session removed by a developer reset', () async {
    final repo = GameRepository.memory();
    addTearDown(repo.close);
    final original = await at(repo, FirstExperienceStep.givensIntroduction);
    await enterGame(original);
    final oldId = original.session!.id;
    original.dispose();
    await original.flush();
    await repo.resetDebugLevels({mapLevelId(1)});

    final resumed = FirstExperienceController(repo);
    addTearDown(resumed.dispose);
    await resumed.resumeGame();

    expect(resumed.readyToPlay, isTrue);
    expect(resumed.session!.id, isNot(oldId));
    expect(resumed.gameIndex, 0);
    expect(resumed.remaining, 6);
    expect(resumed.fixedIndices.length, 75);
  });

  test('dev fills each sudoku except the selected editable tile without finishing it', () async {
    final repo = GameRepository.memory();
    addTearDown(repo.close);
    final flow = await at(repo, FirstExperienceStep.givensIntroduction);
    addTearDown(flow.dispose);
    await enterGame(flow);
    for (var game = 0; game < 3; game++) {
      final definition = flow.puzzleDefinition!;
      final editable = [
        for (var i = 0; i < 81; i++)
          if (!definition.isFixed(i)) i,
      ];
      flow.selectGameCell(editable.first);
      await flow.placeGameNumber(definition.solution[editable.first] % 9 + 1);
      expect(flow.conflicts, isNotEmpty);
      final mistakes = flow.puzzleProgress!.mistakes;
      flow.selectGameCell(0);
      final firstEmpty = flow.boardValues.indexOf(null);
      await flow.debugFillExceptOne();
      expect(flow.gameCell, firstEmpty);
      expect(flow.remaining, 1);
      expect(flow.conflicts, isEmpty);
      expect(flow.puzzleProgress!.mistakes, mistakes);
      expect(flow.puzzleProgress!.hintsUsed, 0);
      expect(flow.completion, isNull);
      expect(repo.state.totalLights, game);

      // A filled, editable selection can also be left for the final move.
      final last = editable.last;
      flow.selectGameCell(last);
      await flow.debugFillExceptOne();
      expect(flow.boardValues, <int?>[...definition.solution]..[last] = null);
      expect(flow.remaining, 1);
      expect(flow.gameCell, last);
      expect(flow.readyToPlay, true);
      for (final index in flow.fixedIndices) {
        expect(flow.boardValues[index], definition.initial[index]);
      }
      await flow.placeGameNumber(definition.solution[last]);
      expect(flow.completion!.wholeBoard, true);
      expect(flow.completion!.origin, last);
      expect(repo.state.totalLights, game + 1);
      if (game < 2) await flow.advance();
    }
  });

  test(
    'dev restart rewinds only the last completed sudoku and preserves records',
    () async {
      final repo = GameRepository.memory();
      addTearDown(repo.close);
      final flow = await at(repo, FirstExperienceStep.givensIntroduction);
      addTearDown(flow.dispose);
      await enterGame(flow);
      expect(flow.debugPreviousGameIndex, isNull);
      await solve(flow);
      await flow.advance();
      final first = flow.boardValues.indexOf(null);
      flow.selectGameCell(first);
      await flow.placeGameNumber(flow.puzzleDefinition!.solution[first]);
      final secondBoard = [...flow.boardValues];
      for (var attempt = 0; attempt < 2; attempt++) {
        expect(flow.debugPreviousGameIndex, 0);
        await flow.debugRestartPrevious();
        expect(flow.gameIndex, 0);
        expect(flow.readyToPlay, true);
        expect(flow.boardValues, flow.puzzleDefinition!.initial);
        expect(flow.completion, isNull);
        expect(flow.gameCell, isNull);
        expect(repo.state.totalLights, 1);
        repo.state.validate();
        await solve(flow);
        await flow.advance();
        expect(flow.gameIndex, 1);
        expect(flow.boardValues, secondBoard);
        expect(repo.state.totalLights, 1);
      }
      await solve(flow);
      await flow.advance();
      await solve(flow);
      expect(flow.debugPreviousGameIndex, 2);
      await flow.debugRestartPrevious();
      expect(flow.gameIndex, 2);
      expect(flow.remaining, 18);
      expect(flow.session!.completedAt, isNull);
      expect(repo.state.totalLights, 3);
      expect(repo.state.isUnlocked(mapLevelId(2)), true);
      final restored = FirstExperienceController(repo);
      expect(restored.gameIndex, 2);
      expect(restored.boardValues, flow.boardValues);
      restored.dispose();
      repo.state.validate();
    },
  );

  test('three uninterrupted games save stars and unlock level 2', () async {
    final repo = GameRepository.memory();
    addTearDown(repo.close);
    final flow = await at(repo, FirstExperienceStep.givensIntroduction);
    addTearDown(flow.dispose);
    await enterGame(flow);
    for (var game = 0; game < 3; game++) {
      expect(flow.step, FirstExperienceStep.playing);
      expect(flow.readyToPlay, true);
      expect(flow.remaining, [6, 12, 18][game]);
      expect(flow.gameCell, isNull);
      expect(flow.highlightedIndices, isEmpty);
      expect(flow.playMessage, isEmpty);
      final first = flow.boardValues.indexOf(null);
      flow.selectGameCell(first);
      await flow.placeGameNumber(flow.puzzleDefinition!.solution[first]);
      expect(flow.gameCell, first);
      expect(flow.playMessage, isEmpty);
      expect(flow.readyToPlay, true);
      final second = flow.boardValues.indexOf(null);
      flow.selectGameCell(second);
      await flow.placeGameNumber(flow.puzzleDefinition!.solution[second]);
      expect(flow.boardValues[second], flow.puzzleDefinition!.solution[second]);
      expect(flow.puzzleProgress!.hintsUsed, 0);
      await solve(flow);
      expect(flow.session!.lights, game + 1);
      expect(repo.state.totalLights, game + 1);
      expect(repo.state.isUnlocked(mapLevelId(2)), game == 2);
      final restored = FirstExperienceController(repo);
      expect(
        restored.step,
        game == 2
            ? FirstExperienceStep.complete
            : FirstExperienceStep.celebration,
      );
      expect(restored.gameIndex, game);
      restored.dispose();
      if (game < 2) await flow.advance();
    }
    expect(flow.step, FirstExperienceStep.complete);
    expect(flow.session!.status, PlayStatus.completed);
    expect(repo.state.sessions.length, 1);
    await repo.saveModule(FirstExperienceController.moduleKey, {
      ...(repo.state.modules[FirstExperienceController.moduleKey] as Map)
          .cast<String, Object?>(),
      'step': 'celebration',
    });
    final oldCompletion = FirstExperienceController(repo);
    expect(oldCompletion.step, FirstExperienceStep.complete);
    expect(oldCompletion.session!.lights, 3);
    oldCompletion.dispose();
    await flow.repeatLessons();
    while (flow.step != FirstExperienceStep.complete) {
      await flow.advance();
    }
    expect(repo.state.sessions.length, 1);
    expect(repo.state.totalLights, 3);
  });

  test(
    'sudoku 2 waves include incomplete lines and blocks by position',
    () async {
      final repo = GameRepository.memory();
      addTearDown(repo.close);
      final flow = await at(repo, FirstExperienceStep.givensIntroduction);
      addTearDown(flow.dispose);
      await enterGame(flow);
      await solve(flow);
      await flow.advance();
      expect(flow.gameIndex, 1);

      for (final origin in [70, 75]) {
        expect(flow.boardValues[origin], isNull);
        flow.selectGameCell(origin);
        await flow.placeGameNumber(flow.puzzleDefinition!.solution[origin]);
        final wave = flow.completion!;
        expect(wave.origin, origin);
        expect(wave.wholeBoard, false);
        expect(wave.cells.length, 21);
        for (final group in SudokuGroup.values) {
          expect(wave.cells, containsAll(groupCells(origin, group)));
        }
        expect(flow.boardValues[79], isNull);
        expect(flow.boardValues[80], isNull);
        expect(wave.cells, containsAll([79, 80]));

        flow.selectGameCell(0);
        expect(flow.completion, same(wave));
        flow.selectGameCell(origin);
        await flow.placeGameNumber(flow.puzzleDefinition!.solution[origin]);
        expect(flow.completion, same(wave));
      }
    },
  );

  test('wrong entries stay on the board and only mark themselves; clues stay immutable', () async {
    final repo = GameRepository.memory();
    addTearDown(repo.close);
    final flow = await at(repo, FirstExperienceStep.givensIntroduction);
    addTearDown(flow.dispose);
    await enterGame(flow);
    final board = flow.boardValues;
    final selected = TutorialSudokus.guidedOrder.first;
    flow.selectGameCell(selected);
    await flow.placeGameNumber(1);
    final withError = [...board]..[selected] = 1;
    expect(flow.boardValues, withError);
    expect(flow.conflicts, {selected});
    expect(flow.playMessage, contains('Ya hay un 1'));
    expect(flow.puzzleProgress!.mistakes, 1);
    expect(flow.gameCell, selected);
    expect(flow.availableGameNumbers, contains(1));
    await flow.placeGameNumber(1);
    expect(flow.puzzleProgress!.mistakes, 1);
    flow.selectGameCell(0);
    expect(flow.gameCell, 0);
    expect(flow.conflicts, {selected});
    await flow.placeGameNumber(flow.puzzleDefinition!.solution[selected]);
    await flow.clearGameCell();
    expect(flow.boardValues, withError);
    flow.selectGameCell(selected);
    await flow.clearGameCell();
    expect(flow.conflicts, isEmpty);
    expect(flow.boardValues, board);
    await flow.placeGameNumber(1);
    await flow.placeGameNumber(flow.puzzleDefinition!.solution[selected]);
    expect(flow.conflicts, isEmpty);
    expect(flow.playMessage, isEmpty);
    await flow.clearGameCell();
    expect(flow.boardValues[selected], isNull);
    expect(flow.remaining, 6);
  });

  test('a full incorrect board survives reopening and rewards only after correction', () async {
    final store = MemorySaveStore();
    var repo = await GameRepository.open(store);
    var flow = await at(repo, FirstExperienceStep.givensIntroduction);
    await enterGame(flow);
    final target = TutorialSudokus.guidedOrder.first;
    flow.selectGameCell(target);
    await flow.placeGameNumber(1);
    expect(flow.boardValues.where((n) => n == 1).length, 9);
    expect(flow.availableGameNumbers, contains(1));
    while (flow.remaining > 0) {
      final index = flow.boardValues.indexOf(null);
      flow.selectGameCell(index);
      await flow.placeGameNumber(flow.puzzleDefinition!.solution[index]);
      expect(flow.playMessage, isEmpty);
    }
    expect(flow.availableGameNumbers, isNot(contains(1)));
    expect(
      flow.availableGameNumbers,
      contains(flow.puzzleDefinition!.solution[target]),
    );
    expect(flow.step, FirstExperienceStep.playing);
    expect(repo.state.totalLights, 0);
    final saved = flow.boardValues;
    flow.dispose();
    await flow.flush();
    await repo.close();
    repo = await GameRepository.open(store);
    flow = FirstExperienceController(repo);
    addTearDown(repo.close);
    addTearDown(flow.dispose);
    expect(flow.boardValues, saved);
    expect(flow.conflicts, {target});
    expect(flow.step, FirstExperienceStep.playing);
    await flow.resumeGame();
    flow.selectGameCell(target);
    await flow.placeGameNumber(flow.puzzleDefinition!.solution[target]);
    expect(flow.conflicts, isEmpty);
    expect(flow.step, FirstExperienceStep.celebration);
    expect(repo.state.totalLights, 1);
  });

  test('failed preparation is atomic, retries once and resumes moves after reopening', () async {
    final store = _FailingStore();
    var repo = await GameRepository.open(store);
    var flow = await at(repo, FirstExperienceStep.givensIntroduction);
    store.fail = true;
    await flow.advance();
    expect(flow.step, FirstExperienceStep.givensIntroduction);
    expect(repo.state.puzzles, isEmpty);
    expect(repo.state.sessions, isEmpty);
    store.fail = false;
    await enterGame(flow);
    final target = flow.boardValues.indexOf(null);
    flow.selectGameCell(target);
    store.fail = true;
    await flow.placeGameNumber(flow.puzzleDefinition!.solution[target]);
    expect(flow.boardValues[target], isNull);
    expect(flow.gameCell, target);
    expect(flow.error, isNotNull);
    expect(flow.completion, isNull);
    store.fail = false;
    await flow.placeGameNumber(flow.puzzleDefinition!.solution[target]);
    expect(flow.boardValues[target], isNotNull);
    expect(flow.completion!.origin, target);
    final saved = flow.boardValues;
    final sessionId = flow.session!.id;
    flow.dispose();
    await flow.flush();
    await repo.close();
    repo = await GameRepository.open(store);
    flow = FirstExperienceController(repo);
    addTearDown(repo.close);
    addTearDown(flow.dispose);
    expect(flow.step, FirstExperienceStep.playing);
    await flow.resumeGame();
    expect(flow.readyToPlay, true);
    expect(flow.boardValues, saved);
    expect(flow.session!.id, sessionId);
    expect(repo.state.sessions.length, 1);
    expect(
      flow.completion,
      isNull,
      reason: 'A saved group does not celebrate again',
    );
  });

  test('failed final moves and transitions never award twice', () async {
    final store = _FailingStore();
    final repo = await GameRepository.open(store);
    addTearDown(repo.close);
    final flow = await at(repo, FirstExperienceStep.givensIntroduction);
    addTearDown(flow.dispose);
    await enterGame(flow);
    while (flow.remaining > 1) {
      final index = flow.boardValues.indexOf(null);
      flow.selectGameCell(index);
      await flow.placeGameNumber(flow.puzzleDefinition!.solution[index]);
    }
    final last = flow.boardValues.indexOf(null);
    flow.selectGameCell(last);
    store.fail = true;
    await flow.placeGameNumber(flow.puzzleDefinition!.solution[last]);
    expect(flow.step, FirstExperienceStep.playing);
    expect(repo.state.totalLights, 0);
    store.fail = false;
    await flow.placeGameNumber(flow.puzzleDefinition!.solution[last]);
    expect(flow.step, FirstExperienceStep.celebration);
    expect(repo.state.totalLights, 1);
    store.fail = true;
    await flow.advance();
    expect(flow.step, FirstExperienceStep.celebration);
    expect(flow.gameIndex, 0);
    store.fail = false;
    await flow.advance();
    expect(flow.gameIndex, 1);
    expect(repo.state.totalLights, 1);
    final restored = FirstExperienceController(repo);
    expect(restored.step, FirstExperienceStep.playing);
    expect(restored.gameIndex, 1);
    restored.dispose();
  });
}
