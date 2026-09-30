import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/map_ambient_motion.dart';
import '../models/world_map_definition.dart';

/// Decoded sprites are shared by every depth in one map scene.
class MapAmbientArt extends ChangeNotifier {
  MapAmbientArt({
    String? leafAsset,
    String? beeAsset,
    List<String> leafAssets = const [],
    this.petalAsset,
    this.creatureAssets = const {},
    this.creatureWingAssets = const {},
  }) : leafAssets = leafAssets.isEmpty
           ? [leafAsset ?? 'assets/images/map/ambient/leaf.png']
           : leafAssets,
       beeAsset = beeAsset ?? 'assets/images/map/ambient/bee.png';

  final List<String> leafAssets;
  final String beeAsset;
  final String? petalAsset;
  final Map<MapCreatureKind, String> creatureAssets;
  final Map<MapCreatureKind, String> creatureWingAssets;
  final List<ui.Image> leaves = [];
  ui.Image? get leaf => leaves.isEmpty ? null : leaves.first;
  ui.Image? bee;
  ui.Image? petal;
  final Map<MapCreatureKind, ui.Image> creatures = {};
  final Map<MapCreatureKind, ui.Image> creatureWings = {};
  bool _disposed = false;
  Future<void>? _loading;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    for (final path in leafAssets) {
      final image = await _decode(path);
      if (_disposed) return;
      if (image != null) leaves.add(image);
      notifyListeners();
    }
    bee = await _decode(beeAsset);
    if (_disposed) return;
    notifyListeners();
    if (petalAsset case final path?) {
      petal = await _decode(path);
      if (_disposed) return;
      notifyListeners();
    }
    for (final entry in creatureWingAssets.entries) {
      final image = await _decode(entry.value);
      if (_disposed) return;
      if (image != null) creatureWings[entry.key] = image;
      notifyListeners();
    }
    for (final entry in creatureAssets.entries) {
      final image = await _decode(entry.value);
      if (_disposed) return;
      if (image != null) creatures[entry.key] = image;
      notifyListeners();
    }
  }

  Future<ui.Image?> _decode(String path) async {
    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (_disposed) {
        frame.image.dispose();
        return null;
      }
      return frame.image;
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
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final image in leaves) {
      image.dispose();
    }
    bee?.dispose();
    petal?.dispose();
    for (final image in creatures.values) {
      image.dispose();
    }
    for (final image in creatureWings.values) {
      image.dispose();
    }
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
    if (art.leaf != null) {
      for (final leaf in motion.leaves) {
        if (leaf.depth != depth) continue;
        final point = origin + leaf.position * scale;
        if (!bounds.contains(point)) continue;
        final multiplier = leaf.kind == MapLeafKind.petal
            ? 1.35
            : leaf.spriteIndex == 2
            ? 2.1
            : leaf.spriteIndex == 1
            ? 1.25
            : 1.0;
        final width = (leaf.size * scale * multiplier).clamp(
          leaf.kind == MapLeafKind.pink ? 4.0 : 6.0,
          30.0,
        );
        final opacity = leaf.opacity;
        if (opacity <= .01) continue;
        final leafArt = leaf.kind == MapLeafKind.petal
            ? art.petal
            : art.leaves[math.min(leaf.spriteIndex, art.leaves.length - 1)];
        if (leafArt == null) continue;
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
    if (depth == MapLeafDepth.air) {
      for (final creature in motion.creatures) {
        final creatureArt = art.creatures[creature.kind];
        if (creatureArt == null) continue;
        final pose = motion.creaturePose(creature);
        final point = origin + pose.position * scale;
        if (!bounds.contains(point)) continue;
        canvas.save();
        canvas.translate(point.dx, point.dy);
        canvas.scale(pose.facing * pose.visualScale, pose.visualScale);
        final width = creature.size * scale;
        final wing = art.creatureWings[creature.kind];
        switch (creature.kind) {
          case MapCreatureKind.butterfly:
            _butterfly(canvas, creatureArt, wing, width, pose.wingBeat);
          case MapCreatureKind.dragonfly:
            _dragonfly(canvas, creatureArt, wing, width, pose.wingBeat);
          case MapCreatureKind.mayfly:
            _mayfly(canvas, creatureArt, wing, width, pose.wingBeat);
          case MapCreatureKind.fish:
            _fish(canvas, creatureArt, width, pose.wingBeat);
        }
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

  // Separate wings pivot at their painted roots; the body does not stretch
  // when the wings fold toward and away from the viewer.
  void _butterfly(
    Canvas canvas,
    ui.Image body,
    ui.Image? wing,
    double width,
    double beat,
  ) {
    if (wing != null) {
      final wingWidth = width * .72;
      final wingHeight = wingWidth * wing.height / wing.width;
      final wingRect = Rect.fromLTWH(
        -wingWidth,
        -wingHeight,
        wingWidth,
        wingHeight,
      );
      final projection = .55 + .4 * ((beat + 1) / 2);
      for (var i = 0; i < 2; i++) {
        canvas.save();
        canvas.translate(width * (i == 0 ? .09 : .12), width * .11);
        canvas.rotate((i == 0 ? -.1 : .04) + beat * .1);
        canvas.scale(projection * (i == 0 ? .82 : 1.0), i == 0 ? .82 : 1.0);
        _imageRect(canvas, wing, wingRect, i == 0 ? .5 : .96);
        canvas.restore();
      }
    }
    _sprite(canvas, body, width * .78, .96);
  }

  void _dragonfly(
    Canvas canvas,
    ui.Image body,
    ui.Image? wing,
    double width,
    double beat,
  ) {
    if (wing != null) {
      final wingWidth = width * .68;
      final wingHeight = wingWidth * wing.height / wing.width;
      final wingRect = Rect.fromLTWH(0, -wingHeight / 2, wingWidth, wingHeight);
      for (var i = 0; i < 2; i++) {
        canvas.save();
        canvas.translate(width * (i == 0 ? .08 : .22), -width * .05);
        canvas.rotate((i == 0 ? .2 : .36) + beat * .15);
        canvas.scale(-(i == 0 ? .83 : 1.0), i == 0 ? .85 : 1.0);
        _imageRect(canvas, wing, wingRect, i == 0 ? .55 : .82);
        canvas.restore();
      }
    }
    _sprite(canvas, body, width, .96);
  }

  void _mayfly(
    Canvas canvas,
    ui.Image body,
    ui.Image? wing,
    double width,
    double beat,
  ) {
    if (wing != null) {
      final wingWidth = width * .44;
      final wingHeight = wingWidth * wing.height / wing.width;
      final wingRect = Rect.fromLTWH(0, -wingHeight, wingWidth, wingHeight);
      final projection = .66 + .29 * ((beat + 1) / 2);
      for (var i = 0; i < 2; i++) {
        canvas.save();
        canvas.translate(width * (i == 0 ? .08 : .11), -width * .04);
        canvas.rotate((i == 0 ? -.07 : .06) + beat * .1);
        canvas.scale(projection * (i == 0 ? .84 : 1.0), i == 0 ? .85 : 1.0);
        _imageRect(canvas, wing, wingRect, i == 0 ? .5 : .86);
        canvas.restore();
      }
    }
    _sprite(canvas, body, width, .94);
  }

  void _fish(Canvas canvas, ui.Image image, double width, double beat) {
    final height = width * image.height / image.width;
    final hinge = -width * .16;
    canvas.save();
    canvas.translate(hinge, 0);
    canvas.rotate(beat * .26);
    canvas.translate(-hinge, 0);
    canvas.clipRect(
      Rect.fromLTRB(
        -width / 2 - 1,
        -height / 2 - 1,
        hinge + width * .06,
        height / 2 + 1,
      ),
    );
    _sprite(canvas, image, width, .7);
    canvas.restore();
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(
        hinge - width * .03,
        -height / 2 - 1,
        width / 2 + 1,
        height / 2 + 1,
      ),
    );
    _sprite(canvas, image, width, .7);
    canvas.restore();
  }

  void _imageRect(
    Canvas canvas,
    ui.Image image,
    Rect destination,
    double opacity,
  ) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      destination,
      Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..filterQuality = FilterQuality.medium,
    );
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
