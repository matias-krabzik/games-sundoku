import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/map_ambient_motion.dart';

/// Two small decoded sprites, shared by every depth in one map scene.
class MapAmbientArt extends ChangeNotifier {
  MapAmbientArt({String? leafAsset, String? beeAsset})
    : leafAsset = leafAsset ?? 'assets/images/map/ambient/leaf.png',
      beeAsset = beeAsset ?? 'assets/images/map/ambient/bee.png';
  final String leafAsset;
  final String beeAsset;
  ui.Image? leaf;
  ui.Image? bee;
  bool _disposed = false;
  Future<void>? _loading;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    for (final name in ['leaf', 'bee']) {
      try {
        final data = await rootBundle.load(
          name == 'leaf' ? leafAsset : beeAsset,
        );
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        codec.dispose();
        if (_disposed) {
          frame.image.dispose();
          return;
        }
        if (name == 'leaf') {
          leaf = frame.image;
        } else {
          bee = frame.image;
        }
        notifyListeners();
      } catch (error, stack) {
        if (!_disposed) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'SunDoku map ambient art',
            ),
          );
        }
      }
      if (_disposed) return;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    leaf?.dispose();
    bee?.dispose();
    super.dispose();
  }
}

class MapAmbientPainter extends CustomPainter {
  // Match the flowering tree's pale pink while keeping the leaf's shading.
  static const _pinkLeafFilter = ColorFilter.matrix(<double>[
    0,
    .40,
    0,
    0,
    155,
    0,
    .36,
    0,
    0,
    117,
    0,
    .34,
    0,
    0,
    145,
    0,
    0,
    0,
    1,
    0,
  ]);

  MapAmbientPainter({
    required this.motion,
    required this.art,
    required this.depth,
    required this.origin,
    required this.scale,
    required this.protectedRects,
    required this.time,
  }) : super(repaint: art);

  final MapAmbientMotion motion;
  final MapAmbientArt art;
  final MapLeafDepth depth;
  final Offset origin;
  final double scale;
  final List<Rect> protectedRects;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = (Offset.zero & size).inflate(40);
    final leafArt = art.leaf;
    if (leafArt != null) {
      for (final leaf in motion.leaves) {
        if (leaf.depth != depth) continue;
        final point = origin + leaf.position * scale;
        if (!bounds.contains(point)) continue;
        final width = (leaf.size * scale).clamp(
          leaf.kind == MapLeafKind.pink ? 4.0 : 6.0,
          26.0,
        );
        final opacity = leaf.opacity;
        if (opacity <= .01) continue;
        canvas.save();
        canvas.translate(point.dx, point.dy);
        canvas.rotate(leaf.angle);
        canvas.scale(.3 + .7 * math.cos(time * 2 + leaf.phase).abs(), 1);
        _sprite(
          canvas,
          leafArt,
          width,
          opacity,
          colorFilter: leaf.kind == MapLeafKind.pink ? _pinkLeafFilter : null,
        );
        canvas.restore();
      }
    }
    if (depth == MapLeafDepth.behindTrees || art.bee == null) return;
    final foreground = depth == MapLeafDepth.foreground;
    for (final bee in motion.bees) {
      if ((bee.depth < .5) != foreground) continue;
      final point =
          origin + motion.beePosition(bee, foreground: foreground) * scale;
      if (!bounds.contains(point)) continue;
      final width = bee.paintedWidth(scale);
      // Distant bees share the terrain plane and sit behind the foreground.
      // IgnorePointer keeps both planes from blocking level taps and drags.
      const opacity = 1.0;
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.scale(bee.facing, 1);
      if (!bee.perched) canvas.rotate(math.sin(time * 3 + bee.phase) * .09);
      // Separate wings flutter behind the illustrated body. Their folded
      // silhouette stays visible when the bee is resting on a blossom.
      for (var i = 0; i < 2; i++) {
        canvas.save();
        canvas.translate(-width * .12, -width * .12);
        final flutter = bee.perched
            ? .35
            : math.sin(time * (bee.startled ? 105 : 65) + bee.phase + i * .8);
        canvas.rotate(-.35 - i * .5 + flutter * .55);
        final wing = Rect.fromLTWH(
          -width * .25,
          -width * (bee.perched ? .32 : .56),
          width * .31,
          width * (bee.perched ? .37 : .61),
        );
        canvas.drawOval(
          wing,
          Paint()
            ..shader = ui.Gradient.linear(wing.topCenter, wing.bottomCenter, [
              Colors.white.withValues(alpha: opacity * .9),
              const Color(0xFFBDECF6).withValues(alpha: opacity * .5),
            ]),
        );
        canvas.drawOval(
          wing,
          Paint()
            ..color = Colors.white.withValues(alpha: opacity * .6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .7,
        );
        canvas.restore();
      }
      _sprite(canvas, art.bee!, width, opacity);
      canvas.restore();
    }
  }

  void _sprite(
    Canvas canvas,
    ui.Image image,
    double width,
    double opacity, {
    ColorFilter? colorFilter,
  }) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromCenter(
        center: Offset.zero,
        width: width,
        height: width * image.height / image.width,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..colorFilter = colorFilter
        ..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(MapAmbientPainter oldDelegate) =>
      time != oldDelegate.time ||
      origin != oldDelegate.origin ||
      scale != oldDelegate.scale ||
      motion != oldDelegate.motion ||
      art != oldDelegate.art ||
      depth != oldDelegate.depth ||
      protectedRects != oldDelegate.protectedRects;
}
