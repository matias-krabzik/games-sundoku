import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../data/level_node.dart';
import '../models/world_map_definition.dart';

/// Keeps dense maps touchable without stretching the source artwork.
class MapLayout {
  MapLayout(
    Size viewport,
    WorldMapDefinition definition,
    List<LevelNode> nodes,
  ) {
    final ratio = definition.aspectRatio;
    var gap = double.infinity;
    for (var i = 1; i < nodes.length; i++) {
      gap = math.min(
        gap,
        Offset(
          (nodes[i].x - nodes[i - 1].x) * ratio,
          nodes[i].y - nodes[i - 1].y,
        ).distance,
      );
    }
    final naturalHeight = math.max(viewport.height, viewport.width / ratio);
    // The medallion and its crest extend beyond its 48 px touch surface.
    final spacing = definition.markerSeparation;
    final requiredHeight = gap > 0 && gap.isFinite ? 48 * spacing / gap : 0.0;
    final height = math.max(naturalHeight, requiredHeight);
    worldSize = Size(height * ratio, height);
    final preferred = viewport.height < 520
        ? 68.0
        : (viewport.width * .24).clamp(82.0, 106.0);
    nodeSize = math
        .min(preferred, gap * height / spacing)
        .clamp(48.0, preferred);
    var topOffset = (viewport.height - height) / 2;
    if (requiredHeight > naturalHeight && nodes.isNotEmpty) {
      final minY = nodes.map((node) => node.y).reduce(math.min) * height;
      final maxY = nodes.map((node) => node.y).reduce(math.max) * height;
      final top = 16 + nodeSize * .85 - minY;
      final bottom = viewport.height - 16 - nodeSize / 2 - 22 - maxY;
      topOffset = top <= bottom
          ? topOffset.clamp(top, bottom)
          : (top + bottom) / 2;
    }
    worldTop = topOffset;
  }

  late final Size worldSize;
  late final double nodeSize;
  late final double worldTop;
}
