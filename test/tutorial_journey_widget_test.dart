import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/domain/models/game_session.dart';
import 'package:sundoku/domain/tutorial/tutorial_sudokus.dart';
import 'package:sundoku/screens/first_experience_screen.dart';
import 'package:sundoku/screens/settings_screen.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/sudoku_board.dart';
import 'package:sundoku/widgets/sudoku_digit.dart';
import 'package:sundoku/widgets/home_art.dart';
import 'package:sundoku/widgets/game_feedback_scope.dart';
import 'package:sundoku/widgets/illustrated_action_button.dart';
import 'package:sundoku/widgets/tutorial_block_controls.dart';
import 'package:sundoku/widgets/tutorial_story_navigation.dart';
import 'package:sundoku/widgets/ui_surface_art.dart';
import 'package:sundoku/widgets/tutorial_celebration.dart';
import 'package:sundoku/widgets/victory_particles.dart';

final next = find.byKey(const ValueKey('tutorial-next'));
final board = find.byKey(const ValueKey('intro-board'));
const center = [8, 3, 5, 4, 1, 6, 9, 2, 7];
final captureKey = GlobalKey();

class _ErrorFeedbackSpy extends GameFeedback {
  final vibrations = <bool>[];

  @override
  Future<void> error({required bool vibration}) async =>
      vibrations.add(vibration);
}

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

Future<void> capture(
  WidgetTester tester,
  String name, {
  bool settleAnimations = true,
}) async {
  final directory = Platform.environment['TUTORIAL_CAPTURE_DIR'];
  if (directory == null) return;
  final context = captureKey.currentContext!;
  await tester.runAsync(() async {
    for (final asset in {
      for (final surface in UiSurface.values) surface.spec.asset,
      'assets/images/home-background.png',
      'assets/images/tutorial/block-guide-atlas.png',
      'assets/images/tutorial/cleaning-brush.png',
      'assets/images/tutorial/lives-icons.png',
      'assets/images/map/icons.png',
    }) {
      await precacheImage(AssetImage(asset), context);
    }
  });
  if (settleAnimations) {
    await settle(tester);
  } else {
    await tester.pump();
  }
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
  bool showDeveloperControls = false,
  GameFeedback feedback = const GameFeedback(),
}) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: captureKey,
      child: GameFeedbackHost(
        repository: repo,
        output: feedback,
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
                              showDeveloperControls: showDeveloperControls,
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
                  showDeveloperControls: showDeveloperControls,
                ),
        ),
      ),
    ),
  );
  await settle(tester);
}

void main() {
  for (final gameIndex in [0, 1, 2]) {
    testWidgets('victory ${gameIndex + 1} fans the actual solved boards', (
      tester,
    ) async {
      configure(tester, reduced: false);
      final repo = GameRepository.memory();
      final definitions = TutorialSudokus.create(center);
      final session = await repo.startOrResumeLevel(
        mapLevelId(1),
        definitions: definitions,
        moduleKey: FirstExperienceController.moduleKey,
        moduleData: {
          'step': 'playing',
          'gameIndex': gameIndex,
          'cells': center,
          'briefingAccepted': true,
        },
      );
      final last = definitions[gameIndex].initial.lastIndexOf(null);
      for (var game = 0; game <= gameIndex; game++) {
        for (var i = 0; i < 81; i++) {
          if (!definitions[game].isFixed(i) &&
              (game != gameIndex || i != last)) {
            await repo.setCell(
              session.id,
              definitions[game].id,
              i,
              definitions[game].solution[i],
            );
          }
        }
      }
      await show(tester, repo);
      final element = tester.element(board);
      await tap(tester, find.byKey(ValueKey('sudoku-cell-$last')));
      await tester.tap(
        find.byKey(
          ValueKey('intro-number-${definitions[gameIndex].solution[last]}'),
        ),
      );
      for (var frame = 0; frame < 60; frame++) {
        await tester.pump(const Duration(milliseconds: 20));
        if (find.byType(TutorialCelebration).evaluate().isNotEmpty) break;
      }
      // Measure the reward slot and initialize the flight ticker before timing it.
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      for (var previous = 0; previous < gameIndex; previous++) {
        expect(
          tester
              .widget<Opacity>(
                find.byKey(ValueKey('reward-fan-fade-$previous')),
              )
              .opacity,
          0,
        );
      }
      await tester.pump(const Duration(milliseconds: 500));
      if (gameIndex > 0) {
        expect(
          tester
              .widget<Opacity>(find.byKey(const ValueKey('reward-fan-fade-0')))
              .opacity,
          inExclusiveRange(0, 1),
        );
      }
      final particlesElement = tester.element(find.byType(VictoryParticles));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();
      expect(
        tester.element(find.byType(VictoryParticles)),
        same(particlesElement),
      );
      expect(tester.element(board), same(element));
      expect(find.byType(SudokuBoard), findsNWidgets(gameIndex + 1));
      final fan = tester.widget<TutorialBoardFan>(
        find.byType(TutorialBoardFan),
      );
      expect(fan.previousBoards.length, gameIndex);
      var previousSize = 0.0;
      for (var previous = 0; previous < gameIndex; previous++) {
        final miniature = find.byKey(
          ValueKey('reward-board-${definitions[previous].id}'),
        );
        final widget = tester.widget<SudokuBoard>(miniature);
        expect(widget.cells, definitions[previous].solution);
        expect(widget.onSelect, isNull);
        expect(widget.completion, isNull);
        final size = tester.getSize(miniature).width;
        expect(size, greaterThan(previousSize));
        expect(size, lessThan(tester.getSize(board).width));
        previousSize = size;
        final angle = tester
            .widget<Transform>(
              find.byKey(ValueKey('reward-fan-rotation-$previous')),
            )
            .transform;
        expect(angle.storage[1], isNot(0));
      }
      expect(
        tester.getRect(find.byType(VictoryParticles)),
        tester.getRect(find.byKey(const ValueKey('first-experience-flow'))),
      );
      expect(
        tester
            .widget<VictoryParticles>(find.byType(VictoryParticles))
            .grandFinale,
        gameIndex == 2,
      );
      await tester.tap(find.byKey(const ValueKey('intro-story')));
      await tester.pump();
      await capture(
        tester,
        'victoria-${gameIndex + 1}-festejo',
        settleAnimations: false,
      );
      await tester.pump(const Duration(seconds: 3));
      await capture(tester, 'victoria-${gameIndex + 1}-abanico');
      if (gameIndex == 2) {
        for (final size in [const Size(320, 568), const Size(844, 390)]) {
          tester.view.physicalSize = size;
          await show(tester, repo, textScale: 2);
          expect(tester.element(board), same(element));
          expect(next.hitTestable(), findsOneWidget);
          expect(tester.getRect(next).bottom, lessThanOrEqualTo(size.height));
          final bounds = tester.getRect(find.byType(TutorialBoardFan));
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(size.width));
          expect(tester.takeException(), isNull);
          await capture(tester, 'victoria-3-${size.width.toInt()}');
        }
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await repo.flush();
      await repo.close();
    });
  }

  for (final completedGame in [0, 1]) {
    testWidgets(
      'sudoku ${completedGame + 2} slides in, deals after landing, and DEV can rewind',
      (tester) async {
        configure(tester, reduced: false);
        final repo = GameRepository.memory();
        final definitions = TutorialSudokus.create(center);
        final session = await repo.startOrResumeLevel(
          mapLevelId(1),
          definitions: definitions,
          moduleKey: FirstExperienceController.moduleKey,
          moduleData: {
            'step': 'playing',
            'gameIndex': completedGame,
            'cells': center,
            'briefingAccepted': true,
          },
        );
        for (var game = 0; game <= completedGame; game++) {
          final definition = definitions[game];
          for (var i = 0; i < 81; i++) {
            if (!definition.isFixed(i)) {
              await repo.setCell(
                session.id,
                definition.id,
                i,
                definition.solution[i],
              );
            }
          }
        }
        await show(tester, repo, showDeveloperControls: true);
        final element = tester.element(board);
        final oldRect = tester.getRect(board);
        expect(find.byType(TutorialReward), findsOneWidget);
        tester.widget<IllustratedActionButton>(next).onPressed!();
        await tester.pump();
        expect(tester.getRect(board), rectMoreOrLessEquals(oldRect));
        await tester.pump(const Duration(milliseconds: 160));
        expect(tester.getRect(board).left, lessThan(oldRect.left));
        expect(
          tester
              .widget<Opacity>(find.byKey(const ValueKey('next-board-fade')))
              .opacity,
          inExclusiveRange(0, 1),
        );
        expect(tester.widget<IllustratedActionButton>(next).onPressed, isNull);
        await capture(
          tester,
          'sudoku-${completedGame + 1}-salida',
          settleAnimations: false,
        );
        await tester.pump(const Duration(milliseconds: 160));
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 1));
          if (tester.widget<SudokuBoard>(board).dealProgress != null) break;
        }
        await tester.pump();
        expect(
          (repo.state.modules[FirstExperienceController.moduleKey]
              as Map)['gameIndex'],
          completedGame + 1,
        );
        expect(tester.widget<SudokuBoard>(board).dealProgress, 0);
        expect(tester.element(board), same(element));
        expect(tester.getRect(board).left, greaterThan(390));
        double tileOpacity(int index) => tester
            .widget<Opacity>(find.byKey(ValueKey('tile-arrival-$index')))
            .opacity;
        double controlsOpacity() => tester
            .widget<Opacity>(find.byKey(const ValueKey('next-game-controls')))
            .opacity;
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.getSize(board).width, inExclusiveRange(154, 358));
        expect(tileOpacity(40), 0);
        expect(tileOpacity(0), 0);
        expect(controlsOpacity(), 0);
        expect(tester.widget<SudokuBoard>(board).onSelect, isNull);
        await capture(
          tester,
          'sudoku-${completedGame + 2}-entrada',
          settleAnimations: false,
        );
        await tester.pump(const Duration(milliseconds: 400));
        final landed = tester.getRect(board);
        expect(landed.width, closeTo(358, .001));
        expect(tileOpacity(40), 0);
        expect(controlsOpacity(), 0);
        await tester.pump(const Duration(milliseconds: 100));
        expect(tileOpacity(40), greaterThan(0));
        expect(tileOpacity(0), 0);
        expect(tester.getRect(board), landed);
        await tester.pump(const Duration(milliseconds: 250));
        expect(tileOpacity(0), greaterThan(0));
        expect(controlsOpacity(), inExclusiveRange(0, 1));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump();
        expect(tester.getRect(board), landed);
        expect(tester.element(board), same(element));
        expect(tileOpacity(0), 1);
        expect(controlsOpacity(), 1);
        expect(tester.widget<SudokuBoard>(board).onSelect, isNotNull);
        expect(
          tester.widget<SudokuBoard>(board).cells,
          definitions[completedGame + 1].initial,
        );
        await capture(tester, 'sudoku-${completedGame + 2}-listo');
        await tap(tester, find.byKey(const ValueKey('dev-game-options')));
        await tap(tester, find.byKey(const ValueKey('dev-restart-previous')));
        expect(
          (repo.state.modules[FirstExperienceController.moduleKey]
              as Map)['gameIndex'],
          completedGame,
        );
        expect(
          tester.widget<SudokuBoard>(board).cells,
          definitions[completedGame].initial,
        );
        expect(repo.state.totalLights, completedGame + 1);
        expect(tester.widget<SudokuBoard>(board).completion, isNull);
        await tap(tester, find.byKey(const ValueKey('dev-fill-except-one')));
        expect(
          tester
              .widget<SudokuBoard>(board)
              .cells
              .where((c) => c == null)
              .length,
          1,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await repo.flush();
        await repo.close();
      },
    );
  }

  testWidgets(
    'dev button leaves one selected tile and the final move celebrates normally',
    (tester) async {
      configure(tester, reduced: false);
      final repo = GameRepository.memory();
      final definitions = TutorialSudokus.create(center);
      await repo.startOrResumeLevel(
        mapLevelId(1),
        definitions: definitions,
        moduleKey: FirstExperienceController.moduleKey,
        moduleData: {
          'step': 'playing',
          'gameIndex': 0,
          'cells': center,
          'briefingAccepted': true,
        },
      );
      final fill = find.byKey(const ValueKey('dev-fill-except-one'));
      await show(tester, repo);
      expect(fill, findsNothing);
      await show(tester, repo, showDeveloperControls: true);
      expect(fill.hitTestable(), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('sudoku-cell-67')));
      await tap(tester, fill);
      final widget = tester.widget<SudokuBoard>(board);
      expect(widget.cells.where((n) => n == null).length, 1);
      expect(widget.cells[67], isNull);
      expect(widget.selectedIndex, 67);
      expect(widget.completion, isNull);
      expect(find.byType(TutorialReward), findsNothing);
      expect(repo.state.totalLights, 0);
      await capture(tester, 'dev-one-tile');
      await tap(
        tester,
        find.byKey(ValueKey('intro-number-${definitions.first.solution[67]}')),
      );
      expect(tester.widget<SudokuBoard>(board).completion!.wholeBoard, true);
      expect(repo.state.totalLights, 1);
      expect(find.byType(TutorialReward), findsOneWidget);
      expect(tester.widget<TextButton>(fill).onPressed, isNull);
      expect(find.byKey(const ValueKey('dev-game-options')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await repo.flush();
      await repo.close();
    },
  );

  testWidgets('the final board wave stays visible before showing the reward', (
    tester,
  ) async {
    configure(tester, reduced: false);
    final repo = GameRepository.memory();
    final definitions = TutorialSudokus.create(center);
    final session = await repo.startOrResumeLevel(
      mapLevelId(1),
      definitions: definitions,
      moduleKey: FirstExperienceController.moduleKey,
      moduleData: {
        'step': 'playing',
        'gameIndex': 0,
        'cells': center,
        'briefingAccepted': true,
      },
    );
    const last = 67;
    await repo.activatePuzzle(session.id, definitions.first.id);
    for (var i = 0; i < 81; i++) {
      if (definitions.first.initial[i] == null && i != last) {
        await repo.setCell(
          session.id,
          definitions.first.id,
          i,
          definitions.first.solution[i],
        );
      }
    }
    await show(tester, repo);
    expect(tester.widget<SudokuBoard>(board).completion, isNull);
    await tap(tester, find.byKey(const ValueKey('sudoku-cell-$last')));
    final initialRect = tester.getRect(board);
    final element = tester.element(board);
    await tester.tap(
      find.byKey(ValueKey('intro-number-${definitions.first.solution[last]}')),
    );
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      if (tester.widget<SudokuBoard>(board).completion != null) break;
    }
    final completion = tester.widget<SudokuBoard>(board).completion!;
    expect(completion.wholeBoard, true);
    expect(completion.cells.length, 81);
    expect(completion.origin, last);
    expect(tester.getRect(board), initialRect);
    expect(find.byType(TutorialReward), findsNothing);
    expect(next, findsNothing);
    expect(find.text('Sudoku 1 de 3'), findsOneWidget);
    expect(repo.state.totalLights, 1);
    await tester.pump(const Duration(milliseconds: 100));
    await capture(tester, 'onda-final-inicio', settleAnimations: false);
    await tester.pump(const Duration(milliseconds: 350));
    await capture(tester, 'onda-final-mitad', settleAnimations: false);
    await tester.pump(const Duration(milliseconds: 250));
    await capture(tester, 'onda-final-bordes', settleAnimations: false);
    expect(find.byType(TutorialReward), findsNothing);
    expect(next, findsNothing);
    expect(tester.element(board), same(element));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    expect(find.byType(TutorialReward), findsOneWidget);
    expect(next, findsOneWidget);
    expect(tester.element(board), same(element));
    expect(tester.takeException(), isNull);
    // The same board flies from its game position while Doku fades up beneath it.
    await tester.pump();
    expect(tester.getRect(board).width, closeTo(initialRect.width, .01));
    double opacity(String key) =>
        tester.widget<Opacity>(find.byKey(ValueKey(key))).opacity;
    await tester.pump(const Duration(milliseconds: 350));
    final middle = tester.getRect(board);
    expect(middle.width, lessThan(initialRect.width));
    expect(middle.width, greaterThan(154));
    expect(middle.top, lessThan(initialRect.top));
    expect(opacity('reward-doku-fade'), inExclusiveRange(0, 1));
    expect(opacity('reward-star-0'), 0);
    expect(tester.widget<IllustratedActionButton>(next).onPressed, isNull);
    await capture(tester, 'felicitaciones-transicion', settleAnimations: false);
    await tester.pump(const Duration(milliseconds: 400));
    expect(opacity('reward-star-0'), greaterThan(0));
    expect(opacity('reward-star-1'), 0);
    expect(opacity('reward-star-2'), 0);
    await tester.pump(const Duration(milliseconds: 250));
    expect(opacity('reward-star-0'), 1);
    expect(opacity('reward-star-1'), greaterThan(0));
    expect(opacity('reward-star-2'), 0);
    await tester.pump(const Duration(milliseconds: 300));
    expect(opacity('reward-star-2'), greaterThan(0));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();
    expect(tester.element(board), same(element));
    expect(tester.getSize(board).width, 154);
    expect(
      tester.getRect(board).bottom,
      lessThan(
        tester.getRect(find.byKey(const ValueKey('reward-doku-fade'))).top,
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    final storyText = tester.widget<Text>(
      find.byKey(const ValueKey('intro-story-text')),
    );
    final spans = (storyText.textSpan! as TextSpan).children!.cast<TextSpan>();
    expect(spans.first.text, isNotEmpty);
    expect(spans.last.text, isNotEmpty);
    await tester.tap(find.byKey(const ValueKey('intro-story')));
    await tester.pump();
    await capture(tester, 'felicitaciones-listas');
    for (final size in [
      const Size(320, 568),
      const Size(844, 390),
      const Size(1200, 800),
    ]) {
      tester.view.physicalSize = size;
      await show(tester, repo, textScale: 2);
      expect(tester.element(board), same(element));
      expect(tester.getSize(board).width, lessThanOrEqualTo(154));
      expect(next.hitTestable(), findsOneWidget);
      expect(tester.getRect(next).bottom, lessThanOrEqualTo(size.height));
      expect(tester.takeException(), isNull);
    }
    await capture(tester, 'felicitaciones-texto-grande');
    await tester.pumpWidget(const SizedBox());
    await repo.flush();
    await repo.close();
  });

  testWidgets(
    'errors vibrate once per attempt using the saved preference, never on resume',
    (tester) async {
      configure(tester);
      final repo = GameRepository.memory();
      await repo.startOrResumeLevel(
        mapLevelId(1),
        definitions: TutorialSudokus.create(center),
        moduleKey: FirstExperienceController.moduleKey,
        moduleData: {
          'step': 'playing',
          'gameIndex': 0,
          'cells': center,
          'briefingAccepted': true,
        },
      );
      final feedback = _ErrorFeedbackSpy();
      await show(tester, repo, feedback: feedback);
      expect(feedback.vibrations, isEmpty);
      await tap(tester, find.byKey(const ValueKey('sudoku-cell-11')));
      await tap(tester, find.byKey(const ValueKey('intro-number-1')));
      expect(feedback.vibrations, [true]);
      final firstPulse = tester.widget<SudokuBoard>(board).errorPulse;
      await tap(tester, find.byKey(const ValueKey('sudoku-cell-14')));
      await tap(tester, find.byKey(const ValueKey('sudoku-cell-11')));
      expect(feedback.vibrations, [true]);
      await tap(tester, find.byKey(const ValueKey('intro-number-1')));
      expect(feedback.vibrations, [true, true]);
      expect(
        tester.widget<SudokuBoard>(board).errorPulse,
        greaterThan(firstPulse),
      );
      expect(repo.state.sessions.values.single.puzzles.first.mistakes, 1);
      await tester.pumpWidget(const SizedBox());
      await repo.flush();
      await show(tester, repo, feedback: feedback);
      expect(feedback.vibrations, [true, true]);
      await tap(tester, find.byKey(const ValueKey('sudoku-cell-11')));
      await tap(tester, find.byKey(const ValueKey('intro-number-3')));
      expect(feedback.vibrations, [true, true]);
      await repo.updateSettings(vibration: false);
      await tap(tester, find.byKey(const ValueKey('intro-number-1')));
      expect(feedback.vibrations, [true, true, false]);
      expect(tester.widget<SudokuBoard>(board).conflictIndices, {11});
      await tester.pumpWidget(const SizedBox());
      await repo.flush();
      await repo.close();
    },
  );

  testWidgets(
    'incorrect entries use pale red tiles and ordinary matching highlights',
    (tester) async {
      configure(tester);
      final repo = GameRepository.memory();
      await repo.startOrResumeLevel(
        mapLevelId(1),
        definitions: TutorialSudokus.create(center),
        moduleKey: FirstExperienceController.moduleKey,
        moduleData: {
          'step': 'playing',
          'gameIndex': 0,
          'cells': center,
          'briefingAccepted': true,
        },
      );
      await show(tester, repo);
      const target = 11;
      const duplicate = 14;
      Finder cell(int index) => find.byKey(ValueKey('sudoku-cell-$index'));
      SudokuDigit digit(int index) => tester.widget<SudokuDigit>(
        find.descendant(of: cell(index), matching: find.byType(SudokuDigit)),
      );
      UiSurface surface(int index) => tester
          .widget<UiSurfaceArt>(
            find.descendant(
              of: cell(index),
              matching: find.byType(UiSurfaceArt),
            ),
          )
          .surface;
      await tap(tester, cell(target));
      final duplicateDigit = find.descendant(
        of: cell(duplicate),
        matching: find.byType(SudokuDigit),
      );
      final duplicateElement = tester.element(duplicateDigit);
      await tap(tester, find.byKey(const ValueKey('intro-number-1')));
      expect(tester.element(duplicateDigit), same(duplicateElement));
      expect(digit(target).value, 1);
      expect(digit(target).color, const Color(0xFF980A18));
      expect(digit(duplicate).color, homeNavy);
      expect(surface(target), UiSurface.creamTile);
      expect(surface(duplicate), UiSurface.goldTile);
      expect(tester.widget<SudokuBoard>(board).conflictIndices, {target});
      expect(
        find.byKey(const ValueKey('sudoku-matching-number-14')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('sudoku-matching-number-40')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: cell(duplicate),
          matching: find.byType(DecoratedBox),
        ),
        findsNothing,
      );
      await capture(tester, 'sudoku-error-seleccionado');

      await tap(tester, cell(duplicate));
      expect(digit(duplicate).color, Colors.white);
      expect(digit(target).color, const Color(0xFFD51B25));
      expect(surface(target), UiSurface.creamTile);
      expect(tester.widget<SudokuBoard>(board).conflictIndices, {target});
      expect(
        find.byKey(const ValueKey('sudoku-matching-number-11')),
        findsOneWidget,
      );
      await capture(tester, 'sudoku-error-coincidencias');

      await tap(tester, cell(target));
      await tap(tester, find.byKey(const ValueKey('intro-number-3')));
      expect(digit(target).value, 3);
      expect(digit(target).color, Colors.white);
      expect(surface(target), UiSurface.goldTile);
      expect(tester.widget<SudokuBoard>(board).conflictIndices, isEmpty);
      expect(
        find.byKey(const ValueKey('sudoku-matching-number-14')),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox());
      await repo.flush();
      await repo.close();
    },
  );

  testWidgets('step navigation stays locked for the entire board animation', (
    tester,
  ) async {
    configure(tester, reduced: false);
    final repo = GameRepository.memory();
    addTearDown(repo.dispose);
    await repo.saveModule(FirstExperienceController.moduleKey, {
      'step': 'blockIntroduction',
      'cells': center,
    });
    await show(tester, repo);
    final gestures = find.byKey(const ValueKey('tutorial-story-gestures'));
    String step() =>
        (repo.state.modules[FirstExperienceController.moduleKey] as Map)['step']
            as String;
    for (final target in [
      'expansion',
      'rowRule',
      'columnRule',
      'givensIntroduction',
    ]) {
      await tester.widget<IllustratedActionButton>(next).onPressed!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pump();
      expect(step(), target);
      expect(tester.widget<TutorialStoryGestures>(gestures).enabled, false);
      expect(tester.widget<IllustratedActionButton>(next).onPressed, isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      final bounds = tester.getRect(gestures);
      await tester.tapAt(Offset(bounds.right - 20, bounds.center.dy));
      await tester.drag(gestures, const Offset(180, 0));
      await tester.tap(next);
      await tester.pump();
      expect(step(), target);
      if (target == 'givensIntroduction') {
        await tester.pump(const Duration(milliseconds: 950));
        await tester.pump();
        expect(tester.widget<TutorialStoryGestures>(gestures).enabled, false);
        expect(tester.widget<IllustratedActionButton>(next).onPressed, isNull);
      }
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(tester.widget<TutorialStoryGestures>(gestures).enabled, true);
      expect(tester.widget<IllustratedActionButton>(next).onPressed, isNotNull);
      expect(step(), target);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'board moves upward before briefing and play controls wait for acceptance',
    (tester) async {
      configure(tester, reduced: false);
      tester.view.physicalSize = const Size(390, 1000);
      final repo = GameRepository.memory();
      addTearDown(repo.dispose);
      await repo.saveModule(FirstExperienceController.moduleKey, {
        'step': 'givensIntroduction',
        'cells': center,
      });
      await show(tester, repo);
      final before = tester.getRect(board);
      final element = tester.element(board);
      await tester.widget<IllustratedActionButton>(next).onPressed!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      expect(tester.widget<SudokuBoard>(board).onSelect, isNull);
      expect(find.byKey(const ValueKey('game-briefing')), findsNothing);
      await tester.pump(const Duration(milliseconds: 350));
      final middle = tester.getRect(board);
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester);
      final after = tester.getRect(board);
      expect(middle.top, lessThan(before.top));
      expect(middle.top, greaterThan(after.top));
      expect(tester.element(board), same(element));
      expect(find.byKey(const ValueKey('game-briefing')), findsOneWidget);
      expect(tester.widget<SudokuBoard>(board).onSelect, isNull);
      await tester.tapAt(const Offset(2, 2));
      await tester.pump();
      expect(find.byKey(const ValueKey('game-briefing')), findsOneWidget);
      await capture(tester, 'tutorial-antes-de-jugar');
      await tap(tester, find.byKey(const ValueKey('game-briefing-accept')));
      expect(tester.widget<SudokuBoard>(board).onSelect, isNotNull);
      final tray = tester.widget<TutorialNumberTray>(
        find.byType(TutorialNumberTray),
      );
      expect(tray.horizontal, true);
      final buttons = [
        for (var n = 1; n <= 9; n++)
          tester.getRect(find.byKey(ValueKey('intro-number-$n'))),
      ];
      for (var i = 1; i < buttons.length; i++) {
        expect(buttons[i].top, buttons.first.top);
        expect(buttons[i].left, greaterThan(buttons[i - 1].right));
      }
      final clear = tester.getRect(find.byKey(const ValueKey('intro-clear')));
      final lives = tester.getRect(
        find.byKey(const ValueKey('game-unlimited-lives')),
      );
      final banner = tester.getRect(find.text('Sudoku 1 de 3'));
      expect(lives.top, greaterThan(banner.bottom));
      expect(lives.bottom, lessThanOrEqualTo(after.top));
      expect(clear.top, greaterThan(buttons.first.bottom));
      expect(clear.left, closeTo(buttons.first.left + 12, 1));
      expect(clear.width, clear.height);
      expect(
        (repo.state.modules[FirstExperienceController.moduleKey]
            as Map)['briefingAccepted'],
        true,
      );
      await capture(tester, 'tutorial-tablero-arriba');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'normal play opens settings above the title and returns to the map',
    (tester) async {
      configure(tester);
      final repo = GameRepository.memory();
      addTearDown(repo.dispose);
      await repo.startOrResumeLevel(
        mapLevelId(1),
        definitions: TutorialSudokus.create(center),
        moduleKey: FirstExperienceController.moduleKey,
        moduleData: {
          'step': 'playing',
          'gameIndex': 0,
          'cells': center,
          'briefingAccepted': true,
        },
      );
      await show(tester, repo, withParentRoute: true);
      await tap(tester, find.text('Abrir tutorial'));
      expect(next, findsNothing);
      expect(find.text('Pista'), findsNothing);
      expect(find.text('Seguir'), findsNothing);
      final title = tester.getRect(find.text('Sudoku 1 de 3'));
      final back = find.byKey(const ValueKey('game-back'));
      final settings = find.byKey(const ValueKey('game-settings'));
      expect(tester.getRect(back).bottom, lessThan(title.top));
      expect(tester.getRect(settings).bottom, lessThan(title.top));
      expect(tester.widget<SudokuBoard>(board).selectedIndex, isNull);
      final session = repo.state.sessions.values.single;
      final definition = repo.state.puzzles[session.puzzles.first.puzzleId]!;
      final target = tester.widget<SudokuBoard>(board).cells.indexOf(null);
      await tap(tester, find.byKey(ValueKey('sudoku-cell-$target')));
      await tap(
        tester,
        find.byKey(ValueKey('intro-number-${definition.solution[target]}')),
      );
      final element = tester.element(board);
      final saved = [...tester.widget<SudokuBoard>(board).cells];
      expect(next, findsNothing);
      await tap(tester, settings);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(repo.state.sessions.values.single.status, PlayStatus.paused);
      await tap(tester, find.byKey(const ValueKey('settings-close')));
      expect(find.byType(SettingsScreen), findsNothing);
      expect(tester.element(board), same(element));
      expect(tester.widget<SudokuBoard>(board).cells, saved);
      expect(tester.widget<SudokuBoard>(board).selectedIndex, target);
      await tap(tester, back);
      expect(find.byType(FirstExperienceScreen), findsNothing);
      expect(find.text('Abrir tutorial'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

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
      expect(find.byKey(const ValueKey('game-briefing')), findsOneWidget);
      expect(tester.widget<SudokuBoard>(board).onSelect, isNull);
      await tap(tester, find.byKey(const ValueKey('game-briefing-accept')));
      for (var game = 0; game < 3; game++) {
        expect(find.byType(TutorialStoryProgress), findsNothing);
        expect(
          repo.state.sessions.values.single.puzzles[game].status,
          PlayStatus.active,
        );
        if (game == 0) await capture(tester, 'tutorial-primer-sudoku');
        expect(next, findsNothing);
        expect(find.text('Pista'), findsNothing);
        expect(find.text('Seguir'), findsNothing);
        expect(find.byKey(const ValueKey('game-back')), findsOneWidget);
        expect(find.byKey(const ValueKey('game-settings')), findsOneWidget);
        var moves = 0;
        while (repo.state.sessions.values.single.puzzles[game].status !=
                PlayStatus.completed &&
            moves++ < 81) {
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
        await settle(tester);
        expect(find.byType(TutorialReward), findsOneWidget);
        if (game < 2) await tap(tester, next);
      }
      expect(find.text('¡Completaste el nivel 1!'), findsOneWidget);
      expect(find.text('Ir al mapa'), findsOneWidget);
      expect(find.text('Repasar las reglas'), findsNothing);
      expect(find.byKey(const ValueKey('tutorial-review')), findsNothing);
      expect(find.byKey(const ValueKey('reward-map-icon')), findsOneWidget);
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
        moduleData: {
          'step': 'playing',
          'gameIndex': 0,
          'cells': center,
          'briefingAccepted': true,
        },
      );
      await show(tester, repo, textScale: 2);
      final element = tester.element(board);
      for (final size in [
        const Size(320, 568),
        const Size(844, 390),
        const Size(390, 844),
        const Size(1440, 1000),
        const Size(768, 1024),
      ]) {
        tester.view.physicalSize = size;
        await settle(tester);
        expect(tester.element(board), same(element));
        expect(tester.takeException(), isNull);
        expect(next, findsNothing);
        final settingsBounds = tester.getRect(
          find.byKey(const ValueKey('game-settings')),
        );
        final backBounds = tester.getRect(
          find.byKey(const ValueKey('game-back')),
        );
        expect(backBounds.left, closeTo(16, .01));
        expect(settingsBounds.right, closeTo(size.width - 16, .01));
        final boardBounds = tester.getRect(board);
        expect(boardBounds.width, lessThanOrEqualTo(430));
        expect(boardBounds.center.dx, closeTo(size.width / 2, .01));
        for (var number = 1; number <= 9; number++) {
          final numberSize = tester.getSize(
            find.byKey(ValueKey('intro-number-$number')),
          );
          expect(numberSize.width, lessThanOrEqualTo(backBounds.width));
          expect(numberSize.height, lessThanOrEqualTo(backBounds.height));
        }
        final clearSize = tester.getSize(
          find.byKey(const ValueKey('intro-clear')),
        );
        expect(clearSize.width, lessThanOrEqualTo(backBounds.width));
        expect(clearSize.height, lessThanOrEqualTo(backBounds.height));
        expect(settingsBounds.top, greaterThanOrEqualTo(0));
        expect(settingsBounds.bottom, lessThan(size.height));
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
