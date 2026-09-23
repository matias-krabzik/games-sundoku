import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/models/map_ambient_motion.dart';
import 'package:sundoku/widgets/map_ambient_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('new bees stay opaque when crossing protected level markers', () async {
    final art = MapAmbientArt();
    addTearDown(art.dispose);
    await art.load();
    expect(art.bee, isNotNull);
    final motion = MapAmbientMotion(seed: 1);
    motion.bees.add(MapBee(const ui.Offset(100, 100), 0, 0)..rest = 2);

    Future<Uint8List> render(List<ui.Rect> protectedRects) async {
      final recorder = ui.PictureRecorder();
      MapAmbientPainter(
        motion: motion,
        art: art,
        depth: MapLeafDepth.foreground,
        origin: ui.Offset.zero,
        scale: 1,
        protectedRects: protectedRects,
        time: 0,
      ).paint(ui.Canvas(recorder), const ui.Size(200, 200));
      final picture = recorder.endRecording();
      final image = await picture.toImage(200, 200);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      picture.dispose();
      return data!.buffer.asUint8List();
    }

    final clear = await render([]);
    final overLevel = await render([const ui.Rect.fromLTWH(60, 60, 80, 80)]);
    var opaquePixels = 0;
    for (var i = 3; i < clear.length; i += 4) {
      if (clear[i] == 255) opaquePixels++;
    }
    expect(
      opaquePixels,
      greaterThan(100),
      reason: 'Visible on the first frame',
    );
    expect(
      overLevel,
      orderedEquals(clear),
      reason: 'No fade over level buttons',
    );
  });
}
