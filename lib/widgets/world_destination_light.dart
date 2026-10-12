import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'selection_light_art.dart';

/// Soft light behind a selected destination, independent of its hit targets.
class WorldDestinationLight extends StatelessWidget {
  const WorldDestinationLight({
    super.key,
    required this.worldId,
    required this.selected,
    required this.motion,
  });

  final String worldId;
  final bool selected;
  final Animation<double> motion;

  @override
  Widget build(BuildContext context) {
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: selected ? 1 : 0),
          duration: reduced ? Duration.zero : const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
          child: RepaintBoundary(
            child: CustomPaint(painter: _DestinationRays(motion)),
          ),
          builder: (context, opacity, child) => Opacity(
            key: ValueKey('world-selection-light-$worldId'),
            opacity: opacity,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _DestinationRays extends CustomPainter {
  _DestinationRays(this.motion) : super(repaint: motion);

  final Animation<double> motion;
  @override
  void paint(Canvas canvas, Size size) => SelectionLightArt.paint(
    canvas,
    center: size.center(Offset.zero),
    radius: size.shortestSide / 2,
    phase: motion.value * math.pi * 2,
  );

  @override
  bool shouldRepaint(_DestinationRays oldDelegate) =>
      motion != oldDelegate.motion;
}
