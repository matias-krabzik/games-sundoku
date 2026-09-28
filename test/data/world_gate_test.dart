import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/save_store.dart';

void main() {
  test('each world keeps its own gate celebration and debug reset', () async {
    final repo = GameRepository.memory();
    for (var level = 1; level <= 10; level++) {
      await repo.recordDebugLights(mapLevelId(level), 3);
    }
    await repo.markWorldGateCelebrated();
    for (var level = 1; level <= 21; level++) {
      await repo.recordDebugLights(mapLevelId(level, worldId: 'world-2'), 3);
    }
    expect(repo.shouldCelebrateGate('world-2'), isTrue);
    expect(repo.shouldCelebrateWorldGate, isFalse);
    await repo.markWorldGateCelebrated(worldId: 'world-2');
    expect(repo.shouldCelebrateGate('world-2'), isFalse);
    expect(repo.state.modules['world1GateCelebrated'], isTrue);
    await repo.resetDebugLevels({mapLevelId(21, worldId: 'world-2')});
    await repo.recordDebugLights(mapLevelId(21, worldId: 'world-2'), 3);
    expect(repo.shouldCelebrateGate('world-2'), isTrue);
    expect(repo.shouldCelebrateWorldGate, isFalse);
    await repo.close();
  });

  test(
    'gate celebration survives reopening and is independent of home discovery',
    () async {
      final store = MemorySaveStore();
      var repo = await GameRepository.open(store);
      expect(repo.shouldCelebrateWorldGate, isFalse);
      for (var level = 1; level <= 9; level++) {
        await repo.recordDebugLights(mapLevelId(level), 3);
      }
      await repo.recordDebugLights(mapLevelId(10), 2);
      await repo.markWorldGateCelebrated();
      expect(repo.shouldCelebrateWorldGate, isFalse);
      await repo.recordDebugLights(mapLevelId(10), 3);
      expect(repo.shouldCelebrateWorldGate, isTrue);
      await repo.markQuickPlayCelebrated();
      await repo.markQuickPlayOpened();
      await repo.close();

      repo = await GameRepository.open(store);
      expect(repo.shouldCelebrateWorldGate, isTrue);
      await repo.markWorldGateCelebrated();
      final revision = repo.state.revision;
      await repo.markWorldGateCelebrated();
      expect(repo.state.revision, revision);
      await repo.close();

      repo = await GameRepository.open(store);
      expect(repo.shouldCelebrateWorldGate, isFalse);
      await repo.resetDebugLevels({mapLevelId(10)});
      expect(repo.shouldCelebrateWorldGate, isFalse);
      await repo.recordDebugLights(mapLevelId(10), 3);
      expect(repo.shouldCelebrateWorldGate, isTrue);
      await repo.markWorldGateCelebrated();
      await repo.completeDebugWorldExceptLastPuzzle();
      expect(repo.shouldCelebrateWorldGate, isFalse);
      await repo.recordDebugLights(mapLevelId(10), 3);
      expect(repo.shouldCelebrateWorldGate, isTrue);
      await repo.close();
    },
  );
}
