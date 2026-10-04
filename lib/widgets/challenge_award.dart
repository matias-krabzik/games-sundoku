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
  });
  final int stars;
  final double size;
  final int? points, target;
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
              MapIcon(
                i < stars ? MapGlyph.goldStar : MapGlyph.emptyStar,
                size: size,
              ),
          ],
        ),
      ),
      if (points != null && target != null) ...[
        const SizedBox(height: 8),
        Text(
          '${formatScore(points!)} / ${formatScore(target!)} puntos',
          textAlign: TextAlign.center,
          style: homeText(18),
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
                  widthFactor: (points! / target!).clamp(0.0, 1.0),
                  heightFactor: 1,
                  child: const UiSurfaceArt(UiSurface.progressFill),
                ),
              ],
            ),
          ),
        ),
      ],
    ],
  );
}
