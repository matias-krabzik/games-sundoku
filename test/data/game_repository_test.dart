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
import 'package:sundoku/domain/models/sudoku_definition.dart';

import '../fixtures.dart';

class FailingStore extends MemorySaveStore {
  bool failNext = false;

  @override
  Future<void> write(String data, {required int expectedRevision}) async {
    if (failNext) {
      failNext = false;
      throw const FileSystemException('Simulated full disk');
    }
    await super.write(data, expectedRevision: expectedRevision);
  }
}

Future<void> solve(GameRepository repo, String session, String puzzle) async {
  await repo.setCell(session, puzzle, 0, 1);
  await repo.setCell(session, puzzle, 1, 2);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dev rewind persists the board and selected game atomically', () async {
    final store = FailingStore();
    final repo = await GameRepository.open(store);
    addTearDown(repo.close);
    final session = await repo.startOrResumeLevel(
      mapLevelId(1),
      definitions: levelPuzzles(),
    );
    await solve(repo, session.id, session.puzzles.first.puzzleId);
    await repo.saveModule('firstExperience', {'gameIndex': 1});
    final before = repo.state;
    store.failNext = true;
    await expectLater(
      repo.debugRestartPuzzle(
        session.id,
        0,
        moduleKey: 'firstExperience',
        moduleData: {'gameIndex': 0},
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(repo.state, same(before));
    await repo.debugRestartPuzzle(
      session.id,
      0,
      moduleKey: 'firstExperience',
      moduleData: {'gameIndex': 0},
    );
    final restored = const SaveCodec().decode((await store.read())!);
    expect(restored.modules['firstExperience'], {'gameIndex': 0});
    expect(
      restored.sessions[session.id]!.puzzles.first.cells.map((c) => c.value),
      levelPuzzles().first.initial,
    );
    expect(restored.totalLights, 1);
    await expectLater(
      repo.debugRestartPuzzle(
        session.id,
        0,
        moduleKey: 'firstExperience',
        moduleData: {},
      ),
      throwsStateError,
    );
  });

  test(
    'dev fill saves one incomplete board atomically and preserves fixed cells',
    () async {
      final store = FailingStore();
      final repo = await GameRepository.open(store);
      addTearDown(repo.close);
      final session = await repo.startOrResumeLevel(
        mapLevelId(1),
        definitions: levelPuzzles(),
      );
      final puzzle = session.nextPuzzleId!;
      await repo.activatePuzzle(session.id, puzzle);
      await repo.setCell(session.id, puzzle, 0, 4);
      await repo.setNotes(session.id, puzzle, 1, [2, 3]);
      final before = repo.state;
      store.failNext = true;
      await expectLater(
        repo.debugFillExceptCell(session.id, puzzle, 1),
        throwsA(isA<FileSystemException>()),
      );
      expect(repo.state, same(before));
      var notifications = 0;
      repo.addListener(() => notifications++);
      await repo.debugFillExceptCell(session.id, puzzle, 1);
      expect(notifications, 1);
      final board = repo.state.sessions[session.id]!.puzzles.first;
      expect(board.cells.map((c) => c.value), [
        1,
        null,
        ...smallSolution.skip(2),
      ]);
      expect(
        board.cells.every((c) => !c.errorRevealed && c.notes.isEmpty),
        true,
      );
      expect(board.status, PlayStatus.active);
      expect(board.mistakes, 1);
      expect(repo.state.totalLights, 0);
      for (var i = 2; i < 16; i++) {
        expect(
          board.cells[i],
          same(before.sessions[session.id]!.puzzles.first.cells[i]),
        );
      }
      await expectLater(
        repo.debugFillExceptCell(session.id, puzzle, 2),
        throwsStateError,
      );
      expect(notifications, 1);
      final saved = await store.read();
      expect(
        const SaveCodec()
            .decode(saved!)
            .sessions[session.id]!
            .puzzles
            .first
            .cells[1]
            .value,
        isNull,
      );
    },
  );

  test('SQLite reopen preserves profile, settings, notes, mistakes, hints and time', () async {
    final directory = await Directory.systemTemp.createTemp('sundoku-save-');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/save.db';
    var repo = await GameRepository.open(
      await SqliteSaveStore.open(databaseFactoryFfi, path),
    );
    final playerId = repo.state.player.id;
    expect(repo.state.player.name, 'Jugador');
    expect(repo.state.player.nameChosen, false);
    await repo.setPlayerName('  Sol  ');
    await repo.updateSettings(sound: false, music: false);
    await repo.registerPuzzles(mapLevelId(1), levelPuzzles());
    final session = await repo.startOrResumeLevel(mapLevelId(1));
    final puzzle = session.nextPuzzleId!;
    await repo.activatePuzzle(session.id, puzzle);
    await repo.setCell(session.id, puzzle, 0, 4);
    await repo.setCell(
      session.id,
      puzzle,
      0,
      4,
    ); // no extra mistake for duplicate input
    await repo.setNotes(session.id, puzzle, 1, [2, 3]);
    await repo.addElapsed(session.id, puzzle, 12345);
    await repo.saveModule('story', {
      'sceneId': 'intro-2',
      'seen': ['intro-1'],
    });
    await repo.close();

    repo = await GameRepository.open(
      await SqliteSaveStore.open(databaseFactoryFfi, path),
    );
    addTearDown(repo.close);
    expect(repo.state.player.id, playerId);
    expect(repo.state.player.name, 'Sol');
    expect(repo.state.player.nameChosen, true);
    expect(repo.state.settings.sound, false);
    expect(repo.state.settings.music, false);
    final resumed = await repo.startOrResumeLevel(mapLevelId(1));
    expect(resumed.id, session.id);
    expect(resumed.status, PlayStatus.paused);
    final board = resumed.puzzles.first;
    expect(board.cells[0].value, 4);
    expect(board.cells[0].errorRevealed, true);
    expect(board.cells[1].notes, [2, 3]);
    expect(board.mistakes, 1);
    expect(board.elapsedMs, 12345);
    expect(repo.state.modules['story'], {
      'sceneId': 'intro-2',
      'seen': ['intro-1'],
    });
    await repo.useHint(session.id, puzzle, 0);
    expect(repo.state.sessions[session.id]!.puzzles.first.hintsUsed, 1);
    expect(
      repo.state.sessions[session.id]!.puzzles.first.cells.first.source,
      ValueSource.hint,
    );
    expect(repo.state.puzzles[puzzle]!.seed, '1-1');
  });

  test('three completions award three lights, resume keeps them, replay keeps boards and records', () async {
    final store = MemorySaveStore();
    var repo = await GameRepository.open(store);
    await repo.registerPuzzles(mapLevelId(1), levelPuzzles());
    var session = await repo.startOrResumeLevel(mapLevelId(1));
    await solve(repo, session.id, session.puzzles.first.puzzleId);
    expect(repo.state.totalLights, 1);
    expect(repo.state.isUnlocked(mapLevelId(2)), false);
    await repo.close();
    repo = await GameRepository.open(store);
    addTearDown(repo.close);
    session = await repo.startOrResumeLevel(mapLevelId(1));
    expect(session.lights, 1);
    expect(session.nextPuzzleId, session.puzzles[1].puzzleId);
    for (final puzzle in session.puzzles.skip(1)) {
      await solve(repo, session.id, puzzle.puzzleId);
    }
    expect(repo.state.totalLights, 3);
    expect(repo.state.isUnlocked(mapLevelId(2)), true);
    expect(repo.state.sessions[session.id]!.status, PlayStatus.completed);
    expect(repo.state.activeSessionId, isNull);
    final definitions = repo.state.puzzles.map(
      (id, puzzle) => MapEntry(id, puzzle.toJson()),
    );
    final replay = await repo.startOrResumeLevel(mapLevelId(1));
    expect(replay.id, isNot(session.id));
    expect(replay.lights, 0);
    expect(repo.state.totalLights, 3);
    expect(
      repo.state.puzzles.map((id, puzzle) => MapEntry(id, puzzle.toJson())),
      definitions,
    );
    expect(repo.state.progress[mapLevelId(1)]!.firstCompletedAt, isNotNull);
    await solve(repo, replay.id, replay.puzzles.first.puzzleId);
    expect(repo.state.totalLights, 3);
  });

  test(
    'failed final move leaves board and reward unchanged; retry saves both',
    () async {
      final store = FailingStore();
      final repo = await GameRepository.open(store);
      addTearDown(repo.close);
      await repo.registerPuzzles(mapLevelId(1), levelPuzzles());
      final session = await repo.startOrResumeLevel(mapLevelId(1));
      final puzzle = session.nextPuzzleId!;
      await repo.setCell(session.id, puzzle, 0, 1);
      final before = repo.state.toJson();
      store.failNext = true;
      await expectLater(
        repo.setCell(session.id, puzzle, 1, 2),
        throwsA(isA<FileSystemException>()),
      );
      expect(repo.state.toJson(), before);
      expect(repo.state.totalLights, 0);
      expect(const SaveCodec().decode((await store.read())!).totalLights, 0);
      await repo.setCell(session.id, puzzle, 1, 2);
      expect(repo.state.totalLights, 1);
      expect(
        const SaveCodec()
            .decode((await store.read())!)
            .sessions[session.id]!
            .lights,
        1,
      );
      await expectLater(
        repo.setCell(session.id, puzzle, 1, 2),
        throwsStateError,
      );
      expect(repo.state.totalLights, 1);
    },
  );

  test(
    'rapid independent writes are serialized without losing changes',
    () async {
      final repo = GameRepository.memory();
      addTearDown(repo.close);
      await Future.wait([
        repo.updateSettings(sound: false),
        repo.updateSettings(music: false),
        repo.setPlayerName('Ana'),
        repo.saveModule('tutorial', {'completed': true}),
      ]);
      expect(repo.state.settings.sound, false);
      expect(repo.state.settings.music, false);
      expect(repo.state.player.name, 'Ana');
      expect(repo.state.modules['tutorial'], {'completed': true});
    },
  );

  test('fixed cells, invalid numbers, locked levels and changed seeds are rejected', () async {
    final repo = GameRepository.memory();
    addTearDown(repo.close);
    final puzzles = levelPuzzles();
    await repo.registerPuzzles(mapLevelId(1), puzzles);
    await expectLater(repo.startOrResumeLevel(mapLevelId(2)), throwsStateError);
    final session = await repo.startOrResumeLevel(mapLevelId(1));
    final id = session.nextPuzzleId!;
    await expectLater(repo.setCell(session.id, id, 2, 1), throwsStateError);
    await expectLater(
      repo.setCell(session.id, id, 0, 5),
      throwsFormatException,
    );
    await expectLater(
      repo.setNotes(session.id, id, 0, [0]),
      throwsFormatException,
    );
    await expectLater(
      repo.setCell(session.id, session.puzzles[1].puzzleId, 0, 1),
      throwsStateError,
    );
    final changed = SudokuDefinition.fromJson({
      ...puzzles.first.toJson(),
      'seed': 'different',
    });
    await expectLater(
      repo.registerPuzzles(mapLevelId(1), [changed, ...puzzles.skip(1)]),
      throwsStateError,
    );
    expect(repo.state.puzzles[id]!.seed, puzzles.first.seed);
  });

  test(
    'challenge count is data and restarting abandons only the pending attempt',
    () async {
      final repo = GameRepository.memory();
      addTearDown(repo.close);
      final puzzle = levelPuzzles().first;
      await repo.addLevel(
        LevelDefinition(id: 'bonus', worldId: 'bonus', puzzleIds: [puzzle.id]),
      );
      await repo.registerPuzzles('bonus', [puzzle]);
      final first = await repo.startOrResumeLevel('bonus');
      final restarted = await repo.startOrResumeLevel('bonus', restart: true);
      expect(repo.state.sessions[first.id]!.status, PlayStatus.abandoned);
      await solve(repo, restarted.id, puzzle.id);
      expect(repo.state.sessions[restarted.id]!.status, PlayStatus.completed);
      expect(repo.state.progress['bonus']!.bestLights, 1);
    },
  );

  test(
    'SQLite detects stale writers instead of overwriting a newer save',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'sundoku-conflict-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final path = '${directory.path}/save.db';
      final first = await GameRepository.open(
        await SqliteSaveStore.open(databaseFactoryFfi, path),
      );
      final second = await GameRepository.open(
        await SqliteSaveStore.open(databaseFactoryFfi, path),
      );
      await first.setPlayerName('Primer jugador');
      await expectLater(
        second.setPlayerName('Otro jugador'),
        throwsA(isA<SaveConflict>()),
      );
      expect(second.state.player.name, 'Jugador');
      await second.close();
      await first.close();
      final reopened = await GameRepository.open(
        await SqliteSaveStore.open(databaseFactoryFfi, path),
      );
      addTearDown(reopened.close);
      expect(reopened.state.player.name, 'Primer jugador');
    },
  );

  test(
    'corrupt or future saves are never replaced by a fresh profile',
    () async {
      for (final future in [true, false]) {
        final store = MemorySaveStore();
        final seed = GameRepository.memory();
        final data = seed.state.toJson();
        await seed.close();
        final source = future
            ? jsonEncode({...data, 'schemaVersion': 999})
            : '{invalid';
        await store.write(source, expectedRevision: -1);
        await expectLater(GameRepository.open(store), throwsFormatException);
        expect(await store.read(), source);
      }
    },
  );

  test('optional fields default, unknown fields survive updates, migrations are sequential', () async {
    final original = GameRepository.memory();
    final data = original.state.toJson();
    await original.close();
    data['player'] = {
      ...jsonObject(data['player']),
      'avatar': {'color': 'yellow'},
    }..remove('name');
    data.remove('settings');
    data['futureFeature'] = {'enabled': true};
    final store = MemorySaveStore();
    await store.write(jsonEncode(data), expectedRevision: -1);
    final repo = await GameRepository.open(store);
    addTearDown(repo.close);
    expect(repo.state.player.name, 'Jugador');
    expect(repo.state.settings.music, true);
    await repo.setPlayerName('Luna');
    final saved = jsonObject(jsonDecode((await store.read())!));
    expect(jsonObject(saved['player'])['avatar'], {'color': 'yellow'});
    expect(saved['futureFeature'], {'enabled': true});
    final codec = SaveCodec(
      migrations: {
        0: (old) => {...old, 'schemaVersion': 1},
      },
    );
    expect(
      codec.decode(jsonEncode({...data, 'schemaVersion': 0})).player.name,
      'Jugador',
    );
    expect(
      () => const SaveCodec().decode(jsonEncode({...data, 'schemaVersion': 0})),
      throwsFormatException,
    );
  });
}
