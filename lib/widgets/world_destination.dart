import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../data/world_catalog.dart';
import 'curved_ribbon_title.dart';
import 'game_feedback_scope.dart';
import 'home_art.dart';
import 'juicy_press.dart';
import 'map_art.dart';
import 'settings_art.dart';
import 'ui_surface_art.dart';

/// The art, hit targets and camera all share these proportions.
abstract final class WorldDestinationGeometry {
  static const heightFactor = .82;
  static const anchorFactor = .16;
}

/// A destination assembled from a crest, a ribbon and two live progress plates.
class WorldDestination extends StatefulWidget {
  const WorldDestination({
    super.key,
    required this.world,
    required this.unlocked,
    required this.highlighted,
    required this.completedLevels,
    required this.stars,
    required this.onPressed,
  });

  final AdventureWorld world;
  final bool unlocked;
  final bool highlighted;
  final int completedLevels;
  final int stars;
  final Future<void> Function()? onPressed;

  @override
  State<WorldDestination> createState() => _WorldDestinationState();
}

class _WorldDestinationState extends State<WorldDestination>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  bool _reduced = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (_reduced || !TickerMode.valuesOf(context).enabled) {
      _shine.stop();
    } else if (!_shine.isAnimating) {
      _shine.repeat();
    }
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final w = widget;
      final width = bounds.maxWidth;
      final crest = switch (w.world.id) {
        'world-1' => ('sun', const Rect.fromLTRB(.049, .09, .952, .925)),
        'world-2' => ('mountain', const Rect.fromLTRB(.10, .107, .906, .933)),
        _ => ('water', const Rect.fromLTRB(.025, .208, .976, .875)),
      };
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: width * .18,
            top: 0,
            width: width * .64,
            height: width * .33,
            child: JuicyPress(
              key: ValueKey('world-medallion-${w.world.id}'),
              label: 'Centrar ${w.world.name}',
              onPressed: w.unlocked ? w.onPressed : null,
              onFeedback: () => GameFeedbackScope.tap(context),
              builder: (context, _) => AnimatedBuilder(
                animation: _shine,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: w.world.id == 'world-2' ? 1.95 : 2.17,
                    child: SettingsArtRegion(
                      asset:
                          'assets/images/world-selection/aventura-crest-${crest.$1}.png',
                      region: crest.$2,
                    ),
                  ),
                ),
                builder: (context, child) {
                  final pulse = _reduced || !w.highlighted
                      ? 0.0
                      : math.sin(_shine.value * math.pi * 2);
                  return Transform.translate(
                    offset: Offset(0, -pulse * 1.3),
                    child: Transform.scale(
                      scale: 1 + pulse * .012,
                      child: child,
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: width * .245,
            bottom: 0,
            child: JuicyPress(
              key: ValueKey('choose-${w.world.id}'),
              label:
                  '${w.world.name}. ${w.completedLevels} de ${w.world.levelCount} niveles completados. ${w.stars} de ${w.world.levelCount * 3} estrellas. ${w.unlocked ? 'Centrar destino' : 'Bloqueado'}',
              onPressed: w.unlocked ? w.onPressed : null,
              onFeedback: () => GameFeedbackScope.tap(context),
              builder: (context, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final starPlate in [false, true])
                    Positioned(
                      left: width * (starPlate ? .522 : .183),
                      top: width * .255,
                      width: width * .295,
                      height: width * .32,
                      child: _ProgressPlate(
                        width: width * .295,
                        stars: starPlate,
                        label: starPlate
                            ? '${w.stars} / ${w.world.levelCount * 3}'
                            : '${w.completedLevels} / ${w.world.levelCount} niveles',
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: width * .30,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        UiSurfaceArt(
                          UiSurface.adventureRibbon,
                          referenceSize: Size(width, width * .30),
                        ),
                        Positioned(
                          left: width * .13,
                          right: width * .13,
                          top: width * .068,
                          height: width * .14,
                          child: CurvedRibbonTitle(
                            key: ValueKey('world-title-${w.world.id}'),
                            text: w.world.name,
                            fontSize: width * .091,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!w.unlocked)
            Positioned(
              right: width * .16,
              top: width * .15,
              child: MapIcon(MapGlyph.lock, size: width * .10),
            ),
        ],
      );
    },
  );
}

class _ProgressPlate extends StatelessWidget {
  const _ProgressPlate({
    required this.width,
    required this.stars,
    required this.label,
  });

  final double width;
  final bool stars;
  final String label;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      UiSurfaceArt(
        UiSurface.adventurePlaque,
        referenceSize: Size(width, width / .89),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(
          width * .115,
          width * .20,
          width * .115,
          width * .23,
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: stars
                    ? MapIcon(MapGlyph.goldStar, size: width * .43)
                    : HomeIcon(HomeGlyph.map, size: width * .46),
              ),
            ),
            SizedBox(height: width * .035),
            SizedBox(
              height: width * .23,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: homeText(stars ? width * .19 : width * .145),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

@Preview(
  name: 'Destino disponible',
  group: 'Selección de destinos',
  size: Size(390, 400),
)
Widget availableWorldDestinationPreview() => _destinationPreview(true);

@Preview(
  name: 'Destino bloqueado',
  group: 'Selección de destinos',
  size: Size(390, 400),
)
Widget lockedWorldDestinationPreview() => _destinationPreview(false);

Widget _destinationPreview(bool unlocked) => MaterialApp(
  home: Scaffold(
    backgroundColor: const Color(0xFF98BF74),
    body: Center(
      child: SizedBox(
        width: 350,
        height: 350 * WorldDestinationGeometry.heightFactor,
        child: WorldDestination(
          world: adventureWorld(unlocked ? 'world-1' : 'world-2'),
          unlocked: unlocked,
          highlighted: unlocked,
          completedLevels: unlocked ? 2 : 0,
          stars: unlocked ? 6 : 0,
          onPressed: () async {},
        ),
      ),
    ),
  ),
);
