import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One light travels from a level marker into one of its score points.
class LightAwardOverlay extends StatelessWidget {
  const LightAwardOverlay({
    super.key,
    required this.animation,
    required this.scroll,
    required this.destination,
    required this.source,
    required this.variant,
  });
  final Animation<double> animation;
  final ScrollController scroll;
  final Offset destination;
  final Offset source;
  final int variant;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: _AwardPainter(animation, scroll, destination, source, variant),
      ),
    ),
  );
}

class _AwardPainter extends CustomPainter {
  _AwardPainter(
    this.animation,
    this.scroll,
    this.destination,
    this.source,
    this.variant,
  ) : super(repaint: Listenable.merge([animation, scroll]));
  final Animation<double> animation;
  final ScrollController scroll;
  final Offset destination;
  final Offset source;
  final int variant;

  double _noise(int salt) {
    final value = math.sin((variant + salt * 977) * 12.9898) * 43758.5453;
    return value - value.floorToDouble();
  }

  Offset _cubic(
    Offset start,
    Offset first,
    Offset second,
    Offset end,
    double t,
  ) {
    final double inverse = 1 - t;
    return start * (inverse * inverse * inverse) +
        first * (3 * inverse * inverse * t) +
        second * (3 * inverse * t * t) +
        end * (t * t * t);
  }

  Offset position(double t) {
    final start = source - Offset(scroll.hasClients ? scroll.offset : 0, 0);
    final end = destination - Offset(scroll.hasClients ? scroll.offset : 0, 0);
    final delta = end - start;
    final distance = math.max(delta.distance, 1);
    final normal = Offset(-delta.dy / distance, delta.dx / distance);
    final direction = _noise(1) < 0.5 ? -1.0 : 1.0;
    final side =
        direction * math.min(180, distance * 0.24) * (0.55 + _noise(2) * 0.45);
    final lift = math.min(145, distance * 0.19) * (0.65 + _noise(3) * 0.35);
    final first =
        Offset.lerp(start, end, 0.20 + _noise(4) * 0.10)! +
        normal * side -
        Offset(0, lift);
    final second =
        Offset.lerp(start, end, 0.62 + _noise(5) * 0.13)! -
        normal * side * (0.15 + _noise(6) * 0.25) -
        Offset(0, lift * (0.35 + _noise(7) * 0.35));
    final curve = _cubic(start, first, second, end, t);
    final flutter =
        math.sin(math.pi * t) *
        math.sin(
          (1.25 + _noise(8) * 0.75) * math.pi * t + _noise(9) * math.pi,
        ) *
        (4 + _noise(10) * 7);
    return curve + normal * flutter;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeInOutCubic.transform(animation.value);
    if (t <= 0 || t >= 1) return;
    final sourcePoint =
        source - Offset(scroll.hasClients ? scroll.offset : 0, 0);
    final sourceStrength = (1 - (t / 0.30).clamp(0, 1)).toDouble();
    if (sourceStrength > 0) {
      _drawBloom(canvas, sourcePoint, 38, sourceStrength * 0.9);
    }
    for (int i = 12; i >= 0; i--) {
      final at = position((t - i * 0.025).clamp(0, 1));
      final radius = i == 0 ? 23.0 : 10.0;
      final strength = i == 0 ? 1.0 : (1 - i / 13) * 0.4;
      _drawBloom(canvas, at, radius, strength);
    }
  }

  void _drawBloom(
    Canvas canvas,
    Offset center,
    double radius,
    double strength,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: strength),
            const Color(0xFFFFD147).withValues(alpha: strength * 0.8),
            Colors.transparent,
          ],
          stops: const [0, 0.25, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_AwardPainter oldDelegate) => true;
}
