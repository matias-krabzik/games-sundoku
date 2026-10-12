import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/widgets/map_art.dart';
import 'package:sundoku/widgets/juicy_press.dart';
import 'package:sundoku/widgets/world_crest.dart';
import 'package:sundoku/widgets/world_frontier_notice.dart';
import 'package:sundoku/widgets/world_overview_fog.dart';
import 'package:sundoku/widgets/world_overview_viewport.dart';

import 'support/world3_baseline.dart';
import 'tutorial_journey_widget_test.dart' as scene;
import 'world_selection_test.dart' as overview;

final card = find.byKey(const ValueKey('world-frontier-card'));

WorldOverviewViewport viewportOf(WidgetTester tester) =>
    tester.widget<WorldOverviewViewport>(find.byType(WorldOverviewViewport));

double noticeOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find.ancestor(of: card, matching: find.byType(FadeTransition)).first,
    )
    .opacity
    .value;

double focusScale(WidgetTester tester, String worldId) => tester
    .widget<Transform>(find.byKey(ValueKey('world-focus-pulse-$worldId')))
    .transform
    .entry(0, 0);

double lightOpacity(WidgetTester tester, String worldId) => tester
    .widget<Opacity>(find.byKey(ValueKey('world-selection-light-$worldId')))
    .opacity;

Future<void> exploreFrontier(WidgetTester tester, Size size) async {
  viewportOf(tester).camera.pan(
    size.width > size.height * 1.12
        ? const Offset(-1e5, 0)
        : const Offset(0, 1e5),
  );
  await scene.settle(tester);
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Baloo2',
    )..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'))).load();
  });

  testWidgets(
    'scrolling to fog shows live valley progress and permits dragging back',
    (tester) async {
      scene.configure(tester);
      final repo = GameRepository.memory();
      await repo.recordDebugLights('world-1/level-1', 3);
      await repo.recordDebugLights('world-1/level-2', 2);
      await overview.show(tester, repo);
      expect(card, findsNothing);

      await tester.dragFrom(const Offset(195, 150), const Offset(0, 650));
      await scene.settle(tester);
      expect(card, findsOneWidget);
      expect(find.text('1 de 10 niveles completados'), findsOneWidget);
      expect(
        find.text(
          'Completa todos los niveles de Valle del Sol para descubrir el próximo mundo.',
        ),
        findsOneWidget,
      );
      final notice = find.byType(WorldFrontierNotice);
      expect(
        tester
            .widget<WorldCrest>(
              find.descendant(of: notice, matching: find.byType(WorldCrest)),
            )
            .worldId,
        'world-1',
      );
      expect(
        tester
            .widgetList<MapIcon>(
              find.descendant(of: notice, matching: find.byType(MapIcon)),
            )
            .where((icon) => icon.glyph == MapGlyph.lock),
        isEmpty,
      );

      await repo.recordDebugLights('world-1/level-2', 3);
      await scene.settle(tester);
      expect(find.text('2 de 10 niveles completados'), findsOneWidget);
      await tester.dragFrom(tester.getCenter(card), const Offset(0, -650));
      await scene.settle(tester);
      expect(card, findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );

  for (final worldNumber in [1, 2]) {
    for (final size in [const Size(390, 844), const Size(1210, 834)]) {
      testWidgets(
        'notice centers world $worldNumber, pulses after arrival and preserves light on entry at $size',
        (tester) async {
          scene.configure(tester, reduced: false);
          tester.view.physicalSize = size;
          final repo = await openBaselineRepository(
            baselineSave(completedWorlds: worldNumber - 1),
          );
          final worldId = 'world-$worldNumber';
          await repo.visitWorld(worldId);
          final entered = <String>[];
          await overview.show(
            tester,
            repo,
            onSelect: (id) async => entered.add(id),
          );
          await exploreFrontier(tester, size);
          final camera = viewportOf(tester).camera;
          expect(camera.selectedWorld, isNull);
          expect(lightOpacity(tester, worldId), 0);
          final action = find.byKey(const ValueKey('world-frontier-action'));
          expect(action.hitTestable(), findsOneWidget);
          expect(tester.widget<JuicyPress>(action).label, contains('Centrar'));
          await tester.tap(card);
          for (var i = 0; i < 60 && camera.centeredWorld != worldId; i++) {
            await tester.pump(const Duration(milliseconds: 20));
          }
          expect(camera.centeredWorld, worldId);
          expect(camera.selectedWorld, worldId);
          expect(camera.entryWorld, worldId);
          expect(entered, isEmpty);
          expect(focusScale(tester, worldId), closeTo(1, .013));
          await tester.pump(const Duration(milliseconds: 310));
          expect(focusScale(tester, worldId), greaterThan(1.08));
          await tester.pump(const Duration(milliseconds: 340));
          expect(focusScale(tester, worldId), closeTo(1, .013));
          expect(lightOpacity(tester, worldId), 1);
          expect(card, findsNothing);

          await overview.snapshot(
            tester,
            'selected-$worldId-${size.width.toInt()}x${size.height.toInt()}',
          );
          final enter = find.byKey(ValueKey('world-enter-$worldId'));
          await scene.tap(tester, enter);
          expect(entered, [worldId]);
          expect(camera.selectedWorld, worldId);
          expect(lightOpacity(tester, worldId), 1);

          await tester.tapAt(const Offset(300, 125));
          await tester.pump();
          expect(camera.selectedWorld, isNull);
          expect(camera.entryWorld, worldId);
          await tester.pump(const Duration(milliseconds: 160));
          expect(lightOpacity(tester, worldId), inExclusiveRange(0, 1));
          await tester.pump(const Duration(milliseconds: 180));
          expect(lightOpacity(tester, worldId), 0);
          expect(enter.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await repo.close();
        },
      );
    }
  }

  testWidgets('notice selects without motion when animations are reduced', (
    tester,
  ) async {
    scene.configure(tester);
    final repo = GameRepository.memory();
    await overview.show(tester, repo);
    await exploreFrontier(tester, const Size(390, 844));
    await tester.tap(card);
    await tester.pump();
    expect(viewportOf(tester).camera.centeredWorld, 'world-1');
    expect(lightOpacity(tester, 'world-1'), 1);
    expect(focusScale(tester, 'world-1'), 1);
    await scene.settle(tester);
    expect(focusScale(tester, 'world-1'), 1);
    expect(card, findsNothing);
    await tester.pumpWidget(const SizedBox());
    await repo.close();
  });

  testWidgets(
    'light transfers between all worlds and survives entering and returning',
    (tester) async {
      scene.configure(tester, reduced: false);
      final repo = await openBaselineRepository(
        baselineSave(completedWorlds: 2),
      );
      late NavigatorState navigator;
      await overview.show(
        tester,
        repo,
        onSelect: (id) async {
          await navigator.push<void>(
            MaterialPageRoute(
              builder: (_) => Scaffold(body: Text('Dentro de $id')),
            ),
          );
        },
      );
      final camera = viewportOf(tester).camera;
      navigator = Navigator.of(
        tester.element(find.byType(WorldOverviewViewport)),
      );
      camera.focusWorld('world-1', animate: false);
      await scene.settle(tester);
      for (final worldId in ['world-2', 'world-3']) {
        final previous = camera.selectedWorld!;
        camera.focusWorld(worldId, animate: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 160));
        expect(lightOpacity(tester, previous), inExclusiveRange(0, 1));
        expect(lightOpacity(tester, worldId), inExclusiveRange(0, 1));
        await tester.pump(const Duration(milliseconds: 180));
        expect(lightOpacity(tester, previous), 0);
        expect(lightOpacity(tester, worldId), 1);
      }
      await overview.snapshot(tester, 'selected-world-3-390x844');
      await tester.tap(find.byKey(const ValueKey('world-enter-world-3')));
      await scene.settle(tester);
      expect(find.text('Dentro de world-3'), findsOneWidget);
      expect(camera.selectedWorld, 'world-3');
      navigator.pop();
      await scene.settle(tester);
      expect(lightOpacity(tester, 'world-3'), 1);
      expect(camera.selectedWorld, 'world-3');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );

  testWidgets(
    'next frontier uses the forest totem and its twenty levels, then disappears on unlock',
    (tester) async {
      scene.configure(tester);
      final repo = await openBaselineRepository(
        baselineSave(completedWorlds: 1),
      );
      await repo.visitWorld('world-2');
      await repo.recordDebugLights('world-2/level-1', 3);
      await repo.recordDebugLights('world-2/level-2', 2);
      await overview.show(tester, repo);
      await exploreFrontier(tester, const Size(390, 844));
      expect(card, findsOneWidget);
      expect(find.text('1 de 20 niveles completados'), findsOneWidget);
      expect(
        find.text(
          'Completa todos los niveles de Bosque de la Cumbre para descubrir el próximo mundo.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('frontier-totem-world-2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('frontier-totem-world-1')),
        findsNothing,
      );
      await repo.recordDebugLights('world-2/level-2', 3);
      await scene.settle(tester);
      expect(find.text('2 de 20 niveles completados'), findsOneWidget);

      await repo.completeNextDebugWorld();
      await scene.settle(tester);
      expect(card, findsNothing);
      expect(find.byKey(const ValueKey('world-point-world-3')), findsOneWidget);
      await exploreFrontier(tester, const Size(390, 844));
      expect(card, findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );

  testWidgets(
    'unlock fades the old notice during discovery and uses the next prerequisite afterwards',
    (tester) async {
      scene.configure(tester, reduced: false);
      final repo = GameRepository.memory();
      await overview.show(tester, repo);
      await exploreFrontier(tester, const Size(390, 844));
      expect(
        find.byKey(const ValueKey('frontier-totem-world-1')),
        findsOneWidget,
      );
      await repo.completeNextDebugWorld();
      await tester.pump();
      expect(card, findsOneWidget);
      expect(noticeOpacity(tester), 1);
      await tester.pump(const Duration(milliseconds: 120));
      expect(noticeOpacity(tester), inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 140));
      expect(card, findsNothing);
      expect(
        find.byKey(const ValueKey('frontier-totem-world-1')),
        findsNothing,
      );
      viewportOf(tester).camera.advance(2);
      await tester.pump();
      await exploreFrontier(tester, const Size(390, 844));
      expect(
        find.byKey(const ValueKey('frontier-totem-world-2')),
        findsOneWidget,
      );
      expect(find.text('0 de 20 niveles completados'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );

  for (final size in [const Size(390, 844), const Size(1210, 834)]) {
    testWidgets('scrolling away fades the notice before removing it at $size', (
      tester,
    ) async {
      scene.configure(tester, reduced: false);
      tester.view.physicalSize = size;
      final repo = GameRepository.memory();
      await overview.show(tester, repo);
      await exploreFrontier(tester, size);
      expect(card, findsOneWidget);
      expect(noticeOpacity(tester), 1);
      final before = tester.getRect(card);

      viewportOf(tester).camera.pan(
        size.width > size.height ? const Offset(1e5, 0) : const Offset(0, -1e5),
      );
      await tester.pump();
      expect(card, findsOneWidget);
      expect(noticeOpacity(tester), 1);
      expect(tester.getRect(card), before);
      await tester.pump(const Duration(milliseconds: 80));
      final first = noticeOpacity(tester);
      expect(first, inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 80));
      expect(noticeOpacity(tester), inExclusiveRange(0, first));
      await tester.pump(const Duration(milliseconds: 100));
      expect(card, findsNothing);

      await exploreFrontier(tester, size);
      expect(card, findsOneWidget);
      expect(noticeOpacity(tester), 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    });
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'both frontiers fit the window and leave navigation usable at text $scale',
      (tester) async {
        scene.configure(tester);
        for (final worldNumber in [1, 2]) {
          final repo = await openBaselineRepository(
            baselineSave(completedWorlds: worldNumber - 1),
          );
          final worldId = 'world-$worldNumber';
          await repo.visitWorld(worldId);
          await repo.recordDebugLights('$worldId/level-1', 3);
          await repo.recordDebugLights('$worldId/level-2', 3);
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
            await overview.show(tester, repo, scale: scale);
            await exploreFrontier(tester, size);
            expect(card, findsOneWidget, reason: '$worldId at $size');
            final header = tester.getRect(
              find.byKey(const ValueKey('worlds-back')),
            );
            for (final target in [
              card,
              find.byKey(ValueKey('frontier-totem-$worldId')),
            ]) {
              final rect = tester.getRect(target);
              expect(rect.left, greaterThanOrEqualTo(16 - .01));
              expect(rect.right, lessThanOrEqualTo(size.width - 16 + .01));
              expect(rect.top, greaterThan(header.bottom));
              expect(rect.bottom, lessThanOrEqualTo(size.height - 36 + .01));
            }
            expect(
              find.byKey(const ValueKey('worlds-settings')).hitTestable(),
              findsOneWidget,
            );
            expect(find.byType(Scrollable), findsNothing);
            expect(tester.takeException(), isNull);
            await tester.runAsync(
              () => tester
                  .widget<WorldOverviewFog>(find.byType(WorldOverviewFog))
                  .art
                  .load(),
            );
            await overview.snapshot(
              tester,
              'frontier-$worldId-${size.width.toInt()}x${size.height.toInt()}-text-$scale',
            );
            await tester.pumpWidget(const SizedBox());
          }
          await repo.close();
        }
      },
    );
  }
}
