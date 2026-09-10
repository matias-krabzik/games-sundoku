import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// The bare sun mark (no text). Safe to rotate.
class SunMark extends StatelessWidget {
  const SunMark({super.key, this.size = 160});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SunPainter()),
    );
  }
}

/// The sun mark plus the "SunDoku" wordmark.
class SunLogo extends StatelessWidget {
  const SunLogo({super.key, this.size = 160});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SunMark(size: size),
        SizedBox(height: size * 0.12),
        Text(
          'SunDoku',
          style: TextStyle(
            fontSize: size * 0.24,
            fontWeight: FontWeight.w800,
            color: kSunFace,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _SunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double coreRadius = size.width * 0.28;
    final double rayInner = size.width * 0.34;
    final double rayOuter = size.width * 0.48;

    final Paint rayPaint = Paint()
      ..color = kSunRay
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round;

    const int rays = 12;
    for (int i = 0; i < rays; i++) {
      final double angle = (i / rays) * 2 * math.pi;
      final Offset dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(center + dir * rayInner, center + dir * rayOuter, rayPaint);
    }

    canvas.drawCircle(center, coreRadius, Paint()..color = kSunYellow);

    // Friendly face.
    final Paint face = Paint()..color = kSunFace;
    final double eyeDx = coreRadius * 0.4;
    final double eyeDy = coreRadius * 0.15;
    final double eyeR = coreRadius * 0.12;
    canvas.drawCircle(center + Offset(-eyeDx, -eyeDy), eyeR, face);
    canvas.drawCircle(center + Offset(eyeDx, -eyeDy), eyeR, face);

    final Rect smile = Rect.fromCircle(
      center: center + Offset(0, coreRadius * 0.12),
      radius: coreRadius * 0.45,
    );
    canvas.drawArc(
      smile,
      0.15 * math.pi,
      0.7 * math.pi,
      false,
      Paint()
        ..color = kSunFace
        ..style = PaintingStyle.stroke
        ..strokeWidth = coreRadius * 0.12
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
