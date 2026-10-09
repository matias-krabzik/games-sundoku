import 'dart:math' as math;
import 'dart:ui';

/// Normalized registration points in the two approved, UI-free landscapes.
class WorldOverview {
  const WorldOverview(this.landscape);
  final bool landscape;

  String get asset =>
      'assets/images/world-selection/overview-${landscape ? 'landscape' : 'portrait'}.png';
  Size get sourceSize =>
      landscape ? const Size(1536, 1024) : const Size(1024, 1536);
  List<Offset> get destinations => landscape
      ? const [Offset(.145, .511), Offset(.48, .410), Offset(.794, .264)]
      : const [Offset(.377, .74), Offset(.39, .383), Offset(.79, .163)];

  /// Fog stays registered to the painted regions when the image is cropped.
  Map<String, Rect> get fogRegions => landscape
      ? const {
          'world-2': Rect.fromLTRB(.25, -.20, .73, 1.20),
          'world-3': Rect.fromLTRB(.57, -.25, 1.24, 1.15),
        }
      : const {
          'world-2': Rect.fromLTRB(-.22, .16, 1.22, .64),
          'world-3': Rect.fromLTRB(-.22, -.18, 1.22, .35),
        };
  List<Offset> get canopies => landscape
      ? const [
          Offset(.13, .55),
          Offset(.30, .47),
          Offset(.38, .27),
          Offset(.60, .32),
          Offset(.81, .29),
        ]
      : const [
          Offset(.23, .59),
          Offset(.29, .43),
          Offset(.25, .28),
          Offset(.53, .18),
          Offset(.72, .31),
        ];
  List<Rect> get water => landscape
      ? const [
          Rect.fromLTWH(.80, .35, .075, .03),
          Rect.fromLTWH(.83, .55, .085, .025),
          Rect.fromLTWH(.43, .67, .07, .025),
          Rect.fromLTWH(.63, .09, .05, .025),
        ]
      : const [
          Rect.fromLTWH(.85, .30, .10, .018),
          Rect.fromLTWH(.85, .378, .085, .023),
          Rect.fromLTWH(.54, .827, .07, .023),
          Rect.fromLTWH(.61, .435, .045, .02),
        ];
  List<(Offset, Offset)> get waterfalls => landscape
      ? const [
          (Offset(.90, .108), Offset(.889, .149)),
          (Offset(.576, .523), Offset(.588, .563)),
          (Offset(.369, .548), Offset(.372, .573)),
        ]
      : const [
          (Offset(.89, .035), Offset(.875, .069)),
          (Offset(.486, .303), Offset(.49, .332)),
          (Offset(.825, .731), Offset(.835, .758)),
        ];

  Offset pixels(Offset point) =>
      Offset(point.dx * sourceSize.width, point.dy * sourceSize.height);

  /// Cover without distorting the painting. Markers and effects use this same
  /// transform, including cropped edges on particularly tall/narrow windows.
  Rect imageRect(Size viewport) {
    final scale = math.max(
      viewport.width / sourceSize.width,
      viewport.height / sourceSize.height,
    );
    final width = sourceSize.width * scale;
    final height = sourceSize.height * scale;
    return Rect.fromLTWH(
      (viewport.width - width) / 2,
      landscape ? 0 : (viewport.height - height) / 2,
      width,
      height,
    );
  }

  Offset project(Offset point, Rect image) =>
      image.topLeft + Offset(point.dx * image.width, point.dy * image.height);
}
