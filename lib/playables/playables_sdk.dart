/// The build variant and the actual YouTube environment are separate states.
const youtubePlayablesBuild = bool.fromEnvironment('YOUTUBE_PLAYABLES');

abstract interface class PlayablesSdk {
  bool get inPlayablesEnvironment;
  bool get audioEnabled;

  void registerCallbacks({
    required void Function() onPause,
    required void Function() onResume,
    required void Function(bool) onAudioEnabledChange,
  });

  void firstFrameReady();
  void gameReady();
  Future<String?> loadData();
  Future<void> saveData(String data);
  void dispose();
}

/// Used by native builds and by the Playables build outside YouTube.
class NullPlayablesSdk implements PlayablesSdk {
  const NullPlayablesSdk();

  @override
  bool get inPlayablesEnvironment => false;
  @override
  bool get audioEnabled => true;
  @override
  void registerCallbacks({
    required void Function() onPause,
    required void Function() onResume,
    required void Function(bool) onAudioEnabledChange,
  }) {}
  @override
  void firstFrameReady() {}
  @override
  void gameReady() {}
  @override
  Future<String?> loadData() async => null;
  @override
  Future<void> saveData(String data) async {}
  @override
  void dispose() {}
}
