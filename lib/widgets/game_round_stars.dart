import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'map_art.dart';

class GameRoundStars extends StatefulWidget {
  const GameRoundStars({
    super.key,
    required this.levelNumber,
    required this.currentRound,
    required this.completedRounds,
    this.animate = true,
  }) : assert(currentRound >= 0 && currentRound < 3);

  final int levelNumber;
  final int currentRound;
  final Set<int> completedRounds;
  final bool animate;

  @override
  State<GameRoundStars> createState() => _GameRoundStarsState();
}

class _GameRoundStarsState extends State<GameRoundStars>
    with SingleTickerProviderStateMixin {
  static const _currentScale = 1.1;
  static const _otherScale = .85;
  static const _motionPadding = 3.0;
  late final _sway = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  bool _motionAllowed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.maybeOf(context);
    _motionAllowed =
        !(media?.disableAnimations ?? false) &&
        !(media?.accessibleNavigation ?? false) &&
        TickerMode.valuesOf(context).enabled;
    _syncMotion();
  }

  @override
  void didUpdateWidget(GameRoundStars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentRound != oldWidget.currentRound) _sway.value = 0;
    _syncMotion();
  }

  void _syncMotion() {
    final moving =
        widget.animate &&
        _motionAllowed &&
        !widget.completedRounds.contains(widget.currentRound);
    if (moving) {
      if (!_sway.isAnimating) _sway.repeat();
    } else {
      _sway.stop();
      _sway.value = 0;
    }
  }

  @override
  void dispose() {
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: LayoutBuilder(
      builder: (context, bounds) {
        final gap = math.min(4.0, bounds.maxWidth / 8);
        // Equal slots keep the header steady as the current round changes.
        final slot = math.max(
          0.0,
          math.min(
            36 * _currentScale + _motionPadding * 2,
            math.min(bounds.maxHeight, (bounds.maxWidth - gap * 2) / 3),
          ),
        );
        final baseSize = math.max(
          0.0,
          (slot - _motionPadding * 2) / _currentScale,
        );
        return Center(
          child: Semantics(
            label:
                'Nivel ${widget.levelNumber}. Ronda ${widget.currentRound + 1} de 3. '
                '${widget.completedRounds.length} de 3 estrellas ganadas',
            image: true,
            excludeSemantics: true,
            child: Row(
              key: const ValueKey('game-round-stars'),
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < 3; index++) ...[
                  if (index > 0) SizedBox(width: gap),
                  SizedBox.square(
                    dimension: slot,
                    child: Center(
                      child: _star(
                        index,
                        baseSize *
                            (index == widget.currentRound
                                ? _currentScale
                                : _otherScale),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget _star(int index, double size) {
    final art = MapIcon(
      widget.completedRounds.contains(index)
          ? MapGlyph.goldStar
          : MapGlyph.emptyStar,
      key: ValueKey('game-round-star-$index'),
      size: size,
    );
    if (index != widget.currentRound) return art;
    return AnimatedBuilder(
      animation: _sway,
      child: art,
      builder: (context, child) {
        final beat = math.sin(_sway.value * math.pi * 2);
        return Transform.translate(
          key: const ValueKey('game-current-star-float'),
          offset: Offset(0, -beat * size * .035),
          child: Transform.rotate(
            key: const ValueKey('game-current-star-sway'),
            angle: beat * .045,
            child: child,
          ),
        );
      },
    );
  }
}
