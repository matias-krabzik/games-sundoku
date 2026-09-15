import 'dart:ui' show AppExitResponse;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/controllers/game_session_controller.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/domain/models/game_session.dart';

import 'game_session_controller_test.dart' show TestClock;
import 'tutorial_journey_test.dart' show solve;

class _FailingStore extends MemorySaveStore {
  bool fail = false;
  @override
  Future<void> write(String data, {required int expectedRevision}) async {
    if (fail) throw StateError('Disk full');
    await super.write(data, expectedRevision: expectedRevision);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'levels 2–10 have three saved puzzles, unlock in order and cannot replay',
    () async {
      final repo = GameRepository.memory();
      await repo.recordDebugLights(mapLevelId(1), 3);
      for (var level = 2; level <= 10; level++) {
        final session = await repo.startGeneratedLevel(level);
        final flow = FirstExperienceController(repo, levelNumber: level);
        expect(flow.step, FirstExperienceStep.playing);
        expect(session.puzzles.length, 3);
        if (level < 10) {
          expect(repo.state.isUnlocked(mapLevelId(level + 1)), false);
        }
        await flow.resumeGame();
        for (var game = 0; game < 3; game++) {
          expect(flow.gameIndex, game);
          expect(flow.puzzleDefinition!.difficulty, 'easy');
          await repo.addElapsed(
            session.id,
            flow.puzzleDefinition!.id,
            (game + 1) * 1000,
          );
          await solve(flow);
          if (game < 2) await flow.advance();
        }
        expect(flow.session!.status, PlayStatus.completed);
        expect(flow.session!.elapsedMs, greaterThanOrEqualTo(6000));
        expect(
          repo.state.progress[mapLevelId(level)]!.bestElapsedMs,
          flow.session!.elapsedMs,
        );
        expect(repo.state.progress[mapLevelId(level)]!.bestLights, 3);
        if (level < 10) {
          expect(repo.state.isUnlocked(mapLevelId(level + 1)), true);
        }
        await expectLater(repo.startGeneratedLevel(level), throwsStateError);
        await expectLater(
          repo.startOrResumeLevel(mapLevelId(level), restart: true),
          throwsStateError,
        );
        flow.dispose();
        await flow.flush();
      }
      expect(repo.state.modules[FirstExperienceController.moduleKey], isNull);
      await repo.close();
    },
  );

  test(
    'disk reopen restores seeds, input, selection, hints and paused session',
    () async {
      final store = MemorySaveStore();
      var repo = await GameRepository.open(store);
      await repo.recordDebugLights(mapLevelId(1), 3);
      final session = await repo.startGeneratedLevel(2);
      var flow = FirstExperienceController(repo, levelNumber: 2);
      final definitions = repo.state.puzzles.values
          .map((p) => p.toJson())
          .toList();
      await flow.resumeGame();
      final cell = flow.boardValues.indexOf(null);
      flow.selectGameCell(cell);
      for (var i = 0; i < 12; i++) {
        flow.showHelp();
        await flow.flush();
        flow.dismissHelp();
      }
      expect(flow.puzzleProgress!.hintsUsed, 12);
      final wrong = flow.puzzleDefinition!.solution[cell] % 9 + 1;
      await flow.placeGameNumber(wrong);
      expect(flow.boardValues[cell], wrong);
      expect(flow.conflicts, contains(cell));
      await repo.addElapsed(session.id, flow.puzzleDefinition!.id, 12345);
      await flow.pauseGame();
      flow.dispose();
      await flow.flush();
      await repo.close();
      repo = await GameRepository.open(store);
      final resumed = await repo.startGeneratedLevel(2);
      flow = FirstExperienceController(repo, levelNumber: 2);
      expect(resumed.id, session.id);
      expect(
        repo.state.puzzles.values.map((p) => p.toJson()).toList(),
        definitions,
      );
      expect(flow.isPaused, true);
      expect(flow.gameCell, cell);
      expect(flow.boardValues[cell], wrong);
      expect(flow.conflicts, contains(cell));
      expect(flow.puzzleProgress!.elapsedMs, greaterThanOrEqualTo(12345));
      expect(flow.puzzleProgress!.hintsUsed, 12);
      await flow.resumeGame();
      expect(flow.readyToPlay, true);
      await flow.clearGameCell();
      expect(flow.boardValues[cell], isNull);
      flow.dispose();
      await flow.flush();
      await repo.close();
    },
  );

  test(
    'manual foreground resume counts only active time and saves last move',
    () async {
      final repo = GameRepository.memory();
      await repo.recordDebugLights(mapLevelId(1), 3);
      final session = await repo.startGeneratedLevel(2);
      final clock = TestClock();
      final play = GameSessionController(
        repo,
        clock: clock,
        resumeOnForeground: false,
      );
      await play.start(session.id);
      clock.advance(1234);
      expect(play.elapsedMs, 1234);
      play.didChangeAppLifecycleState(AppLifecycleState.inactive);
      expect(play.isPaused, true);
      await play.flush();
      clock.advance(100000);
      play.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await play.flush();
      expect(play.isRunning, false);
      expect(play.elapsedMs, 1234);
      await expectLater(play.setCell(0, 1), throwsStateError);
      await play.start(session.id);
      clock.advance(2345);
      final puzzle = repo.state.puzzles[session.nextPuzzleId]!;
      final cell = puzzle.initial.indexOf(null);
      await play.setCell(cell, puzzle.solution[cell]);
      expect(repo.state.sessions[session.id]!.puzzles.first.elapsedMs, 3579);
      expect(play.elapsedMs, 3579);
      clock.advance(111);
      await play.pause();
      clock.advance(5000);
      expect(play.elapsedMs, 3690);
      play.dispose();
      await play.flush();
      await repo.close();
    },
  );

  test('failed writes keep generation atomic, retain input and cancel exit until saved', () async {
    final store = _FailingStore();
    final repo = await GameRepository.open(store);
    await expectLater(repo.startGeneratedLevel(2), throwsStateError);
    await repo.recordDebugLights(mapLevelId(1), 3);
    store.fail = true;
    await expectLater(repo.startGeneratedLevel(2), throwsStateError);
    expect(repo.state.puzzles, isEmpty);
    expect(repo.state.sessions, isEmpty);
    expect(repo.state.modules['generatedLevel/2'], isNull);
    store.fail = false;
    final session = await repo.startGeneratedLevel(2);
    final clock = TestClock();
    final play = GameSessionController(
      repo,
      clock: clock,
      resumeOnForeground: false,
    );
    await play.start(session.id);
    final puzzle = repo.state.puzzles[session.nextPuzzleId]!;
    final cell = puzzle.initial.indexOf(null);
    clock.advance(1000);
    store.fail = true;
    await expectLater(
      play.setCell(cell, puzzle.solution[cell]),
      throwsStateError,
    );
    expect(
      repo.state.sessions[session.id]!.puzzles.first.cells[cell].value,
      isNull,
    );
    expect(await play.didRequestAppExit(), AppExitResponse.cancel);
    expect(play.isRunning, false);
    store.fail = false;
    expect(await play.didRequestAppExit(), AppExitResponse.exit);
    expect(repo.state.sessions[session.id]!.elapsedMs, 1000);
    expect(repo.state.sessions[session.id]!.status, PlayStatus.paused);
    await play.start(session.id);
    await play.setCell(cell, puzzle.solution[cell]);
    expect(
      repo.state.sessions[session.id]!.puzzles.first.cells[cell].value,
      puzzle.solution[cell],
    );
    play.dispose();
    await play.flush();
    await repo.close();
  });
}
