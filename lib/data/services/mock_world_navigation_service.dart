import '../repositories/game_repository.dart';
import '../world_catalog.dart';
import 'world_navigation_service.dart';

/// Local world navigation until a dedicated world service is available.
class MockWorldNavigationService implements WorldNavigationService {
  MockWorldNavigationService(this._repository);

  final GameRepository _repository;

  @override
  List<AdventureWorld> get worlds =>
      adventureWorlds.values.toList()
        ..sort((a, b) => a.number.compareTo(b.number));

  @override
  bool isUnlocked(String worldId) {
    final world = adventureWorld(worldId);
    return world.number == 1 ||
        (world.id == 'world-2' && _repository.forestUnlocked);
  }

  @override
  Future<void> enterWorld(String worldId) {
    if (!isUnlocked(worldId)) throw StateError('World is locked');
    return _repository.visitWorld(worldId);
  }
}
