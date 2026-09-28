import 'dart:ui';

import '../models/world_map_definition.dart';

const valleyFlowers = <Offset>[
  Offset(98, 516),
  Offset(295, 638),
  Offset(809, 612),
  Offset(964, 662),
  Offset(1129, 654),
  Offset(1307, 673),
  Offset(1394, 685),
  Offset(1908, 637),
  Offset(1935, 627),
  Offset(2082, 600),
  Offset(45, 472),
  Offset(368, 416),
  Offset(645, 368),
  Offset(1055, 524),
  Offset(1123, 528),
  Offset(1518, 480),
  Offset(1924, 535),
  Offset(2144, 290),
];
const valleyCanopies = <Offset>[
  Offset(115, 155),
  Offset(485, 260),
  Offset(741, 330),
  Offset(1420, 324),
  Offset(1758, 244),
  Offset(2138, 243),
];

const valleyMapPath = <Offset>[
  Offset(.065, .640),
  Offset(.160, .685),
  Offset(.255, .657),
  Offset(.350, .627),
  Offset(.445, .668),
  Offset(.550, .600),
  Offset(.665, .613),
  Offset(.755, .552),
  Offset(.850, .586),
  Offset(.942, .477),
];

// Padding matches the original exports; motion matches the approved valley.
const valleyMapLayers = <MapLayerDefinition>[
  MapLayerDefinition(
    id: 'sky',
    asset: 'assets/images/map/layers/sky.png',
    horizontalPadding: 512,
    verticalPadding: 128,
    motion: MapLayerMotion(
      scrollFactor: .55,
      tilt: Offset(-8, -4),
      cameraFactor: .70,
    ),
  ),
  MapLayerDefinition(
    id: 'clouds',
    asset: 'assets/images/map/layers/clouds.png',
    horizontalPadding: 512,
    verticalPadding: 128,
    motion: MapLayerMotion(
      scrollFactor: .60,
      tilt: Offset(-7, -4),
      cameraFactor: .75,
      drift: Offset(40, 2),
      driftFrequency: Offset(.20, .16),
    ),
  ),
  MapLayerDefinition(
    id: 'mountains',
    asset: 'assets/images/map/layers/mountains.png',
    horizontalPadding: 512,
    verticalPadding: 128,
    motion: MapLayerMotion(
      scrollFactor: .65,
      tilt: Offset(-5, -3),
      cameraFactor: .82,
    ),
  ),
  MapLayerDefinition(
    id: 'distance',
    asset: 'assets/images/map/layers/distance.png',
    horizontalPadding: 512,
    verticalPadding: 48,
    motion: MapLayerMotion(
      scrollFactor: .82,
      tilt: Offset(-3, -2),
      cameraFactor: .92,
    ),
  ),
  MapLayerDefinition(
    id: 'terrain',
    asset: 'assets/images/map/layers/terrain.png',
    plane: MapLayerPlane.terrain,
    horizontalPadding: 128,
    verticalPadding: 128,
  ),
  MapLayerDefinition(
    id: 'foreground',
    asset: 'assets/images/map/layers/foreground.png',
    plane: MapLayerPlane.foreground,
    horizontalPadding: 128,
    verticalPadding: 80,
    motion: MapLayerMotion(scrollFactor: 1.08, tilt: Offset(14, 10)),
  ),
];

const valleyMapAmbient = MapAmbientDefinition(
  flowers: valleyFlowers,
  foregroundFlowerCount: 10,
  canopies: valleyCanopies,
  foregroundLayerId: 'foreground',
);

const valleyMap = WorldMapDefinition(
  markerSeparation: 1,
  sourceSize: Size(2172, 724),
  path: valleyMapPath,
  layers: valleyMapLayers,
  camera: MapCameraDefinition(targetY: .61, strength: .35, maxTravel: .025),
  terrainTilt: Offset(5, 3.5),
  ambient: valleyMapAmbient,
  gate: MapGateDefinition(
    anchor: Offset(1982 / 2172, 179 / 724),
    asset: 'assets/images/map/gate-sun.png',
    sourceDiameter: 104,
  ),
  numberAssets: {
    1: 'assets/images/level-number-1.png',
    2: 'assets/images/level-number-2.png',
    3: 'assets/images/level-number-3.png',
    4: 'assets/images/level-number-4.png',
    5: 'assets/images/level-number-5.png',
    6: 'assets/images/level-number-6.png',
    7: 'assets/images/level-number-7.png',
    8: 'assets/images/level-number-8.png',
    9: 'assets/images/level-number-9.png',
    10: 'assets/images/level-number-10.png',
  },
);
