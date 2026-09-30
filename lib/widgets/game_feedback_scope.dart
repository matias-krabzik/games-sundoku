import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/repositories/game_repository.dart';
import '../data/services/game_feedback.dart';
import '../playables/playables_runtime.dart';

class GameFeedbackScope extends InheritedWidget {
  const GameFeedbackScope({
    super.key,
    required this.onTap,
    this.onError,
    this.onToggle,
    this.onLevelCompleted,
    this.onWorldGate,
    this.onStopWorldGate,
    required super.child,
  });

  final VoidCallback onTap;
  final VoidCallback? onError;
  final VoidCallback? onLevelCompleted;
  final void Function(WorldGateSound cue)? onWorldGate;
  final VoidCallback? onStopWorldGate;

  static void levelCompleted(BuildContext context) => context
      .getInheritedWidgetOfExactType<GameFeedbackScope>()
      ?.onLevelCompleted
      ?.call();
  final void Function(bool enabled, bool sound)? onToggle;

  static void toggle(
    BuildContext context, {
    required bool enabled,
    required bool sound,
  }) => context
      .getInheritedWidgetOfExactType<GameFeedbackScope>()
      ?.onToggle
      ?.call(enabled, sound);

  static void tap(BuildContext context) =>
      context.getInheritedWidgetOfExactType<GameFeedbackScope>()?.onTap();

  static void error(BuildContext context) => context
      .getInheritedWidgetOfExactType<GameFeedbackScope>()
      ?.onError
      ?.call();

  @override
  bool updateShouldNotify(GameFeedbackScope oldWidget) =>
      onTap != oldWidget.onTap ||
      onError != oldWidget.onError ||
      onToggle != oldWidget.onToggle ||
      onLevelCompleted != oldWidget.onLevelCompleted ||
      onWorldGate != oldWidget.onWorldGate ||
      onStopWorldGate != oldWidget.onStopWorldGate;
}

class GameFeedbackHost extends StatefulWidget {
  const GameFeedbackHost({
    super.key,
    required this.repository,
    required this.output,
    this.playables,
    required this.child,
  });

  final GameRepository repository;
  final GameFeedback output;
  final PlayablesRuntime? playables;
  final Widget child;

  @override
  State<GameFeedbackHost> createState() => _GameFeedbackHostState();
}

class _GameFeedbackHostState extends State<GameFeedbackHost>
    with WidgetsBindingObserver {
  bool _engaged = false;
  bool _foreground = true;
  bool? _playing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.playables?.addListener(_syncMusic);
    widget.repository.addListener(_syncMusic);
    if (widget.playables == null) unawaited(widget.output.prepareEffects());
  }

  void _syncMusic() {
    final available =
        _foreground &&
        widget.playables?.isPaused != true &&
        widget.playables?.audioEnabled != false;
    unawaited(widget.output.setSuspended(!available));
    if (!available || !widget.repository.state.settings.sound) {
      _stopWorldGate();
    }
    final playing =
        _engaged && available && widget.repository.state.settings.music;
    if (_playing == playing) return;
    _playing = playing;
    unawaited(widget.output.setMusicEnabled(playing));
  }

  void _engage() {
    // The first user gesture also permits audio in browsers with autoplay limits.
    if (!_engaged && widget.playables != null) {
      unawaited(widget.output.prepareEffects());
    }
    _engaged = true;
    _syncMusic();
  }

  void _tap() {
    if (widget.playables?.isPaused == true) return;
    _engage();
    final settings = widget.repository.state.settings;
    unawaited(
      widget.output.tap(
        sound: settings.sound && widget.playables?.audioEnabled != false,
        vibration: settings.vibration,
      ),
    );
  }

  void _toggle(bool enabled, bool sound) {
    if (widget.playables?.isPaused == true) return;
    _engage();
    unawaited(
      widget.output.toggle(
        enabled: enabled,
        sound: sound && widget.playables?.audioEnabled != false,
        vibration: widget.repository.state.settings.vibration,
      ),
    );
  }

  void _levelCompleted() {
    if (!_foreground || widget.playables?.isPaused == true) return;
    unawaited(
      widget.output.levelCompleted(
        sound:
            widget.repository.state.settings.sound &&
            widget.playables?.audioEnabled != false,
      ),
    );
  }

  void _error() {
    if (!_foreground || widget.playables?.isPaused == true) return;
    unawaited(
      widget.output.error(
        vibration: widget.repository.state.settings.vibration,
      ),
    );
  }

  void _worldGate(WorldGateSound cue) {
    if (!_foreground || widget.playables?.isPaused == true) return;
    unawaited(
      widget.output.worldGate(
        cue,
        sound:
            widget.repository.state.settings.sound &&
            widget.playables?.audioEnabled != false,
      ),
    );
  }

  void _stopWorldGate() => unawaited(widget.output.stopWorldGate());

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.playables?.inPlayablesEnvironment == true) return;
    _foreground = state == AppLifecycleState.resumed;
    _syncMusic();
  }

  @override
  void dispose() {
    widget.repository.removeListener(_syncMusic);
    widget.playables?.removeListener(_syncMusic);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(widget.output.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GameFeedbackScope(
    onTap: _tap,
    onError: _error,
    onToggle: _toggle,
    onLevelCompleted: _levelCompleted,
    onWorldGate: _worldGate,
    onStopWorldGate: _stopWorldGate,
    child: Listener(onPointerDown: (_) => _engage(), child: widget.child),
  );
}
