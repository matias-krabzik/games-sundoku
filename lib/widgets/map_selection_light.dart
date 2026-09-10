import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/level_node.dart';
import 'map_level_button.dart';

/// A viewport-sized light layer; only its canvas repaints on animation frames.
class MapSelectionLight extends StatefulWidget {
  const MapSelectionLight({
    super.key,
    required this.level,
    this.enabled = true,
    this.scoreLevels = const <int>{},
    required this.worldSize,
    required this.nodeSize,
    required this.scroll,
  });

  final int level;
  final bool enabled;
  final Set<int> scoreLevels;
  final Size worldSize;
  final double nodeSize;
  final ScrollController scroll;

  @override
  State<MapSelectionLight> createState() => _MapSelectionLightState();
}

class _MapSelectionLightState extends State<MapSelectionLight>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4800),
  );
  late final AnimationController _travel = AnimationController(
    vsync: this,
    value: 1,
    duration: const Duration(milliseconds: 850),
  );
  late Offset _origin = _node(widget.level);
  Map<int, double> _fadingLights = {};
  bool _reduceMotion = false;
  bool _foreground = true;

  Offset _node(int level) {
    final node = kMap1Nodes[level - 1];
    return Offset(node.x, node.y);
  }

  Offset _position(double progress) => _arc(
    _origin,
    _node(widget.level),
    Curves.easeInOutCubic.transform(progress),
    widget.worldSize,
  );

  Map<int, double> _intensities() {
    if (!widget.enabled) return {};
    final double t = _travel.value;
    return {
      for (final light in _fadingLights.entries)
        light.key: light.value * (1 - (t / 0.45).clamp(0, 1)),
      widget.level: Curves.easeOut.transform(((t - 0.5) / 0.5).clamp(0, 1)),
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncMotion();
  }

  void _syncMotion() {
    if (_reduceMotion || !_foreground || !widget.enabled) {
      _shimmer.stop();
      _travel.stop();
      if (_reduceMotion || !widget.enabled) _travel.value = 1;
    } else {
      if (!_shimmer.isAnimating) _shimmer.repeat();
      if (_travel.value < 1) _travel.forward();
    }
  }

  @override
  void didUpdateWidget(MapSelectionLight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level == widget.level) {
      if (oldWidget.enabled != widget.enabled) {
        _origin = _node(widget.level);
        _fadingLights = {};
        _travel.value = widget.enabled && !_reduceMotion ? 0 : 1;
        _syncMotion();
      }
      return;
    }
    // Retarget from the current in-flight location, even after rapid taps.
    final double t = _travel.value;
    final previousTarget = _node(oldWidget.level);
    final previousLights = <int, double>{
      for (final light in _fadingLights.entries)
        light.key: light.value * (1 - (t / 0.45).clamp(0, 1)),
      oldWidget.level: Curves.easeOut.transform(((t - 0.5) / 0.5).clamp(0, 1)),
    };
    _origin = _arc(
      _origin,
      previousTarget,
      Curves.easeInOutCubic.transform(t),
      widget.worldSize,
    );
    _fadingLights = previousLights..removeWhere((_, value) => value < 0.01);
    _travel.value = _reduceMotion ? 1 : 0;
    _syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shimmer.dispose();
    _travel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: _LightPainter(
          repaint: Listenable.merge([_shimmer, _travel, widget.scroll]),
          phase: () => _reduceMotion ? 0.25 : _shimmer.value,
          progress: () => _travel.value,
          intensities: _intensities,
          position: _position,
          worldSize: widget.worldSize,
          nodeSize: widget.nodeSize,
          scoreLevels: widget.scoreLevels,
          scroll: widget.scroll,
        ),
      ),
    ),
  );
}

Offset _arc(Offset from, Offset to, double t, Size world) {
  final double distance = Offset(
    (to.dx - from.dx) * world.width,
    (to.dy - from.dy) * world.height,
  ).distance;
  final double lift = math.min(64, distance * 0.18) / world.height;
  return Offset.lerp(from, to, t)! - Offset(0, math.sin(t * math.pi) * lift);
}

class _LightPainter extends CustomPainter {
  _LightPainter({
    required Listenable repaint,
    required this.phase,
    required this.progress,
    required this.intensities,
    required this.position,
    required this.worldSize,
    required this.nodeSize,
    required this.scoreLevels,
    required this.scroll,
  }) : super(repaint: repaint);

  final double Function() phase;
  final double Function() progress;
  final Map<int, double> Function() intensities;
  final Offset Function(double) position;
  final Size worldSize;
  final double nodeSize;
  final Set<int> scoreLevels;
  final ScrollController scroll;

  static const _gold = Color(0xFFFFCC44);
  static const _white = Color(0xFFFFFBE7);

  Offset _screen(Offset normalized, Size size) => Offset(
    normalized.dx * worldSize.width - (scroll.hasClients ? scroll.offset : 0),
    normalized.dy * worldSize.height + (size.height - worldSize.height) / 2,
  );

  void _bloom(Canvas canvas, Offset center, double radius, double alpha) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            _white.withValues(alpha: alpha),
            _gold.withValues(alpha: alpha * 0.55),
            _gold.withValues(alpha: 0),
          ],
          stops: const [0, 0.2, 1],
        ).createShader(rect),
    );
  }

  void _flare(Canvas canvas, Offset center, double strength, double angle) {
    _bloom(canvas, center, 19, strength * 0.65);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    // Lens-like light streaks with feathered ends, rather than star outlines.
    for (final radius in [const Offset(24, 2.3), const Offset(1.6, 12)]) {
      canvas.save();
      canvas.scale(radius.dx, radius.dy);
      canvas.drawCircle(
        Offset.zero,
        1,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            colors: [
              _white.withValues(alpha: strength),
              _gold.withValues(alpha: strength * 0.45),
              _gold.withValues(alpha: 0),
            ],
            stops: const [0, 0.18, 1],
          ).createShader(const Rect.fromLTWH(-1, -1, 2, 2)),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final scoreCutouts = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    for (final level in scoreLevels) {
      final node = kMap1Nodes[level - 1];
      final center = _screen(Offset(node.x, node.y), size);
      for (int socket = 0; socket < 3; socket++) {
        scoreCutouts.addOval(
          Rect.fromCircle(
            center: center + mapScoreStarOffset(socket, nodeSize),
            radius: mapScoreStarSize(socket) / 2 + 3,
          ),
        );
      }
    }
    canvas.clipPath(scoreCutouts);
    final double p = phase() * math.pi * 2;
    final double radius = nodeSize * 0.56;
    for (final light in intensities().entries) {
      if (light.value <= 0.005) continue;
      final node = kMap1Nodes[light.key - 1];
      final center = _screen(Offset(node.x, node.y), size);
      if (!(Offset.zero & size).inflate(100).contains(center)) continue;
      final double energy = light.value * (0.83 + math.sin(p) * 0.17);
      final double haloRadius = radius * 2.1;
      canvas.drawCircle(
        center,
        haloRadius,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            colors: [
              Colors.transparent,
              Colors.transparent,
              _gold.withValues(alpha: energy * 0.6),
              _gold.withValues(alpha: energy * 0.15),
              Colors.transparent,
            ],
            stops: const [0, 0.34, 0.48, 0.65, 1],
          ).createShader(Rect.fromCircle(center: center, radius: haloRadius)),
      );
      for (int i = 0; i < 3; i++) {
        final angle = -2.2 + i * 2.1 + math.sin(p + i) * 0.12;
        final centerOfFlare =
            center + Offset(math.cos(angle), math.sin(angle)) * radius;
        final strength =
            energy *
            (0.52 + 0.48 * math.pow((math.sin(p + i * 2.3) + 1) / 2, 3));
        _flare(canvas, centerOfFlare, strength, -0.3);
      }
    }

    final double t = progress();
    if (t <= 0 || t >= 1) return;
    final double strength = math.sin(math.pi * t).clamp(0, 1);
    // A short luminous tail follows the same arc as the white-hot head.
    for (int i = 20; i > 0; i--) {
      final double behind = (t - i * 0.009).clamp(0, 1);
      final at = _screen(position(behind), size);
      _bloom(canvas, at, 5 + (20 - i) * 0.4, strength * (1 - i / 21) * 0.18);
    }
    final head = _screen(position(t), size);
    _bloom(canvas, head, 27, strength * 0.8);
    _flare(canvas, head, strength, -0.25);
  }

  @override
  bool shouldRepaint(covariant _LightPainter oldDelegate) => true;
}
