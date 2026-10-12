import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_feedback_scope.dart';
import 'map_art.dart';
import 'home_art.dart';

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
class MapLevelButton extends StatefulWidget {
  const MapLevelButton({
    super.key,
    required this.level,
    required this.active,
    required this.lights,
    required this.unlocked,
    this.lockedReason,
    required this.onTap,
  });

  final int level;
  final bool active;
  final int lights;
  final bool unlocked;
  final String? lockedReason;
  final VoidCallback onTap;

  @override
  State<MapLevelButton> createState() => _MapLevelButtonState();
}

class _MapLevelButtonState extends State<MapLevelButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Nivel ${widget.level}',
    value: widget.unlocked
        ? 'Disponible, ${widget.lights} de 3 puntos'
        : 'Bloqueado, ${widget.lockedReason ?? 'consigue 3 puntos en el nivel ${widget.level - 1}'}',
    button: true,
    selected: widget.active,
    child: LayoutBuilder(
      builder: (context, bounds) {
        final size = bounds.maxWidth;
        final reduced = MediaQuery.disableAnimationsOf(context);
        final gold = widget.unlocked && (widget.active || widget.lights == 3);
        final artwork = MapMarkerArt(gold: gold);
        return AnimatedScale(
          scale: _hovered && !reduced && widget.unlocked ? 1.03 : 1,
          duration: reduced ? Duration.zero : const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -size * .16,
                top: -size * .35,
                width: size * 1.32,
                height: size * 1.34,
                child: IgnorePointer(
                  child: AnimatedScale(
                    scale: widget.active ? 1.035 : 1,
                    duration: reduced
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey('level-${widget.level}-star-crest'),
                      child: widget.unlocked
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
                      key: ValueKey(
                        'level-${widget.level}-score-${socket + 1}',
                      ),
                      size: mapScoreStarSize(socket, size),
                      earned: widget.lights > socket,
                      reduced: reduced,
                    ),
                  ),
                ),
              MouseRegion(
                onEnter: (_) {
                  if (!mounted || !widget.unlocked) return;
                  setState(() => _hovered = true);
                },
                onExit: (_) {
                  if (!mounted || !widget.unlocked) return;
                  setState(() => _hovered = false);
                },
                child: SizedBox.square(
                  dimension: size,
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        GameFeedbackScope.tap(context);
                        widget.onTap();
                      },
                      child: Center(
                        child: Transform.translate(
                          // The ribbon puts the illustrated circle above the
                          // hit area's center. Also balance Baloo's baseline.
                          offset: Offset(0, -size * (gold ? .07 : .06)),
                          child: SizedBox(
                            width: size * .64,
                            height: size * .50,
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: ExcludeSemantics(
                                  child: Text(
                                    '${widget.level}',
                                    key: ValueKey(
                                      'level-${widget.level}-label',
                                    ),
                                    maxLines: 1,
                                    softWrap: false,
                                    textScaler: TextScaler.noScaling,
                                    style: homeText(size * .44).copyWith(
                                      height: 1,
                                      color: homeNavy.withValues(
                                        alpha: widget.unlocked ? 1 : .58,
                                      ),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!widget.unlocked)
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
          ),
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
