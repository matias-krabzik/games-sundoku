import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/domain/scoring/adventure_challenge.dart';

import '../support/challenge_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final level in [1, 11, 21, 30]) {
    test(
      'DEV leaves one cell and enough points, lives and time at level $level',
      () async {
        final repo = await challengeRepository(MemorySaveStore(), level: level);
        addTearDown(repo.close);
        final session = await repo.startGeneratedLevel(
          level,
          worldId: 'world-3',
        );
        final id = session.puzzles.first.puzzleId;
        final puzzle = repo.state.puzzles[id]!;
        final empty = [
          for (var i = 0; i < 81; i++)
            if (!puzzle.isFixed(i)) i,
        ];
        if (level <= 20) {
          await repo.setCell(
            session.id,
            id,
            empty.first,
            puzzle.solution[empty.first] % 9 + 1,
          );
        }
        if (level < 30) {
          await repo.useHint(session.id, id, empty[1]);
        }
        await repo.addElapsed(session.id, id, 90000);
        await repo.debugFillExceptCell(session.id, id, empty.last);
        final board = roundBoard(repo, session.id);
        expect(board.cells.where((cell) => cell.value == null).length, 1);
        expect(board.mistakes, 0);
        expect(board.hintsUsed, 0);
        expect(board.elapsedMs, 0);
        expect(board.attempt!.result, isNull);
        expect(repo.state.sessions[session.id]!.lights, 0);
        final points = board.points;
        await repo.debugFillExceptCell(session.id, id, empty.last);
        expect(roundBoard(repo, session.id).points, points);
        await repo.setCell(
          session.id,
          id,
          empty.last,
          puzzle.solution[empty.last],
        );
        final won = roundBoard(repo, session.id);
        expect(won.attempt!.result!.outcome, ChallengeOutcome.won);
        expect(won.points, won.attempt!.rules.perfectPoints);
        expect(repo.state.sessions[session.id]!.lights, 1);
      },
    );
  }
}
