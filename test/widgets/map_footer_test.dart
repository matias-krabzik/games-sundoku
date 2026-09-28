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
import 'package:sundoku/widgets/map_parallax_scene.dart';
import 'package:sundoku/widgets/world_thumbnail.dart';

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

  testWidgets(
    'map progress floats over the scene and keeps navigation usable',
    (tester) async {
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
                  disableAnimations: true,
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
        final card = tester.getRect(find.byType(MapStatusCard));
        expect(card.left, greaterThan(0));
        expect(card.right, lessThan(size.width));
        expect(card.width, lessThanOrEqualTo(480));
        expect(card.bottom, lessThanOrEqualTo(size.height));
        expect(card.top, greaterThan(size.height / 2));
        expect(
          tester.getSize(find.byType(MapParallaxScene)).height,
          size.height,
        );
        expect(find.text('Valle del Sol'), findsOneWidget);
        expect(find.text('Nivel 1'), findsOneWidget);
        expect(find.text('Mundo 1'), findsOneWidget);
        expect(find.text('1 / 10'), findsOneWidget);
        final progressBar = tester.getRect(
          find.byKey(const ValueKey('map-level-progress')),
        );
        final counter = tester.getRect(find.text('1 / 10'));
        expect(progressBar.height, greaterThanOrEqualTo(30));
        expect(progressBar.contains(counter.center), isTrue);
        expect(
          find.byKey(const ValueKey('map-next')).hitTestable(),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('map-previous')), findsOneWidget);
        final world = tester.getRect(
          find.byKey(const ValueKey('map-world-selector')),
        );
        final previous = tester.getRect(
          find.byKey(const ValueKey('map-previous')),
        );
        final next = tester.getRect(find.byKey(const ValueKey('map-next')));
        final level = tester.getRect(find.text('Nivel 1'));
        expect((previous.center.dy - level.center.dy).abs(), lessThan(1));
        expect((next.center.dy - level.center.dy).abs(), lessThan(1));
        expect(previous.right, lessThan(level.left));
        expect(next.left, greaterThan(level.right));
        expect(level.center.dy, greaterThan(world.center.dy));
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
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
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
    },
  );

  testWidgets('world two progress card keeps the reference proportions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(622, 317);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final font = FontLoader('Baloo2')
      ..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'));
    await font.load();
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildSunDokuTheme(),
        home: RepaintBoundary(
          key: key,
          child: Scaffold(
            backgroundColor: const Color(0xFFB0B0B0),
            body: Center(
              child: Transform.translate(
                offset: const Offset(0, 5),
                child: SizedBox(
                  width: 477,
                  child: MapStatusCard(
                    worldId: 'world-2',
                    level: 13,
                    unlockedLevels: 13,
                    onPrevious: () {},
                    onNext: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final card = tester.getRect(find.byType(MapStatusCard));
    final thumbnail = tester.getRect(find.byType(WorldThumbnail));
    final progress = tester.getRect(
      find.byKey(const ValueKey('map-level-progress')),
    );
    expect(card.width, 477);
    expect(card.height, 204);
    expect(thumbnail.width, 68);
    expect(progress.width, 365);
    expect(progress.height, 30);
    expect(find.text('13 / 20'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final capture = Platform.environment['MAP_CARD_REFERENCE_CAPTURE'];
    if (capture != null) {
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
        await File(capture).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}
