import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/app.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/level_progress.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/map_world_gate.dart';

import 'map_entry_focus_test.dart' as map;

Future<void> frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  final directory = Platform.environment['SUMMIT_CAPTURE_DIR'];
  if (directory == null) return;
  await tester.runAsync(() async {
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(image.image, key.currentContext!);
    }
  });
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(directory).create(recursive: true);
    await File('$directory/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
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
    'summit enters world 3 with saved completion and reduced motion',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(834, 1210);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final repo = GameRepository.memory();
      await repo.prepareDebugForest();
      for (var n = 1; n <= 20; n++) {
        await repo.recordDebugLights(mapLevelId(n, worldId: 'world-2'), 3);
      }
      await repo.markQuickPlayCelebrated();
      await repo.markWorldGateCelebrated();
      await repo.markWorldGateCelebrated(worldId: 'world-2');
      await repo.saveModule('homeWelcome', {'namePromptShown': true});
      await repo.saveModule('tutorials/notes/v1', {'completed': true});
      await repo.markNotesAnnounced();
      await repo.visitWorld('world-2');
      await tester.pumpWidget(
        SunDokuApp(repository: repo, feedback: const GameFeedback()),
      );
      await frames(tester, 30);
      await tester.tap(find.byKey(const ValueKey('home-play')));
      await frames(tester, 30);
      await tester.ensureVisible(find.byKey(const ValueKey('choose-world-2')));
      await tester.tap(find.byKey(const ValueKey('choose-world-2')));
      await frames(tester, 30);
      expect(
        tester.widget<MapScreen>(find.byType(MapScreen)).progress!.worldId,
        'world-2',
      );
      final rotation = find.byKey(const ValueKey('map-gate-rotation'));
      final still = tester.widget<Transform>(rotation).transform.clone();
      await frames(tester, 10);
      expect(tester.widget<Transform>(rotation).transform, still);
      await tester.tap(find.byKey(const ValueKey('map-world-gate')));
      await frames(tester, 40);
      expect(repo.lastAdventureWorld, 'world-3');
      expect(
        tester.widget<MapScreen>(find.byType(MapScreen)).progress!.worldId,
        'world-3',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );

  map.desktopTestWidgets(
    'summit stays dormant until last round then ignites, spins and opens rivers',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(834, 1210);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final repo = GameRepository.memory();
      await repo.prepareDebugForest();
      for (var n = 1; n <= 20; n++) {
        await repo.recordDebugLights(
          mapLevelId(n, worldId: 'world-2'),
          n == 20 ? 2 : 3,
        );
      }
      final progress = LevelProgress(repository: repo, worldId: 'world-2');
      final boundary = GlobalKey();
      var visits = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildSunDokuTheme(),
          home: RepaintBoundary(
            key: boundary,
            child: MapScreen(
              progress: progress,
              showDeveloperControls: false,
              onNextWorld: () {
                visits++;
              },
            ),
          ),
        ),
      );
      await frames(tester, 30);
      final gate = find.byKey(const ValueKey('map-world-gate'));
      expect(tester.widget<MapWorldGate>(gate).unlocked, isFalse);
      final still = tester
          .widget<Transform>(find.byKey(const ValueKey('map-gate-rotation')))
          .transform
          .clone();
      await frames(tester, 10);
      expect(
        tester
            .widget<Transform>(find.byKey(const ValueKey('map-gate-rotation')))
            .transform,
        still,
      );
      await capture(tester, boundary, 'summit-dormant-ipad');
      await tester.tap(gate, warnIfMissed: false);
      expect(visits, 0);
      await progress.awardLight(20);
      await frames(tester, 100);
      expect(tester.widget<MapWorldGate>(gate).unlocked, isTrue);
      expect(progress.gateCelebrationPending, isFalse);
      expect(repo.isWorldUnlocked('world-3'), isTrue);
      final rotation = tester
          .widget<Transform>(find.byKey(const ValueKey('map-gate-rotation')))
          .transform
          .clone();
      await frames(tester, 10);
      expect(
        tester
            .widget<Transform>(find.byKey(const ValueKey('map-gate-rotation')))
            .transform,
        isNot(rotation),
      );
      for (final size in [
        const Size(834, 1210),
        const Size(390, 844),
        const Size(1210, 834),
        const Size(844, 390),
      ]) {
        tester.view.physicalSize = size;
        await frames(tester, 15);
        await capture(
          tester,
          boundary,
          'summit-active-${size.width.toInt()}x${size.height.toInt()}',
        );
        final rect = tester.getRect(gate);
        expect(rect.top, greaterThanOrEqualTo(0), reason: '$size: $rect');
        expect(
          rect.bottom,
          lessThanOrEqualTo(size.height),
          reason: '$size: $rect',
        );
        expect(rect.left, greaterThanOrEqualTo(0), reason: '$size: $rect');
        expect(
          rect.right,
          lessThanOrEqualTo(size.width),
          reason: '$size: $rect',
        );
        final lastLevelRect = tester.getRect(
          find.byKey(const ValueKey('map-level-20')),
        );
        expect(rect.overlaps(lastLevelRect), isFalse);
        expect(gate.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.tap(gate);
      await frames(tester, 5);
      expect(visits, 1);
      await tester.pumpWidget(const SizedBox());
      progress.dispose();
      await repo.close();
    },
  );
}
