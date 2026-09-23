import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/level_progress.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/map_world_gate.dart';

import 'map_entry_focus_test.dart' as map;

final _captureKey = GlobalKey();
final _gate = find.byKey(const ValueKey('map-world-gate'));

void _configure(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<void> _show(
  WidgetTester tester,
  LevelProgress progress, {
  VoidCallback? onNextWorld,
}) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: _captureKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildSunDokuTheme(),
        home: MapScreen(
          progress: progress,
          showDeveloperControls: false,
          onNextWorld: onNextWorld,
        ),
      ),
    ),
  );
  await map.settle(tester);
  map.scroll(tester).jumpTo(map.scroll(tester).position.maxScrollExtent);
  await map.settle(tester);
}

Future<void> _capture(WidgetTester tester, String name) async {
  final directory = Platform.environment['MAP_GATE_CAPTURE_DIR'];
  if (directory == null) return;
  final context = _captureKey.currentContext!;
  await tester.runAsync(() async {
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(image.image, context);
    }
  });
  await map.settle(tester);
  await tester.runAsync(() async {
    final boundary = context.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await Directory(directory).create(recursive: true);
    await File('$directory/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Baloo2',
    )..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  map.desktopTestWidgets(
    'gate unlocks only after the last round and relocks when progress resets',
    (tester) async {
      _configure(tester);
      final progress = LevelProgress();
      for (var level = 1; level <= 9; level++) {
        await progress.recordResult(level, 3);
      }
      await progress.recordResult(10, 2);
      var opened = 0;
      await _show(tester, progress, onNextWorld: () => opened++);
      expect(tester.widget<MapWorldGate>(_gate).unlocked, isFalse);
      await _capture(tester, 'phone-locked');
      await tester.tap(_gate);
      await map.settle(tester);
      expect(opened, 0);

      await progress.awardLight(10);
      await map.settle(tester);
      expect(tester.widget<MapWorldGate>(_gate).unlocked, isTrue);
      await _capture(tester, 'phone-completed');
      await tester.tap(_gate);
      await map.settle(tester);
      expect(opened, 1);

      await progress.resetLevel(10);
      await map.settle(tester);
      expect(tester.widget<MapWorldGate>(_gate).unlocked, isFalse);
      await tester.tap(_gate);
      await map.settle(tester);
      expect(opened, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      progress.dispose();
    },
  );

  map.desktopTestWidgets(
    'completed gate has no navigation action until its destination is connected',
    (tester) async {
      _configure(tester);
      final semantics = tester.ensureSemantics();
      final progress = LevelProgress();
      for (var level = 1; level <= 10; level++) {
        await progress.recordResult(level, 3);
      }
      await _show(tester, progress);
      expect(tester.widget<MapWorldGate>(_gate).unlocked, isTrue);
      final node = tester.getSemantics(find.bySemanticsLabel('Próximo mundo'));
      expect(
        node.getSemanticsData().hasAction(ui.SemanticsAction.tap),
        isFalse,
      );
      await tester.tap(_gate);
      await map.settle(tester);
      expect(find.byType(MapScreen), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
      progress.dispose();
    },
  );

  map.desktopTestWidgets(
    'sun remains anchored to terrain through scrolling and responsive resizing',
    (tester) async {
      _configure(tester);
      final progress = LevelProgress();
      for (var level = 1; level <= 10; level++) {
        await progress.recordResult(level, 3);
      }
      await _show(tester, progress);
      final terrain = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/map/layers/terrain.png',
      );
      for (final size in [
        const Size(390, 844),
        const Size(834, 1210),
        const Size(844, 390),
        const Size(320, 568),
      ]) {
        tester.view.physicalSize = size;
        await map.settle(tester);
        final scroll = map.scroll(tester);
        for (final fraction in [.75, 1.0]) {
          scroll.jumpTo(scroll.position.maxScrollExtent * fraction);
          await map.settle(tester);
          final scale = tester.getSize(terrain).width / 2428;
          // Source coordinate includes the layer's 128 px overscan.
          final expected =
              tester.getTopLeft(terrain) + Offset(2110, 307) * scale;
          expect((tester.getCenter(_gate) - expected).distance, lessThan(.01));
          expect(tester.getSize(_gate).shortestSide, greaterThanOrEqualTo(48));
          expect(
            tester
                .getRect(_gate)
                .overlaps(
                  tester.getRect(find.byKey(const ValueKey('map-settings'))),
                ),
            isFalse,
          );
          expect(tester.takeException(), isNull);
        }
        await _capture(
          tester,
          '${size.width.toInt()}x${size.height.toInt()}-completed',
        );
      }
      await tester.pumpWidget(const SizedBox());
      progress.dispose();
    },
  );
}
