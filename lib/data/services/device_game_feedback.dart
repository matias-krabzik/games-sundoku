import 'dart:async';
import 'dart:math';

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

  DeviceGameFeedback({Random? random}) : _random = random ?? Random();

  static const homeTrack = 'audio/map/Devonshire-Waltz-Moderato.mp3';
  static const mapTrack = 'audio/map/Devonshire-Waltz-Allegretto.mp3';
  static const gameTracks = [
    'audio/games/Morning.mp3',
    'audio/games/Evening.mp3',
  ];
  final Random _random;
  String _track = homeTrack;
  String? _loadedTrack;
  bool _musicEnabled = false;
  bool _winPlaying = false;
  double _musicVolume = .24;
  int _musicFadeGeneration = 0;
  StreamSubscription<void>? _winCompleted;

  AudioPlayer? _music;
  AudioPlayer? _effects;
  AudioPlayer? _modal;
  AudioPlayer? _win;
  Future<void>? _winPreparation;
  Future<void> _winTail = Future.value();
  Future<void>? _modalPreparation;
  Future<void> _modalTail = Future.value();
  Future<void> _musicTail = Future.value();
  Future<void> _effectTail = Future.value();
  final _gatePlayers = <WorldGateSound, AudioPlayer>{};
  Future<void>? _gatePreparation;
  Future<void> _gateTail = Future.value();
  int _gateGeneration = 0;
  bool _closed = false;
  bool _suspended = false;

  @override
  Future<void> setSuspended(bool suspended) async {
    if (_suspended == suspended) return;
    _suspended = suspended;
    ++_musicFadeGeneration;
    ++_gateGeneration;
    if (suspended) {
      await _safely(() async {
        for (final player in [
          _music,
          _effects,
          _modal,
          _win,
          ..._gatePlayers.values,
        ]) {
          if (player?.state == PlayerState.playing) await player!.pause();
        }
      });
    } else {
      await _syncMusic();
    }
  }

  Future<void> _safely(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      // Unsupported devices and browser autoplay restrictions must not block UI.
      debugPrint('SunDoku feedback unavailable: $error');
    }
  }

  @override
  Future<void> setMusicScene(MusicScene scene) {
    _track = switch (scene) {
      MusicScene.home => homeTrack,
      MusicScene.map => mapTrack,
      MusicScene.game => gameTracks[_random.nextInt(gameTracks.length)],
    };
    return _syncMusic();
  }

  @override
  Future<void> setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    return _syncMusic();
  }

  Future<void> _syncMusic() {
    final generation = ++_musicFadeGeneration;
    _musicTail = _musicTail.then(
      (_) => _safely(() async {
        if (_closed || generation != _musicFadeGeneration) return;
        if (!_musicEnabled || _suspended) {
          await _music?.pause();
          return;
        }
        if (_loadedTrack != _track) {
          final track = _track;
          AudioPlayer? incoming = AudioPlayer()..positionUpdater = null;
          try {
            // Prepare the destination while the current track keeps playing.
            await incoming.setAudioContext(_context);
            await incoming.setReleaseMode(ReleaseMode.loop);
            await incoming.setVolume(0);
            await incoming.setSource(AssetSource(track));
            if (_closed ||
                _suspended ||
                !_musicEnabled ||
                generation != _musicFadeGeneration) {
              return;
            }
            final outgoing = _music;
            if (outgoing != null) {
              await _fadeMusic(outgoing, 0, generation);
            }
            if (_closed ||
                _suspended ||
                !_musicEnabled ||
                generation != _musicFadeGeneration) {
              return;
            }
            await outgoing?.pause();
            _music = incoming;
            incoming = null;
            _loadedTrack = track;
            _musicVolume = 0;
            await outgoing?.dispose();
          } finally {
            await incoming?.dispose();
          }
        }
        if (_closed ||
            _suspended ||
            !_musicEnabled ||
            generation != _musicFadeGeneration) {
          return;
        }
        final player = _music;
        if (player == null) return;
        if (_musicEnabled && player.state != PlayerState.playing) {
          await player.resume();
        }
        await _fadeMusic(player, _winPlaying ? .04 : .24, generation);
      }),
    );
    return _musicTail;
  }

  Future<void> _fadeMusic(
    AudioPlayer player,
    double target,
    int generation,
  ) async {
    final start = _musicVolume;
    if ((target - start).abs() < .001) return;
    final steps = target < start ? 15 : 40;
    for (var step = 1; step <= steps; step++) {
      if (_closed ||
          _suspended ||
          !_musicEnabled ||
          generation != _musicFadeGeneration) {
        return;
      }
      final progress = step / steps;
      final eased = progress * progress * (3 - 2 * progress);
      _musicVolume = start + (target - start) * eased;
      await player.setVolume(_musicVolume);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  @override
  Future<void> tap({required bool sound, required bool vibration}) async {
    await _effect('audio/soft-tap.wav', sound: sound, vibration: vibration);
  }

  @override
  Future<void> toggle({
    required bool enabled,
    required bool sound,
    required bool vibration,
  }) => _effect(
    enabled ? 'audio/sfx/maximize.wav' : 'audio/sfx/minimize.wav',
    sound: sound,
    vibration: vibration,
  );

  Future<void> _effect(
    String asset, {
    required bool sound,
    required bool vibration,
  }) async {
    if (_closed || _suspended) return;
    if (vibration) unawaited(_safely(HapticFeedback.lightImpact));
    if (!sound) return;
    _effectTail = _effectTail.then(
      (_) => _safely(() async {
        if (_closed || _suspended) return;
        final player = _effects ??= AudioPlayer()..positionUpdater = null;
        await player.setAudioContext(_context);
        await player.play(AssetSource(asset), volume: .45);
      }),
    );
    await _effectTail;
  }

  @override
  Future<void> prepareEffects() async {
    await Future.wait([_prepareModal(), _prepareWin(), _prepareGate()]);
  }

  // TODO: Replace the sun's ignite/sparkle sounds and update their credits.
  Future<void> _prepareGate() => _gatePreparation ??= _safely(() async {
    for (final cue in WorldGateSound.values) {
      if (_closed) return;
      final player = _gatePlayers[cue] = AudioPlayer()..positionUpdater = null;
      await player.setAudioContext(_context);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(cue == WorldGateSound.ignite ? .35 : .65);
      await player.setSource(AssetSource('audio/sfx/gate/${cue.name}.wav'));
    }
  });

  @override
  Future<void> worldGate(WorldGateSound cue, {required bool sound}) {
    if (_closed || _suspended || !sound) return Future.value();
    final generation = _gateGeneration;
    _gateTail = _gateTail.then(
      (_) => _safely(() async {
        await _prepareGate();
        if (_closed || _suspended || generation != _gateGeneration) return;
        final player = _gatePlayers[cue];
        if (player?.source == null) return;
        await player!.seek(Duration.zero);
        if (_closed || _suspended || generation != _gateGeneration) return;
        await player.resume();
      }),
    );
    return _gateTail;
  }

  @override
  Future<void> stopWorldGate() {
    ++_gateGeneration;
    if (_closed) return Future.value();
    _gateTail = _gateTail.then(
      (_) => _safely(() async {
        for (final player in _gatePlayers.values) {
          if (player.state == PlayerState.playing) await player.pause();
        }
      }),
    );
    return _gateTail;
  }

  Future<void> _prepareWin() => _winPreparation ??= _safely(() async {
    if (_closed) return;
    final player = _win ??= AudioPlayer()..positionUpdater = null;
    _winCompleted ??= player.onPlayerComplete.listen((_) {
      _winPlaying = false;
      if (!_closed) unawaited(_syncMusic());
    });
    await player.setAudioContext(_context);
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setVolume(.45);
    await player.setSource(
      AssetSource('audio/sfx/win/mixkit-completion-of-a-level-2063.wav'),
    );
  });

  @override
  Future<void> levelCompleted({required bool sound}) {
    if (_closed || _suspended || !sound) return Future.value();
    _winTail = _winTail.then(
      (_) => _safely(() async {
        await _prepareWin();
        if (_closed || _suspended) return;
        if (_win?.source == null) return;
        _winPlaying = true;
        unawaited(_syncMusic());
        try {
          await _win?.seek(Duration.zero);
          await _win?.resume();
        } catch (_) {
          _winPlaying = false;
          await _syncMusic();
          rethrow;
        }
      }),
    );
    return _winTail;
  }

  Future<void> _prepareModal() => _modalPreparation ??= _safely(() async {
    if (_closed) return;
    final player = _modal ??= AudioPlayer()..positionUpdater = null;
    await player.setAudioContext(_context);
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setVolume(.45);
    await player.setSource(AssetSource('audio/sfx/question.wav'));
  });

  @override
  Future<void> modalOpened({required bool sound}) {
    if (_closed || _suspended || !sound) return Future.value();
    _modalTail = _modalTail.then(
      (_) => _safely(() async {
        await _prepareModal();
        if (_closed || _suspended) return;
        final player = _modal;
        if (player == null) return;
        await player.seek(Duration.zero);
        await player.resume();
      }),
    );
    return _modalTail;
  }

  @override
  Future<void> error({required bool vibration}) async {
    if (_closed || !vibration) return;
    await _safely(HapticFeedback.vibrate);
  }

  @override
  Future<void> close() async {
    _closed = true;
    await Future.wait([
      _musicTail,
      _effectTail,
      _modalTail,
      _winTail,
      _gateTail,
      ?_gatePreparation,
      ?_winPreparation,
      ?_modalPreparation,
    ]);
    await _safely(() async {
      await _music?.dispose();
      await _effects?.dispose();
      await _modal?.dispose();
      await _winCompleted?.cancel();
      await _win?.dispose();
      for (final player in _gatePlayers.values) {
        await player.dispose();
      }
    });
  }
}
