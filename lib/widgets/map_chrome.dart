import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_feedback_scope.dart';
import 'home_art.dart';
import 'juicy_press.dart';
import 'map_art.dart';

class MapWorldHeader extends StatelessWidget {
  const MapWorldHeader({
    super.key,
    required this.onBack,
    this.onViewTutorial,
    this.compact = false,
  });

  final VoidCallback onBack;
  final VoidCallback? onViewTutorial;
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _MapRoundButton(
        key: const ValueKey('map-back'),
        label: 'Volver',
        glyph: MapGlyph.back,
        size: compact ? 50 : 58,
        onPressed: onBack,
      ),
      if (onViewTutorial != null) ...[
        const SizedBox(width: 8),
        _MapRoundButton(
          key: const ValueKey('map-tutorial'),
          label: 'Ver el tutorial',
          icon: Icons.menu_book_rounded,
          size: compact ? 50 : 58,
          onPressed: onViewTutorial,
        ),
      ],
      const SizedBox(width: 12),
      Expanded(
        child: Align(
          alignment: Alignment.topRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 236 : 260),
            child: SizedBox(
              height: compact ? 66 : 78,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const HomeArt(HomeSurface.status),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 11, 17, compact ? 13 : 16),
                    child: Row(
                      children: [
                        if (MediaQuery.sizeOf(context).width >= 400 ||
                            onViewTutorial == null) ...[
                          HomeIcon(HomeGlyph.sun, size: compact ? 39 : 46),
                          const SizedBox(width: 7),
                        ],
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'MUNDO 1',
                                    style: homeText(12).copyWith(
                                      color: const Color(0xFFA46A0E),
                                      letterSpacing: 2.3,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Flexible(
                                flex: 2,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Valle del Sol',
                                    style: homeText(compact ? 22 : 26),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class MapStatusCard extends StatelessWidget {
  const MapStatusCard({
    super.key,
    required this.level,
    required this.totalLevels,
    required this.points,
    required this.unlocked,
    required this.onPrevious,
    required this.onNext,
    this.compact = false,
  });

  final int level;
  final int totalLevels;
  final int points;
  final bool unlocked;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool compact;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 370),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, 370.0);
        final unit = (width / 350).clamp(.82, 1.06);
        final height = (compact ? 88.0 : 102.0) + (unlocked ? 0 : 12);
        final status = unlocked
            ? '$points/3 puntos obtenidos'
            : 'Consigue 3 puntos en el nivel ${level - 1}';

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const HomeArt(HomeSurface.status),
              Padding(
                padding: EdgeInsets.fromLTRB(16 * unit, 12, 16 * unit, 16),
                child: Row(
                  children: [
                    _MapRoundButton(
                      key: const ValueKey('map-previous'),
                      label: 'Nivel anterior',
                      glyph: MapGlyph.chevron,
                      mirrored: true,
                      gold: onPrevious != null,
                      size: compact ? 48 : 50 * unit,
                      onPressed: onPrevious,
                    ),
                    SizedBox(width: 6 * unit),
                    Expanded(
                      child: Semantics(
                        label: 'Nivel $level de $totalLevels. $status',
                        excludeSemantics: true,
                        child: Column(
                          children: [
                            Expanded(
                              flex: 3,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Nivel $level de $totalLevels',
                                  style: homeText(23 * unit),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Expanded(
                              flex: unlocked ? 2 : 3,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: SizedBox(
                                  width: unlocked ? null : 190,
                                  child: Text(
                                    status,
                                    textAlign: TextAlign.center,
                                    style: homeText(
                                      14 * unit,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            SizedBox(
                              height: compact ? 21 : 26,
                              child: _MapPointsTrack(
                                points: unlocked ? points : 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 6 * unit),
                    _MapRoundButton(
                      key: const ValueKey('map-next'),
                      label: 'Nivel siguiente',
                      glyph: MapGlyph.chevron,
                      gold: onNext != null,
                      size: compact ? 48 : 50 * unit,
                      onPressed: onNext,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _MapPointsTrack extends StatelessWidget {
  const _MapPointsTrack({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 160),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final starSize = constraints.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: starSize / 2),
              child: Center(
                child: SizedBox(
                  height: 8,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const HomeArt(HomeSurface.progressTrack),
                      Padding(
                        padding: const EdgeInsets.all(1),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: (points / 3).clamp(0, 1),
                            heightFactor: 1,
                            child: const HomeArt(HomeSurface.progressFill),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var index = 0; index < 3; index++)
                  MapIcon(
                    index < points ? MapGlyph.goldStar : MapGlyph.emptyStar,
                    size: starSize,
                  ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

class _MapRoundButton extends StatelessWidget {
  const _MapRoundButton({
    super.key,
    required this.label,
    this.glyph,
    this.icon,
    required this.size,
    required this.onPressed,
    this.gold = false,
    this.mirrored = false,
  });

  final String label;
  final MapGlyph? glyph;
  final IconData? icon;
  final double size;
  final VoidCallback? onPressed;
  final bool gold;
  final bool mirrored;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: SizedBox.square(
      dimension: math.max(48, size),
      child: JuicyPress(
        label: label,
        onFeedback: () => GameFeedbackScope.tap(context),
        onPressed: onPressed,
        builder: (context, depression) => Center(
          child: SizedBox.square(
            dimension: size,
            child: Opacity(
              opacity: onPressed == null ? .42 : 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MapRoundSurface(gold: gold),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Transform.flip(
                        flipX: mirrored,
                        child: icon != null
                            ? Icon(
                                icon,
                                size: size * .5,
                                color: homeNavy,
                                shadows: const [
                                  Shadow(
                                    color: Color(0xFFFFFFFF),
                                    offset: Offset(0, -1),
                                  ),
                                  Shadow(
                                    color: Color(0x555C3900),
                                    offset: Offset(0, 2),
                                    blurRadius: 1,
                                  ),
                                ],
                              )
                            : MapIcon(glyph!, size: size * .45),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
