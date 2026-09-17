import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/level_progress.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/map_chrome.dart';
import 'package:sundoku/widgets/score_feedback.dart';

void main() {
  test('world score retains best results and resets with the world', () async {
    final repo = GameRepository.memory();
    final progress = LevelProgress(repository: repo);
    await repo.completeDebugLevel(1, random: Random(7));
    final first = progress.recordFor(1).bestPoints;
    await repo.completeDebugLevel(2, random: Random(9));
    expect(progress.worldPoints, first + progress.recordFor(2).bestPoints);
    await progress.resetLevel(1);
    expect(progress.worldPoints, 0);
    progress.dispose();
    await repo.close();
  });

  testWidgets('footer spans the screen, names levels and shows a score badge', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final font = FontLoader('Baloo2')
      ..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'));
    await font.load();
    final repo = GameRepository.memory();
    final progress = LevelProgress(repository: repo);
    final key = GlobalKey();
    for (final size in [
      const Size(834, 1210),
      const Size(390, 844),
      const Size(844, 390),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildSunDokuTheme(),
          home: RepaintBoundary(
            key: key,
            child: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(size.height < 500 ? 2 : 1),
              ),
              child: MapScreen(
                progress: progress,
                showDeveloperControls: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      final footer = tester.getRect(find.byType(MapStatusCard));
      expect(footer.left, 0);
      expect(footer.right, size.width);
      expect(footer.bottom, size.height);
      expect(find.text('La entrada del valle'), findsOneWidget);
      final sun = tester.widget<Image>(
        find.byKey(const ValueKey('map-score-sun')),
      );
      expect(
        (sun.image as AssetImage).assetName,
        'assets/images/map/score-sun.png',
      );
      expect(find.text(formatScore(progress.worldPoints)), findsOneWidget);
      expect(find.byKey(const ValueKey('map-next')), findsNothing);
      expect(find.textContaining('puntos obtenidos'), findsNothing);
      expect(tester.takeException(), isNull);
      if (size.width == 834 &&
          Platform.environment['MAP_FOOTER_CAPTURE'] != null) {
        await tester.runAsync(() async {
          final context = key.currentContext!;
          for (final widget in tester.widgetList<Image>(find.byType(Image))) {
            await precacheImage(widget.image, context);
          }
        });
        await tester.pump();
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(Platform.environment['MAP_FOOTER_CAPTURE']!)
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
    await tester.pumpWidget(const SizedBox());
    progress.dispose();
    await repo.close();
    debugDefaultTargetPlatformOverride = null;
  });
}
