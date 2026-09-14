/// Injectable output; the default implementation is silent for previews/tests.
class GameFeedback {
  const GameFeedback();

  Future<void> setMusicEnabled(bool enabled) async {}
  Future<void> tap({required bool sound, required bool vibration}) async {}
  Future<void> error({required bool vibration}) async {}
  Future<void> close() async {}
}
