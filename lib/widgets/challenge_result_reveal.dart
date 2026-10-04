import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'game_feedback_scope.dart';
import 'tutorial_activity.dart';
import 'victory_particles.dart';

/// Presentation only: the saved result remains the authority for the reward.
class ChallengeResultReveal extends StatefulWidget {
  const ChallengeResultReveal({
    super.key,
    required this.points,
    required this.target,
    required this.won,
    required this.builder,
    this.animate = true,
  });
  final int points, target;
  final bool won, animate;
  final Widget Function(BuildContext, ChallengeResultRevealState) builder;

  @override
  State<ChallengeResultReveal> createState() => ChallengeResultRevealState();
}

class ChallengeResultRevealState extends State<ChallengeResultReveal>
    with TickerProviderStateMixin {
  late final _count = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..addListener(_tick);
  late final _celebration = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..addListener(_refresh);
  ValueListenable<bool>? _activity;
  bool _reduced = false;
  bool _celebrated = false;
  bool _initialized = false;
  bool _hasCelebration = false;

  int get points => complete
      ? widget.points
      : (widget.points * Curves.easeOutCubic.transform(_count.value)).floor();
  bool get complete => _count.isCompleted;
  bool get earned => widget.won && points >= widget.target;
  double get pulse => _reduced || !_celebration.isAnimating
      ? 1
      : 1 + .18 * math.sin(math.pi * (_celebration.value * 3).clamp(0, 1));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final activity = TutorialActivity.of(context);
    if (_activity != activity) {
      _activity?.removeListener(_activityChanged);
      _activity = activity;
      _activity?.addListener(_activityChanged);
    }
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!widget.animate || _reduced || widget.points == 0) {
          _celebrated = true;
          _count.value = 1;
        } else {
          _activityChanged();
        }
      });
    } else if (_reduced) {
      _celebrated = true;
      _count.value = 1;
      _celebration.value = 1;
    }
  }

  void _activityChanged() {
    if (_activity?.value == false) {
      _count.stop();
      _celebration.stop();
    } else {
      if (!complete) _count.forward();
      if (_hasCelebration && !_celebration.isCompleted) {
        _celebration.forward();
      }
    }
    _refresh();
  }

  void _tick() {
    if (earned && !_celebrated) {
      _celebrated = true;
      if (!_reduced) {
        _hasCelebration = true;
        GameFeedbackScope.levelCompleted(context);
        _celebration.forward();
      }
    }
    _refresh();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void finish() {
    if (!complete) _count.value = 1;
  }

  @override
  void dispose() {
    _activity?.removeListener(_activityChanged);
    _count.dispose();
    _celebration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      GestureDetector(
        onTap: complete ? null : finish,
        child: widget.builder(context, this),
      ),
      if (_hasCelebration && !_reduced && !_celebration.isCompleted)
        Positioned.fill(
          child: IgnorePointer(
            child: TickerMode(
              enabled: _activity?.value != false,
              child: VictoryParticles(
                entrance: _celebration,
                grandFinale: false,
              ),
            ),
          ),
        ),
    ],
  );
}
