import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/level_node.dart';
import 'package:sundoku/data/level_progress.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/map_level_button.dart';
import 'package:sundoku/widgets/map_selection_light.dart';

import '../support/world3_baseline.dart';

Future<ByteData> pixels(WidgetTester tester, GlobalKey key) async {
  final image = await tester.runAsync(
    () => (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
        .toImage(pixelRatio: 1),
  );
  final data = await tester.runAsync(() => image!.toByteData());
  image!.dispose();
  return data!;
}

int brightness(ByteData data, int x, int y) {
  final index = (y * 400 + x) * 4;
  return data.getUint8(index) +
      data.getUint8(index + 1) +
      data.getUint8(index + 2);
}

void desktopTestWidgets(String name, WidgetTesterCallback body) {
  testWidgets(name, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await body(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Baloo2',
    )..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'))).load();
  });
  desktopTestWidgets('level rays fade between targets behind usable markers', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 300);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final capture = GlobalKey();
    var presses = 0;
    const nodes = [
      LevelNode(level: 1, x: .2, y: .5),
      LevelNode(level: 2, x: .533333333333, y: .5),
    ];
    Future<void> show(int level, {bool reduced = false, bool ticking = true}) =>
        tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: TickerMode(
                enabled: ticking,
                child: RepaintBoundary(
                  key: capture,
                  child: ColoredBox(
                    color: Colors.black,
                    child: MapSelectionLight(
                      level: level,
                      nodes: nodes,
                      nodeSize: 80,
                      worldSize: const Size(600, 300),
                      scroll: scroll,
                      child: SingleChildScrollView(
                        controller: scroll,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 600,
                          height: 300,
                          child: Stack(
                            children: [
                              for (final node in nodes)
                                Positioned(
                                  left: node.x * 600 - 30,
                                  top: 120,
                                  width: 60,
                                  height: 60,
                                  child: GestureDetector(
                                    key: ValueKey('marker-${node.level}'),
                                    onTap: () => presses++,
                                    child: const ColoredBox(
                                      color: Color(0xFFFF0000),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

    await show(1);
    final initial = await pixels(tester, capture);
    final oldGlow = brightness(initial, 120, 220);
    expect(oldGlow, greaterThan(20));
    expect(brightness(initial, 320, 220), 0);
    // An opaque marker keeps its exact color: the rays are underneath it.
    final center = (150 * 400 + 120) * 4;
    expect(initial.buffer.asUint8List(center, 4), [255, 0, 0, 255]);
    await tester.tap(find.byKey(const ValueKey('marker-1')));
    expect(presses, 1);

    await show(2);
    await tester.pump(const Duration(milliseconds: 150));
    final fading = await pixels(tester, capture);
    expect(brightness(fading, 120, 220), inExclusiveRange(0, oldGlow));
    await tester.pump(const Duration(milliseconds: 550));
    final arriving = await pixels(tester, capture);
    expect(brightness(arriving, 120, 220), 0);
    expect(brightness(arriving, 320, 220), greaterThan(20));
    await tester.pump(const Duration(milliseconds: 150));

    // Motion pauses off-route and the light still tracks the map's scroll.
    await show(2, ticking: false);
    final paused = await pixels(tester, capture);
    await tester.pump(const Duration(seconds: 3));
    final later = await pixels(tester, capture);
    expect(later.buffer.asUint8List(), paused.buffer.asUint8List());
    scroll.jumpTo(120);
    await tester.pump();
    final scrolled = await pixels(tester, capture);
    expect(brightness(scrolled, 200, 220), greaterThan(20));
    expect(brightness(scrolled, 320, 220), 0);

    // Reduced motion transfers the highlight immediately, with no trail.
    scroll.jumpTo(0);
    await show(1, reduced: true);
    final reduced = await pixels(tester, capture);
    expect(brightness(reduced, 120, 220), greaterThan(20));
    expect(brightness(reduced, 320, 220), 0);
    await tester.pump(const Duration(seconds: 3));
    final still = await pixels(tester, capture);
    expect(still.buffer.asUint8List(), reduced.buffer.asUint8List());
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final world in ['world-1', 'world-2', 'world-3']) {
    for (final size in [const Size(390, 844), const Size(834, 1210)]) {
      desktopTestWidgets('$world selected level has rays at $size', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final repo = await openBaselineRepository(
          baselineSave(completedWorlds: int.parse(world.substring(6)) - 1),
        );

        final progress = LevelProgress(repository: repo, worldId: world);

        await progress.recordResult(1, 3);
        await progress.recordResult(2, 2);
        final capture = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildSunDokuTheme(),
            home: RepaintBoundary(
              key: capture,
              child: MapScreen(
                progress: progress,
                showDeveloperControls: false,
              ),
            ),
          ),
        );
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final light = tester.widget<MapSelectionLight>(
          find.byType(MapSelectionLight),
        );
        final selected = tester
            .widgetList<MapLevelButton>(find.byType(MapLevelButton))
            .singleWhere((button) => button.active);
        expect(light.level, selected.level);
        expect(selected.level, 2);
        expect(selected.unlocked, isTrue);
        expect(light.nodes, progress.world.nodes);
        expect(
          find.byKey(const ValueKey('map-level-selection-rays')),
          findsOneWidget,
        );
        final dir = Platform.environment['MAP_LIGHT_CAPTURE_DIR'];
        if (dir != null) {
          final context = capture.currentContext!;
          final images = tester
              .widgetList<Image>(find.byType(Image))
              .map((image) => image.image)
              .toSet();
          await tester.runAsync(() async {
            for (final provider in images) {
              await precacheImage(provider, context);
            }
          });
          await tester.pump(const Duration(milliseconds: 50));
          await tester.runAsync(() async {
            final image =
                await (context.findRenderObject()! as RenderRepaintBoundary)
                    .toImage(pixelRatio: 1);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory(dir).create(recursive: true);
            await File(
              '$dir/$world-${size.width.toInt()}x${size.height.toInt()}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        progress.dispose();
        await repo.close();
      });
    }
  }
}
