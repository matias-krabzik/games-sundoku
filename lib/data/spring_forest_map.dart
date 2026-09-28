import 'dart:ui';

import '../models/world_map_definition.dart';
import 'level_node.dart';

// The outer 60/40 pixels of the original art are real overscan, not stretched
// or mirrored extensions. All layers keep the same pixel registration.
// Explicit markers follow the painted bends, including mountain switchbacks.
const springForestPath = <Offset>[
  Offset(0.029240, 0.555141),
  Offset(0.087048, 0.637442),
  Offset(0.151652, 0.727972),
  Offset(0.213673, 0.736202),
  Offset(0.270525, 0.691760),
  Offset(0.337714, 0.727972),
  Offset(0.402318, 0.742786),
  Offset(0.464338, 0.727972),
  Offset(0.528942, 0.760892),
  Offset(0.590963, 0.696698),
  Offset(0.647815, 0.665424),
  Offset(0.715004, 0.695052),
  Offset(0.782193, 0.711512),
  Offset(0.849381, 0.658840),
  Offset(0.890728, 0.629212),
  Offset(0.942411, 0.571601),
  Offset(0.875223, 0.481071),
  Offset(0.916570, 0.382310),
  Offset(0.875223, 0.291780),
  Offset(0.908817, 0.160099),
];

final springForestNodes = List<LevelNode>.unmodifiable([
  for (var i = 0; i < springForestPath.length; i++)
    LevelNode(
      level: i + 1,
      x: springForestPath[i].dx,
      y: springForestPath[i].dy,
    ),
]);

const springForestMap = WorldMapDefinition(
  sourceSize: Size(2052, 644),
  path: springForestPath,
  focusLastWhenCompleted: true,
  markerSeparation: 2.0,
  terrainTilt: Offset(4, 3),
  allowVerticalPan: true,
  camera: MapCameraDefinition(),
  layers: [
    MapLayerDefinition(
      id: 'sky',
      asset: 'assets/images/map/spring-forest/sky.png',
      horizontalPadding: 60,
      verticalPadding: 40,
      motion: MapLayerMotion(scrollFactor: .96, cameraFactor: .8),
    ),
    MapLayerDefinition(
      id: 'clouds',
      asset: 'assets/images/map/spring-forest/clouds.png',
      horizontalPadding: 60,
      verticalPadding: 40,
      motion: MapLayerMotion(
        scrollFactor: .97,
        cameraFactor: .85,
        drift: Offset(12, 2),
        driftFrequency: Offset(.25, .16),
      ),
    ),
    MapLayerDefinition(
      id: 'mountains',
      asset: 'assets/images/map/spring-forest/mountains.png',
      horizontalPadding: 60,
      verticalPadding: 40,
      motion: MapLayerMotion(
        scrollFactor: .96,
        cameraFactor: .85,
        tilt: Offset(-3, -2),
      ),
    ),
    MapLayerDefinition(
      id: 'distance',
      asset: 'assets/images/map/spring-forest/distance.png',
      horizontalPadding: 60,
      verticalPadding: 40,
      motion: MapLayerMotion(
        scrollFactor: .95,
        cameraFactor: .92,
        tilt: Offset(-2, -1),
      ),
    ),
    MapLayerDefinition(
      id: 'terrain',
      asset: 'assets/images/map/spring-forest/terrain.png',
      horizontalPadding: 60,
      verticalPadding: 40,
      plane: MapLayerPlane.terrain,
    ),
    MapLayerDefinition(
      id: 'foreground',
      asset: 'assets/images/map/spring-forest/foreground.png',
      horizontalPadding: 60,
      verticalPadding: 40,
      plane: MapLayerPlane.foreground,
      motion: MapLayerMotion(scrollFactor: 1.04, tilt: Offset(8, 5)),
    ),
  ],
  ambient: MapAmbientDefinition(
    foregroundLayerId: 'foreground',
    pinkCanopy: Offset(295, 265),
    foregroundFlowerCount: 5,
    flowers: [
      Offset(75, 530),
      Offset(250, 556),
      Offset(1030, 535),
      Offset(1330, 575),
      Offset(1820, 600),
      Offset(470, 425),
      Offset(1280, 435),
      Offset(1720, 410),
    ],
    canopies: [
      Offset(10, 105),
      Offset(335, 180),
      Offset(480, 255),
      Offset(870, 165),
      Offset(1340, 235),
    ],
  ),
);
