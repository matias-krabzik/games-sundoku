import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_feedback_scope.dart';
import 'map_art.dart';

/// Star geometry shared by the indicator, light masking and award destination.
Offset mapScoreStarOffset(int socket, double nodeSize) {
  assert(socket >= 0 && socket < 3);
  return Offset(
    (socket - 1) * nodeSize * .40,
    -nodeSize * (socket == 1 ? .68 : .60),
  );
}

double mapScoreStarSize(int socket, [double nodeSize = 100]) =>
    nodeSize * (socket == 1 ? .34 : .29);

/// The approved illustrated medallion with independently earned stars.
class MapLevelButton extends StatelessWidget {
  const MapLevelButton({
    super.key,
    required this.level,
    required this.active,
    required this.lights,
    required this.unlocked,
    required this.onTap,
  });

  final int level;
  final bool active;
  final int lights;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Nivel $level',
    value: unlocked
        ? 'Disponible, $lights de 3 puntos'
        : 'Bloqueado, consigue 3 puntos en el nivel ${level - 1}',
    button: true,
    selected: active,
    child: LayoutBuilder(
      builder: (context, bounds) {
        final size = bounds.maxWidth;
        final reduced = MediaQuery.disableAnimationsOf(context);
        final gold = unlocked && (active || lights == 3);
        final artwork = MapMarkerArt(gold: gold);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -size * .16,
              top: -size * .35,
              width: size * 1.32,
              height: size * 1.34,
              child: IgnorePointer(
                child: AnimatedScale(
                  scale: active ? 1.035 : 1,
                  duration: reduced
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey('level-$level-star-crest'),
                    child: unlocked
                        ? artwork
                        : ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFAFBBC3),
                              BlendMode.modulate,
                            ),
                            child: artwork,
                          ),
                  ),
                ),
              ),
            ),
            for (int socket = 0; socket < 3; socket++)
              Positioned(
                left:
                    size / 2 +
                    mapScoreStarOffset(socket, size).dx -
                    mapScoreStarSize(socket, size) / 2,
                top:
                    size / 2 +
                    mapScoreStarOffset(socket, size).dy -
                    mapScoreStarSize(socket, size) / 2,
                child: IgnorePointer(
                  child: _ScoreStar(
                    key: ValueKey('level-$level-score-${socket + 1}'),
                    size: mapScoreStarSize(socket, size),
                    earned: lights > socket,
                    reduced: reduced,
                  ),
                ),
              ),
            SizedBox.square(
              dimension: size,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    GameFeedbackScope.tap(context);
                    onTap();
                  },
                  child: Center(
                    child: Image.asset(
                      'assets/images/level-number-$level.png',
                      key: ValueKey('level-$level-label'),
                      width: level == 10 ? size * .60 : size * .49,
                      height: size * .58,
                      fit: BoxFit.contain,
                      cacheWidth: 200,
                      excludeFromSemantics: true,
                      opacity: AlwaysStoppedAnimation(unlocked ? 1 : .58),
                    ),
                  ),
                ),
              ),
            ),
            if (!unlocked)
              Positioned(
                right: -2,
                bottom: 18,
                child: IgnorePointer(
                  child: SizedBox.square(
                    dimension: size * .28,
                    child: const Stack(
                      fit: StackFit.expand,
                      children: [
                        MapRoundSurface(),
                        Padding(
                          padding: EdgeInsets.all(4),
                          child: MapIcon(MapGlyph.lock, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _ScoreStar extends StatelessWidget {
  const _ScoreStar({
    super.key,
    required this.size,
    required this.earned,
    required this.reduced,
  });
  final double size;
  final bool earned;
  final bool reduced;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: earned ? 1 : 0, end: earned ? 1 : 0),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic,
      builder: (context, value, _) => SizedBox.square(
        dimension: size,
        child: Transform.scale(
          scale: 1 + math.sin(value * math.pi) * .18,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MapIcon(MapGlyph.emptyStar, size: size),
              Opacity(
                opacity: value.clamp(0, 1),
                child: MapIcon(MapGlyph.goldStar, size: size),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
