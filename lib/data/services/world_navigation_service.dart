import '../world_catalog.dart';

/// Supplies the world selector without tying the map UI to a data source.
abstract interface class WorldNavigationService {
  List<AdventureWorld> get worlds;

  bool isUnlocked(String worldId);

  Future<void> enterWorld(String worldId);
}
