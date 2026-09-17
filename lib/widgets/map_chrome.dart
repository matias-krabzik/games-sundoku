import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../routes.dart';
import '../data/level_node.dart';
import 'score_feedback.dart';
import 'ui_surface_art.dart';
import 'game_feedback_scope.dart';
import 'home_art.dart';
import 'juicy_press.dart';
import 'map_art.dart';
import 'settings_art.dart';

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
        label: 'Volver al inicio',
        icon: Icons.home_rounded,
        size: compact ? 50 : 54,
        onPressed: onBack,
      ),
      if (onViewTutorial != null) ...[
        const SizedBox(width: 8),
        _MapRoundButton(
          key: const ValueKey('map-tutorial'),
          label: 'Ver el tutorial',
          icon: Icons.menu_book_rounded,
          size: compact ? 50 : 54,
          onPressed: onViewTutorial,
        ),
      ],
      const Spacer(),
      _MapRoundButton(
        key: const ValueKey('map-settings'),
        label: 'Ajustes',
        artwork: SettingsIcon(SettingsGlyph.gear, size: compact ? 30 : 33),
        size: compact ? 50 : 54,
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
      ),
    ],
  );
}

/// Full-width world footer. Stars remain on their level markers.
class MapStatusCard extends StatelessWidget {
  const MapStatusCard({
    super.key,
    required this.level,
    required this.points,
    required this.onPrevious,
    required this.onNext,
    this.compact = false,
  });

  final int level;
  final int points;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool compact;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(child: UiSurfaceArt(UiSurface.worldFooter)),
      SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, bounds) {
            final desktop =
                defaultTargetPlatform != TargetPlatform.android &&
                defaultTargetPlatform != TargetPlatform.iOS;
            final large = bounds.maxWidth >= 700;
            final titleSize = compact
                ? 23.0
                : large
                ? 34.0
                : 26.0;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                compact ? 10 : 16,
                16,
                compact ? 8 : 14,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MUNDO 1 · VALLE DEL SOL',
                    textAlign: TextAlign.center,
                    style: homeText(compact ? 10 : 12).copyWith(
                      color: const Color(0xFFA46A0E),
                      letterSpacing: 1.8,
                    ),
                  ),
                  SizedBox(height: compact ? 3 : 6),
                  Row(
                    children: [
                      if (desktop)
                        _MapRoundButton(
                          key: const ValueKey('map-previous'),
                          label: 'Nivel anterior',
                          glyph: MapGlyph.chevron,
                          mirrored: true,
                          gold: onPrevious != null,
                          size: 48,
                          onPressed: onPrevious,
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              kValleyLevelNames[level - 1],
                              key: const ValueKey('map-level-name'),
                              style: homeText(titleSize),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      if (desktop)
                        _MapRoundButton(
                          key: const ValueKey('map-next'),
                          label: 'Nivel siguiente',
                          glyph: MapGlyph.chevron,
                          gold: onNext != null,
                          size: 48,
                          onPressed: onNext,
                        ),
                    ],
                  ),
                  SizedBox(height: compact ? 3 : 8),
                  _WorldScoreBadge(
                    points: points,
                    height: compact
                        ? 42
                        : large
                        ? 66
                        : 54,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}

class _WorldScoreBadge extends StatelessWidget {
  const _WorldScoreBadge({required this.points, required this.height});
  final int points;
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Puntaje acumulado del mundo: $points puntos',
    excludeSemantics: true,
    child: SizedBox(
      height: height,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: height * .5,
                top: height * .12,
                bottom: height * .12,
              ),
              child: UiSurfacePanel(
                surface: UiSurface.blueScoreCapsule,
                padding: EdgeInsets.fromLTRB(
                  height * .6,
                  height * .11,
                  height * .3,
                  height * .13,
                ),
                child: Text(
                  formatScore(points),
                  key: const ValueKey('map-world-score'),
                  style: homeText(height * .48).copyWith(
                    color: const Color(0xFFFFF1CE),
                    shadows: const [
                      Shadow(color: Color(0x88001741), offset: Offset(0, 2)),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Image.asset(
                  'assets/images/map/score-sun.png',
                  key: const ValueKey('map-score-sun'),
                  width: height,
                  height: height,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MapRoundButton extends StatelessWidget {
  const _MapRoundButton({
    super.key,
    required this.label,
    this.glyph,
    this.icon,
    this.artwork,
    required this.size,
    required this.onPressed,
    this.gold = false,
    this.mirrored = false,
  });

  final String label;
  final MapGlyph? glyph;
  final IconData? icon;
  final Widget? artwork;
  final double size;
  final VoidCallback? onPressed;
  final bool gold;
  final bool mirrored;

  @override
  Widget build(BuildContext context) => SizedBox.square(
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
                      child:
                          artwork ??
                          (icon != null
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
                              : MapIcon(glyph!, size: size * .45)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
