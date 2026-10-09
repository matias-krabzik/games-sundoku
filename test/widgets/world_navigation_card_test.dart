import '../support/world_selection.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/app.dart';
import 'package:sundoku/data/level_progress.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/data/services/mock_world_navigation_service.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/widgets/juicy_press.dart';

void main() {
  testWidgets('world picker keeps locked worlds unavailable', (tester) async {
    final repository = GameRepository.memory();
    final progress = LevelProgress(repository: repository);
    final navigation = MockWorldNavigationService(repository);
    String? selectedWorld;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            disableAnimations: true,
          ),
          child: MapScreen(
            progress: progress,
            worldNavigation: navigation,
            onSelectWorld: (worldId) => selectedWorld = worldId,
            showDeveloperControls: false,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Mundo '), findsNothing);
    expect(find.text('Valle del Sol'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('map-world-selector')));
    await tester.pump();
    expect(
      tester
          .widget<JuicyPress>(find.byKey(const ValueKey('map-world-option-2')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<JuicyPress>(find.byKey(const ValueKey('map-world-option-3')))
          .onPressed,
      isNull,
    );
    expect(selectedWorld, isNull);

    await tester.pumpWidget(const SizedBox());
    progress.dispose();
    await repository.close();
  });

  testWidgets(
    'world picker replaces the map and remembers the selected world',
    (tester) async {
      final repository = GameRepository.memory();
      await repository.prepareDebugForest();
      await repository.markWorldGateCelebrated();
      await repository.saveModule('homeWelcome', {'namePromptShown': true});
      await repository.saveModule('tutorials/notes/v1', {'completed': true});
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        SunDokuApp(repository: repository, feedback: const GameFeedback()),
      );
      Future<void> frames() async {
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await frames();
      await tester.tap(find.byKey(const ValueKey('home-play')));
      await frames();
      await enterOverviewWorld(tester, 'world-1');
      await frames();
      expect(find.text('Valle del Sol'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('map-world-selector')));
      await frames();

      await enterOverviewWorld(tester, 'world-2');
      await frames();
      expect(find.text('Bosque de la Cumbre'), findsOneWidget);
      expect(repository.lastAdventureWorld, 'world-2');
      await tester.tap(find.byKey(const ValueKey('map-world-selector')));
      await frames();
      expect(find.byKey(const ValueKey('choose-world-3')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('worlds-back')));
      await frames();
      await tester.tap(find.byKey(const ValueKey('map-world-selector')));
      await frames();
      await enterOverviewWorld(tester, 'world-1');
      await frames();
      expect(find.text('Valle del Sol'), findsOneWidget);
      expect(repository.lastAdventureWorld, 'world-1');
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      await repository.close();
    },
  );
}
