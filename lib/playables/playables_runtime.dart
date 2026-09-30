import 'dart:async';

import 'package:flutter/foundation.dart';

import 'playables_sdk.dart';

typedef PlayablesPauseHandler = Future<void> Function(bool paused);

/// Receives SDK events immediately, including events sent while data loads.
class PlayablesRuntime extends ChangeNotifier {
  PlayablesRuntime(this.sdk) : _audioEnabled = sdk.audioEnabled {
    sdk.registerCallbacks(
      onPause: () => unawaited(_setPaused(true)),
      onResume: () => unawaited(_setPaused(false)),
      onAudioEnabledChange: (enabled) {
        _audioEnabled = enabled;
        notifyListeners();
      },
    );
  }

  static PlayablesRuntime? active;
  final PlayablesSdk sdk;
  final _pauseHandlers = <PlayablesPauseHandler>{};
  bool _paused = false;
  bool _audioEnabled;
  bool _firstFrameSent = false;
  bool _gameReadySent = false;
  Future<void> Function()? saveOnPause;

  bool get isPaused => _paused;
  bool get audioEnabled => _audioEnabled;
  bool get inPlayablesEnvironment => sdk.inPlayablesEnvironment;

  void addPauseHandler(PlayablesPauseHandler handler) {
    _pauseHandlers.add(handler);
    if (_paused) unawaited(handler(true));
  }

  void removePauseHandler(PlayablesPauseHandler handler) {
    _pauseHandlers.remove(handler);
  }

  Future<void> _setPaused(bool paused) async {
    if (_paused == paused) return;
    _paused = paused;
    notifyListeners();
    final work = [
      for (final handler in _pauseHandlers.toList()) handler(paused),
    ];
    try {
      await Future.wait(work);
    } catch (error) {
      debugPrint('SunDoku Playables pause failed: $error');
    }
    if (paused) {
      try {
        await saveOnPause?.call();
      } catch (error) {
        debugPrint('SunDoku Playables save on pause failed: $error');
      }
    }
  }

  void firstFrameReady() {
    if (_firstFrameSent || !inPlayablesEnvironment) return;
    _firstFrameSent = true;
    sdk.firstFrameReady();
  }

  void gameReady() {
    if (_gameReadySent || !inPlayablesEnvironment) return;
    if (!_firstFrameSent) {
      throw StateError('firstFrameReady must be sent first');
    }
    _gameReadySent = true;
    sdk.gameReady();
  }

  @override
  void dispose() {
    if (identical(active, this)) active = null;
    sdk.dispose();
    super.dispose();
  }
}
