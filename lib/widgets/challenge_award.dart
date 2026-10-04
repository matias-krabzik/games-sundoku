import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'map_art.dart';
import 'home_art.dart';
import 'score_feedback.dart';
import 'ui_surface_art.dart';

/// Shared read-only award art for saved results and isolated demonstrations.
class ChallengeAward extends StatelessWidget {
  const ChallengeAward({
    super.key,
    required this.stars,
    this.size = 56,
    this.points,
    this.target,
    this.ceiling,
    this.pulseIndex,
    this.pulseScale = 1,
  });
  final int stars;
  final double size;
  final int? points, target, ceiling, pulseIndex;
  final double pulseScale;
  int get _ceiling =>
      math.max(1, math.max(ceiling ?? target ?? 1, target ?? 1));
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Semantics(
        label: '$stars de 3 estrellas ganadas',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Transform.scale(
                key: ValueKey('challenge-star-$i'),
                scale: i == pulseIndex ? pulseScale : 1,
                child: MapIcon(
                  i < stars ? MapGlyph.goldStar : MapGlyph.emptyStar,
                  size: size,
                ),
              ),
          ],
        ),
      ),
      if (points != null && target != null) ...[
        const SizedBox(height: 8),
        SizedBox(
          height: MediaQuery.textScalerOf(context).scale(18) * 1.5,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${formatScore(points!)} / ${formatScore(target!)} puntos',
              key: const ValueKey('challenge-panel-points'),
              textAlign: TextAlign.center,
              style: homeText(18),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          value: '${(points! / target! * 100).round()} por ciento de la meta',
          child: SizedBox(
            height: 16,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: UiSurfaceArt(UiSurface.progressTrack),
                ),
                FractionallySizedBox(
                  key: const ValueKey('challenge-score-fill'),
                  widthFactor: (points! / _ceiling).clamp(0.0, 1.0),
                  heightFactor: 1,
                  child: const UiSurfaceArt(UiSurface.progressFill),
                ),
                Align(
                  alignment: Alignment(2 * target! / _ceiling - 1, 0),
                  child: const SizedBox(
                    key: ValueKey('challenge-score-threshold'),
                    width: 3,
                    height: 16,
                    child: ColoredBox(color: homeNavy),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ],
  );
}
