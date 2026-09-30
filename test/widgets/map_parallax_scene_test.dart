import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/models/map_ambient_motion.dart';
import 'package:sundoku/widgets/map_ambient_painter.dart';
import 'package:sundoku/widgets/map_parallax_scene.dart';

class _Sensors extends SensorsPlatform {
  int listeners = 0;
  late final events = StreamController<AccelerometerEvent>.broadcast(
    onListen: () => listeners++,
    onCancel: () => listeners--,
  );
  @override
  Stream<AccelerometerEvent> accelerometerEventStream({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }) => events.stream;
}

Future<void> frames(WidgetTester tester, [int count = 50]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  test('path camera is continuous and bounded throughout the panorama', () {
    const world = Size(2172, 724);
    for (final viewport in [const Size(390, 724), const Size(1600, 724)]) {
      var previous = mapPathCameraOffset(0, viewport, world);
      for (var x = 1.0; x <= world.width - viewport.width; x++) {
        final next = mapPathCameraOffset(x, viewport, world);
        expect(next.abs(), lessThanOrEqualTo(world.height * .025));
        expect((next - previous).abs(), lessThan(.3));
        previous = next;
      }
    }
  });

  Widget scene(
    ScrollController scroll, {
    bool reduced = false,
    bool visible = true,
    bool landscape = false,
    VoidCallback? onMarkerTap,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        disableAnimations: reduced,
        size: landscape ? const Size(800, 400) : const Size(400, 800),
      ),
      child: TickerMode(
        enabled: visible,
        child: MapParallaxScene(
          scroll: scroll,
          worldSize: const Size(1800, 600),
          child: SingleChildScrollView(
            controller: scroll,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1800,
              height: 600,
              child: Stack(
                children: [
                  Positioned(
                    left: 350,
                    top: 400,
                    child: GestureDetector(
                      key: const ValueKey('marker'),
                      behavior: HitTestBehavior.opaque,
                      onTap: onMarkerTap ?? () {},
                      child: const SizedBox(width: 50, height: 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  MapAmbientPainter ambientPainter(WidgetTester tester, MapLeafDepth depth) =>
      tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<MapAmbientPainter>()
          .firstWhere((painter) => painter.depth == depth);

  testWidgets(
    'ambient tap preserves level taps and horizontal drags; motion pauses',
    (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      var selected = 0;
      await tester.pumpWidget(scene(scroll, onMarkerTap: () => selected++));
      await frames(tester, 2);
      var painter = ambientPainter(tester, MapLeafDepth.foreground);
      final motion = painter.motion;
      // Decoding begins in the widget's fake-async zone. Pump its continuations
      // between real IO turns instead of awaiting that future in runAsync.
      for (var i = 0; i < 50 && painter.art.bee == null; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expect(painter.art.leaf, isNotNull);
      expect(painter.art.bee, isNotNull);
      await tester.tapAt(const Offset(740, 200));
      await tester.pump();
      expect(motion.gustCount, 1);
      await tester.tap(find.byKey(const ValueKey('marker')));
      await tester.pump();
      expect(selected, 1);
      expect(motion.gustCount, 1);
      final startOrigin = painter.origin;
      final startAir = ambientPainter(tester, MapLeafDepth.air).origin;
      await tester.dragFrom(const Offset(650, 280), const Offset(-220, 0));
      await frames(tester, 5);
      expect(scroll.offset, greaterThan(150));
      expect(motion.gustCount, 1);
      painter = ambientPainter(tester, MapLeafDepth.foreground);
      expect(
        painter.origin.dx - startOrigin.dx,
        closeTo(-scroll.offset * 1.08, .01),
      );
      expect(
        ambientPainter(tester, MapLeafDepth.air).origin.dx - startAir.dx,
        closeTo(-scroll.offset, .01),
      );
      // A tiny distant bee retains a finger-sized target in the terrain plane.
      // A drag on the same bee still belongs to the horizontal scroll view.
      final bee = motion.bees.first;
      final terrainOrigin = ambientPainter(tester, MapLeafDepth.air).origin;
      bee
        ..position = (const Offset(550, 360) - terrainOrigin) / painter.scale
        ..depth = 1
        ..rest = 10;
      final beforePop = bee.position;
      await tester.tapAt(const Offset(573, 360));
      await tester.pump();
      expect(bee.startled, isTrue);
      expect(motion.gustCount, 1);
      await frames(tester, 8);
      expect(bee.visualScale, greaterThan(1));
      expect(bee.position, beforePop);
      painter = ambientPainter(tester, MapLeafDepth.foreground);
      final beforeDrag = scroll.offset;
      await tester.dragFrom(
        painter.origin + motion.beePosition(bee) * painter.scale,
        const Offset(-100, 0),
      );
      await frames(tester, 5);
      expect(scroll.offset, greaterThan(beforeDrag + 50));
      expect(motion.gustCount, 1);
      await tester.pumpWidget(scene(scroll, visible: false));
      await tester.pump();
      final pausedTime = motion.time;
      final pausedBee = motion.bees.first.position;
      await frames(tester, 100);
      expect(motion.time, pausedTime);
      expect(motion.bees.first.position, pausedBee);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(scene(scroll, reduced: true));
      await frames(tester, 10);
      expect(motion.time, pausedTime);
      expect(
        tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .where((w) => w.painter is MapAmbientPainter),
        isEmpty,
      );
      await tester.pumpWidget(scene(scroll));
      await frames(tester, 5);
      expect(motion.time - pausedTime, lessThan(.2));
      expect(motion.time, greaterThan(pausedTime));

      final context = tester.element(find.byType(MapParallaxScene));
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(content: Text('Pausa')),
        ),
      );
      await frames(tester, 20);
      final modalTime = motion.time;
      await frames(tester, 30);
      expect(motion.time, modalTime);
      Navigator.of(context).pop();
      await frames(tester, 20);
      expect(motion.time, greaterThan(modalTime));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final backgroundTime = motion.time;
      await frames(tester, 20);
      expect(motion.time, backgroundTime);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await frames(tester, 5);
      expect(motion.time, greaterThan(backgroundTime));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant({TargetPlatform.macOS}),
  );

  testWidgets(
    'terrain and markers share hover and scroll, reduced motion stops ticks',
    (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(scene(scroll));
      await frames(tester, 2);
      final marker = find.byKey(const ValueKey('marker'));
      final terrain = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            (w.image as AssetImage).assetName.endsWith('/terrain.png'),
      );
      final startMarker = tester.getTopLeft(marker);
      final startTerrain = tester.getTopLeft(terrain);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(790, 590));
      await frames(tester);
      scroll.jumpTo(100);
      await frames(tester);
      expect(
        ((tester.getTopLeft(marker) - startMarker) -
                (tester.getTopLeft(terrain) - startTerrain))
            .distance,
        lessThan(.001),
      );
      expect(marker.hitTestable(), findsOneWidget);
      await tester.pumpWidget(scene(scroll, reduced: true));
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      final transform = tester.widget<Transform>(
        find.byKey(const ValueKey('map-terrain-transform')),
      );
      expect(transform.transform.storage[12], 0);
      expect(transform.transform.storage[13], 0);
      await mouse.removePointer();
      await tester.pumpWidget(scene(scroll, visible: false));
      await frames(tester);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant({TargetPlatform.macOS}),
  );

  testWidgets(
    'horizontal scroll visibly separates depth and covers viewport edges',
    (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      Finder layer(String name) => find.byWidgetPredicate(
        (w) =>
            w is Image &&
            (w.image as AssetImage).assetName.endsWith('/$name.png'),
      );
      await tester.pumpWidget(scene(scroll));
      await frames(tester, 2);
      final names = ['sky', 'mountains', 'distance', 'terrain', 'foreground'];
      final before = {
        for (final name in names) name: tester.getTopLeft(layer(name)).dx,
      };
      scroll.jumpTo(400);
      await frames(tester, 2);
      final moved = {
        for (final name in names)
          name: tester.getTopLeft(layer(name)).dx - before[name]!,
      };
      expect(moved['terrain'], closeTo(-400, .001));
      expect(moved['sky']!, greaterThan(moved['mountains']!));
      expect(moved['mountains']!, greaterThan(moved['distance']!));
      expect(moved['distance']!, greaterThan(moved['terrain']!));
      expect(moved['terrain']!, greaterThan(moved['foreground']!));
      // A 400 px pan must separate mountains and terrain by at least 120 px.
      // Merely ordering the speeds allowed an imperceptible 4% difference.
      expect(moved['mountains']!.abs(), lessThanOrEqualTo(280));
      expect(moved['mountains']!.abs(), greaterThanOrEqualTo(200));
      expect(moved['distance']!.abs(), inInclusiveRange(300, 350));
      expect(moved['foreground']!.abs(), greaterThanOrEqualTo(420));
      expect(moved['sky']! - moved['foreground']!, greaterThan(180));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(790, 590));
      await frames(tester);
      for (final offset in [0.0, scroll.position.maxScrollExtent]) {
        scroll.jumpTo(offset);
        await frames(tester, 2);
        for (final name in [...names, 'clouds']) {
          final rect = tester.getRect(layer(name));
          expect(rect.left, lessThanOrEqualTo(0), reason: name);
          expect(rect.top, lessThanOrEqualTo(0), reason: name);
          expect(rect.right, greaterThanOrEqualTo(800), reason: name);
          expect(rect.bottom, greaterThanOrEqualTo(600), reason: name);
        }
      }
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant({TargetPlatform.macOS}),
  );

  testWidgets(
    'clouds drift visibly without moving markers and pause offscreen',
    (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(scene(scroll));
      await frames(tester, 2);
      final clouds = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            (w.image as AssetImage).assetName.endsWith('/clouds.png'),
      );
      final marker = find.byKey(const ValueKey('marker'));
      final markerStart = tester.getTopLeft(marker);
      final cloudStart = tester.getTopLeft(clouds);
      await frames(tester, 60);
      final drift = (tester.getTopLeft(clouds) - cloudStart).distance;
      expect(drift, greaterThan(6));
      expect(drift, lessThan(10));
      expect(tester.getTopLeft(marker), markerStart);
      await tester.pumpWidget(scene(scroll, visible: false));
      await tester.pump();
      final paused = tester.getTopLeft(clouds);
      await frames(tester);
      expect(tester.getTopLeft(clouds), paused);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(scene(scroll, reduced: true));
      await frames(tester);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant({TargetPlatform.macOS}),
  );

  testWidgets(
    'sensor calibrates on rotation, stops hidden and handles unavailable hardware',
    (tester) async {
      final previous = SensorsPlatform.instance;
      final sensors = _Sensors();
      SensorsPlatform.instance = sensors;
      addTearDown(() async {
        SensorsPlatform.instance = previous;
        await sensors.events.close();
      });
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(scene(scroll));
      await tester.pump();
      expect(sensors.listeners, 1);
      sensors.events.add(AccelerometerEvent(0, 8, 3, DateTime.now()));
      await frames(tester, 2);
      sensors.events.add(AccelerometerEvent(3, 6, 3, DateTime.now()));
      await frames(tester);
      var transform = tester.widget<Transform>(
        find.byKey(const ValueKey('map-terrain-transform')),
      );
      expect(transform.transform.storage[12].abs(), greaterThan(0));
      await tester.pumpWidget(scene(scroll, visible: false));
      await tester.pump();
      expect(sensors.listeners, 0);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(scene(scroll, landscape: true));
      await tester.pump();
      expect(sensors.listeners, 1);
      sensors.events.add(AccelerometerEvent(8, 0, 3, DateTime.now()));
      await frames(tester);
      transform = tester.widget<Transform>(
        find.byKey(const ValueKey('map-terrain-transform')),
      );
      expect(transform.transform.storage[12], 0);
      sensors.events.addError(StateError('Sensor unavailable'));
      await frames(tester, 2);
      expect(sensors.listeners, 0);
      scroll.jumpTo(250);
      await frames(tester, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets('map renders the separated landscape on phone and tablet', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final capture = Platform.environment['MAP_CAPTURE_DIR'];
    if (capture != null) {
      final font = FontLoader('Baloo2')
        ..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'));
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
    for (final size in [
      const Size(390, 844),
      const Size(1194, 834),
      const Size(844, 390),
    ]) {
      tester.view.physicalSize = size;
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: key,
            child: const MapScreen(showDeveloperControls: false),
          ),
        ),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(MapScreen));
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        for (final path in manifest.listAssets().where(
          (path) =>
              path.endsWith('.png') &&
              (path.startsWith('assets/images/map/') ||
                  path.startsWith('assets/images/home/') ||
                  path.startsWith('assets/images/ui/')),
        )) {
          await precacheImage(AssetImage(path), context);
        }
      });
      await frames(tester);
      expect(find.byType(MapParallaxScene), findsOneWidget);
      final layerAssets = tester
          .widgetList<Image>(
            find.descendant(
              of: find.byType(MapParallaxScene),
              matching: find.byType(Image),
            ),
          )
          .map((image) => image.image)
          .whereType<AssetImage>()
          .map((asset) => asset.assetName)
          .where((path) => path.startsWith('assets/images/map/layers/'));
      expect(
        layerAssets,
        unorderedEquals([
          'assets/images/map/layers/sky.png',
          'assets/images/map/layers/clouds.png',
          'assets/images/map/layers/mountains.png',
          'assets/images/map/layers/distance.png',
          'assets/images/map/layers/terrain.png',
          'assets/images/map/layers/foreground.png',
        ]),
      );
      expect(tester.takeException(), isNull);
      final map = tester.widget<MapParallaxScene>(
        find.byType(MapParallaxScene),
      );
      final viewport = tester.getRect(find.byType(MapParallaxScene));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(
        location: viewport.bottomRight - const Offset(1, 1),
      );
      await frames(tester);
      for (final position in [
        (name: 'start', fraction: 0.0),
        (name: 'middle', fraction: .5),
        (name: 'end', fraction: 1.0),
      ]) {
        map.scroll.jumpTo(
          map.scroll.position.maxScrollExtent * position.fraction,
        );
        await frames(tester, 2);
        for (final asset in layerAssets) {
          final rect = tester.getRect(
            find.byWidgetPredicate(
              (w) =>
                  w is Image &&
                  w.image is AssetImage &&
                  (w.image as AssetImage).assetName == asset,
            ),
          );
          final reason = '$asset at ${position.name}, $size';
          expect(rect.left, lessThanOrEqualTo(viewport.left), reason: reason);
          expect(rect.top, lessThanOrEqualTo(viewport.top), reason: reason);
          expect(
            rect.right,
            greaterThanOrEqualTo(viewport.right),
            reason: reason,
          );
          expect(
            rect.bottom,
            greaterThanOrEqualTo(viewport.bottom),
            reason: reason,
          );
        }
        expect(tester.takeException(), isNull);
        if (capture != null) {
          final art = ambientPainter(tester, MapLeafDepth.foreground).art;
          for (var i = 0; i < 50 && art.bee == null; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)),
            );
            await tester.pump();
          }
          expect(art.leaf, isNotNull);
          expect(art.bee, isNotNull);
          await frames(tester, 130);
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory(capture).create(recursive: true);
            await File(
              '$capture/map-${size.width.toInt()}-${position.name}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
          if (Platform.environment['MAP_CAPTURE_MOTION'] == '1' &&
              ((size.width == 390 && position.name == 'start') ||
                  (size.width == 1194 && position.name == 'middle'))) {
            for (var frame = 0; frame < 160; frame++) {
              await tester.pump(const Duration(milliseconds: 50));
              if (frame == 50) {
                final painter = ambientPainter(tester, MapLeafDepth.foreground);
                final bee = painter.motion.bees.last;
                await tester.tapAt(
                  painter.origin + bee.position * painter.scale,
                );
              }
              await tester.runAsync(() async {
                final image = await boundary.toImage();
                final data = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final folder = Directory(
                  '$capture/motion-${size.width.toInt()}',
                );
                await folder.create(recursive: true);
                await File(
                  '${folder.path}/${frame.toString().padLeft(3, '0')}.png',
                ).writeAsBytes(data!.buffer.asUint8List());
                image.dispose();
              });
            }
          }
        }
      }
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox());
    }
  }, variant: TargetPlatformVariant({TargetPlatform.macOS}));
}
