import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'playables_sdk.dart';

@JS('ytgame')
external _YtGame? get _ytgame;

@JS()
@staticInterop
class _YtGame {}

extension _YtGameAccess on _YtGame {
  // ignore: non_constant_identifier_names
  external bool get IN_PLAYABLES_ENV;
  external _YtGameApi get game;
  external _YtSystem get system;
}

@JS()
@staticInterop
class _YtGameApi {}

extension _YtGameApiAccess on _YtGameApi {
  external void firstFrameReady();
  external void gameReady();
  external JSPromise<JSString?> loadData();
  external JSPromise<JSAny?> saveData(JSString data);
}

@JS()
@staticInterop
class _YtSystem {}

extension _YtSystemAccess on _YtSystem {
  external bool isAudioEnabled();
  external JSFunction onPause(JSFunction callback);
  external JSFunction onResume(JSFunction callback);
  external JSFunction onAudioEnabledChange(JSFunction callback);
}

PlayablesSdk createPlayablesSdk() {
  // A local Playables build has the SDK's no-op shim, but is not YouTube.
  if (!globalContext.has('ytgame')) return const NullPlayablesSdk();
  final game = _ytgame;
  if (game == null || !game.IN_PLAYABLES_ENV) {
    return const NullPlayablesSdk();
  }
  return _BrowserPlayablesSdk(game);
}

class _BrowserPlayablesSdk implements PlayablesSdk {
  _BrowserPlayablesSdk(this._yt);
  final _YtGame _yt;
  final _unregister = <JSFunction>[];
  // Keep the JS wrappers reachable until their SDK subscriptions are removed.
  final _callbacks = <JSFunction>[];

  @override
  bool get inPlayablesEnvironment => true;
  @override
  bool get audioEnabled => _yt.system.isAudioEnabled();

  @override
  void registerCallbacks({
    required void Function() onPause,
    required void Function() onResume,
    required void Function(bool) onAudioEnabledChange,
  }) {
    final pause = (() => onPause()).toJS;
    final resume = (() => onResume()).toJS;
    final audio = ((JSBoolean enabled) => onAudioEnabledChange(
      enabled.toDart,
    )).toJS;
    _callbacks.addAll([pause, resume, audio]);
    _unregister.addAll([
      _yt.system.onPause(pause),
      _yt.system.onResume(resume),
      _yt.system.onAudioEnabledChange(audio),
    ]);
  }

  @override
  void firstFrameReady() => _yt.game.firstFrameReady();
  @override
  void gameReady() => _yt.game.gameReady();
  @override
  Future<String?> loadData() async =>
      (await _yt.game.loadData().toDart)?.toDart;
  @override
  Future<void> saveData(String data) async {
    await _yt.game.saveData(data.toJS).toDart;
  }

  @override
  void dispose() {
    for (final unregister in _unregister) {
      unregister.callAsFunction();
    }
    _unregister.clear();
    _callbacks.clear();
  }
}
