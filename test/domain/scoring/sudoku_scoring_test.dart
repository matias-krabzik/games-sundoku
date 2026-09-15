import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/domain/models/game_session.dart';
import 'package:sundoku/domain/models/sudoku_definition.dart';
import 'package:sundoku/domain/scoring/sudoku_scoring.dart';

import '../../fixtures.dart';
import '../../data/game_repository_test.dart' show FailingStore;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final entry in {
    'easy': 1,
    'normal': 3,
    'medium': 5,
    'hard': 7,
    'extreme': 11,
  }.entries) {
    test(
      '${entry.key}: simultaneous completion rewards and difficulty persist',
      () async {
        final store = MemorySaveStore();
        var repo = await GameRepository.open(store);
        final definitions = levelPuzzles()
            .map(
              (p) => SudokuDefinition.fromJson({
                ...p.toJson(),
                'difficulty': entry.key,
              }),
            )
            .toList();
        final session = await repo.startOrResumeLevel(
          mapLevelId(1),
          definitions: definitions,
        );
        final puzzle = session.nextPuzzleId!;
        await repo.setCell(session.id, puzzle, 0, 1);
        expect(repo.state.sessions[session.id]!.points, 64 * entry.value);
        await repo.close();
        repo = await GameRepository.open(store);
        await repo.setCell(session.id, puzzle, 0, null);
        await repo.setCell(session.id, puzzle, 0, 1);
        expect(repo.state.sessions[session.id]!.points, 64 * entry.value);
        expect(
          repo.state.sessions[session.id]!.puzzles.first.scoring.streak,
          1,
        );
        await repo.setCell(session.id, puzzle, 1, 2);
        expect(repo.state.sessions[session.id]!.points, 567 * entry.value);
        expect(repo.state.sessions[session.id]!.lights, 1);
        expect(repo.state.isUnlocked(mapLevelId(2)), isFalse);
        await repo.close();
      },
    );
  }

  test(
    'streak tiers survive time and pauses; mistakes reset; notes do not earn',
    () async {
      final repo = GameRepository.memory();
      final definitions = levelPuzzles()
          .map(
            (p) => SudokuDefinition.fromJson({
              ...p.toJson(),
              'initial': List<int?>.filled(16, null),
            }),
          )
          .toList();
      final session = await repo.startOrResumeLevel(
        mapLevelId(1),
        definitions: definitions,
      );
      final puzzle = session.nextPuzzleId!;
      for (final (position, index) in [0, 5, 10, 15, 1].indexed) {
        await repo.setCell(session.id, puzzle, index, smallSolution[index]);
        expect(
          repo.state.sessions[session.id]!.points,
          [11, 22, 39, 56, 79][position],
        );
        await repo.addElapsed(session.id, puzzle, 20000);
        await repo.pauseSession(session.id);
        await repo.activatePuzzle(session.id, puzzle);
      }
      await repo.setNotes(session.id, puzzle, 2, [1, 2]);
      expect(repo.state.sessions[session.id]!.points, 79);
      await repo.setCell(session.id, puzzle, 2, 1, revealError: false);
      expect(repo.state.sessions[session.id]!.puzzles.first.scoring.streak, 0);
      expect(repo.state.sessions[session.id]!.points, 79);
      await repo.setCell(session.id, puzzle, 2, 3);
      expect(repo.state.sessions[session.id]!.points, 90);
      await repo.close();
    },
  );

  for (final fillsCell in [true, false]) {
    test(
      'hint costs exactly 77 at extreme and cannot earn completion rewards: fill=$fillsCell',
      () async {
        final repo = GameRepository.memory();
        final definitions = levelPuzzles()
            .map(
              (p) => SudokuDefinition.fromJson({
                ...p.toJson(),
                'difficulty': 'extreme',
              }),
            )
            .toList();
        final session = await repo.startOrResumeLevel(
          mapLevelId(1),
          definitions: definitions,
        );
        final puzzle = session.nextPuzzleId!;
        await repo.setCell(session.id, puzzle, 0, 1);
        expect(repo.state.sessions[session.id]!.points, 704);
        if (fillsCell) {
          await repo.useHint(session.id, puzzle, 1);
        } else {
          await repo.recordHint(session.id, puzzle, index: 1);
          await repo.setCell(session.id, puzzle, 1, 2);
        }
        final progress = repo.state.sessions[session.id]!.puzzles.first;
        expect(progress.points, 627);
        expect(progress.hintsUsed, 1);
        expect(progress.scoring.streak, 1);
        expect(progress.status, PlayStatus.completed);
        await repo.close();
      },
    );
  }

  test(
    'zero-score assisted wins still unlock; replay only improves best total',
    () async {
      final repo = GameRepository.memory();
      final session = await repo.startOrResumeLevel(
        mapLevelId(1),
        definitions: levelPuzzles(),
      );
      for (final board in session.puzzles) {
        await repo.useHint(session.id, board.puzzleId, 0);
        await repo.useHint(session.id, board.puzzleId, 1);
      }
      expect(repo.state.sessions[session.id]!.points, 0);
      expect(repo.state.isUnlocked(mapLevelId(2)), true);
      final replay = await repo.startOrResumeLevel(
        mapLevelId(1),
        restart: true,
      );
      for (final board in replay.puzzles) {
        await repo.setCell(replay.id, board.puzzleId, 0, 1);
        await repo.setCell(replay.id, board.puzzleId, 1, 2);
      }
      expect(repo.state.totalPoints, 1701);
      final third = await repo.startOrResumeLevel(mapLevelId(1), restart: true);
      for (final board in third.puzzles) {
        await repo.useHint(third.id, board.puzzleId, 0);
        await repo.useHint(third.id, board.puzzleId, 1);
      }
      expect(repo.state.totalPoints, 1701);
      await repo.close();
    },
  );

  test('failed save does not publish or double-award the move', () async {
    final store = FailingStore();
    final repo = await GameRepository.open(store);
    final session = await repo.startOrResumeLevel(
      mapLevelId(1),
      definitions: levelPuzzles(),
    );
    store.failNext = true;
    await expectLater(
      repo.setCell(session.id, session.nextPuzzleId!, 0, 1),
      throwsException,
    );
    expect(repo.state.sessions[session.id]!.points, 0);
    await repo.setCell(session.id, session.nextPuzzleId!, 0, 1);
    expect(repo.state.sessions[session.id]!.points, 64);
    await repo.close();
  });

  test(
    'legacy saves initialize history without rewarding previous correct cells',
    () {
      final puzzle = levelPuzzles().first;
      var board = PuzzleProgress.initial(puzzle);
      final cells = [...board.cells]..[0] = CellProgress(value: 1);
      board = PuzzleProgress.fromJson(
        {...board.toJson(), 'cells': cells.map((c) => c.toJson()).toList()}
          ..remove('scoring'),
      );
      final cleared = [...board.cells]..[0] = CellProgress();
      final afterClear = SudokuScoring.move(
        puzzle: puzzle,
        before: board,
        after: board.copyWith(cells: cleared),
        index: 0,
        hintUsed: false,
        isError: false,
      );
      final restored = SudokuScoring.move(
        puzzle: puzzle,
        before: afterClear,
        after: afterClear.copyWith(cells: cells),
        index: 0,
        hintUsed: false,
        isError: false,
      );
      expect(restored.points, 0);
      expect(restored.scoring.streak, 0);
    },
  );
}
