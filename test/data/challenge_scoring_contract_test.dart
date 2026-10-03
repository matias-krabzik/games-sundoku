import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/domain/scoring/adventure_challenge.dart';

import '../support/challenge_simulation.dart';
import '../support/world3_baseline.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('R06/R07: repository errors, notes, erase, pause and reentry preserve accounting', () async {
    final repo = await openBaselineRepository(baselineSave(completedWorlds: 2));
    addTearDown(repo.close);
    final session = await repo.startGeneratedLevel(1, worldId: 'world-3');
    final id = session.nextPuzzleId!;
    final puzzle = repo.state.puzzles[id]!;
    final rules = AdventureChallenges.forPuzzle(
      worldId: 'world-3',
      level: 1,
      puzzle: puzzle,
    )!;
    final simulation = ChallengeSimulation(puzzle, rules);
    final first = simulation.empty.first;
    final second = simulation.empty[1];
    final wrong = puzzle.solution[first] % puzzle.size + 1;
    getBoard() => repo.state.sessions[session.id]!.puzzles.first;
    await repo.activatePuzzle(session.id, id);
    await repo.setCell(session.id, id, first, wrong);
    await repo.setCell(session.id, id, first, wrong);
    expect(getBoard().mistakes, 1);
    expect(rules.evaluate(puzzle, getBoard()).remainingLives, 2);
    await repo.setCell(session.id, id, first, null);
    await repo.setCell(session.id, id, first, wrong);
    expect(getBoard().mistakes, 2);
    expect(rules.evaluate(puzzle, getBoard()).remainingLives, 1);
    await repo.setCell(session.id, id, first, puzzle.solution[first]);
    final points = getBoard().points;
    await repo.setCell(session.id, id, first, null);
    await repo.setCell(session.id, id, first, puzzle.solution[first]);
    await repo.setNotes(session.id, id, second, [1, 2]);
    await repo.addElapsed(session.id, id, 2500);
    await repo.pauseSession(session.id);
    expect(getBoard().elapsedMs, 2500);
    expect(getBoard().mistakes, 2);
    expect(getBoard().points, points);
    await repo.activatePuzzle(session.id, id);
    expect(getBoard().elapsedMs, 2500);
    expect(
      rules.evaluate(puzzle, getBoard()).remainingTimeMs,
      rules.timeLimitMs - 2500,
    );
  });

  for (final explanation in [false, true]) {
    test(
      'calibration driver matches real repository rewards, hint history: explanation=$explanation',
      () async {
        final repo = await openBaselineRepository(
          baselineSave(completedWorlds: 2),
        );
        addTearDown(repo.close);
        final session = await repo.startGeneratedLevel(1, worldId: 'world-3');
        final id = session.nextPuzzleId!;
        final puzzle = repo.state.puzzles[id]!;
        final rules = AdventureChallenges.forPuzzle(
          worldId: 'world-3',
          level: 1,
          puzzle: puzzle,
        )!;
        final simulation = ChallengeSimulation(puzzle, rules);
        for (final (position, index) in simulation.empty.indexed) {
          if (position == 8) {
            final wrong = puzzle.solution[index] % puzzle.size + 1;
            await repo.setCell(session.id, id, index, wrong);
            simulation.enter(index, wrong);
          }
          if (position == 12) {
            if (explanation) {
              await repo.recordHint(session.id, id, index: index);
              simulation.explain(index: index);
            } else {
              await repo.useHint(session.id, id, index);
              simulation.enter(index, puzzle.solution[index], hint: true);
            }
          }
          await repo.setCell(session.id, id, index, puzzle.solution[index]);
          simulation.enter(index, puzzle.solution[index]);
        }
        final actual = repo.state.sessions[session.id]!.puzzles.first;
        expect(actual.points, simulation.progress.points);
        expect(actual.scoring.toJson(), simulation.progress.scoring.toJson());
        expect(actual.mistakes, simulation.progress.mistakes);
        expect(actual.hintsUsed, simulation.progress.hintsUsed);
        expect(
          rules.evaluate(puzzle, actual).outcome,
          simulation.result.outcome,
        );
      },
    );
  }
}
