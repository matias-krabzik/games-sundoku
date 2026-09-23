import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/save_store.dart';

void main() {
  test(
    'quick play requires all thirty rounds and persists its discovery',
    () async {
      final store = MemorySaveStore();
      var repo = await GameRepository.open(store);
      expect(repo.quickPlayUnlocked, isFalse);
      await repo.markQuickPlayCelebrated();
      await repo.markQuickPlayOpened();
      for (var level = 1; level <= 9; level++) {
        await repo.recordDebugLights(mapLevelId(level), 3);
        expect(repo.quickPlayUnlocked, isFalse);
      }
      await repo.recordDebugLights(mapLevelId(10), 2);
      expect(repo.quickPlayUnlocked, isFalse);
      await repo.recordDebugLights(mapLevelId(10), 3);
      expect(repo.quickPlayUnlocked, isTrue);
      expect(repo.quickPlayIsNew, isTrue);
      expect(repo.shouldCelebrateQuickPlay, isTrue);

      await repo.markQuickPlayCelebrated();
      await repo.close();
      repo = await GameRepository.open(store);
      expect(repo.quickPlayUnlocked, isTrue);
      expect(repo.quickPlayIsNew, isTrue);
      expect(repo.shouldCelebrateQuickPlay, isFalse);
      await repo.markQuickPlayOpened();
      await repo.close();
      repo = await GameRepository.open(store);
      expect(repo.quickPlayUnlocked, isTrue);
      expect(repo.quickPlayIsNew, isFalse);
      expect(repo.shouldCelebrateQuickPlay, isFalse);

      await repo.resetDebugLevels({mapLevelId(10)});
      expect(repo.quickPlayUnlocked, isFalse);
      await repo.recordDebugLights(mapLevelId(10), 3);
      expect(repo.shouldCelebrateQuickPlay, isTrue);
      await repo.close();
    },
  );
}
