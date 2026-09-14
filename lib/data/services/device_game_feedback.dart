import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'game_feedback.dart';

/// Local music and tactile feedback, independent of the lifetime of a dialog.
class DeviceGameFeedback extends GameFeedback {
  // Both players mix: a UI pop must not take audio focus from the music.
  static final _context = AudioContext(
    android: const AudioContextAndroid(
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  AudioPlayer? _music;
  AudioPlayer? _effects;
  Future<void> _musicTail = Future.value();
  Future<void> _effectTail = Future.value();
  bool _closed = false;

  Future<void> _safely(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      // Unsupported devices and browser autoplay restrictions must not block UI.
      debugPrint('SunDoku feedback unavailable: $error');
    }
  }

  @override
  Future<void> setMusicEnabled(bool enabled) {
    _musicTail = _musicTail.then(
      (_) => _safely(() async {
        if (_closed) return;
        if (!enabled) {
          await _music?.pause();
          return;
        }
        final player = _music ??= AudioPlayer()..positionUpdater = null;
        if (player.source == null) {
          await player.setAudioContext(_context);
          await player.setReleaseMode(ReleaseMode.loop);
          await player.setVolume(.24);
          await player.setSource(AssetSource('audio/sunny-loop.wav'));
        }
        if (player.state != PlayerState.playing) await player.resume();
      }),
    );
    return _musicTail;
  }

  @override
  Future<void> tap({required bool sound, required bool vibration}) async {
    if (_closed) return;
    if (vibration) unawaited(_safely(HapticFeedback.lightImpact));
    if (!sound) return;
    _effectTail = _effectTail.then(
      (_) => _safely(() async {
        if (_closed) return;
        final player = _effects ??= AudioPlayer()..positionUpdater = null;
        await player.setAudioContext(_context);
        await player.play(AssetSource('audio/soft-tap.wav'), volume: .45);
      }),
    );
    await _effectTail;
  }

  @override
  Future<void> error({required bool vibration}) async {
    if (_closed || !vibration) return;
    await _safely(HapticFeedback.vibrate);
  }

  @override
  Future<void> close() async {
    _closed = true;
    await Future.wait([_musicTail, _effectTail]);
    await _safely(() async {
      await _music?.dispose();
      await _effects?.dispose();
    });
  }
}
