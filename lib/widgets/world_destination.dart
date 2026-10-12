import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../data/world_catalog.dart';
import 'curved_ribbon_title.dart';
import 'game_feedback_scope.dart';
import 'home_art.dart';
import 'juicy_press.dart';
import 'map_art.dart';
import 'ui_surface_art.dart';
import 'world_crest.dart';
import 'world_destination_light.dart';

/// The art, hit targets and camera all share these proportions.
abstract final class WorldDestinationGeometry {
  static const heightFactor = .79;
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
    this.hitPadding = EdgeInsets.zero,
    this.centered = true,
    this.pulse = 0,
  });

  final AdventureWorld world;
  final bool unlocked;
  final bool highlighted;
  final int completedLevels;
  final int stars;
  final Future<void> Function()? onPressed;
  final EdgeInsets hitPadding;
  final bool centered;
  final int pulse;

  @override
  State<WorldDestination> createState() => _WorldDestinationState();
}

class _WorldDestinationState extends State<WorldDestination>
    with TickerProviderStateMixin {
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  bool _pulsePending = false;
  bool _reduced = true;

  void _syncShine() {
    if (_reduced || !TickerMode.valuesOf(context).enabled) {
      _shine.stop();
    } else if (!_shine.isAnimating) {
      _shine.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    _syncShine();
    if (_reduced) {
      _pulse.stop();
      _pulse.value = 0;
      _pulsePending = false;
    }
  }

  @override
  void didUpdateWidget(WorldDestination oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncShine();
    if (widget.pulse != oldWidget.pulse && widget.pulse > 0) {
      _pulsePending = true;
    }
    if (!widget.highlighted) _pulsePending = false;
    if (_pulsePending && widget.centered) {
      _pulsePending = false;
      if (!_reduced) _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shine.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => JuicyPress(
    key: ValueKey('choose-${widget.world.id}'),
    label:
        '${widget.world.name}. ${widget.completedLevels} de ${widget.world.levelCount} niveles completados. ${widget.stars} de ${widget.world.levelCount * 3} estrellas. ${widget.unlocked ? 'Centrar destino' : 'Bloqueado'}',
    onPressed: widget.unlocked ? widget.onPressed : null,
    onFeedback: () => GameFeedbackScope.tap(context),
    builder: (context, _) => Padding(
      padding: widget.hitPadding,
      child: LayoutBuilder(
        builder: (context, bounds) {
          final w = widget;
          final width = bounds.maxWidth;
          return Stack(
            key: ValueKey('world-art-${w.world.id}'),
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -width * .5,
                top: -width * .55,
                width: width * 2,
                height: width * 1.8,
                child: WorldDestinationLight(
                  worldId: w.world.id,
                  selected: w.highlighted,
                  motion: _shine,
                ),
              ),
              Positioned(
                left: width * .18,
                top: 0,
                width: width * .64,
                height: width * .33,
                child: SizedBox(
                  key: ValueKey('world-medallion-${w.world.id}'),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_shine, _pulse]),
                    child: Center(child: WorldCrest(worldId: w.world.id)),
                    builder: (context, child) {
                      final phase = _shine.value * math.pi * 2;
                      final pulse = _reduced ? 0.0 : math.sin(phase * 2);
                      final emphasis = _reduced
                          ? 0.0
                          : Curves.easeInOut.transform(
                              math.sin(_pulse.value * math.pi).clamp(0, 1),
                            );
                      return Transform.translate(
                        key: ValueKey('world-totem-motion-${w.world.id}'),
                        offset: Offset(pulse * width * .009, -pulse * 1.5),
                        child: Transform.rotate(
                          angle: _reduced ? 0 : math.sin(phase) * .009,
                          child: Transform.scale(
                            key: ValueKey('world-focus-pulse-${w.world.id}'),
                            scale: 1 + pulse * .012 + emphasis * .1,
                            child: child,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: width * .235,
                bottom: 0,
                child: Stack(
                  key: ValueKey('world-ribbon-${w.world.id}'),
                  clipBehavior: Clip.none,
                  children: [
                    for (final starPlate in [false, true])
                      Positioned(
                        left: width * (starPlate ? .522 : .183),
                        top: width * .235,
                        width: width * .295,
                        height: width * .32,
                        child: _PlateMotion(
                          worldId: w.world.id,
                          stars: starPlate,
                          motion: _shine,
                          reduced: _reduced,
                          width: width,
                          child: _ProgressPlate(
                            width: width * .295,
                            stars: starPlate,
                            label: starPlate
                                ? '${w.stars} / ${w.world.levelCount * 3}'
                                : '${w.completedLevels} / ${w.world.levelCount}',
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: width * .30,
                      child: _RibbonMotion(
                        worldId: w.world.id,
                        motion: _shine,
                        reduced: _reduced,
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
                    ),
                  ],
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
      ),
    ),
  );
}

class _PlateMotion extends StatelessWidget {
  const _PlateMotion({
    required this.worldId,
    required this.stars,
    required this.motion,
    required this.reduced,
    required this.width,
    required this.child,
  });

  final String worldId;
  final bool stars;
  final Animation<double> motion;
  final bool reduced;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: motion,
    child: RepaintBoundary(child: child),
    builder: (context, child) {
      final phase = motion.value * math.pi * 2;
      final sway = reduced
          ? 0.0
          : math.sin(phase * (stars ? 2 : 1) + (stars ? 3.6 : .9));
      return Transform.translate(
        key: ValueKey('world-${stars ? 'stars' : 'levels'}-motion-$worldId'),
        offset: Offset(sway * width * .007, sway * width * .003),
        child: Transform.rotate(
          alignment: Alignment.topCenter,
          angle: sway * .018,
          child: child,
        ),
      );
    },
  );
}

class _RibbonMotion extends StatelessWidget {
  const _RibbonMotion({
    required this.worldId,
    required this.motion,
    required this.reduced,
    required this.child,
  });

  final String worldId;
  final Animation<double> motion;
  final bool reduced;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: motion,
    child: RepaintBoundary(child: child),
    builder: (context, child) {
      final phase = motion.value * math.pi * 2;
      final wave = reduced ? 0.0 : math.sin(phase + 1.8);
      final breathe = reduced ? 0.0 : math.sin(phase * 2 + .4);
      return Transform(
        key: ValueKey('world-ribbon-motion-$worldId'),
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(0, 0, 1 + wave * .012)
          ..setEntry(1, 1, 1 + breathe * .018)
          ..setEntry(1, 0, wave * .009)
          ..setTranslationRaw(wave * 1.5, breathe * 1.2, 0),
        child: child,
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
                child: Text(label, maxLines: 1, style: homeText(width * .19)),
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
