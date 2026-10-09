import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'tutorial_activity.dart';

/// With instant text, allow the time that would otherwise be spent typing it.
Duration tutorialReadingPause(BuildContext context, int characterCount) =>
    Duration(
      milliseconds:
          2000 +
          (MediaQuery.disableAnimationsOf(context) ? characterCount * 32 : 0),
    );

/// Advances once after narration and demonstration finish, while visible.
/// Changing steps cancels the old pause; covering the lesson suspends it.
class TutorialAutoAdvance extends StatefulWidget {
  const TutorialAutoAdvance({
    super.key,
    required this.step,
    required this.ready,
    required this.child,
    this.readingPause = const Duration(seconds: 2),
    this.onAdvance,
  });

  final Object step;
  final bool ready;
  final Duration readingPause;
  final VoidCallback? onAdvance;
  final Widget child;

  @override
  State<TutorialAutoAdvance> createState() => _TutorialAutoAdvanceState();
}

class _TutorialAutoAdvanceState extends State<TutorialAutoAdvance>
    with SingleTickerProviderStateMixin {
  late final _reading = AnimationController(
    vsync: this,
    duration: widget.readingPause,
  )..addStatusListener((_) => _schedule());
  ValueListenable<bool>? _activity;
  bool _accessible = false;
  bool _advanced = false;
  bool _queued = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activity = TutorialActivity.of(context);
    if (activity != _activity) {
      _activity?.removeListener(_activityChanged);
      _activity = activity;
      _activity?.addListener(_activityChanged);
    }
    _accessible = MediaQuery.accessibleNavigationOf(context);
    _activityChanged();
  }

  @override
  void didUpdateWidget(TutorialAutoAdvance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.step != oldWidget.step) {
      _advanced = false;
      _reading.reset();
    }
    _reading.duration = widget.readingPause;
    if (!widget.ready || widget.onAdvance == null) _reading.reset();
    _schedule();
  }

  void _activityChanged() {
    if (_activity?.value == false || _accessible) _reading.stop();
    _schedule();
  }

  void _schedule() {
    if (_queued) return;
    _queued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queued = false;
      if (!mounted) return;
      if (_activity?.value == false ||
          _accessible ||
          !widget.ready ||
          widget.onAdvance == null ||
          _advanced) {
        _reading.stop();
        return;
      }
      if (_reading.isCompleted) {
        _advanced = true;
        widget.onAdvance!();
      } else if (!_reading.isAnimating) {
        _reading.forward();
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _activity?.removeListener(_activityChanged);
    _reading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
