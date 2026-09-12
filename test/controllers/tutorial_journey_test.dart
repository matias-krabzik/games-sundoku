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
    if (flow.confirmingMove) {
      flow.continuePlaying();
      continue;
    }
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
    'three real games reduce guidance, save stars and unlock level 2',
    () async {
      final repo = GameRepository.memory();
      addTearDown(repo.close);
      final flow = await at(repo, FirstExperienceStep.givensIntroduction);
      addTearDown(flow.dispose);
      await enterGame(flow);
      for (var game = 0; game < 3; game++) {
        expect(flow.step, FirstExperienceStep.playing);
        expect(flow.readyToPlay, true);
        expect(flow.remaining, [6, 12, 18][game]);
        if (game == 0) {
          expect(flow.showingAnswer, true);
          expect(flow.hint!.group!.name, 'row');
          final index = flow.gameCell!;
          await flow.placeGameNumber(flow.puzzleDefinition!.solution[index]);
          expect(flow.confirmingMove, true);
          flow.continuePlaying();
          expect(flow.hint!.group!.name, 'column');
        } else {
          expect(flow.gameCell, isNull);
          final before = flow.boardValues;
          await flow.requestHint();
          expect(flow.showingAnswer, false);
          expect(flow.puzzleProgress!.hintsUsed, 0);
          await flow.requestHint();
          expect(flow.showingAnswer, true);
          expect(flow.boardValues, before);
          expect(flow.puzzleProgress!.hintsUsed, 1);
        }
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
    },
  );

  test('wrong numbers explain a visible duplicate; clues stay immutable; clearing works', () async {
    final repo = GameRepository.memory();
    addTearDown(repo.close);
    final flow = await at(repo, FirstExperienceStep.givensIntroduction);
    addTearDown(flow.dispose);
    await enterGame(flow);
    final board = flow.boardValues;
    final selected = flow.gameCell!;
    await flow.placeGameNumber(7);
    expect(flow.boardValues, board);
    expect(flow.conflicts, contains(selected));
    expect(flow.playMessage, contains('Ya hay un 7'));
    expect(flow.puzzleProgress!.mistakes, 0);
    flow.selectGameCell(0);
    expect(flow.playMessage, contains('pistas no se cambian'));
    expect(flow.gameCell, selected);
    await flow.placeGameNumber(flow.puzzleDefinition!.solution[selected]);
    flow.continuePlaying();
    flow.selectGameCell(selected);
    await flow.clearGameCell();
    expect(flow.boardValues[selected], isNull);
    expect(flow.remaining, 6);
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
    final target = flow.gameCell!;
    store.fail = true;
    await flow.placeGameNumber(flow.puzzleDefinition!.solution[target]);
    expect(flow.boardValues[target], isNull);
    expect(flow.gameCell, target);
    expect(flow.error, isNotNull);
    store.fail = false;
    await flow.placeGameNumber(flow.puzzleDefinition!.solution[target]);
    expect(flow.boardValues[target], isNotNull);
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
  });

  test('failed final moves and transitions never award twice', () async {
    final store = _FailingStore();
    final repo = await GameRepository.open(store);
    addTearDown(repo.close);
    final flow = await at(repo, FirstExperienceStep.givensIntroduction);
    addTearDown(flow.dispose);
    await enterGame(flow);
    while (flow.remaining > 1) {
      if (flow.confirmingMove) flow.continuePlaying();
      final index = flow.gameCell!;
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
