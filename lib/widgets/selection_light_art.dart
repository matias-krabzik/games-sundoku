import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared soft, counter-rotating rays for world and level selection.
abstract final class SelectionLightArt {
  static const _cream = Color(0xFFFFFBE8);
  static const _gold = Color(0xFFFFD265);

  static void paint(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double phase,
    double opacity = 1,
  }) {
    if (opacity <= 0) return;
    final glow = Rect.fromCircle(center: center, radius: radius);
    final wave = math.sin(phase);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _cream.withValues(alpha: (.72 + wave * .035) * opacity),
            _gold.withValues(alpha: .42 * opacity),
            _gold.withValues(alpha: .14 * opacity),
            _gold.withValues(alpha: 0),
          ],
          stops: const [0, .3, .72, 1],
        ).createShader(glow),
    );
    _rays(
      canvas,
      center: center,
      radius: radius,
      glow: glow,
      color: const Color(0xFFE1F5FF),
      opacity: .22 * opacity,
      count: 18,
      rotation: math.pi / 18 - phase / 9,
      wave: -wave,
    );
    _rays(
      canvas,
      center: center,
      radius: radius,
      glow: glow,
      color: _cream,
      opacity: .5 * opacity,
      count: 14,
      rotation: phase / 7,
      wave: wave,
    );
  }

  static void _rays(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Rect glow,
    required Color color,
    required double opacity,
    required int count,
    required double rotation,
    required double wave,
  }) {
    final rayPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: .12 * opacity),
          color.withValues(alpha: (.76 + wave * .035) * opacity),
          color.withValues(alpha: .56 * opacity),
          color.withValues(alpha: 0),
        ],
        stops: const [0, .22, .62, 1],
      ).createShader(glow);
    for (var i = 0; i < count; i++) {
      final angle = i * math.pi * 2 / count + rotation;
      final halfWidth = math.pi / count * (i.isEven ? .4 : .56);
      final reach = radius * (i.isEven ? 1 : .9);
      final left = center + Offset.fromDirection(angle - halfWidth, reach);
      final right = center + Offset.fromDirection(angle + halfWidth, reach);
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(left.dx, left.dy)
          ..lineTo(right.dx, right.dy)
          ..close(),
        rayPaint,
      );
    }
  }
}
