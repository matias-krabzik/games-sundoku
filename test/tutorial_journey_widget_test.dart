import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/domain/models/game_session.dart';
import 'package:sundoku/domain/tutorial/tutorial_sudokus.dart';
import 'package:sundoku/screens/first_experience_screen.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/sudoku_board.dart';
import 'package:sundoku/widgets/tutorial_story_navigation.dart';
import 'package:sundoku/widgets/ui_surface_art.dart';

final next = find.byKey(const ValueKey('tutorial-next'));
final board = find.byKey(const ValueKey('intro-board'));
const center = [8, 3, 5, 4, 1, 6, 9, 2, 7];
final captureKey = GlobalKey();

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await settle(tester);
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await settle(tester);
  expect(tester.takeException(), isNull);
}

Future<void> capture(WidgetTester tester, String name) async {
  final directory = Platform.environment['TUTORIAL_CAPTURE_DIR'];
  if (directory == null) return;
  final context = captureKey.currentContext!;
  await tester.runAsync(() async {
    for (final asset in {
      for (final surface in UiSurface.values) surface.spec.asset,
      'assets/images/home-background.png',
      'assets/images/tutorial/block-guide-atlas.png',
      'assets/images/tutorial/cleaning-brush.png',
      'assets/images/map/icons.png',
    }) {
      await precacheImage(AssetImage(asset), context);
    }
  });
  await settle(tester);
  await tester.runAsync(() async {
    final boundary = context.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await Directory(directory).create(recursive: true);
    await File('$directory/$name.png').writeAsBytes(data!.buffer.asUint8List());
  });
}

void configure(WidgetTester tester, {bool reduced = true}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reduced);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<void> show(
  WidgetTester tester,
  GameRepository repo, {
  double textScale = 1,
  bool withParentRoute = false,
}) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: captureKey,
      child: MaterialApp(
        theme: buildSunDokuTheme(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: withParentRoute
            ? Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => FirstExperienceScreen(
                            repository: repo,
                            showDeveloperControls: false,
                          ),
                        ),
                      ),
                      child: const Text('Abrir tutorial'),
                    ),
                  ),
                ),
              )
            : FirstExperienceScreen(
                repository: repo,
                showDeveloperControls: false,
              ),
      ),
    ),
  );
  await settle(tester);
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Baloo2')
      ..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'));
    await font.load();
  });

  testWidgets(
    'stories explain the rules without exercises and keep the same board for all three games',
    (tester) async {
      configure(tester, reduced: false);
      final repo = GameRepository.memory();
      await repo.saveModule(FirstExperienceController.moduleKey, {
        'step': 'blockIntroduction',
        'cells': center,
      });
      await show(tester, repo, withParentRoute: true);
      await tap(tester, find.text('Abrir tutorial'));
      final element = tester.element(board);
      const stories = [
        'blockIntroduction',
        'expansion',
        'rowRule',
        'columnRule',
        'givensIntroduction',
      ];
      for (var i = 0; i < stories.length; i++) {
        final step =
            (repo.state.modules[FirstExperienceController.moduleKey]
                as Map)['step'];
        expect(step, stories[i]);
        expect(repo.state.sessions, isEmpty);
        expect(find.byType(TutorialStoryProgress), findsOneWidget);
        final progress = tester.widget<TutorialStoryProgress>(
          find.byType(TutorialStoryProgress),
        );
        expect(progress.index, i + 1);
        expect(progress.count, 6);
        expect(next.hitTestable(), findsOneWidget);
        expect(find.byKey(const ValueKey('intro-number-1')), findsNothing);
        if (step == 'blockIntroduction') {
          await capture(tester, 'tutorial-historia-bloque');
        }
        if (step == 'rowRule') await capture(tester, 'tutorial-regla-fila');
        if (step == 'columnRule') {
          await capture(tester, 'tutorial-regla-columna');
        }
        await tap(tester, next);
        expect(tester.element(board), same(element));
      }
      for (var game = 0; game < 3; game++) {
        expect(find.byType(TutorialStoryProgress), findsNothing);
        expect(
          repo.state.sessions.values.single.puzzles[game].status,
          PlayStatus.active,
        );
        if (game == 0) await capture(tester, 'tutorial-primer-sudoku');
        if (game == 1) {
          await tap(tester, next); // point out group
          expect(find.text('Ver el número'), findsOneWidget);
          await capture(tester, 'tutorial-segundo-pista');
          final values = repo.state.sessions.values.single.puzzles[game].cells
              .map((c) => c.value)
              .toList();
          await tap(tester, next); // explain, without solving
          expect(
            repo.state.sessions.values.single.puzzles[game].cells.map(
              (c) => c.value,
            ),
            values,
          );
        }
        var moves = 0;
        while (repo.state.sessions.values.single.puzzles[game].status !=
                PlayStatus.completed &&
            moves++ < 81) {
          if (find.text('Seguir').evaluate().isNotEmpty) {
            await tap(tester, next);
          }
          final progress = repo.state.sessions.values.single.puzzles[game];
          final definition = repo.state.puzzles[progress.puzzleId]!;
          final widget = tester.widget<SudokuBoard>(board);
          final selected = widget.selectedIndex;
          final target =
              selected != null && progress.cells[selected].value == null
              ? selected
              : progress.cells.indexWhere((c) => c.value == null);
          await tap(tester, find.byKey(ValueKey('sudoku-cell-$target')));
          await tap(
            tester,
            find.byKey(ValueKey('intro-number-${definition.solution[target]}')),
          );
          expect(tester.element(board), same(element));
        }
        expect(repo.state.sessions.values.single.lights, game + 1);
        if (game < 2) await tap(tester, next);
      }
      expect(find.text('¡Completaste el nivel 1!'), findsOneWidget);
      expect(repo.state.isUnlocked(mapLevelId(2)), true);
      await capture(tester, 'tutorial-nivel-completo');
      expect(tester.element(board), same(element));
      await tap(tester, next);
      expect(find.byType(FirstExperienceScreen), findsNothing);
      expect(find.text('Abrir tutorial'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await repo.flush();
      await repo.close();
    },
  );

  testWidgets(
    'story taps, swipes and keyboard arrows navigate while waiting never advances',
    (tester) async {
      configure(tester);
      final repo = GameRepository.memory();
      await repo.saveModule(FirstExperienceController.moduleKey, {
        'step': 'expansion',
        'cells': center,
      });
      await show(tester, repo);
      final element = tester.element(board);
      final gestures = find.byKey(const ValueKey('tutorial-story-gestures'));
      String savedStep() =>
          (repo.state.modules[FirstExperienceController.moduleKey]
                  as Map)['step']
              as String;
      expect(gestures, findsOneWidget);
      await tester.pump(const Duration(seconds: 30));
      expect(savedStep(), 'expansion');
      var bounds = tester.getRect(gestures);
      await tester.tapAt(Offset(bounds.right - 20, bounds.center.dy));
      await settle(tester);
      expect(savedStep(), 'rowRule');
      bounds = tester.getRect(gestures);
      await tester.tapAt(Offset(bounds.left + 20, bounds.center.dy));
      await settle(tester);
      expect(savedStep(), 'expansion');
      await tester.drag(gestures, const Offset(-180, 0));
      await settle(tester);
      expect(savedStep(), 'rowRule');
      await tester.drag(gestures, const Offset(180, 0));
      await settle(tester);
      expect(savedStep(), 'expansion');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await settle(tester);
      expect(savedStep(), 'rowRule');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await settle(tester);
      expect(savedStep(), 'expansion');
      expect(tester.element(board), same(element));
      expect(tester.takeException(), isNull);
      expect(repo.state.sessions, isEmpty);
      expect(
        (repo.state.modules[FirstExperienceController.moduleKey]
            as Map)['cells'],
        center,
      );
      await tester.pumpWidget(const SizedBox());
      await repo.flush();
      await repo.close();
    },
  );

  testWidgets(
    'story actions remain visible with large text and scrolling does not change the story',
    (tester) async {
      configure(tester);
      final repo = GameRepository.memory();
      await repo.saveModule(FirstExperienceController.moduleKey, {
        'step': 'rowRule',
        'cells': center,
      });
      await show(tester, repo, textScale: 2);
      final element = tester.element(board);
      for (final size in [
        const Size(320, 568),
        const Size(844, 390),
        const Size(390, 844),
      ]) {
        tester.view.physicalSize = size;
        await settle(tester);
        expect(tester.takeException(), isNull);
        expect(tester.element(board), same(element));
        final bounds = tester.getRect(next);
        expect(bounds.bottom, lessThanOrEqualTo(size.height - 5));
        expect(bounds.top, greaterThan(0));
        expect(next.hitTestable(), findsOneWidget);
        await tester.drag(
          find.byKey(const ValueKey('tutorial-story-gestures')),
          const Offset(0, -150),
        );
        await settle(tester);
        expect(
          (repo.state.modules[FirstExperienceController.moduleKey]
              as Map)['step'],
          'rowRule',
        );
        if (size.width == 320) {
          await capture(tester, 'tutorial-historia-texto-grande');
        }
      }
      await tester.pumpWidget(const SizedBox());
      await repo.flush();
      await repo.close();
    },
  );

  testWidgets(
    'small screens, rotation and enlarged text keep actions and cells reachable',
    (tester) async {
      configure(tester);
      final repo = GameRepository.memory();
      await repo.startOrResumeLevel(
        mapLevelId(1),
        definitions: TutorialSudokus.create(center),
        moduleKey: FirstExperienceController.moduleKey,
        moduleData: {'step': 'playing', 'gameIndex': 0, 'cells': center},
      );
      await show(tester, repo, textScale: 2);
      final element = tester.element(board);
      for (final size in [
        const Size(320, 568),
        const Size(844, 390),
        const Size(390, 844),
      ]) {
        tester.view.physicalSize = size;
        await settle(tester);
        expect(tester.element(board), same(element));
        expect(tester.takeException(), isNull);
        final buttonBounds = tester.getRect(next);
        expect(buttonBounds.bottom, lessThanOrEqualTo(size.height - 5));
        expect(buttonBounds.top, greaterThan(0));
        await tester.ensureVisible(
          find.byKey(const ValueKey('intro-number-3')),
        );
        await settle(tester);
        expect(
          find.byKey(const ValueKey('intro-number-3')).hitTestable(),
          findsOneWidget,
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('sudoku-cell-11')),
        );
        await settle(tester);
        expect(
          find.byKey(const ValueKey('sudoku-cell-11')).hitTestable(),
          findsOneWidget,
        );
        if (size.width == 320) await capture(tester, 'tutorial-texto-grande');
      }
      await tester.pumpWidget(const SizedBox());
      await repo.flush();
      await repo.close();
    },
  );
}
