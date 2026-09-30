import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/mock_world_navigation_service.dart';

void main() {
  test(
    'mock navigation respects the save unlock and remembers the world',
    () async {
      final repository = GameRepository.memory();
      final navigation = MockWorldNavigationService(repository);
      expect(navigation.worlds.map((world) => world.id), [
        'world-1',
        'world-2',
        'world-3',
      ]);
      expect(navigation.isUnlocked('world-2'), isFalse);
      expect(() => navigation.enterWorld('world-2'), throwsStateError);
      expect(navigation.isUnlocked('world-3'), isFalse);
      expect(() => navigation.enterWorld('world-3'), throwsStateError);

      await repository.prepareDebugForest();
      expect(navigation.isUnlocked('world-2'), isTrue);
      await navigation.enterWorld('world-2');
      expect(repository.lastAdventureWorld, 'world-2');
      expect(navigation.isUnlocked('world-3'), isFalse);
      await navigation.enterWorld('world-1');
      expect(repository.lastAdventureWorld, 'world-1');
      await repository.close();
    },
  );
}
