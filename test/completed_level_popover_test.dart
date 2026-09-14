import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/level_progress.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/widgets/ui_surface_art.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Baloo2')
      ..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'));
    await font.load();
  });

  testWidgets(
    'summary actions stay reachable on small screens and with large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      for (final size in [const Size(320, 568), const Size(844, 390)]) {
        tester.view.physicalSize = size;
        final progress = LevelProgress();
        await progress.recordResult(1, 3);
        await tester.pumpWidget(
          MaterialApp(
            home: MapScreen(
              progress: progress,
              showDeveloperControls: false,
              onReplayIntroduction: () async {},
            ),
          ),
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('level-1-label')));
        await settle(tester);
        expect(
          find.byKey(const ValueKey('level-replay')).hitTestable(),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('level-summary-ok')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        // System back dismisses the popover rather than leaving the map.
        await tester.binding.handlePopRoute();
        await settle(tester);
        expect(find.byKey(const ValueKey('level-summary')), findsNothing);
        expect(find.byType(MapScreen), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        progress.dispose();
      }
    },
  );

  testWidgets(
    'completed practice slides up, fades, closes in reverse and replays on request',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final progress = LevelProgress();
      addTearDown(progress.dispose);
      await progress.recordResult(1, 3);
      var replays = 0;
      final capture = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: MapScreen(
              progress: progress,
              showDeveloperControls: false,
              onReplayIntroduction: () async {
                replays++;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      final marker = find.byKey(const ValueKey('level-1-label'));
      await tester.tap(marker);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final fade = find.byKey(const ValueKey('level-summary-fade'));
      final slide = find.byKey(const ValueKey('level-summary-slide'));
      expect(tester.widget<Opacity>(fade).opacity, inExclusiveRange(0, 1));
      expect(
        tester.widget<Transform>(slide).transform.entry(1, 3),
        greaterThan(0),
      );
      await settle(tester);
      final replay = find.byKey(const ValueKey('level-replay'));
      final ok = find.byKey(const ValueKey('level-summary-ok'));
      expect(replay.hitTestable(), findsOneWidget);
      expect(ok.hitTestable(), findsOneWidget);
      expect(tester.getRect(replay).right, lessThan(tester.getRect(ok).left));
      expect(
        tester.getRect(find.byKey(const ValueKey('level-summary'))).bottom,
        lessThan(tester.getRect(marker).top),
      );

      final directory = Platform.environment['TUTORIAL_CAPTURE_DIR'];
      if (directory != null) {
        await tester.runAsync(() async {
          for (final asset in {
            for (final surface in UiSurface.values) surface.spec.asset,
            'assets/images/world-1-horizontal.png',
            'assets/images/map/marker-gold.png',
            'assets/images/map/marker-ivory.png',
            'assets/images/map/icons.png',
            for (var n = 1; n <= 10; n++) 'assets/images/level-number-$n.png',
          }) {
            await precacheImage(AssetImage(asset), capture.currentContext!);
          }
        });
        await settle(tester);
        await tester.runAsync(() async {
          final image =
              await (capture.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          await Directory(directory).create(recursive: true);
          await File('$directory/completed-level.png')
              .writeAsBytes(data!.buffer.asUint8List());
        });
      }
      await tester.tap(ok);
      await tester.pump();
      for (
        var frame = 0;
        frame < 30 && tester.widget<Opacity>(fade).opacity == 1;
        frame++
      ) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(tester.widget<Opacity>(fade).opacity, lessThan(1));
      expect(
        tester.widget<Transform>(slide).transform.entry(1, 3),
        greaterThan(0),
      );
      await settle(tester);
      expect(find.byKey(const ValueKey('level-summary')), findsNothing);
      expect(replays, 0);
      await tester.tap(marker);
      await settle(tester);
      await tester.tap(replay);
      await settle(tester);
      expect(replays, 1);
      expect(progress.lightsFor(1), 3);
      expect(progress.isUnlocked(2), isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
