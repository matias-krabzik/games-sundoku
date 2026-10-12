import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/app.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/data/tutorial_book.dart';
import 'package:sundoku/screens/first_experience_screen.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/screens/notes_tutorial_screen.dart';
import 'package:sundoku/widgets/solara_book.dart';

import 'support/world3_baseline.dart';
import 'support/world_selection.dart';
import 'support/tutorial_book.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tap(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await settle(tester);
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(() async {
    for (final (family, asset) in [
      ('Baloo2', 'assets/fonts/Baloo2-Variable.ttf'),
      ('LibreBaskerville', 'assets/fonts/LibreBaskerville-Variable.ttf'),
      ('EBGaramond', 'assets/fonts/EBGaramond-Variable.ttf'),
      ('IMFellEnglish', 'assets/fonts/IMFellEnglish-Regular.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });

  for (var completedWorlds = 0; completedWorlds <= 2; completedWorlds++) {
    testWidgets(
      'book opens the rules summary and restores its page with $completedWorlds completed worlds',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final previousPlatform = debugDefaultTargetPlatformOverride;
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        final repo = await openBaselineRepository(
          baselineSave(completedWorlds: completedWorlds),
        );
        try {
          await repo.markQuickPlayCelebrated();
          await repo.markWorldGateCelebrated();
          await repo.markWorldGateCelebrated(worldId: 'world-2');
          await repo.saveModule('homeWelcome', {'namePromptShown': true});
          await tester.pumpWidget(
            SunDokuApp(repository: repo, feedback: const GameFeedback()),
          );
          await tester.pump(const Duration(seconds: 3));
          await settle(tester);
          await tap(tester, 'home-play');
          await enterOverviewWorld(tester, 'world-1');
          await settle(tester);
          expect(find.byType(MapScreen), findsOneWidget);
          final saved = repo.state.toJson();
          await tap(tester, 'map-tutorial');
          expect(find.byType(SolaraBook), findsOneWidget);
          await openBookSummary(tester);
          final savedPage = bookPageCounter(tester);
          await tap(tester, 'book-summary');
          expect(
            tester
                .widget<FirstExperienceScreen>(
                  find.byType(FirstExperienceScreen),
                )
                .reviewOnly,
            isTrue,
          );
          await tap(tester, 'tutorial-skip');
          expect(find.byType(SolaraBook), findsOneWidget);
          expect(bookPageCounter(tester), savedPage);
          expect(repo.state.toJson(), saved);
          if (completedWorlds > 0) {
            await openBookSummary(tester, lesson: BookLesson.notes);
            final notesPage = bookPageCounter(tester);
            await tap(tester, 'book-summary');
            expect(
              tester
                  .widget<NotesTutorialScreen>(find.byType(NotesTutorialScreen))
                  .replay,
              isTrue,
            );
            await tap(tester, 'notes-lesson-skip');
            expect(find.byType(SolaraBook), findsOneWidget);
            expect(bookPageCounter(tester), notesPage);
            expect(repo.state.toJson(), saved);
          }
          await tap(tester, 'book-exit');
          expect(find.byType(SolaraBook), findsNothing);
          expect(find.byType(MapScreen), findsOneWidget);
          expect(repo.state.toJson(), saved);
        } finally {
          await tester.pumpWidget(const SizedBox());
          await settle(tester);
          await repo.close();
          debugDefaultTargetPlatformOverride = previousPlatform;
        }
      },
    );
  }
}
