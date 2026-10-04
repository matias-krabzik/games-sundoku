import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/save_codec.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/data/services/sqlite_save_store.dart';
import 'package:sundoku/domain/models/game_session.dart';
import 'package:sundoku/domain/models/json_data.dart';
import 'package:sundoku/domain/scoring/adventure_challenge.dart';
import 'package:sundoku/domain/scoring/sudoku_scoring.dart';
import 'package:sundoku/domain/generation/seeded_sudokus.dart';
import 'package:sundoku/playables/playables_save_codec.dart';
import 'package:sundoku/playables/playables_save_store.dart';

import 'game_repository_test.dart' show FailingStore;
import '../playables/playables_integration_test.dart' show FakePlayablesSdk;
import '../support/challenge_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('S01: reopen preserves rules, mistakes, notes, hints, active time and attempt identity', () async {
    final store = MemorySaveStore();
    var repo = await challengeRepository(store);
    final session = await startChallenge(repo);
    final id = session.nextPuzzleId!;
    await repo.activatePuzzle(session.id, id);
    await repo.setCell(session.id, id, 0, 2);
    await repo.setCell(session.id, id, 0, null);
    await repo.setNotes(session.id, id, 0, [1, 2]);
    await repo.recordHint(session.id, id, index: 1);
    await repo.addElapsed(session.id, id, 1000);
    await repo.pauseSession(session.id);
    final saved = roundBoard(repo, session.id).toJson();
    await repo.close();
    // An already frozen challenge is enforced even when rollout is disabled.
    repo = await GameRepository.open(store);
    addTearDown(repo.close);
    final resumed = await repo.startOrResumeLevel(session.levelId);
    expect(resumed.id, session.id);
    expect(resumed.rulesMode, SessionRulesMode.challenge);
    expect(roundBoard(repo, session.id).toJson(), saved);
  });

  test('S02/S03: solved below target never earns a star, all input paths reject after failure', () async {
    final repo = await challengeRepository(MemorySaveStore());
    addTearDown(repo.close);
    final session = await startChallenge(repo);
    final id = session.nextPuzzleId!;
    await repo.setCell(session.id, id, 0, 1);
    await repo.useHint(session.id, id, 1);
    final board = roundBoard(repo, session.id);
    expect(board.status, PlayStatus.failed);
    expect(board.attempt!.result!.outcome, ChallengeOutcome.belowTarget);
    expect(repo.state.sessions[session.id]!.lights, 0);
    expect(repo.state.sessions[session.id]!.points, 0);
    expect(repo.state.sessions[session.id]!.nextPuzzleId, isNull);
    expect(repo.state.isUnlocked(mapLevelId(2, worldId: 'world-3')), isFalse);
    for (final action in <Future<void> Function()>[
      () => repo.setCell(session.id, id, 0, null),
      () => repo.setNotes(session.id, id, 0, [1]),
      () => repo.toggleNote(session.id, id, 0, 1),
      () => repo.setPuzzleInputState(session.id, id, selectedIndex: 0),
      () => repo.recordHint(session.id, id),
      () => repo.useHint(session.id, id, 1),
      () => repo.activatePuzzle(session.id, id),
      () => repo.addElapsed(session.id, id, 100),
      () => repo.setCell(session.id, session.puzzles[1].puzzleId, 0, 1),
    ]) {
      await expectLater(action(), throwsStateError);
    }
  });

  test('S03/S04/S08: queued last life, retry token is idempotent and preserves first round', () async {
    final repo = await challengeRepository(MemorySaveStore(), level: 21);
    addTearDown(repo.close);
    final session = await startChallenge(repo, level: 21);
    await winRound(repo, session.id);
    await acknowledge(repo, session.id);
    final first = roundBoard(repo, session.id).toJson();
    final id = session.puzzles[1].puzzleId;
    final token = roundBoard(repo, session.id, 1).attempt!.id;
    final wrong = repo.setCell(session.id, id, 0, 2);
    final queued = repo.setCell(session.id, id, 0, 1);
    await expectLater(queued, throwsStateError);
    await wrong;
    expect(
      roundBoard(repo, session.id, 1).attempt!.result!.outcome,
      ChallengeOutcome.outOfLives,
    );
    final failedRules = roundBoard(repo, session.id, 1).attempt!.rules.toJson();
    await Future.wait([
      repo.retryRound(session.id, id, attemptId: token),
      repo.retryRound(session.id, id, attemptId: token),
    ]);
    final retried = roundBoard(repo, session.id, 1);
    expect(retried.attempt!.number, 2);
    expect(retried.attempt!.id, isNot(token));
    expect(retried.attempt!.rules.initialLives, failedRules['initialLives']);
    expect(
      retried.attempt!.rules.targetBasisPoints,
      failedRules['targetBasisPoints'],
    );
    final replacement = repo.state.puzzles[id]!;
    final empty = replacement.initial.indexOf(null);
    expect(retried.mistakes, 0);
    expect(retried.elapsedMs, 0);
    expect(retried.points, 0);
    expect(retried.hintsUsed, 0);
    expect(retried.cells[empty].value, isNull);
    expect(roundBoard(repo, session.id).toJson(), first);
    await repo.setCell(session.id, id, empty, replacement.solution[empty]);
    final definition = replacement.toJson();
    await repo.retryRound(session.id, id, attemptId: token); // delayed callback
    expect(repo.state.puzzles[id]!.toJson(), definition);
    expect(
      roundBoard(repo, session.id, 1).cells[empty].value,
      replacement.solution[empty],
    );
    await expectLater(
      repo.retryRound(session.id, id, attemptId: retried.attempt!.id),
      throwsStateError,
    );
  });

  test('S05/S11: third round failure does not complete level; successful retry awards once, no replay', () async {
    final repo = await challengeRepository(MemorySaveStore(), level: 30);
    addTearDown(repo.close);
    final session = await startChallenge(repo, level: 30);
    for (var i = 0; i < 2; i++) {
      await winRound(repo, session.id, i);
      await acknowledge(repo, session.id, i);
    }
    final id = session.puzzles[2].puzzleId;
    await repo.setCell(session.id, id, 0, 2);
    expect(repo.state.sessions[session.id]!.lights, 2);
    expect(repo.worldCompleted('world-3'), isFalse);
    expect(repo.state.progress[session.levelId]!.bestPoints, 0);
    final token = roundBoard(repo, session.id, 2).attempt!.id;
    await repo.retryRound(session.id, id, attemptId: token);
    await winRound(repo, session.id, 2);
    expect(repo.worldCompleted('world-3'), isTrue);
    final expectedPoints = repo.state.sessions[session.id]!.puzzles.fold<int>(
      0,
      (points, board) =>
          points +
          SudokuScoring.perfectScore(repo.state.puzzles[board.puzzleId]!),
    );
    expect(repo.state.sessions[session.id]!.points, expectedPoints);
    expect(repo.state.progress[session.levelId]!.bestPoints, expectedPoints);
    expect(repo.state.sessions[session.id]!.pendingResult!.puzzleId, id);
    await acknowledge(repo, session.id, 2);
    final revision = repo.state.revision;
    await acknowledge(repo, session.id, 2);
    expect(repo.state.revision, revision);
    await expectLater(
      repo.startOrResumeLevel(session.levelId),
      throwsStateError,
    );
    await expectLater(
      repo.retryRound(session.id, id, attemptId: token),
      throwsStateError,
    );
  });

  test(
    'S06: failed final/life/retry/ack write publishes no premature transition',
    () async {
      final store = FailingStore();
      final repo = await challengeRepository(store, level: 21);
      addTearDown(repo.close);
      final session = await startChallenge(repo, level: 21);
      final id = session.nextPuzzleId!;
      var before = repo.state.toJson();
      store.failNext = true;
      await expectLater(repo.setCell(session.id, id, 0, 2), throwsException);
      expect(repo.state.toJson(), before);
      await repo.setCell(session.id, id, 0, 2);
      final token = roundBoard(repo, session.id).attempt!.id;
      before = repo.state.toJson();
      store.failNext = true;
      await expectLater(
        repo.retryRound(session.id, id, attemptId: token),
        throwsException,
      );
      expect(repo.state.toJson(), before);
      await repo.retryRound(session.id, id, attemptId: token);
      final replacement = repo.state.puzzles[id]!;
      final blanks = [
        for (var i = 0; i < replacement.initial.length; i++)
          if (replacement.initial[i] == null) i,
      ];
      for (final index in blanks.take(blanks.length - 1)) {
        await repo.setCell(session.id, id, index, replacement.solution[index]);
      }
      before = repo.state.toJson();
      store.failNext = true;
      await expectLater(
        repo.setCell(
          session.id,
          id,
          blanks.last,
          replacement.solution[blanks.last],
        ),
        throwsException,
      );
      expect(repo.state.toJson(), before);
      await repo.setCell(
        session.id,
        id,
        blanks.last,
        replacement.solution[blanks.last],
      );
      before = repo.state.toJson();
      store.failNext = true;
      await expectLater(acknowledge(repo, session.id), throwsException);
      expect(repo.state.toJson(), before);
      await acknowledge(repo, session.id);
      expect(repo.state.sessions[session.id]!.lights, 1);
    },
  );

  test('S07/S08: reopen pending win, double continue and stale callbacks never skip a round', () async {
    final store = MemorySaveStore();
    var repo = await challengeRepository(store);
    final session = await startChallenge(repo);
    await winRound(repo, session.id);
    final result = roundBoard(repo, session.id).attempt!.result!.toJson();
    await repo.close();
    repo = await GameRepository.open(store, enableWorld3Challenges: true);
    addTearDown(() => repo.close());
    expect(
      repo.state.sessions[session.id]!.pendingResult!.attempt!.result!.toJson(),
      result,
    );
    await expectLater(
      repo.activatePuzzle(session.id, session.puzzles[1].puzzleId),
      throwsStateError,
    );
    await Future.wait([
      acknowledge(repo, session.id),
      acknowledge(repo, session.id),
    ]);
    await repo.setCell(session.id, session.puzzles[1].puzzleId, 0, 1);
    await acknowledge(repo, session.id);
    expect(roundBoard(repo, session.id, 1).cells[0].value, 1);
    expect(repo.state.sessions[session.id]!.lights, 1);
    await repo.close();
    repo = await GameRepository.open(store);
    expect(repo.state.sessions[session.id]!.pendingResult, isNull);
    expect(
      repo.state.sessions[session.id]!.nextPuzzleId,
      session.puzzles[1].puzzleId,
    );
  });

  for (final level in [1, 11, 21, 30]) {
    test(
      'retry level $level generates distinct solvable boards, saves and resumes exactly',
      () async {
        final store = MemorySaveStore();
        var repo = await challengeRepository(store, level: level);
        final session = await repo.startGeneratedLevel(
          level,
          worldId: 'world-3',
        );
        final id = session.puzzles.first.puzzleId;
        final otherBoards = session.puzzles
            .skip(1)
            .map((p) => p.toJson())
            .toList();
        final otherDefinitions = session.puzzles
            .skip(1)
            .map((p) => repo.state.puzzles[p.puzzleId]!.toJson())
            .toList();
        final seeds = <String>{};
        final solutions = <String>{};
        final layouts = <String>{};
        for (var retry = 0; retry < 4; retry++) {
          final old = repo.state.puzzles[id]!;
          seeds.add(old.seed);
          solutions.add(old.solution.join());
          layouts.add(old.initial.join(','));
          final board = roundBoard(repo, session.id);
          final token = board.attempt!.id;
          await repo.addElapsed(
            session.id,
            id,
            board.attempt!.rules.timeLimitMs,
          );
          await repo.retryRound(session.id, id, attemptId: token);
          final puzzle = repo.state.puzzles[id]!;
          expect(seeds.contains(puzzle.seed), false);
          expect(solutions.contains(puzzle.solution.join()), false);
          expect(layouts.contains(puzzle.initial.join(',')), false);
          expect(puzzle.difficulty, old.difficulty);
          expect(puzzle.initial.where((v) => v == null).length, 38);
          expect(
            SeededSudokus.solveWithSingles(
              puzzle.initial.map((v) => v ?? 0).toList(),
            ),
            puzzle.solution,
          );
          expect(
            SeededSudokus.hasUniqueSolution(
              puzzle.initial.map((v) => v ?? 0).toList(),
            ),
            true,
          );
          final rules = roundBoard(repo, session.id).attempt!.rules;
          expect(
            rules.targetBasisPoints,
            board.attempt!.rules.targetBasisPoints,
          );
          expect(rules.initialLives, board.attempt!.rules.initialLives);
          expect(rules.timeLimitMs, board.attempt!.rules.timeLimitMs);
          expect(rules.perfectPoints, SudokuScoring.perfectScore(puzzle));
          expect(rules.targetPoints, lessThanOrEqualTo(rules.perfectPoints));
          expect(
            repo.state.sessions[session.id]!.puzzles
                .skip(1)
                .map((p) => p.toJson())
                .toList(),
            otherBoards,
          );
          expect(
            session.puzzles
                .skip(1)
                .map((p) => repo.state.puzzles[p.puzzleId]!.toJson())
                .toList(),
            otherDefinitions,
          );
          final savedBoard = roundBoard(repo, session.id).toJson();
          final savedPuzzle = puzzle.toJson();
          await repo.close();
          repo = await GameRepository.open(store, enableWorld3Challenges: true);
          await repo.startGeneratedLevel(level, worldId: 'world-3');
          expect(repo.state.puzzles[id]!.toJson(), savedPuzzle);
          expect(roundBoard(repo, session.id).toJson(), savedBoard);
        }
        await winRound(repo, session.id);
        expect(
          roundBoard(repo, session.id).attempt!.result!.outcome,
          ChallengeOutcome.won,
        );
        expect(repo.state.sessions[session.id]!.lights, 1);
        await repo.close();
      },
    );
  }

  test('map acknowledges intermediate victories only, without starting the next clock', () async {
    final repo = await challengeRepository(MemorySaveStore());
    addTearDown(repo.close);
    final session = await startChallenge(repo);
    for (var round = 0; round < 3; round++) {
      await winRound(repo, session.id, round);
      final result = roundBoard(
        repo,
        session.id,
        round,
      ).attempt!.result!.toJson();
      await repo.acknowledgeIntermediateWin(session.id);
      await repo.acknowledgeIntermediateWin(session.id);
      expect(repo.state.sessions[session.id]!.lights, round + 1);
      expect(
        roundBoard(repo, session.id, round).attempt!.result!.toJson(),
        result,
      );
      if (round < 2) {
        expect(repo.state.sessions[session.id]!.pendingResult, isNull);
        expect(roundBoard(repo, session.id, round + 1).elapsedMs, 0);
      } else {
        expect(repo.state.sessions[session.id]!.pendingResult, isNotNull);
      }
    }
  });
  test(
    'map acknowledgement preserves failure and rolls back a failed write',
    () async {
      final store = FailingStore();
      final repo = await challengeRepository(store);
      addTearDown(repo.close);
      final session = await startChallenge(repo);
      await winRound(repo, session.id);
      final saved = repo.state.toJson();
      store.failNext = true;
      await expectLater(
        repo.acknowledgeIntermediateWin(session.id),
        throwsException,
      );
      expect(repo.state.toJson(), saved);
      await repo.acknowledgeIntermediateWin(session.id);
      final board = roundBoard(repo, session.id, 1);
      await repo.addElapsed(
        session.id,
        board.puzzleId,
        board.attempt!.rules.timeLimitMs,
      );
      final failed = repo.state.toJson();
      await repo.acknowledgeIntermediateWin(session.id);
      expect(repo.state.toJson(), failed);
    },
  );

  test('S09/S10: legacy migration keeps whole session unrestricted, next session opts in', () async {
    final raw = await File(
      'test/fixtures/world3-baseline/world-3-in-progress.json',
    ).readAsString();
    final store = MemorySaveStore();
    // Memory store revisions start at zero; keep this fixture import isolated.
    final json = jsonObject(jsonDecode(raw));
    json['revision'] = 0;
    await store.write(jsonEncode(json), expectedRevision: -1);
    final repo = await GameRepository.open(store, enableWorld3Challenges: true);
    addTearDown(repo.close);
    final session = repo.state.sessions.values.single;
    expect(session.rulesMode, SessionRulesMode.legacy);
    expect(session.puzzles.every((p) => p.attempt == null), isTrue);
    final board = session.puzzles.last;
    final puzzle = repo.state.puzzles[board.puzzleId]!;
    await repo.addElapsed(session.id, board.puzzleId, 9999999);
    for (var i = 0; i < puzzle.initial.length; i++) {
      if (puzzle.initial[i] == null &&
          roundBoard(repo, session.id, 2).cells[i].value !=
              puzzle.solution[i]) {
        await repo.useHint(session.id, board.puzzleId, i);
      }
    }
    expect(repo.state.sessions[session.id]!.lights, 3);
    final next = await repo.startGeneratedLevel(2, worldId: 'world-3');
    expect(next.rulesMode, SessionRulesMode.challenge);
    expect(next.puzzles.every((p) => p.attempt != null), isTrue);
  });

  test('S10: idempotent codec preserves unknown fields and rejects missing/corrupt challenge state', () async {
    final repo = await challengeRepository(MemorySaveStore());
    addTearDown(repo.close);
    final session = await startChallenge(repo);
    final base = repo.state.toJson();
    Json copy() => jsonObject(jsonDecode(jsonEncode(base)));
    final json = copy();
    json['futureRoot'] = {'x': 1};
    final savedSession = (json['sessions'] as Map)[session.id] as Map;
    savedSession['futureSession'] = true;
    final attempt =
        ((savedSession['puzzles'] as List).first as Map)['attempt'] as Map;
    attempt['futureAttempt'] = 7;
    (attempt['rules'] as Map)['futureRules'] = 'kept';
    const codec = SaveCodec();
    final decoded = codec.decode(jsonEncode(json));
    expect(codec.decode(codec.encode(decoded)).toJson(), decoded.toJson());
    expect(decoded.extra['futureRoot'], {'x': 1});
    expect(decoded.sessions[session.id]!.extra['futureSession'], true);
    expect(
      decoded
          .sessions[session.id]!
          .puzzles
          .first
          .attempt!
          .extra['futureAttempt'],
      7,
    );
    expect(
      decoded
          .sessions[session.id]!
          .puzzles
          .first
          .attempt!
          .rules
          .extra['futureRules'],
      'kept',
    );
    for (final corrupt in <void Function(Map)>[
      (s) => s.remove('rulesMode'),
      (s) => ((s['puzzles'] as List).first as Map).remove('attempt'),
      (s) => ((((s['puzzles'] as List).first as Map)['attempt'] as Map).remove(
        'rules',
      )),
      (s) =>
          (((((s['puzzles'] as List).first as Map)['attempt'] as Map)['rules']
                  as Map)['version'] =
              'future-v99'),
    ]) {
      final invalid = copy();
      corrupt((invalid['sessions'] as Map)[session.id] as Map);
      final store = MemorySaveStore();
      invalid['revision'] = 0;
      final source = jsonEncode(invalid);
      await store.write(source, expectedRevision: -1);
      await expectLater(
        GameRepository.open(store),
        throwsA(anyOf(isA<FormatException>(), isA<TypeError>())),
      );
      expect(await store.read(), source);
    }
  });

  test('S10: mismatched result and missing terminal outcome cannot bypass validation', () async {
    final repo = await challengeRepository(MemorySaveStore());
    addTearDown(repo.close);
    final session = await startChallenge(repo);
    await winRound(repo, session.id);
    final source = const SaveCodec().encode(repo.state);
    for (final corruption in ['points', 'result', 'status', 'time', 'lives']) {
      final json = jsonObject(jsonDecode(source));
      final stored = (json['sessions'] as Map)[session.id] as Map;
      final board = (stored['puzzles'] as List).first as Map;
      final attempt = board['attempt'] as Map;
      switch (corruption) {
        case 'points':
          (attempt['result'] as Map)['points'] = 0;
        case 'result':
          attempt['result'] = null;
        case 'status':
          board['status'] = 'paused';
          board['completedAt'] = null;
        case 'time':
          board['elapsedMs'] = (attempt['rules'] as Map)['timeLimitMs'];
        case 'lives':
          (attempt['rules'] as Map)['initialLives'] = 1;
      }
      expect(
        () => const SaveCodec().decode(jsonEncode(json)),
        throwsFormatException,
        reason: corruption,
      );
    }
  });

  test('S12: Playables cloud failure retries the same outcome without duplicate rewards', () async {
    final seed = await challengeRepository(MemorySaveStore());
    final session = await startChallenge(seed);
    final sdk = FakePlayablesSdk()..data = const SaveCodec().encode(seed.state);
    await seed.close();
    final cloud = PlayablesSaveStore(sdk);
    final repo = await GameRepository.open(
      cloud,
      codec: const PlayablesSaveCodec(),
    );
    await winRound(repo, session.id);
    final result = roundBoard(repo, session.id).attempt!.result!.toJson();
    sdk.nextSaveError = const FileSystemException('Cloud unavailable');
    await expectLater(cloud.flush(), throwsException);
    expect(repo.state.sessions[session.id]!.lights, 1);
    expect(cloud.lastSaveError, isNotNull);
    await cloud.flush();
    expect(cloud.lastSaveError, isNull);
    final decoded = const PlayablesSaveCodec().decode(sdk.saves.single);
    expect(decoded.sessions[session.id]!.lights, 1);
    expect(
      decoded.sessions[session.id]!.puzzles.first.attempt!.result!.toJson(),
      result,
    );
    await repo.close();
  });

  test(
    'level 30 hints are rejected without charging; notes remain free',
    () async {
      final repo = await challengeRepository(MemorySaveStore(), level: 30);
      addTearDown(repo.close);
      final session = await startChallenge(repo, level: 30);
      final id = session.nextPuzzleId!;
      await repo.setNotes(session.id, id, 0, [1, 2]);
      final before = roundBoard(repo, session.id).toJson();
      await expectLater(repo.useHint(session.id, id, 0), throwsStateError);
      await expectLater(
        repo.recordHint(session.id, id, index: 0),
        throwsStateError,
      );
      expect(roundBoard(repo, session.id).toJson(), before);
    },
  );

  test('S12: SQLite disk reopen and web/Playables codec preserve the exact pending result', () async {
    sqfliteFfiInit();
    final directory = await Directory.systemTemp.createTemp(
      'sundoku-challenge-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/save.db';
    var store = await SqliteSaveStore.open(databaseFactoryFfi, path);
    var repo = await challengeRepository(store);
    final session = await startChallenge(repo);
    await winRound(repo, session.id);
    final expected = roundBoard(repo, session.id).toJson();
    final source = const SaveCodec().encode(repo.state);
    expect(
      const PlayablesSaveCodec()
          .decode(source)
          .sessions[session.id]!
          .puzzles
          .first
          .toJson(),
      expected,
    );
    await repo.close();
    store = await SqliteSaveStore.open(databaseFactoryFfi, path);
    repo = await GameRepository.open(store);
    expect(roundBoard(repo, session.id).toJson(), expected);
    await repo.close();
    final sdk = FakePlayablesSdk()..data = source;
    var cloud = PlayablesSaveStore(sdk);
    repo = await GameRepository.open(cloud, codec: const PlayablesSaveCodec());
    await acknowledge(repo, session.id);
    await repo.close();
    sdk.data = sdk.saves.last;
    cloud = PlayablesSaveStore(sdk);
    repo = await GameRepository.open(cloud, codec: const PlayablesSaveCodec());
    expect(roundBoard(repo, session.id).attempt!.acknowledged, isTrue);
    expect(
      roundBoard(repo, session.id).attempt!.result!.toJson(),
      expected['attempt'] is Map
          ? (expected['attempt'] as Map)['result']
          : null,
    );
    expect(repo.state.sessions[session.id]!.lights, 1);
    await repo.close();
  });
}
