import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/save_codec.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/data/world_catalog.dart';
import 'package:sundoku/domain/models/game_save.dart';
import 'package:sundoku/domain/models/json_data.dart';
import 'package:sundoku/domain/models/player_profile.dart';

final baselineDate = DateTime.utc(2026, 10, 3, 12);
const baselinePlayer = '00000000-0000-4000-8000-000000000003';
const baselineFixtureNames = [
  'new-profile',
  'world-2-complete',
  'world-3-one-star',
  'world-3-two-stars',
  'world-3-in-progress',
  'world-3-level-complete',
  'world-3-complete',
];

GameSave baselineSave({int completedWorlds = 0}) => GameSave(
  player: PlayerProfile(id: baselinePlayer),
  settings: GameSettings(sound: false, music: false, vibration: false),
  updatedAt: baselineDate,
  levels: initialLevelCatalog,
  progress: {
    for (final world in adventureWorlds.values)
      if (world.number <= completedWorlds)
        for (final node in world.nodes)
          mapLevelId(node.level, worldId: world.id): LevelRecord(bestLights: 3),
  },
  modules: {
    if (completedWorlds >= 2) ...{
      'tutorials/notes/v1': {'step': 7, 'completed': true},
      'announcements/notes': true,
      'world1GateCelebrated': true,
      'navigation/adventure': {'worldId': 'world-2'},
    },
  },
);

/// Isolated in-memory import; no device profile or persistent store is touched.
Future<GameRepository> openBaselineRepository(GameSave save) async {
  final store = MemorySaveStore();
  await store.write(
    const SaveCodec().encode(save.copyWith(revision: 0)),
    expectedRevision: -1,
  );
  return GameRepository.open(store, now: () => baselineDate);
}

/// Only nondeterministic session identities and the storage revision are normalized.
GameSave normalizeBaseline(GameSave save) {
  final ids = {
    for (final (index, id) in save.sessions.keys.indexed)
      id: 'baseline-session-${index + 1}',
  };
  Object? normalize(Object? value) => switch (value) {
    String text => ids[text] ?? text,
    List values => values.map(normalize).toList(),
    Map values => {
      for (final entry in values.entries)
        ids[entry.key] ?? entry.key: normalize(entry.value),
    },
    _ => value,
  };
  return GameSave.fromJson(jsonObject(normalize(save.toJson())))
      .copyWith(revision: 0);
}

/// Opt-in fixture generation against the pre-challenge application.
/// Never regenerate these legacy fixtures as part of a routine test run.
Future<Map<String, GameSave>> buildWorld3Baseline() async {
  final snapshots = <String, GameSave>{
    'new-profile': baselineSave(),
    'world-2-complete': baselineSave(completedWorlds: 2),
  };
  final repo = await openBaselineRepository(snapshots['world-2-complete']!);
  try {
    await repo.visitWorld('world-3');
    final session = await repo.startGeneratedLevel(1, worldId: 'world-3');
    final key = adventureModuleKey('world-3', 1);
    for (var round = 0; round < 3; round++) {
      final puzzleId = session.puzzles[round].puzzleId;
      final puzzle = repo.state.puzzles[puzzleId]!;
      await repo.saveModule(key, {
        'sessionId': session.id,
        'step': 'playing',
        'gameIndex': round,
        'started': false,
      });
      await repo.activatePuzzle(session.id, puzzleId);
      await repo.addElapsed(session.id, puzzleId, (round + 1) * 60000);
      if (round == 2) {
        final empty = [
          for (var i = 0; i < puzzle.initial.length; i++)
            if (puzzle.initial[i] == null) i,
        ];
        await repo.setCell(
          session.id,
          puzzleId,
          empty[0],
          puzzle.solution[empty[0]],
        );
        await repo.setNotes(session.id, puzzleId, empty[1], [2, 7]);
        await repo.setCell(
          session.id,
          puzzleId,
          empty[2],
          puzzle.solution[empty[2]] % 9 + 1,
        );
        await repo.recordHint(session.id, puzzleId, index: empty[3]);
        await repo.pauseSession(session.id);
        snapshots['world-3-in-progress'] = normalizeBaseline(repo.state);
        await repo.activatePuzzle(session.id, puzzleId);
      }
      for (var i = 0; i < puzzle.initial.length; i++) {
        if (puzzle.initial[i] == null) {
          await repo.setCell(session.id, puzzleId, i, puzzle.solution[i]);
        }
      }
      snapshots[switch (round) {
        0 => 'world-3-one-star',
        1 => 'world-3-two-stars',
        _ => 'world-3-level-complete',
      }] = normalizeBaseline(
        repo.state,
      );
    }
    // Other levels are synthetic progress records, not claimed gameplay coverage.
    for (var level = 2; level <= 30; level++) {
      await repo.recordDebugLights(mapLevelId(level, worldId: 'world-3'), 3);
    }
    snapshots['world-3-complete'] = normalizeBaseline(repo.state);
    return snapshots;
  } finally {
    await repo.close();
  }
}
