import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/repositories/game_repository.dart';
import '../data/services/game_feedback.dart';

class GameFeedbackScope extends InheritedWidget {
  const GameFeedbackScope({
    super.key,
    required this.onTap,
    this.onError,
    required super.child,
  });

  final VoidCallback onTap;
  final VoidCallback? onError;

  static void tap(BuildContext context) =>
      context.getInheritedWidgetOfExactType<GameFeedbackScope>()?.onTap();

  static void error(BuildContext context) => context
      .getInheritedWidgetOfExactType<GameFeedbackScope>()
      ?.onError
      ?.call();

  @override
  bool updateShouldNotify(GameFeedbackScope oldWidget) =>
      onTap != oldWidget.onTap || onError != oldWidget.onError;
}

class GameFeedbackHost extends StatefulWidget {
  const GameFeedbackHost({
    super.key,
    required this.repository,
    required this.output,
    required this.child,
  });

  final GameRepository repository;
  final GameFeedback output;
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
    widget.repository.addListener(_syncMusic);
  }

  void _syncMusic() {
    final playing =
        _engaged && _foreground && widget.repository.state.settings.music;
    if (_playing == playing) return;
    _playing = playing;
    unawaited(widget.output.setMusicEnabled(playing));
  }

  void _engage() {
    // The first user gesture also permits audio in browsers with autoplay limits.
    _engaged = true;
    _syncMusic();
  }

  void _tap() {
    _engage();
    final settings = widget.repository.state.settings;
    unawaited(
      widget.output.tap(sound: settings.sound, vibration: settings.vibration),
    );
  }

  void _error() {
    if (!_foreground) return;
    unawaited(
      widget.output.error(
        vibration: widget.repository.state.settings.vibration,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncMusic();
  }

  @override
  void dispose() {
    widget.repository.removeListener(_syncMusic);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(widget.output.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GameFeedbackScope(
    onTap: _tap,
    onError: _error,
    child: Listener(onPointerDown: (_) => _engage(), child: widget.child),
  );
}
