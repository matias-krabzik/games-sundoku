import 'dart:math' as math;
import 'dart:ui';

import '../data/level_node.dart';

enum MapLayerPlane { background, terrain, foreground }

/// Motion relative to the terrain, which also carries all interactive markers.
class MapLayerMotion {
  const MapLayerMotion({
    this.scrollFactor = 1,
    this.tilt = Offset.zero,
    this.cameraFactor = 1,
    this.drift = Offset.zero,
    this.driftFrequency = Offset.zero,
  });

  final double scrollFactor;
  final Offset tilt;
  final double cameraFactor;
  final Offset drift;
  final Offset driftFrequency;

  Offset offset({
    required double centeredScroll,
    required Offset inclination,
    required double camera,
    required double seconds,
    required double scale,
  }) => Offset(
    centeredScroll * (1 - scrollFactor) +
        inclination.dx * tilt.dx +
        math.sin(seconds * driftFrequency.dx) * drift.dx * scale,
    camera * (cameraFactor - 1) +
        inclination.dy * tilt.dy +
        math.sin(seconds * driftFrequency.dy) * drift.dy * scale,
  );
}

class MapLayerDefinition {
  const MapLayerDefinition({
    required this.id,
    required this.asset,
    this.plane = MapLayerPlane.background,
    this.horizontalPadding = 0,
    this.verticalPadding = 0,
    this.motion = const MapLayerMotion(),
  }) : assert(horizontalPadding >= 0),
       assert(verticalPadding >= 0);

  final String id;
  final String asset;
  final MapLayerPlane plane;
  // Margins already painted into the asset, in unscaled source pixels.
  final double horizontalPadding;
  final double verticalPadding;
  final MapLayerMotion motion;
}

class MapCameraDefinition {
  const MapCameraDefinition({
    this.targetY = .61,
    this.strength = 0,
    this.maxTravel = 0,
  });
  final double targetY;
  final double strength;
  final double maxTravel;
}

class MapGateDefinition {
  const MapGateDefinition({
    required this.anchor,
    required this.asset,
    required this.sourceDiameter,
  });
  final Offset anchor;
  final String asset;
  final double sourceDiameter;
}

class MapAmbientDefinition {
  const MapAmbientDefinition({
    required this.flowers,
    required this.foregroundFlowerCount,
    required this.canopies,
    required this.foregroundLayerId,
    this.pinkCanopy,
    this.leafAsset = 'assets/images/map/ambient/leaf.png',
    this.beeAsset = 'assets/images/map/ambient/bee.png',
  }) : assert(foregroundFlowerCount > 0);

  final List<Offset> flowers;
  final int foregroundFlowerCount;
  final List<Offset> canopies;
  final String foregroundLayerId;
  final Offset? pinkCanopy;
  final String leafAsset;
  final String beeAsset;
}

/// Artwork and layout only. Progress, lessons and navigation belong to callers.
class WorldMapDefinition {
  const WorldMapDefinition({
    required this.sourceSize,
    required this.path,
    required this.layers,
    this.backgroundColor = const Color(0xFF78C8F6),
    this.camera = const MapCameraDefinition(),
    this.terrainTilt = Offset.zero,
    this.gate,
    this.ambient,
    this.numberAssets = const {},
    this.markerSeparation = 1.55,
    this.focusLastWhenCompleted = false,
    this.allowVerticalPan = false,
  }) : assert(markerSeparation >= 1);

  final Size sourceSize;
  final List<Offset> path;
  final List<MapLayerDefinition> layers;
  final Color backgroundColor;
  final MapCameraDefinition camera;
  final Offset terrainTilt;
  final MapGateDefinition? gate;
  final MapAmbientDefinition? ambient;
  // Existing illustrated numbers can be reused; every other number uses Text.
  final Map<int, String> numberAssets;
  final double markerSeparation;
  final bool focusLastWhenCompleted;
  final bool allowVerticalPan;
  double get aspectRatio => sourceSize.aspectRatio;

  void validate() {
    if (sourceSize.isEmpty ||
        !sourceSize.width.isFinite ||
        !sourceSize.height.isFinite ||
        path.isEmpty ||
        layers.isEmpty) {
      throw ArgumentError(
        'A map needs a finite source size, a path and artwork.',
      );
    }
    if (layers.map((layer) => layer.id).toSet().length != layers.length) {
      throw ArgumentError('Map layer IDs must be unique.');
    }
    for (var i = 0; i < path.length; i++) {
      final point = path[i];
      if (!point.dx.isFinite ||
          !point.dy.isFinite ||
          point.dx < 0 ||
          point.dx > 1 ||
          point.dy < 0 ||
          point.dy > 1) {
        throw ArgumentError('The route needs finite, normalized points.');
      }
    }
    final effects = ambient;
    if (effects != null &&
        (effects.foregroundFlowerCount > effects.flowers.length ||
            !layers.any((layer) => layer.id == effects.foregroundLayerId))) {
      throw ArgumentError(
        'Ambient anchors must belong to an existing map layer.',
      );
    }
  }

  /// Distributes any number of levels along the painted route by its length.
  List<LevelNode> nodesFor(int count) {
    validate();
    if (count < 1) {
      throw ArgumentError.value(count, 'count', 'Must be positive');
    }
    final lengths = <double>[0];
    for (var i = 1; i < path.length; i++) {
      final delta = path[i] - path[i - 1];
      lengths.add(
        lengths.last + Offset(delta.dx * aspectRatio, delta.dy).distance,
      );
    }
    return List.unmodifiable([
      for (var i = 0; i < count; i++)
        _nodeAt(
          i + 1,
          count == 1 ? 0 : lengths.last * i / (count - 1),
          lengths,
        ),
    ]);
  }

  LevelNode _nodeAt(int number, double distance, List<double> lengths) {
    for (var i = 1; i < path.length; i++) {
      final length = lengths[i] - lengths[i - 1];
      if (distance <= lengths[i] && length > 0) {
        final point = Offset.lerp(
          path[i - 1],
          path[i],
          (distance - lengths[i - 1]) / length,
        )!;
        return LevelNode(level: number, x: point.dx, y: point.dy);
      }
    }
    return LevelNode(level: number, x: path.last.dx, y: path.last.dy);
  }
}

/// Smooth, bounded camera follow; independent of level count and numbering.
double pathCameraOffset(
  double scroll,
  Size viewport,
  Size world,
  WorldMapDefinition definition,
) {
  if (world.isEmpty || definition.camera.strength == 0) return 0;
  final x = ((scroll + viewport.width / 2) / world.width).clamp(0.0, 1.0);
  final path = definition.path;
  var y = x <= path.first.dx ? path.first.dy : path.last.dy;
  for (var i = 1; i < path.length; i++) {
    final a = path[i - 1], b = path[i];
    if (x >= a.dx && x <= b.dx && b.dx > a.dx) {
      final t = (x - a.dx) / (b.dx - a.dx);
      y = a.dy + (b.dy - a.dy) * t * t * (3 - 2 * t);
      break;
    }
  }
  final camera = definition.camera;
  return ((camera.targetY - y) * world.height * camera.strength).clamp(
    -world.height * camera.maxTravel,
    world.height * camera.maxTravel,
  );
}
