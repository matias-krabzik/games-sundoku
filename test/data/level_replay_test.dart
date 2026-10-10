import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/save_codec.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/data/world_catalog.dart';
import 'package:sundoku/domain/models/game_session.dart';

import '../support/world3_baseline.dart';
import 'game_repository_test.dart' show FailingStore;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final (world, level) in [
    ('world-2', 1),
    ('world-2', 20),
    ('world-3', 1),
    ('world-3', 30),
  ]) {
    test(
      '$world level $level replays fresh and resumes after reopening',
      () async {
        final store = MemorySaveStore();
        await store.write(
          const SaveCodec().encode(baselineSave(completedWorlds: 3)),
          expectedRevision: -1,
        );
        var repo = await GameRepository.open(
          store,
          enableWorld3Challenges: true,
        );
        await repo.completeDebugLevel(level, worldId: world);
        final key = adventureModuleKey(world, level);
        final completedId =
            (repo.state.modules[key] as Map)['sessionId'] as String;
        final completed = repo.state.sessions[completedId]!.toJson();
        final progress = repo.state.progress.map(
          (id, record) => MapEntry(id, record.toJson()),
        );
        final totalLights = repo.state.totalLights;
        final totalPoints = repo.state.totalPoints;

        final replay = await repo.startGeneratedLevel(level, worldId: world);
        expect(replay.id, isNot(completedId));
        expect(replay.lights, 0);
        expect(replay.points, 0);
        expect(replay.elapsedMs, 0);
        expect(replay.pendingResult, isNull);
        expect(replay.nextPuzzleId, replay.puzzles.first.puzzleId);
        final flow = FirstExperienceController(
          repo,
          worldId: world,
          levelNumber: level,
        );
        expect(flow.gameIndex, 0);
        expect(flow.isPaused, isFalse);
        expect(
          flow.step,
          world == 'world-3'
              ? FirstExperienceStep.challengeReady
              : FirstExperienceStep.playing,
        );
        flow.dispose();
        await flow.flush();
        for (final board in replay.puzzles) {
          expect(board.status, PlayStatus.pending);
          expect(board.mistakes, 0);
          expect(board.hintsUsed, 0);
          expect(
            board.cells.map((cell) => cell.value).toList(),
            repo.state.puzzles[board.puzzleId]!.initial,
          );
          if (world == 'world-3') {
            expect(board.attempt!.result, isNull);
            expect(board.attempt!.acknowledged, isFalse);
          }
        }
        expect(repo.state.sessions[completedId]!.toJson(), completed);
        expect(
          repo.state.progress.map(
            (id, record) => MapEntry(id, record.toJson()),
          ),
          progress,
        );
        expect(repo.state.totalLights, totalLights);
        expect(repo.state.totalPoints, totalPoints);
        expect(repo.worldCompleted(world), isTrue);

        final puzzle = repo.state.puzzles[replay.nextPuzzleId]!;
        final cell = puzzle.initial.indexOf(null);
        await repo.setCell(replay.id, puzzle.id, cell, puzzle.solution[cell]);
        await repo.addElapsed(replay.id, puzzle.id, 1234);
        if (world == 'world-3') {
          final attempt = replay.puzzles.first.attempt!;
          await repo.addElapsed(
            replay.id,
            puzzle.id,
            attempt.rules.timeLimitMs,
          );
          expect(
            repo.state.sessions[replay.id]!.pendingResult!.status,
            PlayStatus.failed,
          );
          await repo.retryRound(replay.id, puzzle.id, attemptId: attempt.id);
          expect(repo.state.sessions[replay.id]!.pendingResult, isNull);
          expect(repo.state.sessions[completedId]!.toJson(), completed);
        }
        await repo.pauseSession(replay.id);
        final saved = repo.state.sessions[replay.id]!.toJson();
        await repo.close();
        repo = await GameRepository.open(store, enableWorld3Challenges: true);
        addTearDown(repo.close);
        final resumed = await repo.startGeneratedLevel(level, worldId: world);
        expect(resumed.id, replay.id);
        expect(resumed.toJson(), saved);
        expect(repo.state.sessions[completedId]!.toJson(), completed);
        expect(repo.state.totalLights, totalLights);
        expect(repo.state.totalPoints, totalPoints);
      },
    );
  }

  test(
    'a failed replay save leaves the completed attempt and records intact',
    () async {
      final store = FailingStore();
      await store.write(
        const SaveCodec().encode(baselineSave(completedWorlds: 3)),
        expectedRevision: -1,
      );
      final repo = await GameRepository.open(store);
      addTearDown(repo.close);
      await repo.completeDebugLevel(2, worldId: 'world-2');
      final before = repo.state.toJson();
      store.failNext = true;
      await expectLater(
        repo.startGeneratedLevel(2, worldId: 'world-2'),
        throwsException,
      );
      expect(repo.state.toJson(), before);
      final replay = await repo.startGeneratedLevel(2, worldId: 'world-2');
      expect(replay.lights, 0);
      expect(repo.state.progress[replay.levelId]!.bestLights, 3);
    },
  );
}
