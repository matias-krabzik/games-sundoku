import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/domain/models/game_session.dart';

import '../fixtures.dart';

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

  test('notes leave score, errors, hints and completion untouched', () async {
    final repo = GameRepository.memory();
    addTearDown(repo.close);
    final session = await repo.startOrResumeLevel(
      mapLevelId(1),
      definitions: levelPuzzles(),
    );
    await repo.debugEnableNotes(session.id);
    final id = session.nextPuzzleId!;
    await repo.setCell(session.id, id, 0, 1);
    final before = repo.state.sessions[session.id]!.puzzles.first;
    await repo.setNotes(session.id, id, 1, [4, 2, 2]);
    await repo.toggleNote(session.id, id, 1, 4);
    final after = repo.state.sessions[session.id]!.puzzles.first;
    expect(after.cells[1].notes, [2]);
    expect(after.cells[1].value, isNull);
    expect(after.points, before.points);
    expect(after.scoring.toJson(), before.scoring.toJson());
    expect(after.mistakes, before.mistakes);
    expect(after.hintsUsed, before.hintsUsed);
    expect(after.status, before.status);
    expect(repo.state.sessions[session.id]!.lights, 0);
    await repo.setNotes(session.id, id, 1, []);
    expect(
      repo.state.sessions[session.id]!.puzzles.first.points,
      before.points,
    );
    await repo.setNotes(session.id, id, 1, [2]);
    await repo.setCell(session.id, id, 1, 2);
    expect(
      repo.state.sessions[session.id]!.puzzles.first.cells[1].notes,
      isEmpty,
    );
    expect(repo.state.sessions[session.id]!.lights, 1);
  });

  test(
    'notes never erase answers or givens and reject invalid input',
    () async {
      final repo = GameRepository.memory();
      addTearDown(repo.close);
      final session = await repo.startOrResumeLevel(
        mapLevelId(1),
        definitions: levelPuzzles(),
      );
      await repo.debugEnableNotes(session.id);
      final id = session.nextPuzzleId!;
      await repo.setCell(session.id, id, 0, 1);
      final before = repo.state;
      await expectLater(
        repo.setNotes(session.id, id, 0, [2]),
        throwsStateError,
      );
      await expectLater(repo.setNotes(session.id, id, 2, []), throwsStateError);
      await expectLater(
        repo.toggleNote(session.id, id, 1, 0),
        throwsFormatException,
      );
      await expectLater(
        repo.setNotes(session.id, id, 1, [5]),
        throwsFormatException,
      );
      expect(repo.state, same(before));
    },
  );

  test('queued note toggles use the last committed list', () async {
    final repo = GameRepository.memory();
    addTearDown(repo.close);
    final session = await repo.startOrResumeLevel(
      mapLevelId(1),
      definitions: levelPuzzles(),
    );
    await repo.debugEnableNotes(session.id);
    final id = session.nextPuzzleId!;
    await Future.wait([
      repo.toggleNote(session.id, id, 0, 2),
      repo.toggleNote(session.id, id, 0, 3),
      repo.toggleNote(session.id, id, 0, 2),
    ]);
    expect(repo.state.sessions[session.id]!.puzzles.first.cells[0].notes, [3]);
  });

  test(
    'failed notes do not publish and input state survives reopening per puzzle',
    () async {
      final store = _FailingStore();
      final repo = await GameRepository.open(store);
      final session = await repo.startOrResumeLevel(
        mapLevelId(1),
        definitions: levelPuzzles(),
      );
      await repo.debugEnableNotes(session.id);
      final id = session.nextPuzzleId!;
      final before = repo.state;
      store.fail = true;
      await expectLater(
        repo.setNotes(session.id, id, 0, [2]),
        throwsStateError,
      );
      expect(repo.state, same(before));
      store.fail = false;
      await repo.setNotes(session.id, id, 0, [2, 3]);
      await repo.setPuzzleInputState(
        session.id,
        id,
        notesMode: true,
        selectedIndex: 0,
      );
      await repo.close();
      final reopened = await GameRepository.open(store);
      addTearDown(reopened.close);
      final boards = reopened.state.sessions[session.id]!.puzzles;
      expect(boards.first.cells.first.notes, [2, 3]);
      expect(boards.first.extra['notesMode'], true);
      expect(boards.first.extra['selectedCell'], 0);
      expect(boards[1].extra['notesMode'], isNull);
      expect(boards[1].status, PlayStatus.pending);
    },
  );
}
