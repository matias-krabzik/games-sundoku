import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/domain/models/game_save.dart';
import 'package:sundoku/domain/models/json_data.dart';
import 'package:sundoku/domain/models/sudoku_definition.dart';

import '../fixtures.dart';

void main() {
  test('invalid solutions and changed givens cannot enter a save', () {
    final definition = levelPuzzles().first.toJson();
    expect(
      () => SudokuDefinition.fromJson({
        ...definition,
        'solution': [2, ...smallSolution.skip(1)],
      }),
      throwsFormatException,
    );
    expect(
      () => SudokuDefinition.fromJson({
        ...definition,
        'initial': [null, null, 1, ...smallSolution.skip(3)],
      }),
      throwsFormatException,
    );
    expect(
      () =>
          SudokuDefinition.fromJson({...definition, 'initial': smallSolution}),
      throwsFormatException,
    );
  });

  test(
    'published collections and nested extension data cannot be mutated',
    () async {
      final repo = GameRepository.memory();
      addTearDown(repo.close);
      final list = <Object?>['intro'];
      final data = <String, Object?>{'seen': list};
      final saving = repo.saveModule('story', data);
      list.add('later');
      await saving;
      expect(repo.state.modules['story'], {
        'seen': ['intro'],
      });
      expect(() => repo.state.progress.clear(), throwsUnsupportedError);
      final story = repo.state.modules['story'] as Map;
      expect(
        () => (story['seen'] as List).add('other'),
        throwsUnsupportedError,
      );
    },
  );

  test('a corrupt saved fixed cell is rejected on load', () async {
    final repo = GameRepository.memory();
    addTearDown(repo.close);
    await repo.registerPuzzles(mapLevelId(1), levelPuzzles());
    final session = await repo.startOrResumeLevel(mapLevelId(1));
    final data = repo.state.toJson();
    final sessions = jsonObject(data['sessions']);
    final attempt = jsonObject(sessions[session.id]);
    final puzzles = jsonList(attempt['puzzles']);
    final board = jsonObject(puzzles.first);
    final cells = jsonList(board['cells']);
    cells[2] = {...jsonObject(cells[2]), 'value': 1};
    puzzles[0] = {...board, 'cells': cells};
    sessions[session.id] = {...attempt, 'puzzles': puzzles};
    expect(
      () => GameSave.fromJson({...data, 'sessions': sessions}),
      throwsFormatException,
    );
  });

  test('erasing an empty cell also clears its saved notes', () async {
    final repo = GameRepository.memory();
    addTearDown(repo.close);
    await repo.registerPuzzles(mapLevelId(1), levelPuzzles());
    final session = await repo.startOrResumeLevel(mapLevelId(1));
    await repo.setNotes(session.id, session.nextPuzzleId!, 0, [1, 2]);
    await repo.setCell(session.id, session.nextPuzzleId!, 0, null);
    expect(
      repo.state.sessions[session.id]!.puzzles.first.cells.first.notes,
      isEmpty,
    );
  });
}
