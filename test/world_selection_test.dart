import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/app.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/data/services/mock_world_navigation_service.dart';
import 'package:sundoku/screens/world_selection_screen.dart';
import 'package:sundoku/screens/first_experience_screen.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/juicy_press.dart';

import 'support/world3_baseline.dart';
import 'tutorial_journey_widget_test.dart' as scene;

final capture = GlobalKey();
Future<void> show(
  WidgetTester tester,
  GameRepository repo, {
  double scale = 1,
  Future<void> Function(String)? onSelect,
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
    'only unlocked points can enter; progress includes partial stars and reacts to changes',
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
      expect(find.text('1 / 10 niveles'), findsOneWidget);
      expect(find.text('5 / 30'), findsOneWidget);
      expect(find.text('Completa el Mundo 1'), findsOneWidget);
      expect(find.text('Completa el Mundo 2'), findsOneWidget);
      expect(find.textContaining('Continuar'), findsNothing);
      final locked = tester.widget<JuicyPress>(
        find.byKey(const ValueKey('choose-world-2')),
      );
      expect(locked.onPressed, isNull);
      await tester.ensureVisible(find.byKey(const ValueKey('choose-world-2')));
      await tester.tap(find.byKey(const ValueKey('choose-world-2')));
      await scene.settle(tester);
      expect(selected, isEmpty);
      await tester.ensureVisible(find.byKey(const ValueKey('choose-world-1')));
      await scene.tap(tester, find.byKey(const ValueKey('choose-world-1')));
      expect(selected, ['world-1']);
      await repo.recordDebugLights('world-1/level-2', 3);
      await scene.settle(tester);
      expect(find.text('2 / 10 niveles'), findsOneWidget);
      expect(find.text('6 / 30'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );
  for (final allUnlocked in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'all points fit without scroll at text $scale, unlocked: $allUnlocked',
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
            const Size(568, 320),
            const Size(834, 1210),
            const Size(1210, 834),
            const Size(1440, 900),
          ]) {
            tester.view.physicalSize = size;
            await show(tester, repo, scale: scale);
            expect(tester.takeException(), isNull);
            expect(find.text('Elige tu mundo').hitTestable(), findsOneWidget);
            expect(
              find.byKey(const ValueKey('worlds-back')).hitTestable(),
              findsOneWidget,
            );
            final header = tester.getRect(find.text('Elige tu mundo'));
            expect(header.left, greaterThanOrEqualTo(0));
            expect(header.right, lessThanOrEqualTo(size.width));
            expect(find.byType(Scrollable), findsNothing);
            final pointRects = <Rect>[];
            for (final id in ['world-1', 'world-2', 'world-3']) {
              final target = find.byKey(ValueKey('world-point-$id'));
              final card = tester.getRect(target);
              expect(card.left, greaterThan(0));
              expect(card.right, lessThan(size.width));
              expect(card.top, greaterThanOrEqualTo(header.bottom));
              expect(card.bottom, lessThanOrEqualTo(size.height - 20));
              expect(target.hitTestable(), findsOneWidget);
              for (final other in pointRects) {
                expect(
                  card.overlaps(other),
                  isFalse,
                  reason: 'World touch targets must not overlap',
                );
              }
              pointRects.add(card);
            }
            if (!allUnlocked) {
              expect(
                find.text('Completa el Mundo 2').hitTestable(),
                findsOneWidget,
              );
            } else {
              for (final total in ['30 / 30', '60 / 60', '0 / 90']) {
                expect(find.text(total).hitTestable(), findsOneWidget);
              }
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
      expect(find.byType(FirstExperienceScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(FirstExperienceScreen))).pop();
      await scene.settle(tester);
      expect(find.byType(MapScreen), findsOneWidget);
      await scene.tap(tester, find.byKey(const ValueKey('map-world-selector')));
      expect(find.byType(WorldSelectionScreen), findsOneWidget);
      await scene.tap(tester, find.byKey(const ValueKey('choose-world-1')));
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
      await tester.ensureVisible(target);
      await scene.tap(tester, target);
    }
    expect(selected, ['world-1', 'world-2', 'world-3']);
    await tester.pumpWidget(const SizedBox());
    await repo.close();
  });
}
