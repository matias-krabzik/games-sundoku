import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../data/world_catalog.dart';
import 'game_feedback_scope.dart';
import 'home_art.dart';
import 'juicy_press.dart';
import 'map_art.dart';
import 'ui_surface_art.dart';

/// A real button and live progress label, independent from the landscape.
class WorldDestination extends StatefulWidget {
  const WorldDestination({
    super.key,
    required this.world,
    required this.unlocked,
    required this.highlighted,
    required this.completedLevels,
    required this.stars,
    required this.diameter,
    required this.markerLeft,
    required this.onPressed,
  });
  final AdventureWorld world;
  final bool unlocked;
  final bool highlighted;
  final int completedLevels;
  final int stars;
  final double diameter;
  final double markerLeft;
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
  Widget build(BuildContext context) {
    final w = widget;
    final compact = w.diameter < 80;
    final requirement = 'Completa el Mundo ${w.world.number - 1}';
    return JuicyPress(
      key: ValueKey('choose-${w.world.id}'),
      label:
          'Mundo ${w.world.number}. ${w.world.name}. ${w.unlocked ? '${w.completedLevels} de ${w.world.levelCount} niveles completados. ${w.stars} de ${w.world.levelCount * 3} estrellas. Entrar al mundo' : 'Bloqueado. $requirement'}',
      onPressed: w.unlocked ? w.onPressed : null,
      onFeedback: () => GameFeedbackScope.tap(context),
      builder: (context, _) => Column(
        children: [
          SizedBox(
            height: w.diameter + 6,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: w.markerLeft,
                  top: 0,
                  width: w.diameter,
                  height: w.diameter,
                  child: AnimatedBuilder(
                    animation: _shine,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        UiSurfaceArt(
                          w.unlocked
                              ? UiSurface.goldRound
                              : UiSurface.creamRound,
                        ),
                        Padding(
                          padding: EdgeInsets.all(w.diameter * .25),
                          child: CustomPaint(
                            painter: _WorldGlyph(w.world.number),
                          ),
                        ),
                      ],
                    ),
                    builder: (context, medallion) {
                      final pulse = _reduced
                          ? 0.0
                          : (math.sin(_shine.value * math.pi * 2) + 1) / 2;
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (w.highlighted)
                              BoxShadow(
                                color: const Color(0xFFFFE25B)
                                    .withValues(alpha: .20 + pulse * .24),
                                blurRadius: 12 + pulse * 12,
                                spreadRadius: 1 + pulse * 3,
                              ),
                            const BoxShadow(
                              color: Color(0x45000000),
                              blurRadius: 7,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Transform.scale(
                          scale: w.highlighted ? 1 + pulse * .025 : 1,
                          child: medallion,
                        ),
                      );
                    },
                  ),
                ),
                if (!w.unlocked)
                  Positioned(
                    left: w.markerLeft + w.diameter * .70,
                    top: w.diameter * .68,
                    width: w.diameter * .36,
                    height: w.diameter * .36,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Positioned.fill(
                          child: UiSurfaceArt(UiSurface.creamRound),
                        ),
                        MapIcon(MapGlyph.lock, size: w.diameter * .23),
                      ],
                    ),
                  ),
                if (w.completedLevels == w.world.levelCount)
                  Positioned(
                    left: w.markerLeft + w.diameter * .72,
                    top: w.diameter * .69,
                    child: MapIcon(MapGlyph.goldStar, size: w.diameter * .32),
                  ),
              ],
            ),
          ),
          Expanded(
            child: UiSurfacePanel(
              surface: UiSurface.goldCreamPanel,
              constraints: const BoxConstraints.expand(),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 9 : 14,
                vertical: compact ? 9 : 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Mundo ${w.world.number}',
                        maxLines: 1,
                        style: homeText(compact ? 16 : 21),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        w.world.name,
                        maxLines: 1,
                        style: homeText(compact ? 12 : 15),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Expanded(
                    flex: 2,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: w.unlocked
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${w.completedLevels} / ${w.world.levelCount} niveles',
                                  style: homeText(compact ? 10 : 12),
                                ),
                                const SizedBox(width: 7),
                                MapIcon(
                                  MapGlyph.goldStar,
                                  size: compact ? 13 : 17,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${w.stars} / ${w.world.levelCount * 3}',
                                  style: homeText(compact ? 11 : 13),
                                ),
                              ],
                            )
                          : Text(
                              requirement,
                              maxLines: 1,
                              style: homeText(compact ? 10 : 12),
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(
  name: 'Mundo disponible',
  group: 'Selección de mundos',
  size: Size(250, 230),
)
Widget availableWorldDestinationPreview() => _destinationPreview(true);

@Preview(
  name: 'Mundo bloqueado',
  group: 'Selección de mundos',
  size: Size(250, 230),
)
Widget lockedWorldDestinationPreview() => _destinationPreview(false);

Widget _destinationPreview(bool unlocked) => MaterialApp(
  home: Scaffold(
    backgroundColor: const Color(0xFF98BF74),
    body: Center(
      child: SizedBox(
        width: 230,
        height: 200,
        child: WorldDestination(
          world: adventureWorld(unlocked ? 'world-1' : 'world-2'),
          unlocked: unlocked,
          highlighted: unlocked,
          completedLevels: unlocked ? 2 : 0,
          stars: unlocked ? 6 : 0,
          diameter: 110,
          markerLeft: 60,
          onPressed: () async {},
        ),
      ),
    ),
  ),
);

/// Crisp blue pictograms match the approved points without relying on a font.
class _WorldGlyph extends CustomPainter {
  const _WorldGlyph(this.world);
  final int world;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final ink = Paint()
      ..color = const Color(0xFF0757A5)
      ..strokeCap = StrokeCap.round;
    if (world == 1) {
      canvas.drawCircle(const Offset(50, 50), 23, ink);
      ink.strokeWidth = 9;
      for (var i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        final direction = Offset(math.cos(angle), math.sin(angle));
        canvas.drawLine(
          const Offset(50, 50) + direction * 36,
          const Offset(50, 50) + direction * 46,
          ink,
        );
      }
    } else if (world == 2) {
      final mountain = Path()
        ..moveTo(51, 76)
        ..lineTo(76, 28)
        ..quadraticBezierTo(78, 24, 80, 29)
        ..lineTo(100, 76)
        ..close();
      canvas.drawPath(mountain, ink);
      final tree = Path()
        ..moveTo(33, 4)
        ..lineTo(10, 38)
        ..lineTo(20, 38)
        ..lineTo(2, 64)
        ..lineTo(14, 64)
        ..lineTo(0, 84)
        ..lineTo(27, 84)
        ..lineTo(27, 99)
        ..lineTo(40, 99)
        ..lineTo(40, 84)
        ..lineTo(66, 84)
        ..lineTo(52, 64)
        ..lineTo(64, 64)
        ..lineTo(46, 38)
        ..lineTo(56, 38)
        ..close();
      canvas.drawPath(tree, ink);
    } else {
      ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9;
      for (var i = 0; i < 3; i++) {
        final y = 23.0 + i * 27;
        canvas.drawPath(
          Path()
            ..moveTo(6, y)
            ..cubicTo(32, y - 29, 60, y + 29, 94, y - 4),
          ink,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WorldGlyph oldDelegate) => oldDelegate.world != world;
}
