import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/app.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/data/services/mock_world_navigation_service.dart';
import 'package:sundoku/data/world_overview.dart';
import 'package:sundoku/screens/world_selection_screen.dart';
import 'package:sundoku/screens/first_experience_screen.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/world_overview_fog.dart';
import 'package:sundoku/widgets/world_overview_scene.dart';
import 'package:sundoku/widgets/world_overview_viewport.dart';
import 'package:sundoku/widgets/world_destination_arrival.dart';
import 'package:sundoku/widgets/ui_surface_art.dart';
import 'package:sundoku/models/world_overview_camera.dart';

import 'support/world3_baseline.dart';
import 'tutorial_journey_widget_test.dart' as scene;

final capture = GlobalKey();
Future<void> show(
  WidgetTester tester,
  GameRepository repo, {
  double scale = 1,
  Future<void> Function(String)? onSelect,
  bool developerControls = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildSunDokuTheme(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: const EdgeInsets.only(top: 24, bottom: 20),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 20),
        ),
        child: child!,
      ),
      home: RepaintBoundary(
        key: capture,
        child: WorldSelectionScreen(
          repository: repo,
          navigation: MockWorldNavigationService(repo),
          onSelectWorld: onSelect ?? (_) async {},
          showDeveloperControls: developerControls,
        ),
      ),
    ),
  );
  await scene.settle(tester);
}

Future<void> snapshot(WidgetTester tester, String name) async {
  final dir = Platform.environment['WORLD_SELECTION_CAPTURE_DIR'];
  if (dir == null) return;
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
  await scene.settle(tester);
  await tester.runAsync(() async {
    final image = await (context.findRenderObject()! as RenderRepaintBoundary)
        .toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(dir).create(recursive: true);
    await File('$dir/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Baloo2',
    )..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'))).load();
  });
  testWidgets(
    'locked destinations are hidden behind fog; available progress remains live',
    (tester) async {
      scene.configure(tester);
      final repo = GameRepository.memory();
      await repo.recordDebugLights('world-1/level-1', 3);
      await repo.recordDebugLights('world-1/level-2', 2);
      final selected = <String>[];
      await show(
        tester,
        repo,
        onSelect: (id) async {
          selected.add(id);
        },
      );
      expect(find.text('1 / 10'), findsOneWidget);
      expect(find.text('5 / 30'), findsOneWidget);
      expect(find.text('Bosque de la Cumbre'), findsNothing);
      expect(find.text('Ríos Cruzados'), findsNothing);
      expect(find.textContaining('Completa '), findsNothing);
      expect(find.textContaining('Continuar'), findsNothing);
      expect(find.byKey(const ValueKey('choose-world-2')), findsNothing);
      expect(find.byKey(const ValueKey('choose-world-3')), findsNothing);
      for (final id in ['world-2', 'world-3']) {
        expect(
          tester.widget<Opacity>(find.byKey(ValueKey('world-fog-$id'))).opacity,
          1,
        );
      }
      const overview = WorldOverview(false);
      await tester.tapAt(
        overview.project(
          overview.destinations[1],
          tester
              .widget<WorldOverviewViewport>(find.byType(WorldOverviewViewport))
              .camera
              .image,
        ),
      );
      await scene.settle(tester);
      expect(selected, isEmpty);
      await tester.ensureVisible(find.byKey(const ValueKey('choose-world-1')));
      await scene.tap(tester, find.byKey(const ValueKey('choose-world-1')));
      await scene.tap(
        tester,
        find.byKey(const ValueKey('world-enter-world-1')),
      );
      expect(selected, ['world-1']);
      await repo.recordDebugLights('world-1/level-2', 3);
      await scene.settle(tester);
      expect(find.text('2 / 10'), findsOneWidget);
      expect(find.text('6 / 30'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );
  for (final allUnlocked in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'destinations remain reachable with fixed controls at text $scale, unlocked: $allUnlocked',
        (tester) async {
          scene.configure(tester);
          final repo = allUnlocked
              ? await openBaselineRepository(baselineSave(completedWorlds: 2))
              : GameRepository.memory();
          if (!allUnlocked) {
            await repo.recordDebugLights('world-1/level-1', 3);
            await repo.recordDebugLights('world-1/level-2', 3);
          }
          for (final size in [
            const Size(320, 568),
            const Size(390, 844),
            const Size(402, 874),
            const Size(568, 320),
            const Size(834, 1210),
            const Size(1210, 834),
            const Size(1440, 900),
          ]) {
            tester.view.physicalSize = size;
            await show(tester, repo, scale: scale);
            expect(tester.takeException(), isNull);
            expect(find.text('Reino de Solara').hitTestable(), findsOneWidget);
            expect(
              find.byKey(const ValueKey('worlds-back')).hitTestable(),
              findsOneWidget,
            );
            final header = tester.getRect(find.text('Reino de Solara'));
            expect(header.left, greaterThanOrEqualTo(0));
            expect(header.right, lessThanOrEqualTo(size.width));
            expect(find.byType(Scrollable), findsNothing);
            final camera = tester
                .widget<WorldOverviewViewport>(
                  find.byType(WorldOverviewViewport),
                )
                .camera;
            final backRect = tester.getRect(
              find.byKey(const ValueKey('worlds-back')),
            );
            for (final id in ['world-1', 'world-2', 'world-3']) {
              final target = find.byKey(ValueKey('world-point-$id'));
              if (!allUnlocked && id != 'world-1') {
                expect(target, findsNothing);
                continue;
              }
              camera.focusWorld(id, animate: false);
              await tester.pump();
              final card = tester.getRect(
                find.byKey(ValueKey('world-art-$id')),
              );
              expect(card.left, greaterThan(0));
              expect(card.right, lessThan(size.width));
              expect(card.top, greaterThanOrEqualTo(header.bottom));
              expect(card.bottom, lessThanOrEqualTo(size.height - 20));
              expect(target.hitTestable(), findsOneWidget);
              final action = find.byKey(ValueKey('world-enter-$id'));
              await tester.pump(const Duration(milliseconds: 250));
              expect(action.hitTestable(), findsOneWidget);
              final actionRect = tester.getRect(
                find.descendant(
                  of: action,
                  matching: find.byType(UiSurfaceArt),
                ),
              );
              expect(actionRect.left, greaterThanOrEqualTo(0));
              expect(actionRect.right, lessThanOrEqualTo(size.width));
              expect(actionRect.top, greaterThan(card.bottom));
              expect(actionRect.bottom, lessThanOrEqualTo(size.height - 20));

              expect(
                tester.getRect(find.byKey(const ValueKey('worlds-back'))),
                backRect,
              );
            }

            await snapshot(
              tester,
              '${allUnlocked ? 'unlocked-' : ''}${size.width.toInt()}x${size.height.toInt()}-text-$scale',
            );
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
          }
          await repo.close();
        },
      );
    }
  }
  testWidgets(
    'DEV completes one destination at a time and clears only its unlocked fog',
    (tester) async {
      scene.configure(tester);
      final repo = GameRepository.memory(enableWorld3Challenges: true);
      final selected = <String>[];
      await show(
        tester,
        repo,
        developerControls: true,
        onSelect: (id) async {
          selected.add(id);
        },
      );
      final state = tester.state<WorldOverviewSceneState>(
        find.byType(WorldOverviewScene),
      );
      for (final (index, name) in [
        'Valle del Sol',
        'Bosque de la Cumbre',
        'Ríos Cruzados',
      ].indexed) {
        await scene.tap(
          tester,
          find.byKey(const ValueKey('dev-floating-button')),
        );
        expect(find.text('Completar $name'), findsOneWidget);
        await scene.tap(
          tester,
          find.byKey(const ValueKey('dev-complete-next-world')),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(repo.worldCompleted('world-${index + 1}'), isTrue);
        expect(
          tester.state<WorldOverviewSceneState>(
            find.byType(WorldOverviewScene),
          ),
          same(state),
        );
        expect(
          find.byKey(const ValueKey('worlds-settings')).hitTestable(),
          findsOneWidget,
        );
        for (var n = 1; n <= 3; n++) {
          final unlocked = n <= index + 2;
          expect(
            find.byKey(ValueKey('world-point-world-$n')),
            unlocked ? findsOneWidget : findsNothing,
          );
          if (n > 1) {
            expect(
              tester
                  .widget<Opacity>(find.byKey(ValueKey('world-fog-world-$n')))
                  .opacity,
              unlocked ? 0 : 1,
            );
          }
        }
      }
      expect(find.text('90 / 90'), findsOneWidget);
      await scene.tap(tester, find.byKey(const ValueKey('choose-world-3')));
      await scene.tap(
        tester,
        find.byKey(const ValueKey('world-enter-world-3')),
      );
      expect(selected, ['world-3']);
      final fog = tester.widget<WorldOverviewFog>(
        find.byType(WorldOverviewFog),
      );
      expect(fog.lockedWorlds, isEmpty);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );
  testWidgets(
    'unlock rises before card arrival and is remembered after reopening',
    (tester) async {
      scene.configure(tester, reduced: false);
      final repo = GameRepository.memory();
      await show(tester, repo);
      final camera = tester
          .widget<WorldOverviewViewport>(find.byType(WorldOverviewViewport))
          .camera;
      await repo.completeNextDebugWorld();
      await tester.pump();
      final point = find.byKey(const ValueKey('world-point-world-2'));
      Finder arrival() => find.ancestor(
        of: point,
        matching: find.byType(WorldDestinationArrival),
      );
      double opacity() => tester
          .widget<Opacity>(
            find
                .descendant(of: arrival(), matching: find.byType(Opacity))
                .first,
          )
          .opacity;
      OverviewFogPainter fogPainter() =>
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byKey(const ValueKey('world-fog-world-2')),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as OverviewFogPainter;
      expect(opacity(), 0);
      expect(point.hitTestable(), findsNothing);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(
        OverviewDiscovery.lift(fogPainter().discoveryProgress),
        greaterThan(0),
      );
      expect(opacity(), 0);
      expect(
        (repo.state.modules['navigation/worldOverview']
            as Map)['revealedWorlds'],
        ['world-1'],
      );
      for (var i = 0; i < 42; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(OverviewDiscovery.lift(fogPainter().discoveryProgress), 1);
      expect(opacity(), inExclusiveRange(0, 1));
      for (var i = 0; i < 22; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.pump();
      expect(opacity(), 1);
      expect(point.hitTestable(), findsOneWidget);
      expect(camera.revealedWorlds, {'world-1', 'world-2'});
      expect(
        tester
            .widget<Opacity>(find.byKey(const ValueKey('world-fog-world-2')))
            .opacity,
        0,
      );
      expect(
        tester
            .widget<Opacity>(find.byKey(const ValueKey('world-fog-world-3')))
            .opacity,
        1,
      );
      expect(
        (repo.state.modules['navigation/worldOverview']
            as Map)['revealedWorlds'],
        ['world-1', 'world-2'],
      );
      await tester.pumpWidget(const SizedBox());
      await show(tester, repo);
      final reopened = tester
          .widget<WorldOverviewViewport>(find.byType(WorldOverviewViewport))
          .camera;
      expect(reopened.discovery['world-2'], 1);
      expect(reopened.animating, isFalse);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );

  testWidgets('pending discovery waits off-route and resumes without jumping', (
    tester,
  ) async {
    scene.configure(tester, reduced: false);
    final repo = GameRepository.memory();
    await show(tester, repo);
    final camera = tester
        .widget<WorldOverviewViewport>(find.byType(WorldOverviewViewport))
        .camera;
    final navigator = Navigator.of(
      tester.element(find.byType(WorldSelectionScreen)),
    );
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Juego')),
        ),
      ),
    );
    await scene.settle(tester);
    await repo.completeNextDebugWorld();
    await scene.settle(tester);
    expect(camera.discovery['world-2'], 0);
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(camera.discovery['world-2'], lessThan(.1));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(camera.discovery['world-2'], greaterThan(0));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final paused = camera.discovery['world-2'];
    await tester.pump(const Duration(seconds: 5));
    expect(camera.discovery['world-2'], paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(camera.discovery['world-2'], paused);
    for (var i = 0; i < 85; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(camera.discovery['world-2'], 1);
    await tester.pumpWidget(const SizedBox());
    await repo.close();
  });

  testWidgets('an unseen destination starts discovery on a fresh selector', (
    tester,
  ) async {
    scene.configure(tester, reduced: false);
    final repo = GameRepository.memory();
    await repo.saveModule('navigation/worldOverview', {
      'revealedWorlds': ['world-1'],
    });
    await repo.completeNextDebugWorld();
    await show(tester, repo);
    final camera = tester
        .widget<WorldOverviewViewport>(find.byType(WorldOverviewViewport))
        .camera;
    expect(camera.discovery['world-2'], inExclusiveRange(0, 1));
    for (var i = 0; i < 85; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(camera.discovery['world-2'], 1);
    expect(
      find.byKey(const ValueKey('world-point-world-2')).hitTestable(),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await repo.close();
  });

  testWidgets('drag and pinch move only the map, preserving destination taps', (
    tester,
  ) async {
    scene.configure(tester);
    final repo = GameRepository.memory();
    final selected = <String>[];
    await show(
      tester,
      repo,
      onSelect: (id) async {
        selected.add(id);
      },
    );
    final viewport = find.byType(WorldOverviewViewport);
    final camera = tester.widget<WorldOverviewViewport>(viewport).camera;
    final back = tester.getRect(find.byKey(const ValueKey('worlds-back')));
    final before = camera.center;
    await tester.dragFrom(const Offset(300, 630), const Offset(-55, 60));
    await tester.pump();
    expect(camera.center.dx, isNot(before.dx));
    expect(camera.center.dy, isNot(before.dy));
    expect(selected, isEmpty);
    final zoom = camera.zoom;
    final finger1 = await tester.startGesture(
      const Offset(120, 610),
      pointer: 1,
    );
    final finger2 = await tester.startGesture(
      const Offset(220, 610),
      pointer: 2,
    );
    await finger1.moveTo(const Offset(80, 610));
    await finger2.moveTo(const Offset(260, 610));
    await tester.pump();
    expect(camera.zoom, greaterThan(zoom));
    await finger1.up();
    await finger2.up();
    expect(tester.getRect(find.byKey(const ValueKey('worlds-back'))), back);
    camera.focusWorld('world-1', animate: false);
    await tester.pump();
    await scene.tap(tester, find.byKey(const ValueKey('choose-world-1')));
    await scene.tap(tester, find.byKey(const ValueKey('world-enter-world-1')));
    expect(selected, ['world-1']);
    await tester.pumpWidget(const SizedBox());
    await repo.close();
  });

  testWidgets(
    'expanded selection and entry targets stay separate and allow dragging',
    (tester) async {
      scene.configure(tester);
      final repo = GameRepository.memory();
      final selected = <String>[];
      await show(tester, repo, onSelect: (id) async => selected.add(id));
      final camera = tester
          .widget<WorldOverviewViewport>(find.byType(WorldOverviewViewport))
          .camera;
      final selection = find.byKey(const ValueKey('choose-world-1'));
      final artwork = find.byKey(const ValueKey('world-art-world-1'));
      final action = find.byKey(const ValueKey('world-enter-world-1'));

      camera.pan(const Offset(0, 25));
      await tester.pump();
      final before = camera.center;
      final nearCrest = tester.getRect(artwork).topCenter - const Offset(0, 10);
      expect(tester.getRect(selection).contains(nearCrest), isTrue);
      await tester.tapAt(nearCrest);
      await scene.settle(tester);
      expect(camera.center, isNot(before));
      expect(selected, isEmpty);

      final selectionRect = tester.getRect(selection);
      final entryRect = tester.getRect(action);
      expect(selectionRect.overlaps(entryRect), isFalse);
      final nearRibbon =
          tester.getRect(artwork).centerLeft - const Offset(10, 0);
      await tester.tapAt(nearRibbon);
      await scene.settle(tester);
      expect(selected, isEmpty);

      final beforeDrag = camera.center;
      await tester.dragFrom(nearRibbon, const Offset(0, 45));
      await scene.settle(tester);
      expect(camera.center, isNot(beforeDrag));
      expect(selected, isEmpty);
      camera.focusWorld('world-1', animate: false);
      await tester.pump();

      final buttonArt = tester.getRect(
        find.descendant(of: action, matching: find.byType(UiSurfaceArt)),
      );
      final nearEntry = buttonArt.centerRight + const Offset(10, 0);
      expect(tester.getRect(action).contains(nearEntry), isTrue);
      expect(tester.getRect(selection).contains(nearEntry), isFalse);
      await tester.tapAt(nearEntry);
      await scene.settle(tester);
      expect(selected, ['world-1']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );

  testWidgets(
    'background taps keep entry and both destination controls recenter',
    (tester) async {
      scene.configure(tester, reduced: false);
      final repo = GameRepository.memory();
      final selected = <String>[];
      await show(
        tester,
        repo,
        onSelect: (id) async {
          selected.add(id);
        },
      );
      final camera = tester
          .widget<WorldOverviewViewport>(find.byType(WorldOverviewViewport))
          .camera;
      final action = find.byKey(const ValueKey('world-enter-world-1'));
      final originalAction = tester.element(action);
      final originalCenter = camera.center;
      await tester.tapAt(const Offset(300, 125));
      await scene.settle(tester);
      expect(camera.center, originalCenter);
      expect(tester.element(action), same(originalAction));
      expect(action.hitTestable(), findsOneWidget);
      final tap = await tester.startGesture(const Offset(300, 125));
      await tap.moveBy(const Offset(1, 1));
      await tap.up();
      await scene.settle(tester);
      expect(camera.center, originalCenter);
      expect(tester.element(action), same(originalAction));
      for (final key in ['choose-world-1', 'world-medallion-world-1']) {
        camera.pan(const Offset(-25, 25));
        await tester.pump();
        expect(action, findsOneWidget);
        final before = camera.center;
        final target = find.byKey(ValueKey(key));
        final finger = await tester.startGesture(tester.getCenter(target));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 70));
        final transform = tester.widget<Transform>(
          find.descendant(
            of: find.byKey(const ValueKey('choose-world-1')),
            matching: find.byKey(const ValueKey('juicy-press-transform')),
          ),
        );
        expect(transform.transform.entry(0, 0), lessThan(1));
        await finger.up();
        for (var i = 0; i < 55; i++) {
          await tester.pump(const Duration(milliseconds: 20));
        }
        expect(camera.center, isNot(before));
        final cardRect = tester.getRect(
          find.byKey(const ValueKey('world-art-world-1')),
        );
        final buttonRect = tester.getRect(
          find.descendant(of: action, matching: find.byType(UiSurfaceArt)),
        );
        // The actual rendered group is centered, not merely the clamped camera.
        final group = cardRect.expandToInclude(buttonRect);
        expect(group.center.dx, closeTo(195, 1));
        expect(group.center.dy, closeTo((96 + 808) / 2, 1));
        expect(action.hitTestable(), findsOneWidget);
        expect(selected, isEmpty);
      }
      await scene.tap(tester, action);
      expect(selected, ['world-1']);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );

  testWidgets(
    'touch and wheel scrolling have a short inertial tail and stop on touch',
    (tester) async {
      scene.configure(tester, reduced: false);
      final repo = await openBaselineRepository(
        baselineSave(completedWorlds: 2),
      );
      await show(tester, repo);
      final camera = tester
          .widget<WorldOverviewViewport>(find.byType(WorldOverviewViewport))
          .camera;
      camera.focusWorld('world-2', animate: false);
      await tester.pump();
      await tester.flingFrom(
        const Offset(300, 660),
        const Offset(-60, -65),
        700,
      );
      final released = camera.center;
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect((camera.center - released).distance, greaterThan(.001));
      final moved = Offset(
        (camera.center.dx - released.dx) * camera.image.width,
        (camera.center.dy - released.dy) * camera.image.height,
      );
      expect(moved.distance, lessThan(110));
      await tester.tapAt(const Offset(300, 125));
      final stopped = camera.center;
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(camera.center, stopped);
      expect(find.byKey(const ValueKey('world-enter-world-2')), findsOneWidget);
      tester.binding.handlePointerEvent(
        const PointerScrollEvent(
          position: Offset(300, 660),
          scrollDelta: Offset(24, 36),
        ),
      );
      final wheeled = camera.center;
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect((camera.center - wheeled).distance, greaterThan(0));
      final tail = Offset(
        (camera.center.dx - wheeled.dx) * camera.image.width,
        (camera.center.dy - wheeled.dy) * camera.image.height,
      );
      expect(tail.distance, lessThan(12));
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );

  testWidgets(
    'home opens worlds first; choosing world one preserves its first tutorial and map',
    (tester) async {
      scene.configure(tester);
      final repo = GameRepository.memory();
      await repo.saveModule('homeWelcome', {'namePromptShown': true});
      await tester.pumpWidget(
        SunDokuApp(repository: repo, feedback: const GameFeedback()),
      );
      await tester.pump(const Duration(seconds: 3));
      await scene.settle(tester);
      await scene.tap(tester, find.byKey(const ValueKey('home-play')));
      expect(find.byType(WorldSelectionScreen), findsOneWidget);
      expect(find.byType(FirstExperienceScreen), findsNothing);
      expect(repo.state.modules[FirstExperienceController.moduleKey], isNull);
      await scene.tap(tester, find.byKey(const ValueKey('choose-world-1')));
      await scene.tap(
        tester,
        find.byKey(const ValueKey('world-enter-world-1')),
      );
      expect(find.byType(FirstExperienceScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(FirstExperienceScreen))).pop();
      await scene.settle(tester);
      expect(find.byType(MapScreen), findsOneWidget);
      await scene.tap(tester, find.byKey(const ValueKey('map-world-selector')));
      expect(find.byType(WorldSelectionScreen), findsOneWidget);
      await scene.tap(tester, find.byKey(const ValueKey('choose-world-1')));
      await scene.tap(
        tester,
        find.byKey(const ValueKey('world-enter-world-1')),
      );
      expect(find.byType(MapScreen), findsOneWidget);
      expect(find.byType(FirstExperienceScreen), findsNothing);
      await scene.tap(tester, find.byKey(const ValueKey('map-back')));
      expect(find.byKey(const ValueKey('home-play')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );
  testWidgets('all unlocked worlds show their real totals and retain entry', (
    tester,
  ) async {
    scene.configure(tester);
    final repo = await openBaselineRepository(baselineSave(completedWorlds: 2));
    final selected = <String>[];
    await show(
      tester,
      repo,
      onSelect: (id) async {
        selected.add(id);
      },
    );
    expect(find.text('30 / 30'), findsOneWidget);
    expect(find.text('60 / 60'), findsOneWidget);
    expect(find.text('0 / 90'), findsOneWidget);
    for (final world in ['world-1', 'world-2', 'world-3']) {
      final target = find.byKey(ValueKey('choose-$world'));
      tester
          .widget<WorldOverviewViewport>(find.byType(WorldOverviewViewport))
          .camera
          .focusWorld(world, animate: false);
      await tester.pump();
      await scene.tap(tester, target);
      expect(selected.length, int.parse(world.split('-').last) - 1);
      await scene.tap(tester, find.byKey(ValueKey('world-enter-$world')));
    }
    expect(selected, ['world-1', 'world-2', 'world-3']);
    await tester.pumpWidget(const SizedBox());
    await repo.close();
  });
}
