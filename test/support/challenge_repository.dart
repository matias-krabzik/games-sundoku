import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/save_codec.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/domain/models/game_save.dart';
import 'package:sundoku/domain/models/game_session.dart';
import 'package:sundoku/domain/models/sudoku_definition.dart';

import '../fixtures.dart';
import 'world3_baseline.dart';

Future<GameRepository> challengeRepository(
  SaveStore store, {
  int level = 1,
}) async {
  final base = baselineSave(completedWorlds: 2);
  final save = base.copyWith(
    progress: {
      ...base.progress,
      for (var i = 1; i < level; i++)
        mapLevelId(i, worldId: 'world-3'): LevelRecord(bestLights: 3),
    },
  );
  await store.write(const SaveCodec().encode(save), expectedRevision: -1);
  return GameRepository.open(
    store,
    enableWorld3Challenges: true,
    now: () => baselineDate,
  );
}

Future<GameSession> startChallenge(GameRepository repo, {int level = 1}) =>
    repo.startOrResumeLevel(
      mapLevelId(level, worldId: 'world-3'),
      definitions: [
        for (final (index, puzzle) in levelPuzzles().indexed)
          SudokuDefinition.fromJson({
            ...puzzle.toJson(),
            'id': 'world-3/level-$level/sudoku-${index + 1}',
          }),
      ],
    );

PuzzleProgress roundBoard(
  GameRepository repo,
  String session, [
  int round = 0,
]) => repo.state.sessions[session]!.puzzles[round];

Future<void> winRound(
  GameRepository repo,
  String session, [
  int round = 0,
]) async {
  final id = roundBoard(repo, session, round).puzzleId;
  final puzzle = repo.state.puzzles[id]!;
  for (var index = 0; index < puzzle.initial.length; index++) {
    if (puzzle.initial[index] == null) {
      await repo.setCell(session, id, index, puzzle.solution[index]);
    }
  }
}

Future<void> acknowledge(GameRepository repo, String session, [int round = 0]) {
  final board = roundBoard(repo, session, round);
  return repo.acknowledgeRoundResult(
    session,
    board.puzzleId,
    attemptId: board.attempt!.id,
  );
}
