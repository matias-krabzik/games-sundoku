import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'tutorial_activity.dart';
import 'tutorial_auto_advance.dart';
import 'tutorial_story.dart';
import 'tutorial_story_navigation.dart';
import 'home_art.dart';
import 'ui_surface_art.dart';

/// Illustrated lesson title shared with the rules tutorial.
class TutorialLessonTitle extends StatelessWidget {
  const TutorialLessonTitle({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
    final text = Text(
      title,
      key: const ValueKey('intro-header-title'),
      textAlign: TextAlign.center,
      maxLines: largeText ? null : 1,
      style: homeText(largeText ? 18 : 22),
    );
    return UiSurfacePanel(
      key: const ValueKey('intro-header'),
      surface: UiSurface.goldCreamPanel,
      padding: const EdgeInsets.fromLTRB(24, 19, 24, 22),
      child: SizedBox(
        width: double.infinity,
        child: largeText ? text : FittedBox(fit: BoxFit.scaleDown, child: text),
      ),
    );
  }
}

/// Shared story header: progress stays above the lesson title.
class TutorialStepHeader extends StatelessWidget {
  const TutorialStepHeader({
    super.key,
    required this.index,
    required this.count,
    required this.child,
  });
  final int index;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TutorialStoryProgress(index: index, count: count),
      const SizedBox(height: 8),
      child,
    ],
  );
}

/// The first tutorial's entrance, reusable without recreating its child.
/// Hidden content keeps its space but cannot receive focus or semantics.
class TutorialReveal extends StatelessWidget {
  const TutorialReveal({super.key, required this.visible, required this.child});
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final duration = reduced
        ? Duration.zero
        : const Duration(milliseconds: 350);
    return IgnorePointer(
      ignoring: !visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: ExcludeFocus(
          excluding: !visible,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: duration,
            child: AnimatedSlide(
              offset: visible ? Offset.zero : const Offset(0, .04),
              duration: duration,
              curve: Curves.easeOut,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

typedef TutorialPresentationBuilder = Widget Function(
  BuildContext context,
  TutorialPresentationState presentation,
);

/// Reusable sequence: scene entrance → typed explanation → demonstration →
/// reading pause → optional advance. Progress is supplied by the owning flow,
/// so animation never mutates saved game state or starts a game on its own.
/// Place inside [TutorialActivity] to suspend the complete sequence together.
class TutorialPresentation extends StatefulWidget {
  const TutorialPresentation({
    super.key,
    required this.step,
    required this.demonstrationDuration,
    required this.builder,
    this.scene,
    this.readingPause = const Duration(seconds: 2),
    this.onAdvance,
  });
  final Object step;

  /// Steps with the same scene keep its entrance and mounted content intact.
  /// Defaults to [step] for lessons that introduce a new scene at every step.
  final Object? scene;
  final Duration demonstrationDuration;
  final Duration readingPause;
  final VoidCallback? onAdvance;
  final TutorialPresentationBuilder builder;

  @override
  State<TutorialPresentation> createState() => TutorialPresentationState();
}

class TutorialPresentationState extends State<TutorialPresentation>
    with TickerProviderStateMixin {
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..addStatusListener(_changed);
  late final _demonstration = AnimationController(
    vsync: this,
    duration: widget.demonstrationDuration,
  )..addStatusListener(_changed);
  bool _narrated = false;
  bool _queued = false;
  bool _waitingForNext = false;
  bool _active = false;
  ValueListenable<bool>? _activity;
  bool _reduced = false;
  bool _accessible = false;

  Animation<double> get entrance => _entrance;
  Animation<double> get demonstration => _demonstration;
  bool get storyVisible => _entrance.isCompleted;

  /// Completes this step without advancing; the next press may change steps.
  /// A manual reveal cancels automatic advance until the owning flow moves on.
  bool finishAnimations(TutorialStoryController story) {
    final storyChanged = story.finish();
    if (!storyChanged && _entrance.isCompleted && _demonstration.isCompleted) {
      return false;
    }
    _waitingForNext = true;
    _narrated = true;
    _entrance.value = 1;
    _demonstration.value = 1;
    setState(() {});
    return true;
  }

  /// Connect to TutorialStory.onFinished, not a guessed typing duration.
  void storyFinished() {
    if (_narrated) return;
    _narrated = true;
    _schedule();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activity = TutorialActivity.of(context);
    if (activity != _activity) {
      _activity?.removeListener(_activityChanged);
      _activity = activity;
      _activity?.addListener(_activityChanged);
    }
    _activityChanged();
    _accessible = MediaQuery.accessibleNavigationOf(context);
    _reduced = _accessible || MediaQuery.disableAnimationsOf(context);
    _schedule();
  }

  @override
  void didUpdateWidget(TutorialPresentation oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sceneChanged =
        (oldWidget.scene ?? oldWidget.step) != (widget.scene ?? widget.step);
    if (oldWidget.step != widget.step || sceneChanged) {
      _narrated = false;
      _waitingForNext = false;
      if (sceneChanged) _entrance.reset();
      _demonstration.reset();
      _demonstration.duration = widget.demonstrationDuration;
    }
    _schedule();
  }

  void _activityChanged() {
    _active = _activity?.value ?? true;
    if (!_active) {
      _entrance.stop();
      _demonstration.stop();
    } else {
      _schedule();
    }
  }

  void _changed(AnimationStatus _) => _schedule();

  void _schedule() {
    if (_queued) return;
    _queued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queued = false;
      if (!mounted) return;
      if (!_active) {
        _entrance.stop();
        _demonstration.stop();
        return;
      }
      if (!_entrance.isCompleted) {
        if (_reduced) {
          _entrance.value = 1;
        } else if (!_entrance.isAnimating) {
          _entrance.forward();
        }
      } else if (_narrated && !_demonstration.isCompleted) {
        if (_reduced) {
          _demonstration.value = 1;
        } else if (!_demonstration.isAnimating) {
          _demonstration.forward();
        }
      }
      setState(() {});
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _activity?.removeListener(_activityChanged);
    _entrance.dispose();
    _demonstration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TutorialAutoAdvance(
    step: (widget.scene ?? widget.step, widget.step),
    ready: _narrated && _demonstration.isCompleted && !_waitingForNext,
    readingPause: widget.readingPause,
    onAdvance: widget.onAdvance,
    child: widget.builder(context, this),
  );
}
