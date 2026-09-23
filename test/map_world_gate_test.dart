import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/level_progress.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/game_feedback_scope.dart';
import 'package:sundoku/widgets/map_world_gate.dart';

import 'map_entry_focus_test.dart' as map;

final _captureKey = GlobalKey();
final _gate = find.byKey(const ValueKey('map-world-gate'));

void _configure(WidgetTester tester, {bool reduced = true}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reduced);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<void> _show(
  WidgetTester tester,
  LevelProgress progress, {
  VoidCallback? onNextWorld,
  bool settleAnimations = true,
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
  if (!settleAnimations) return;
  await map.settle(tester);
  map.scroll(tester).jumpTo(map.scroll(tester).position.maxScrollExtent);
  await map.settle(tester);
}

Future<void> _capture(
  WidgetTester tester,
  String name, {
  bool settleAnimations = true,
}) async {
  final directory = Platform.environment['MAP_GATE_CAPTURE_DIR'];
  if (directory == null) return;
  final context = _captureKey.currentContext!;
  await tester.runAsync(() async {
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(image.image, context);
    }
  });
  if (settleAnimations) await map.settle(tester);
  await tester.pump();
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

  MapGateRadiance radiance(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(of: _gate, matching: find.byType(CustomPaint)),
      )
      .map((paint) => paint.painter)
      .whereType<MapGateRadiance>()
      .single;

  Future<void> frames(WidgetTester tester, int milliseconds) async {
    for (var elapsed = 0; elapsed < milliseconds; elapsed += 50) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  map.desktopTestWidgets(
    'gate ignites after returning and pauses behind routes and in background',
    (tester) async {
      _configure(tester, reduced: false);
      final progress = LevelProgress();
      for (var level = 1; level <= 9; level++) {
        await progress.recordResult(level, 3);
      }
      await progress.recordResult(10, 2);
      await _show(tester, progress);
      final navigator = Navigator.of(tester.element(find.byType(MapScreen)));
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const Scaffold()),
        ),
      );
      await frames(tester, 500);
      await progress.awardLight(10);
      await frames(tester, 5500);
      expect(progress.gateCelebrationPending, isTrue);
      expect(
        tester
            .widget<MapWorldGate>(
              find.byType(MapWorldGate, skipOffstage: false),
            )
            .ignite,
        isFalse,
      );
      navigator.pop();
      for (var i = 0; i < 70; i++) {
        await frames(tester, 100);
        if (tester.widget<MapWorldGate>(_gate).ignite) break;
      }
      expect(tester.widget<MapWorldGate>(_gate).ignite, isTrue);
      expect(progress.gateCelebrationPending, isTrue);
      expect(map.activeLevel(tester), 10);
      await frames(tester, 250);
      expect(radiance(tester).progress, inExclusiveRange(.15, .4));
      await _capture(tester, 'ignition-core', settleAnimations: false);
      unawaited(
        showDialog<void>(
          context: tester.element(_gate),
          builder: (_) => const AlertDialog(content: Text('Pausa')),
        ),
      );
      await frames(tester, 500);
      final paused = radiance(tester).progress;
      await frames(tester, 5500);
      expect(radiance(tester).progress, paused);
      expect(progress.gateCelebrationPending, isTrue);
      navigator.pop();
      await frames(tester, 500);
      expect(radiance(tester).progress, inExclusiveRange(.4, .7));
      await _capture(tester, 'ignition-rays', settleAnimations: false);
      await frames(tester, 250);
      await _capture(tester, 'ignition-sparks', settleAnimations: false);
      await frames(tester, 500);
      expect(progress.gateCelebrationPending, isFalse);
      expect(radiance(tester).progress, 1);
      final turn = radiance(tester).turn;
      await frames(tester, 1000);
      expect(radiance(tester).turn - turn, closeTo(1 / 24, .003));
      await _capture(tester, 'ignition-lit', settleAnimations: false);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final stopped = radiance(tester).turn;
      await frames(tester, 2000);
      expect(radiance(tester).turn, stopped);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await frames(tester, 1000);
      expect(radiance(tester).turn, greaterThan(stopped));
      await tester.pumpWidget(const SizedBox());
      await _show(tester, progress);
      expect(tester.widget<MapWorldGate>(_gate).ignite, isFalse);
      expect(radiance(tester).progress, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      progress.dispose();
    },
  );

  map.desktopTestWidgets(
    'interrupted ignition stays pending; reduced motion finishes without spin',
    (tester) async {
      _configure(tester, reduced: false);
      final progress = LevelProgress();
      for (var level = 1; level <= 10; level++) {
        await progress.recordResult(level, 3);
      }
      await _show(tester, progress, settleAnimations: false);
      await frames(tester, 1200);
      expect(radiance(tester).progress, inExclusiveRange(0, 1));
      await tester.pumpWidget(const SizedBox());
      expect(progress.gateCelebrationPending, isTrue);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await _show(tester, progress);
      expect(progress.gateCelebrationPending, isFalse);
      expect(radiance(tester).progress, 1);
      await frames(tester, 5000);
      expect(radiance(tester).turn, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      progress.dispose();
    },
  );

  map.desktopTestWidgets(
    'home entry scrolls to the sun before revealing and playing each cue once',
    (tester) async {
      _configure(tester, reduced: false);
      final progress = LevelProgress();
      for (var level = 1; level <= 10; level++) {
        await progress.recordResult(level, 3);
      }
      final cues = <WorldGateSound>[];
      final navigatorKey = GlobalKey<NavigatorState>();
      var stops = 0;
      await tester.pumpWidget(
        GameFeedbackScope(
          onTap: () {},
          onWorldGate: (cue) {
            // On phones the gate center is near the far edge of the map.
            expect(
              map.scroll(tester).offset,
              closeTo(map.scroll(tester).position.maxScrollExtent, 1),
            );
            expect(
              tester
                  .getRect(find.byKey(const ValueKey('world-scroll')))
                  .contains(tester.getCenter(_gate)),
              isTrue,
            );
            cues.add(cue);
          },
          onStopWorldGate: () => stops++,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MapScreen(
                        progress: progress,
                        showDeveloperControls: false,
                      ),
                    ),
                  ),
                  child: const Text('Aventura'),
                ),
              ),
            ),
          ),
        ),
      );
      await frames(tester, 500);
      expect(progress.gateCelebrationPending, isTrue);
      expect(cues, isEmpty);
      await tester.tap(find.text('Aventura'));
      // Wait only for route entry and the first movement of the camera.
      for (var i = 0; i < 20; i++) {
        await frames(tester, 50);
        if (find.byKey(const ValueKey('world-scroll')).evaluate().isEmpty) {
          continue;
        }
        if (map.scroll(tester).offset > 1) break;
      }
      expect(map.scroll(tester).offset, greaterThan(0));
      expect(
        map.scroll(tester).offset,
        lessThan(map.scroll(tester).position.maxScrollExtent),
      );
      expect(tester.widget<MapWorldGate>(_gate).ignite, isFalse);
      expect(radiance(tester).progress, 0);
      expect(cues, isEmpty);

      // Go home before arrival: nothing is consumed or played offscreen.
      navigatorKey.currentState!.pop();
      await frames(tester, 1000);
      expect(progress.gateCelebrationPending, isTrue);
      expect(cues, isEmpty);
      await tester.tap(find.text('Aventura'));
      for (var i = 0; i < 30 && cues.isEmpty; i++) {
        await frames(tester, 50);
      }
      expect(cues, [WorldGateSound.ignite]);
      expect(radiance(tester).progress, lessThan(.1));
      await frames(tester, 2500);
      expect(cues, [WorldGateSound.ignite, WorldGateSound.sparkle]);
      expect(progress.gateCelebrationPending, isFalse);
      await frames(tester, 1000);
      expect(cues.length, 2, reason: 'Idle rotation remains silent');

      final stopsBeforeLeaving = stops;
      navigatorKey.currentState!.pop();
      await frames(tester, 600);
      expect(stops, greaterThan(stopsBeforeLeaving));
      await tester.tap(find.text('Aventura'));
      await frames(tester, 4000);
      expect(cues.length, 2, reason: 'Saved celebration does not repeat');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      progress.dispose();
    },
  );

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
