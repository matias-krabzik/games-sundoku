enum MusicScene { home, map, game }

enum WorldGateSound { ignite, sparkle }

/// Injectable output; the default implementation is silent for previews/tests.
class GameFeedback {
  const GameFeedback();

  Future<void> prepareEffects() async {}
  Future<void> setMusicScene(MusicScene scene) async {}
  Future<void> setMusicEnabled(bool enabled) async {}
  Future<void> toggle({
    required bool enabled,
    required bool sound,
    required bool vibration,
  }) async {}
  Future<void> levelCompleted({required bool sound}) async {}
  Future<void> modalOpened({required bool sound}) async {}
  Future<void> worldGate(WorldGateSound cue, {required bool sound}) async {}
  Future<void> stopWorldGate() async {}
  Future<void> tap({required bool sound, required bool vibration}) async {}
  Future<void> error({required bool vibration}) async {}
  Future<void> close() async {}
}
