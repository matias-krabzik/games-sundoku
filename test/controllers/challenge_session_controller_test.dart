import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/controllers/game_session_controller.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/domain/models/game_session.dart';
import 'package:sundoku/domain/scoring/adventure_challenge.dart';
import 'package:sundoku/playables/playables_runtime.dart';

import 'game_session_controller_test.dart' show TestClock;
import '../data/game_repository_test.dart' show FailingStore;
import '../playables/playables_integration_test.dart' show FakePlayablesSdk;
import '../support/challenge_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final offset in [-1, 0, 1]) {
    test(
      'S13: last input at deadline offset $offset ms is ordered after active-time checkpoint',
      () async {
        final repo = await challengeRepository(MemorySaveStore());
        final session = await startChallenge(repo);
        final clock = TestClock();
        final controller = GameSessionController(repo, clock: clock);
        addTearDown(() async {
          controller.dispose();
          await controller.flush();
          await repo.close();
        });
        await controller.start(session.id);
        await controller.setCell(0, 1);
        clock.advance(
          session.puzzles.first.attempt!.rules.timeLimitMs + offset,
        );
        await controller.setCell(1, 2);
        final board = roundBoard(repo, session.id);
        expect(
          board.attempt!.result!.outcome,
          offset < 0 ? ChallengeOutcome.won : ChallengeOutcome.outOfTime,
        );
        expect(board.cells[1].value, offset < 0 ? 2 : null);
        expect(repo.state.sessions[session.id]!.lights, offset < 0 ? 1 : 0);
        expect(controller.isRunning, isFalse);
        expect(controller.acceptingInput, isFalse);
        await expectLater(controller.setCell(1, 2), throwsStateError);
        await controller.start(session.id);
        expect(controller.isRunning, isFalse);
      },
    );
  }

  test('S13: queued elapsed expiry prevents subsequent repository move and survives pause', () async {
    final repo = await challengeRepository(MemorySaveStore());
    addTearDown(repo.close);
    final session = await startChallenge(repo);
    final board = session.puzzles.first;
    final expires = repo.addElapsed(
      session.id,
      board.puzzleId,
      board.attempt!.rules.timeLimitMs,
    );
    final queued = repo.setCell(session.id, board.puzzleId, 0, 1);
    await expectLater(queued, throwsStateError);
    await expires;
    await repo.pauseSession(session.id);
    expect(
      roundBoard(repo, session.id).attempt!.result!.outcome,
      ChallengeOutcome.outOfTime,
    );
    final resumed = await repo.startOrResumeLevel(session.levelId);
    expect(resumed.puzzles.first.elapsedMs, board.attempt!.rules.timeLimitMs);
    expect(resumed.pendingResult, isNotNull);
    await repo.retryRound(
      session.id,
      board.puzzleId,
      attemptId: board.attempt!.id,
    );
    expect(roundBoard(repo, session.id).elapsedMs, 0);
  });

  test('S14: pause/background exclude inactive time; expiration save failure retains checkpoint', () async {
    final store = FailingStore();
    final repo = await challengeRepository(store);
    final session = await startChallenge(repo);
    final clock = TestClock();
    final controller = GameSessionController(repo, clock: clock);
    addTearDown(() async {
      controller.dispose();
      await controller.flush();
      await repo.close();
    });
    await controller.start(session.id);
    clock.advance(2000);
    await controller.pause();
    clock.advance(5000000);
    await controller.start(session.id);
    clock.advance(1000);
    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    await controller.flush();
    clock.advance(5000000);
    expect(roundBoard(repo, session.id).elapsedMs, 3000);
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await controller.flush();
    clock.advance(session.puzzles.first.attempt!.rules.timeLimitMs - 3000);
    store.failNext = true;
    await expectLater(controller.pause(), throwsA(isA<FileSystemException>()));
    expect(roundBoard(repo, session.id).elapsedMs, 3000);
    expect(roundBoard(repo, session.id).attempt!.result, isNull);
    expect(controller.isRunning, isFalse);
    await controller.checkpoint();
    expect(
      roundBoard(repo, session.id).attempt!.result!.outcome,
      ChallengeOutcome.outOfTime,
    );
    expect(repo.state.sessions[session.id]!.lights, 0);
    expect(controller.lastError, isNull);
  });

  testWidgets(
    'S13: deadline timer expires without another tap or five-second checkpoint',
    (tester) async {
      final repo = await challengeRepository(MemorySaveStore());
      final session = await startChallenge(repo);
      final board = session.puzzles.first;
      await repo.addElapsed(
        session.id,
        board.puzzleId,
        board.attempt!.rules.timeLimitMs - 100,
      );
      final clock = TestClock();
      final controller = GameSessionController(
        repo,
        clock: clock,
        checkpointInterval: const Duration(hours: 1),
      );
      await controller.start(session.id);
      clock.advance(100);
      await tester.pump(const Duration(milliseconds: 100));
      await controller.flush();
      expect(roundBoard(repo, session.id).status, PlayStatus.failed);
      expect(controller.isRunning, isFalse);
      controller.dispose();
      await controller.flush();
      await repo.close();
    },
  );

  test(
    'S14: Playables host suspension excludes hidden time on a challenge',
    () async {
      final repo = await challengeRepository(MemorySaveStore());
      final session = await startChallenge(repo);
      final sdk = FakePlayablesSdk();
      final runtime = PlayablesRuntime(sdk);
      final clock = TestClock();
      final controller = GameSessionController(
        repo,
        clock: clock,
        playables: runtime,
      );
      addTearDown(() async {
        controller.dispose();
        await controller.flush();
        runtime.dispose();
        await repo.close();
      });
      await controller.start(session.id);
      clock.advance(1000);
      sdk.pause();
      await controller.flush();
      clock.advance(5000000);
      sdk.resume();
      await controller.flush();
      clock.advance(500);
      await controller.pause();
      expect(roundBoard(repo, session.id).elapsedMs, 1500);
      expect(roundBoard(repo, session.id).attempt!.result, isNull);
    },
  );
}
