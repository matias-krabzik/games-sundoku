import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/controllers/notes_tutorial_controller.dart';
import 'package:sundoku/data/forest_puzzles.dart';
import 'package:sundoku/data/level_progress.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/save_codec.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/domain/generation/seeded_sudokus.dart';
import 'package:sundoku/domain/models/quick_play_difficulty.dart';
import 'package:sundoku/domain/models/sudoku_definition.dart';

class _SnapshotStore implements SaveStore {
  _SnapshotStore(this.data);
  String data;
  bool fail = false;
  @override
  Future<String?> read() async => data;
  @override
  Future<void> write(String data, {required int expectedRevision}) async {
    if (fail) throw StateError('Disk full');
    this.data = data;
  }

  @override
  Future<void> close() async {}
}

Future<void> _finishRound(GameRepository repo, String sessionId) async {
  final id = repo.state.sessions[sessionId]!.nextPuzzleId!;
  final p = repo.state.puzzles[id]!;
  for (var i = 0; i < 81; i++) {
    if (!p.isFixed(i)) await repo.setCell(sessionId, id, i, p.solution[i]);
  }
}

Future<void> _lesson(NotesTutorialController flow) async {
  await flow.next();
  await flow.toggle();
  await flow.next();
  await flow.number(2);
  await flow.number(7);
  await flow.next();
  await flow.toggle();
  await flow.next();
  await flow.number(7);
  await flow.next();
  await flow.toggle();
  await flow.number(7);
  await flow.next();
  await flow.toggle();
  await flow.number(2);
  await flow.next();
  await flow.next();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('63 frozen puzzles are unique, singles-solvable and have a real note deduction', () {
    final seen = <String>{};
    for (var level = 1; level <= 21; level++) {
      for (final p in forestPuzzles(level)) {
        expect(seen.add(p.initial.join(',')), isTrue);
        final cells = p.initial.map((n) => n ?? 0).toList();
        expect(SeededSudokus.hasUniqueSolution(cells), isTrue, reason: p.id);
        expect(SeededSudokus.solveWithSingles(cells), p.solution, reason: p.id);
        final a = p.extra['notesTarget'] as int,
            b = p.extra['deductionCell'] as int;
        final before = SeededSudokus.candidates(cells, a);
        expect(before.length, 2);
        final bOptions = SeededSudokus.candidates(cells, b);
        expect(bOptions.length, 1);
        expect(before, contains(bOptions.single));
        cells[b] = bOptions.single;
        expect(SeededSudokus.candidates(cells, a), [p.solution[a]]);
      }
    }
    expect(seen.length, 63);
  });

  test('old saves gain levels atomically without changing valley, flags or extra data', () async {
    final repo = GameRepository.memory();
    await repo.prepareDebugForest();
    await repo.markWorldGateCelebrated();
    await repo.setPlayerName('Luna');
    await repo.saveModule('unknown-module', {'preserve': 17});
    final old = repo.state.copyWith(
      levels: {
        for (final e in repo.state.levels.entries)
          if (e.value.worldId == 'world-1') e.key: e.value,
      },
    );
    final original = const SaveCodec().encode(old);
    await repo.close();
    final store = _SnapshotStore(original)..fail = true;
    await expectLater(GameRepository.open(store), throwsStateError);
    expect(store.data, original);
    store.fail = false;
    var migrated = await GameRepository.open(store);
    expect(migrated.state.levels.length, 30);
    expect(
      migrated.state.sessions.map((id, s) => MapEntry(id, s.toJson())),
      old.sessions.map((id, s) => MapEntry(id, s.toJson())),
    );
    expect(migrated.state.player.name, 'Luna');
    expect(migrated.state.modules['unknown-module'], {'preserve': 17});
    expect(migrated.quickPlayUnlocked, isTrue);
    expect(migrated.shouldCelebrateWorldGate, isFalse);
    final revision = migrated.state.revision;
    await migrated.close();
    migrated = await GameRepository.open(store);
    expect(migrated.state.revision, revision);
    await migrated.close();
  });

  test(
    'retired level 21 stays saved but does not block world completion',
    () async {
      final source = GameRepository.memory();
      await source.prepareDebugForest();
      for (var level = 1; level <= 20; level++) {
        await source.recordDebugLights('world-2/level-$level', 3);
      }
      final old = source.state.copyWith(
        levels: {
          ...source.state.levels,
          'world-2/level-21': LevelDefinition(
            id: 'world-2/level-21',
            worldId: 'world-2',
            puzzleIds: ['world-2/level-21/sudoku-1'],
          ),
        },
      );
      await source.close();
      final repo = await GameRepository.open(
        _SnapshotStore(const SaveCodec().encode(old)),
      );
      expect(repo.state.levels.containsKey('world-2/level-21'), isTrue);
      expect(repo.worldCompleted('world-2'), isTrue);
      await repo.close();
    },
  );

  test('tutorial is necessary, unscored, resumable and based only on visible clues', () async {
    final repo = GameRepository.memory();
    addTearDown(repo.close);
    await expectLater(
      repo.startGeneratedLevel(1, worldId: 'world-2'),
      throwsStateError,
    );
    await repo.prepareDebugForest();
    await expectLater(
      repo.startGeneratedLevel(1, worldId: 'world-2'),
      throwsStateError,
    );
    final initial = NotesLesson.initial.map((n) => n ?? 0).toList();
    expect(SeededSudokus.candidates(initial, NotesLesson.target), [2, 7]);
    expect(SeededSudokus.candidates(initial, NotesLesson.other), [7]);
    expect(SeededSudokus.hasUniqueSolution(initial), isTrue);
    final before = repo.state.progress.map((k, v) => MapEntry(k, v.toJson()));
    var flow = NotesTutorialController(repo);
    await flow.next();
    await flow.toggle();
    await flow.next();
    await flow.number(2);
    flow.dispose();
    flow = NotesTutorialController(repo);
    expect(flow.step, 2);
    expect(flow.notesMode, isTrue);
    expect(flow.notes, [2]);
    await flow.number(7);
    await flow.next();
    await flow.toggle();
    await flow.next();
    await flow.number(7);
    await flow.next();
    await flow.toggle();
    await flow.number(7);
    await flow.next();
    await flow.toggle();
    await flow.number(2);
    await flow.next();
    await flow.next();
    flow.dispose();
    expect(repo.notesTutorialCompleted, isTrue);
    expect(repo.notesUnlocked, isFalse);
    expect(repo.state.progress.map((k, v) => MapEntry(k, v.toJson())), before);
    expect(
      repo.state.sessions.values.where((s) => s.levelId.startsWith('world-2')),
      isEmpty,
    );
  });

  test('practice remains local until third win, then notes persist in quick play and valley', () async {
    final repo = GameRepository.memory();
    addTearDown(repo.close);
    await repo.prepareDebugForest();
    final lesson = NotesTutorialController(repo);
    await _lesson(lesson);
    lesson.dispose();
    final session = await repo.startGeneratedLevel(1, worldId: 'world-2');
    final first = repo.state.puzzles[session.nextPuzzleId]!;
    await repo.setNotes(session.id, first.id, first.initial.indexOf(null), [
      2,
      7,
    ]);
    expect(repo.notesAllowedFor('world-1/level-1'), isFalse);
    final quick = await repo.startQuickPlay(QuickPlayDifficulty.easy);
    final quickPuzzle = repo.state.puzzles[quick.nextPuzzleId]!;
    await expectLater(
      repo.setNotes(
        quick.id,
        quickPuzzle.id,
        quickPuzzle.initial.indexOf(null),
        [2],
      ),
      throwsStateError,
    );
    await _finishRound(repo, session.id);
    await _finishRound(repo, session.id);
    expect(repo.notesUnlocked, isFalse);
    await _finishRound(repo, session.id);
    expect(repo.notesUnlocked, isTrue);
    expect(repo.notesAnnouncementPending, isTrue);
    expect(repo.notesAllowedFor('world-1/level-1'), isTrue);
    await repo.setNotes(
      quick.id,
      quickPuzzle.id,
      quickPuzzle.initial.indexOf(null),
      [2, 7],
    );
    final review = NotesTutorialController(repo, replay: true);
    await _lesson(review);
    review.dispose();
    expect(
      repo
          .state
          .sessions[quick.id]!
          .puzzles
          .first
          .cells[quickPuzzle.initial.indexOf(null)]
          .notes,
      [2, 7],
    );
    await repo.markNotesAnnounced();
    expect(repo.notesAnnouncementPending, isFalse);
  });

  test(
    'world 2 dev shortcut, local level 10 and final game use the correct world',
    () async {
      final repo = GameRepository.memory();
      addTearDown(repo.close);
      await repo.prepareDebugForest();
      final lesson = NotesTutorialController(repo);
      await _lesson(lesson);
      lesson.dispose();
      await repo.markWorldGateCelebrated();
      await repo.markQuickPlayOpened();
      await repo.completeDebugWorldExceptLastPuzzle(worldId: 'world-2');
      final progress = LevelProgress(repository: repo, worldId: 'world-2');
      addTearDown(progress.dispose);
      expect(progress.lightsFor(19), 3);
      expect(progress.lightsFor(20), 2);
      expect(progress.worldPoints, greaterThan(0));
      final ten = FirstExperienceController(
        repo,
        worldId: 'world-2',
        levelNumber: 10,
      );
      final last = FirstExperienceController(
        repo,
        worldId: 'world-2',
        levelNumber: 20,
      );
      expect(ten.isLastLevel, isFalse);
      expect(last.isLastLevel, isTrue);
      expect(last.gameIndex, 2);
      ten.dispose();
      last.dispose();
      final pending = repo.state.sessions.values.singleWhere(
        (s) => s.levelId == 'world-2/level-20' && s.canResume,
      );
      await _finishRound(repo, pending.id);
      expect(repo.worldCompleted('world-2'), isTrue);
      expect(repo.shouldCelebrateWorldGate, isFalse);
      expect(repo.quickPlayIsNew, isFalse);
      await repo.visitWorld('world-2');
      expect(repo.lastAdventureWorld, 'world-2');
      await progress.resetLevel(1);
      expect(repo.quickPlayUnlocked, isTrue);
      expect(repo.notesUnlocked, isFalse);
      expect(
        repo.state.sessions.values
            .where((s) => s.levelId.startsWith('world-1'))
            .length,
        10,
      );
      expect(repo.lastAdventureWorld, 'world-1');
    },
  );
}
