import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/save_codec.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/domain/models/game_session.dart';
import 'package:sundoku/domain/scoring/adventure_challenge.dart';

import 'game_repository_test.dart' show FailingStore;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DEV completion persists one world at a time and satisfies river challenges', () async {
    final store = MemorySaveStore();
    final repo = await GameRepository.open(store, enableWorld3Challenges: true);
    addTearDown(repo.close);
    await repo.completeDebugLevel(1, random: Random(7));
    final first = repo.state.progress['world-1/level-1'];
    final firstSession = repo.state.sessions.values.single;
    for (var world = 1; world <= 3; world++) {
      final before = repo.state.revision;
      expect(
        await repo.completeNextDebugWorld(random: Random(world)),
        'world-$world',
      );
      expect(repo.state.revision, before + 1);
      expect(repo.worldCompleted('world-$world'), isTrue);
      if (world < 3) {
        expect(repo.isWorldUnlocked('world-${world + 1}'), isTrue);
        expect(repo.worldCompleted('world-${world + 1}'), isFalse);
      }
      if (world == 1) expect(repo.isWorldUnlocked('world-3'), isFalse);
      // Decode the actual persisted save, including all rule/result validation.
      final saved = const SaveCodec().decode((await store.read())!);
      expect(
        saved.progress.length,
        world == 1
            ? 10
            : world == 2
            ? 30
            : 60,
      );
    }
    expect(repo.state.progress['world-1/level-1'], same(first));
    expect(repo.state.sessions[firstSession.id], same(firstSession));
    final rivers = repo.state.sessions.values.where(
      (s) => s.levelId.startsWith('world-3/'),
    );
    expect(rivers.length, 30);
    for (final session in rivers) {
      expect(session.rulesMode, SessionRulesMode.challenge);
      expect(session.pendingResult, isNull);
      for (final board in session.puzzles) {
        final attempt = board.attempt!;
        expect(attempt.result!.outcome, ChallengeOutcome.won);
        expect(board.points, attempt.rules.perfectPoints);
        expect(board.mistakes, 0);
        expect(board.hintsUsed, 0);
        expect(board.elapsedMs, lessThan(attempt.rules.timeLimitMs));
      }
    }
    final revision = repo.state.revision;
    expect(await repo.completeNextDebugWorld(), isNull);
    expect(repo.state.revision, revision);
  });

  test('failed save leaves the world locked and can be retried', () async {
    final store = FailingStore();
    final repo = await GameRepository.open(store);
    addTearDown(repo.close);
    final before = repo.state;
    store.failNext = true;
    await expectLater(
      repo.completeNextDebugWorld(),
      throwsA(isA<FileSystemException>()),
    );
    expect(repo.state, same(before));
    expect(repo.isWorldUnlocked('world-2'), isFalse);
    store.failNext = false;
    expect(await repo.completeNextDebugWorld(), 'world-1');
  });

  test('existing last-round shortcut retains world-three rules', () async {
    final repo = GameRepository.memory(enableWorld3Challenges: true);
    addTearDown(repo.close);
    await repo.completeNextDebugWorld();
    await repo.completeNextDebugWorld();
    await repo.completeDebugWorldExceptLastPuzzle(worldId: 'world-3');
    final session = repo.state.sessions[repo.state.activeSessionId]!;
    expect(session.rulesMode, SessionRulesMode.challenge);
    expect(session.lights, 2);
    expect(session.nextPuzzleId, session.puzzles.last.puzzleId);
    expect(session.puzzles.last.attempt!.result, isNull);
    expect(session.puzzles.last.attempt!.rules.level, 30);
  });
}
