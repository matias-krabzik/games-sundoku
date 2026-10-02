import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/controllers/notes_tutorial_controller.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/screens/notes_tutorial_screen.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/sudoku_board.dart';
import 'package:sundoku/widgets/sudoku_digit.dart';
import 'package:sundoku/widgets/sudoku_notes.dart';
import 'package:sundoku/widgets/tutorial_block_controls.dart';
import 'package:sundoku/widgets/tutorial_lesson_card.dart';
import 'package:sundoku/widgets/tutorial_presentation.dart';
import 'package:sundoku/widgets/tutorial_story_navigation.dart';

Future<void> frames(WidgetTester tester, int milliseconds) async {
  for (var i = 0; i < milliseconds; i += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

SudokuBoard board(WidgetTester tester) =>
    tester.widget<SudokuBoard>(find.byType(SudokuBoard));
final next = find.byKey(const ValueKey('notes-lesson-next'));

TutorialPresentationState presentation(WidgetTester tester) =>
    tester.state<TutorialPresentationState>(find.byType(TutorialPresentation));

Future<void> until(WidgetTester tester, bool Function() done) async {
  for (var frame = 0; frame < 300 && !done(); frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(
    done(),
    isTrue,
    reason: 'The automatic sequence did not reach its next phase',
  );
}

String visibleText(WidgetTester tester) {
  final span =
      tester
              .widget<Text>(find.byKey(const ValueKey('intro-story-text')))
              .textSpan!
          as TextSpan;
  return (span.children!.first as TextSpan).text!;
}

Future<void> advance(WidgetTester tester) async {
  if (!presentation(tester).demonstration.isCompleted) {
    await tester.tap(next);
    await frames(tester, 400);
  }
  await tester.tap(next);
  await frames(tester, 400);
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  final directory = Platform.environment['NOTES_CAPTURE_DIR'];
  if (directory == null) return;
  await tester.runAsync(() async {
    for (final widget in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(widget.image, key.currentContext!);
    }
  });
  await tester.pump();
  await tester.runAsync(() async {
    final image =
        await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
            .toImage();
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

  testWidgets('next completes entrance and writing before advancing', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(834, 1210);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final repo = GameRepository.memory();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildSunDokuTheme(),
        home: NotesTutorialScreen(
          repository: repo,
          replay: true,
          onFinished: () async {},
        ),
      ),
    );
    final boardState = tester.state(find.byType(SudokuBoard));
    for (var step = 0; step < 3; step++) {
      expect(presentation(tester).demonstration.isCompleted, isFalse);
      await tester.tap(next);
      await frames(tester, 400);
      expect(presentation(tester).widget.step, step);
      expect(presentation(tester).entrance.value, 1);
      expect(presentation(tester).demonstration.value, 1);
      expect(visibleText(tester), NotesLesson.texts[step]);
      expect(tester.state(find.byType(SudokuBoard)), same(boardState));
      expect(find.byType(TutorialLessonCard), findsOneWidget);
      expect(find.byType(TutorialLessonTitle), findsOneWidget);
      expect(find.text(NotesLesson.titles[step]), findsOneWidget);
      for (final key in ['map-back', 'map-settings', 'notes-lesson-pause']) {
        expect(find.byKey(ValueKey(key)), findsNothing);
      }
      final style = tester
          .widget<Text>(find.byKey(const ValueKey('intro-story-text')))
          .style!;
      expect(style.fontFamily, 'Baloo2');
      expect(style.fontSize, 20);
      expect(style.fontWeight, FontWeight.w800);
      expect(style.height, 1.3);
      expect(style.color, const Color(0xFF082A62));
      await frames(tester, 5000);
      expect(presentation(tester).widget.step, step);
      await tester.tap(next);
      await frames(tester, 400);
      expect(presentation(tester).widget.step, step + 1);
    }
    await tester.pumpWidget(const SizedBox());
    await repo.close();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'next finishes a running demo and practice requires another tap',
    (tester) async {
      final repo = GameRepository.memory();
      await repo.prepareDebugForest();
      var completed = 0;
      for (final step in [2, 7]) {
        await repo.saveModule(NotesLesson.key, {'step': step});
        await tester.pumpWidget(
          MaterialApp(
            theme: buildSunDokuTheme(),
            home: NotesTutorialScreen(
              key: ValueKey(step),
              repository: repo,
              onFinished: () async => completed++,
            ),
          ),
        );
        await until(
          tester,
          () => presentation(tester).demonstration.value > .2,
        );
        expect(presentation(tester).demonstration.value, lessThan(.8));
        final revision = repo.state.revision;
        await tester.tap(next);
        await frames(tester, 400);
        expect(presentation(tester).widget.step, step);
        expect(presentation(tester).demonstration.value, 1);
        expect(
          board(tester).notes[NotesLesson.target],
          NotesLesson.stateAfter(step)['notes'],
        );
        expect(repo.state.revision, revision);
        expect(completed, 0);
        await frames(tester, 5000);
        expect(presentation(tester).widget.step, step);
        expect(completed, 0);
        await tester.tap(next);
        await frames(tester, 400);
        if (step == 7) {
          expect(completed, 1);
          expect(repo.notesTutorialCompleted, isTrue);
        } else {
          expect(presentation(tester).widget.step, step + 1);
        }
      }
      await tester.pumpWidget(const SizedBox());
      await repo.close();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'entrance, typing and demonstrations advance automatically; practice waits',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(834, 1210);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final repo = GameRepository.memory();
      await repo.prepareDebugForest();
      final progress = repo.state.progress.map(
        (k, v) => MapEntry(k, v.toJson()),
      );
      var completed = 0;
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildSunDokuTheme(),
          home: RepaintBoundary(
            key: key,
            child: NotesTutorialScreen(
              repository: repo,
              onFinished: () async {
                completed++;
              },
            ),
          ),
        ),
      );
      expect(presentation(tester).entrance.value, 0);
      expect(visibleText(tester), isEmpty);
      await frames(tester, 1500);
      expect(visibleText(tester), isNotEmpty);
      expect(
        visibleText(tester).length,
        lessThan(NotesLesson.texts.first.length),
      );
      expect(presentation(tester).demonstration.value, 0);
      expect(find.text(NotesLesson.titles.first), findsOneWidget);
      expect(repo.state.modules[NotesLesson.key], isNull);
      expect(
        find.byKey(const ValueKey('notes-lesson-background')),
        findsOneWidget,
      );
      final boardState = tester.state(find.byType(SudokuBoard));
      final boardRect = tester.getRect(find.byType(SudokuBoard));
      final trayRect = tester.getRect(find.byType(TutorialNumberTray));
      final unchangedDigit = find.descendant(
        of: find.byKey(const ValueKey('sudoku-cell-80')),
        matching: find.byType(SudokuDigit),
      );
      final digitElement = tester.element(unchangedDigit);
      for (var step = 0; step < 8; step++) {
        expect(presentation(tester).entrance.value, 1);
        expect(tester.state(find.byType(SudokuBoard)), same(boardState));
        expect(tester.element(unchangedDigit), same(digitElement));
        expect(
          tester.getRect(find.byType(SudokuBoard)),
          boardRect,
          reason:
              'step $step, header ${tester.getRect(find.byType(TutorialStepHeader))}',
        );
        expect(tester.getRect(find.byType(TutorialNumberTray)), trayRect);
        expect(
          tester.getRect(find.byKey(const ValueKey('intro-story'))).top,
          greaterThan(trayRect.bottom),
        );
        if (step == 2) {
          expect(board(tester).notes[NotesLesson.target], isEmpty);
          await until(
            tester,
            () => board(tester).notes[NotesLesson.target]?.length == 1,
          );
          expect(board(tester).notes[NotesLesson.target], [2]);
        }
        await until(
          tester,
          () => presentation(tester).demonstration.isCompleted,
        );
        expect(visibleText(tester), NotesLesson.texts[step]);
        expect(find.text(NotesLesson.titles[step]), findsOneWidget);
        expect(
          tester
              .widget<TutorialStoryProgress>(find.byType(TutorialStoryProgress))
              .index,
          step,
        );
        expect(
          tester.getRect(find.byType(TutorialStepHeader)).bottom,
          lessThan(tester.getRect(find.byType(SudokuBoard)).top),
        );
        final expected = NotesLesson.stateAfter(step);
        expect(board(tester).notesMode, expected['notesMode']);
        expect(board(tester).notes[NotesLesson.target], expected['notes']);
        expect(board(tester).cells[NotesLesson.other], step >= 4 ? 7 : null);
        expect(board(tester).cells[NotesLesson.target], step >= 6 ? 2 : null);
        expect(board(tester).onSelect, isNull);
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
        if (step == 2 || step == 6) {
          await capture(tester, key, 'notes-step-${step + 1}-ipad');
        }
        if (step < 7) {
          await until(
            tester,
            () => find.text(NotesLesson.titles[step + 1]).evaluate().isNotEmpty,
          );
        }
      }
      await frames(tester, 20000);
      expect(completed, 0);
      expect(find.text(NotesLesson.titles.last), findsOneWidget);
      await advance(tester);
      expect(completed, 1);
      expect(repo.notesTutorialCompleted, isTrue);
      expect(repo.notesUnlocked, isFalse);
      expect(
        repo.state.progress.map((k, v) => MapEntry(k, v.toJson())),
        progress,
      );
      expect(
        repo.state.sessions.values.where(
          (s) => s.levelId.startsWith('world-2'),
        ),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );

  testWidgets('manual steps keep the scene stable on phone and landscape', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final repo = GameRepository.memory();
    for (final size in [
      const Size(390, 844),
      const Size(1210, 834),
      const Size(844, 390),
    ]) {
      final boundary = GlobalKey();
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildSunDokuTheme(),
          home: RepaintBoundary(
            key: boundary,
            child: NotesTutorialScreen(
              repository: repo,
              replay: true,
              onFinished: () async {},
            ),
          ),
        ),
      );
      await frames(tester, 1500);
      await tester.tap(next);
      await frames(tester, 400);
      final boardRect = tester.getRect(find.byType(SudokuBoard));
      final trayRect = tester.getRect(find.byType(TutorialNumberTray));
      for (var step = 1; step < NotesLesson.texts.length; step++) {
        await advance(tester);
        expect(presentation(tester).entrance.value, 1);
        expect(
          tester.getRect(find.byType(SudokuBoard)),
          boardRect,
          reason:
              '$size step $step, header ${tester.getRect(find.byType(TutorialStepHeader))}',
        );
        expect(tester.getRect(find.byType(TutorialNumberTray)), trayRect);
        expect(
          tester.getRect(find.byKey(const ValueKey('intro-story'))).top,
          greaterThan(trayRect.bottom),
        );
        expect(next.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(next);
        await frames(tester, 400);
        expect(presentation(tester).widget.step, step);
        expect(tester.getRect(find.byType(SudokuBoard)), boardRect);
        if (step == 2) {
          await capture(
            tester,
            boundary,
            'notes-format-${size.width.toInt()}x${size.height.toInt()}',
          );
        }
      }
      await tester.drag(
        find.byKey(const ValueKey('notes-story-gestures')),
        const Offset(160, 0),
      );
      await frames(tester, 400);
      expect(presentation(tester).widget.step, 6);
      expect(presentation(tester).entrance.value, 1);
      expect(tester.getRect(find.byType(SudokuBoard)), boardRect);
    }
    await tester.pumpWidget(const SizedBox());
    await repo.close();
  });

  testWidgets(
    'resumed demo pauses in background and preserves playback through resize',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final repo = GameRepository.memory();
      await repo.prepareDebugForest();
      await repo.saveModule(NotesLesson.key, {
        'step': 2,
        'notesMode': true,
        'notes': [2],
      });
      final revision = repo.state.revision;
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildSunDokuTheme(),
          home: RepaintBoundary(
            key: key,
            child: NotesTutorialScreen(
              repository: repo,
              onFinished: () async {},
            ),
          ),
        ),
      );
      await until(
        tester,
        () => board(tester).notes[NotesLesson.target]?.length == 1,
      );
      expect(board(tester).notes[NotesLesson.target], [2]);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await frames(tester, 3000);
      expect(board(tester).notes[NotesLesson.target], [2]);
      tester.view.physicalSize = const Size(1024, 768);
      await frames(tester, 100);
      expect(board(tester).notes[NotesLesson.target], [2]);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await frames(tester, 1700);
      expect(board(tester).notes[NotesLesson.target], [2, 7]);
      expect(repo.state.revision, revision);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      await frames(tester, 5000);
      expect(repo.state.revision, revision);
      for (final size in [
        const Size(390, 844),
        const Size(834, 1210),
        const Size(1210, 834),
        const Size(844, 390),
      ]) {
        tester.view.physicalSize = size;
        await frames(tester, 350);
        expect(tester.takeException(), isNull);
        expect(next.hitTestable(), findsOneWidget);
        expect(tester.getRect(next).bottom, lessThanOrEqualTo(size.height));
        expect(
          tester.getSize(find.byType(SudokuBoard)).width,
          lessThanOrEqualTo(430),
        );
        expect(board(tester).notes[NotesLesson.target], [2, 7]);
        await capture(
          tester,
          key,
          'notes-${size.width.toInt()}x${size.height.toInt()}',
        );
      }
      // Advancing mid-demonstration settles its result atomically.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await advance(tester);
      await advance(tester);
      await advance(tester);
      expect(board(tester).cells[NotesLesson.other], 7);
      await tester.pumpWidget(const SizedBox());
      await frames(tester, 4000);
      expect(tester.takeException(), isNull);
      await repo.close();
    },
  );

  testWidgets(
    'reduced motion shows final demonstrations and replay never changes the save',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final repo = GameRepository.memory();
      final revision = repo.state.revision;
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildSunDokuTheme(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
              accessibleNavigation: true,
            ),
            child: NotesTutorialScreen(
              repository: repo,
              replay: true,
              onFinished: () async {
                completed++;
              },
            ),
          ),
        ),
      );
      for (var step = 0; step < 8; step++) {
        await frames(tester, 400);
        expect(
          board(tester).notes[NotesLesson.target],
          NotesLesson.stateAfter(step)['notes'],
        );
        expect(next.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await advance(tester);
      }
      expect(completed, 1);
      expect(repo.state.revision, revision);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );
}
