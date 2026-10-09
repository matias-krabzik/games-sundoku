import '../support/world_selection.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/app.dart';
import 'package:sundoku/controllers/notes_tutorial_controller.dart';
import 'package:sundoku/data/level_progress.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/screens/notes_tutorial_screen.dart';
import 'package:sundoku/screens/first_experience_screen.dart';
import 'package:sundoku/widgets/illustrated_action_button.dart';
import 'package:sundoku/widgets/sudoku_notes.dart';
import 'package:sundoku/widgets/sudoku_board.dart';
import 'package:sundoku/widgets/map_parallax_scene.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/tutorial_block_controls.dart';
import 'package:sundoku/data/services/game_feedback.dart';

Future<void> _frames(WidgetTester tester, [int count = 20]) async {
  for (var n = 0; n < count; n++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 120)),
  );
  await tester.pump();
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  final directory = Platform.environment['FOREST_CAPTURE_DIR'];
  if (directory == null) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    await Directory(directory).create(recursive: true);
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('$directory/$name.png').writeAsBytes(data!.buffer.asUint8List());
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
  testWidgets(
    'tutorial reveals before advancing and keeps actions visible at every size',
    (tester) async {
      final repo = GameRepository.memory();
      await repo.prepareDebugForest();
      final boundary = GlobalKey();
      Future<void> render(
        Size size,
        double scale, {
        bool reduced = true,
      }) async {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildSunDokuTheme(),
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(scale),
                disableAnimations: reduced,
              ),
              child: RepaintBoundary(
                key: boundary,
                child: NotesTutorialScreen(
                  repository: repo,
                  onFinished: () async {},
                ),
              ),
            ),
          ),
        );
        await _frames(tester);
      }

      await render(const Size(390, 844), 1, reduced: false);
      final next = find.byKey(const ValueKey('notes-lesson-next'));
      expect(tester.widget<IllustratedActionButton>(next).onPressed, isNotNull);
      await tester.tap(next);
      await _frames(tester, 5);
      expect(repo.state.modules[NotesLesson.key], isNull);
      await tester.tap(next);
      await _frames(tester, 5);
      expect(repo.state.modules[NotesLesson.key], containsPair('step', 1));
      expect(tester.widget<IllustratedActionButton>(next).onPressed, isNotNull);
      await tester.tap(next);
      await _frames(tester, 5);
      expect(repo.state.modules[NotesLesson.key], containsPair('step', 1));
      await tester.tap(next);
      for (
        var frame = 0;
        frame < 100 &&
            tester
                    .widget<SudokuBoard>(find.byType(SudokuBoard))
                    .notes[NotesLesson.target]
                    ?.length !=
                2;
        frame++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(repo.state.modules[NotesLesson.key], containsPair('step', 2));
      final board = tester.widget<SudokuBoard>(find.byType(SudokuBoard));
      expect(board.notes[NotesLesson.target], [2, 7]);
      expect(board.onSelect, isNull);
      expect(
        tester
            .widget<TutorialNumberTray>(find.byType(TutorialNumberTray))
            .onSelected,
        isNull,
      );
      expect(
        tester
            .widget<SudokuNotesButton>(find.byType(SudokuNotesButton))
            .onPressed,
        isNull,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      await _frames(tester, 2);
      await _capture(tester, boundary, 'tutorial-mobile');
      for (final size in [
        const Size(320, 568),
        const Size(844, 390),
        const Size(1024, 768),
      ]) {
        await render(size, 2);
        expect(tester.takeException(), isNull);
        final rect = tester.getRect(next);
        expect(rect.bottom, lessThanOrEqualTo(size.height));
        final skip = find.byKey(const ValueKey('notes-lesson-skip'));
        if (size.height < 520 && size.width >= 650) {
          expect(tester.getRect(skip).left, greaterThan(rect.right));
        } else {
          expect(tester.getRect(skip).top, greaterThan(rect.bottom));
        }
        expect(tester.getRect(skip).bottom, lessThanOrEqualTo(size.height));
        expect(skip.hitTestable(), findsOneWidget);
        expect(
          tester.getSize(find.byType(SudokuBoard)).width,
          lessThanOrEqualTo(430),
        );
      }
      final skip = find.byKey(const ValueKey('notes-lesson-skip'));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(skip.hitTestable(), findsOneWidget);
      await tester.tap(skip);
      await _frames(tester);
      expect(repo.notesTutorialCompleted, isTrue);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'forest map renders all 20 numbers and keeps layers through horizontal scroll',
    (tester) async {
      if (Platform.environment['FOREST_CAPTURE_DIR'] != null) {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      }
      final repo = GameRepository.memory();
      await repo.prepareDebugForest();
      final progress = LevelProgress(repository: repo, worldId: 'world-2');
      final boundary = GlobalKey();
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildSunDokuTheme(),
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(1024, 768),
              disableAnimations:
                  Platform.environment['FOREST_CAPTURE_DIR'] == null,
            ),
            child: RepaintBoundary(
              key: boundary,
              child: MapScreen(
                progress: progress,
                showDeveloperControls: false,
              ),
            ),
          ),
        ),
      );
      await _frames(tester, 30);
      expect(find.byType(MapParallaxScene), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.byKey(const ValueKey('map-world-gate')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _capture(tester, boundary, 'forest-map-tablet');
      final scroll = tester
          .widget<SingleChildScrollView>(
            find.byKey(const ValueKey('world-scroll')),
          )
          .controller!;
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await _frames(tester);
      await _capture(tester, boundary, 'forest-map-end');
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(const Size(844, 390));
      await _frames(tester);
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await _frames(tester);
      final summit = find.text('20');
      final before = tester.getCenter(summit).dy;
      await tester.dragFrom(const Offset(400, 120), const Offset(0, 300));
      await _frames(tester);
      expect(tester.getCenter(summit).dy, greaterThan(before));
      expect(summit.hitTestable(), findsOneWidget);
      await _capture(tester, boundary, 'forest-summit-landscape');
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      progress.dispose();
      await repo.close();
      await tester.binding.setSurfaceSize(null);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets(
    'sun opens world 2 lesson and Practicar replaces it with the first forest game',
    (tester) async {
      final repo = GameRepository.memory();
      await repo.prepareDebugForest();
      await repo.markQuickPlayCelebrated();
      await repo.markWorldGateCelebrated();
      await repo.saveModule('homeWelcome', {'namePromptShown': true});
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await tester.pumpWidget(
        SunDokuApp(repository: repo, feedback: const GameFeedback()),
      );
      await _frames(tester, 40);
      await tester.tap(find.byKey(const ValueKey('home-play')));
      await _frames(tester, 30);
      await enterOverviewWorld(tester, 'world-1');
      await _frames(tester, 30);
      final scroll = tester
          .widget<SingleChildScrollView>(
            find.byKey(const ValueKey('world-scroll')),
          )
          .controller!;
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await _frames(tester);
      await tester.tap(find.byKey(const ValueKey('map-world-gate')));
      await _frames(tester, 30);
      expect(find.byType(NotesTutorialScreen), findsOneWidget);
      expect(repo.lastAdventureWorld, 'world-2');
      Future<void> next() async {
        final finder = find.byKey(const ValueKey('notes-lesson-next'));
        expect(
          tester.widget<IllustratedActionButton>(finder).onPressed,
          isNotNull,
        );
        await tester.tap(finder);
        await _frames(tester);
      }

      for (
        var step = 0;
        step < NotesLesson.texts.length &&
            find.byType(NotesTutorialScreen).evaluate().isNotEmpty;
        step++
      ) {
        await next();
      }
      expect(repo.notesTutorialCompleted, isTrue);
      expect(repo.notesUnlocked, isFalse);
      expect(find.byType(NotesTutorialScreen), findsNothing);
      final game = tester.widget<FirstExperienceScreen>(
        find.byType(FirstExperienceScreen),
      );
      expect(game.worldId, 'world-2');
      expect(game.levelNumber, 1);
      expect(find.byType(SudokuNotesButton), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      await tester.binding.setSurfaceSize(null);
    },
  );
}
