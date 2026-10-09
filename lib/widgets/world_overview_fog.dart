import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/world_overview.dart';
import '../models/world_overview_fog.dart';
import '../models/world_overview_camera.dart';

/// Decode each transparent sprite once, shared by every bank and both zones.
class OverviewFogArt extends ChangeNotifier {
  final images = <OverviewFogTexture, ui.Image>{};
  bool _disposed = false;
  Future<void>? _loading;

  Future<void> load() => _loading ??= _loadAll();

  Future<void> _loadAll() async {
    await Future.wait([
      for (final texture in OverviewFogTexture.values) _load(texture),
    ]);
  }

  Future<void> _load(OverviewFogTexture texture) async {
    final bytes = await rootBundle.load(texture.asset);
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      targetWidth: 1024,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    if (_disposed) {
      frame.image.dispose();
    } else {
      images[texture] = frame.image;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final image in images.values) {
      image.dispose();
    }
    images.clear();
    super.dispose();
  }
}

/// Above the landscape and its creatures; below all interactive controls.
class WorldOverviewFog extends StatelessWidget {
  const WorldOverviewFog({
    super.key,
    required this.overview,
    required this.image,
    required this.lockedWorlds,
    required this.frame,
    required this.art,
    this.discovery = const {},
  });

  final WorldOverview overview;
  final Rect image;
  final Set<String> lockedWorlds;
  final ValueListenable<double> frame;
  final OverviewFogArt art;
  final Map<String, double> discovery;

  @override
  Widget build(BuildContext context) {
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          fit: StackFit.expand,
          children: [
            for (final entry in overview.fogRegions.entries)
              Opacity(
                key: ValueKey('world-fog-${entry.key}'),
                opacity:
                    lockedWorlds.contains(entry.key) ||
                        (!reduced && (discovery[entry.key] ?? 1) < 1)
                    ? 1
                    : 0,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: OverviewFogPainter(
                      region: Rect.fromLTWH(
                        image.left + entry.value.left * image.width,
                        image.top + entry.value.top * image.height,
                        entry.value.width * image.width,
                        entry.value.height * image.height,
                      ),
                      frame: frame,
                      art: art,
                      discoveryProgress: reduced
                          ? (lockedWorlds.contains(entry.key) ? 0 : 1)
                          : discovery[entry.key] ??
                                (lockedWorlds.contains(entry.key) ? 0 : 1),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class OverviewFogPainter extends CustomPainter {
  OverviewFogPainter({
    required this.region,
    required this.frame,
    required this.art,
    this.discoveryProgress = 0,
  }) : super(repaint: Listenable.merge([frame, art]));

  final Rect region;
  final ValueListenable<double> frame;
  final OverviewFogArt art;
  final double discoveryProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final lift = OverviewDiscovery.lift(discoveryProgress);
    if (art.images.isEmpty || lift == 1) return;
    final movingRegion = region.shift(
      Offset(0, -(size.height + region.height) * lift),
    );
    final visible = movingRegion.intersect(Offset.zero & size);
    if (visible.isEmpty) return;
    canvas.save();
    canvas.clipRect(visible);
    canvas.saveLayer(visible, Paint());
    final paint = Paint()..filterQuality = FilterQuality.low;
    // Only the coverage mask follows the map. Sprite sizes and drift are in
    // screen space, so zooming the terrain never enlarges the clouds.
    final rise = Offset(0, -(size.height + region.height) * lift);
    for (final band in overviewFogBands) {
      final sprite = art.images[band.texture];
      if (sprite == null) continue;
      final source = Rect.fromLTWH(
        0,
        0,
        sprite.width.toDouble(),
        sprite.height.toDouble(),
      );
      paint.color = Colors.white.withValues(alpha: band.opacity);
      for (final piece in band.screenPieces(
        size,
        frame.value,
        source.width / source.height,
      )) {
        final lifted = piece.shift(rise);
        if (lifted.overlaps(visible)) {
          canvas.drawImageRect(sprite, source, lifted, paint);
        }
      }
    }
    // Fade only the zone boundaries, without painting an opaque veil or
    // allowing drifting fog to travel into an already unlocked destination.
    for (final (begin, end) in const [
      (Alignment.topCenter, Alignment.bottomCenter),
      (Alignment.centerLeft, Alignment.centerRight),
    ]) {
      canvas.drawRect(
        movingRegion,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = LinearGradient(
            begin: begin,
            end: end,
            colors: const [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: const [0, .20, .72, 1],
          ).createShader(movingRegion),
      );
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(OverviewFogPainter oldDelegate) =>
      oldDelegate.region != region ||
      oldDelegate.discoveryProgress != discoveryProgress ||
      oldDelegate.frame != frame ||
      oldDelegate.art != art;
}
