import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/first_experience_controller.dart';
import 'home_art.dart';

String formatScore(int points) => points.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => '.',
);

class GameScoreCounter extends StatelessWidget {
  const GameScoreCounter({super.key, required this.points});
  final int points;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Puntaje: $points puntos',
    liveRegion: true,
    excludeSemantics: true,
    child: TweenAnimationBuilder<double>(
      key: ValueKey(points),
      tween: Tween(begin: 1.12, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 240),
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Text(
        '${formatScore(points)} pts',
        key: const ValueKey('game-score'),
        maxLines: 1,
        style: homeText(20),
      ),
    ),
  );
}

/// A transient overlay; it never intercepts board input or persists in saves.
class BoardScoreFeedback extends StatefulWidget {
  const BoardScoreFeedback({super.key, required this.feedback});
  final ScoreFeedback? feedback;

  @override
  State<BoardScoreFeedback> createState() => _BoardScoreFeedbackState();
}

class _BoardScoreFeedbackState extends State<BoardScoreFeedback>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );
  final _random = math.Random();
  double _jitter = 0;

  @override
  void didUpdateWidget(BoardScoreFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.feedback != null && widget.feedback != oldWidget.feedback) {
      _jitter = _random.nextDouble() * .08 - .04;
      if (!MediaQuery.disableAnimationsOf(context) &&
          !MediaQuery.accessibleNavigationOf(context)) {
        _animation.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, bounds) {
          final feedback = widget.feedback;
          if (feedback == null) return const SizedBox.shrink();
          final x = ((feedback.origin % 9 + .5) / 9 + _jitter).clamp(.16, .84);
          final y = ((feedback.origin ~/ 9 + .5) / 9).clamp(.18, .92);
          return AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              if (!_animation.isAnimating) return const SizedBox.shrink();
              final t = _animation.value;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: (bounds.maxWidth * x - 64).clamp(
                      0,
                      math.max(0, bounds.maxWidth - 128),
                    ),
                    top:
                        bounds.maxHeight * y -
                        24 -
                        48 * Curves.easeOut.transform(t),
                    width: 128,
                    child: Opacity(
                      key: const ValueKey('score-popup'),
                      opacity: (1 - t).clamp(0, 1),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${feedback.points > 0 ? '+' : '−'}${formatScore(feedback.points.abs())}',
                          style: homeText(32).copyWith(
                            color: feedback.points > 0
                                ? const Color(0xFFFFD13D)
                                : const Color(0xFFFF8169),
                            shadows: const [
                              Shadow(color: homeNavy, offset: Offset(-1, -1)),
                              Shadow(color: homeNavy, offset: Offset(1, -1)),
                              Shadow(color: homeNavy, offset: Offset(-1, 1)),
                              Shadow(
                                color: homeNavy,
                                offset: Offset(1, 2),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    ),
  );
}
