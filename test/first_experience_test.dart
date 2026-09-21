import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sundoku/app.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/screens/first_experience_screen.dart';
import 'package:sundoku/screens/home_screen.dart';
import 'package:sundoku/screens/map_screen.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/juicy_press.dart';
import 'package:sundoku/widgets/illustrated_action_button.dart';
import 'package:sundoku/widgets/sudoku_board.dart';
import 'package:sundoku/widgets/tutorial_story.dart';
import 'package:sundoku/widgets/tutorial_story_navigation.dart';
import 'package:sundoku/widgets/world_journey_route.dart';

final _continue = find.byKey(const ValueKey('intro-continue'));
final _startBlock = find.byKey(const ValueKey('tutorial-next'));
final _board = find.byKey(const ValueKey('intro-board'));
final _center = find.byKey(const ValueKey('sudoku-cell-40'));

class _FailingStore extends MemorySaveStore {
  bool fail = false;

  @override
  Future<void> write(String data, {required int expectedRevision}) async {
    if (fail) throw StateError('Simulated unavailable storage');
    await super.write(data, expectedRevision: expectedRevision);
  }
}

void _configure(WidgetTester tester, {Size size = const Size(390, 844)}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  addTearDown(() => tester.pumpWidget(const SizedBox()));
}

// The map has an ambient animation; bound every navigation wait.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await _settle(tester);
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await _settle(tester);
}

Future<void> _beginBlock(WidgetTester tester) async {
  await _tap(tester, _continue);
}

Future<void> _exitWithDeveloperMenu(WidgetTester tester) async {
  await _tap(tester, find.byKey(const ValueKey('dev-floating-button')));
  await _tap(tester, find.byKey(const ValueKey('dev-exit-tutorial')));
}

Future<void> _openFromHome(
  WidgetTester tester,
  GameRepository repository,
) async {
  await tester.pumpWidget(
    SunDokuApp(repository: repository, feedback: const GameFeedback()),
  );
  await tester.pump(const Duration(seconds: 3));
  await _settle(tester);
  final welcome = find.byKey(const ValueKey('profile-close'));
  if (welcome.evaluate().isNotEmpty) {
    await tester.tap(welcome);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }
  await _tap(tester, find.byKey(const ValueKey('home-play')));
  if (find.byType(MapScreen).evaluate().isNotEmpty) {
    await _tap(tester, find.byKey(const ValueKey('level-1-label')));
    final continueAction = find.byKey(const ValueKey('level-summary-continue'));
    await _tap(
      tester,
      continueAction.evaluate().isNotEmpty
          ? continueAction
          : find.byKey(const ValueKey('level-summary-play')),
    );
  }
  expect(find.byType(FirstExperienceScreen), findsOneWidget);
}

Future<void> _showFlow(WidgetTester tester, GameRepository repository) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildSunDokuTheme(),
      home: FirstExperienceScreen(repository: repository),
    ),
  );
  await _settle(tester);
}

void main() {
  testWidgets('tutorial DEV menu exits to the previous screen', (tester) async {
    final repository = GameRepository.memory();
    addTearDown(repository.dispose);
    _configure(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildSunDokuTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FirstExperienceScreen(
                      repository: repository,
                      showDeveloperControls: true,
                    ),
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('dev-floating-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dev-exit-tutorial')));
    await tester.pumpAndSettle();
    expect(find.text('Abrir'), findsOneWidget);
    expect(find.byType(FirstExperienceScreen), findsNothing);
  });

  testWidgets('first adventure keeps home status hidden during departure', (
    tester,
  ) async {
    _configure(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: false);
    final repository = GameRepository.memory();
    addTearDown(repository.dispose);
    await repository.saveModule('homeWelcome', {'namePromptShown': true});
    await tester.pumpWidget(
      SunDokuApp(repository: repository, feedback: const GameFeedback()),
    );
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);
    final homeRoute = ModalRoute.of(tester.element(find.byType(HomeScreen)));
    expect(homeRoute, isA<WorldJourneyRoute>());
    expect(homeRoute!.animation!.value, lessThan(1));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    final status = find.byKey(const ValueKey('home-game-status'));
    expect(status, findsNothing);
    await tester.tap(find.byKey(const ValueKey('home-play')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(FirstExperienceScreen), findsOneWidget);
      final mapRoute =
          ModalRoute.of(tester.element(find.byType(MapScreen)))!
              as WorldJourneyRoute;
      expect(mapRoute.showClouds, isFalse);
      expect(status, findsNothing);
      expect(
        tester.widget<HomeScreen>(find.byType(HomeScreen)).hasStarted,
        isFalse,
      );
    }
    await tester.pump(const Duration(seconds: 2));
    await _settle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first Play opens tutorial once; map review preserves progress', (
    tester,
  ) async {
    final store = MemorySaveStore();
    final repository = await GameRepository.open(store);
    addTearDown(repository.dispose);
    _configure(tester, size: const Size(320, 568));
    await _openFromHome(tester, repository);
    expect(repository.state.modules[FirstExperienceController.moduleKey], {
      'homeIntroductionShown': true,
    });
    expect(find.byKey(const ValueKey('tutorial-close')), findsNothing);
    Navigator.of(tester.element(find.byType(FirstExperienceScreen))).pop();
    await _settle(tester);
    expect(find.byType(MapScreen), findsOneWidget);
    final back = find.byKey(const ValueKey('map-back'));
    expect(
      find.descendant(of: back, matching: find.byIcon(Icons.home_rounded)),
      findsOneWidget,
    );
    final review = find.byKey(const ValueKey('map-tutorial'));
    expect(
      tester.getRect(review).left,
      greaterThan(tester.getRect(back).right),
    );
    expect(tester.getSize(review).width, tester.getSize(review).height);
    await _tap(tester, back);
    await _tap(tester, find.byKey(const ValueKey('home-play')));
    expect(find.byType(MapScreen), findsOneWidget);
    expect(find.byType(FirstExperienceScreen), findsNothing);
    final saved = repository.state.modules[FirstExperienceController.moduleKey];
    await _tap(tester, review);
    final close = find.byKey(const ValueKey('tutorial-close'));
    expect(close, findsOneWidget);
    expect(tester.getRect(close).right, closeTo(320 - 16, .01));
    expect(tester.getRect(close).top, closeTo(8, .01));
    await _tap(tester, close);
    expect(find.byType(MapScreen), findsOneWidget);
    await _tap(tester, review);
    expect(
      tester
          .widget<FirstExperienceScreen>(find.byType(FirstExperienceScreen))
          .reviewOnly,
      true,
    );
    await _tap(tester, _continue);
    expect(find.byKey(const ValueKey('tutorial-choose-order')), findsNothing);
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await _settle(tester);
    }
    expect(find.text('Volver al mapa'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _settle(tester);
    expect(find.byType(MapScreen), findsOneWidget);
    expect(
      repository.state.modules[FirstExperienceController.moduleKey],
      saved,
    );
    expect(repository.state.sessions, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    final reopened = await GameRepository.open(store);
    addTearDown(reopened.dispose);
    await tester.pumpWidget(
      SunDokuApp(repository: reopened, feedback: const GameFeedback()),
    );
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);
    await _tap(tester, find.byKey(const ValueKey('home-play')));
    expect(find.byType(MapScreen), findsOneWidget);
    expect(find.byType(FirstExperienceScreen), findsNothing);
  });

  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Baloo2')
      ..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'));
    await font.load();
  });

  testWidgets('block fills automatically and survives expansion and rotation', (
    tester,
  ) async {
    final repository = GameRepository.memory();
    addTearDown(repository.dispose);
    _configure(tester);
    await _showFlow(tester, repository);
    final element = tester.element(_board);
    await _beginBlock(tester);
    final cells = List<int?>.of(tester.widget<SudokuBoard>(_board).cells);
    expect(
      cells.whereType<int>(),
      unorderedEquals(List.generate(9, (i) => i + 1)),
    );
    expect(tester.widget<SudokuBoard>(_board).onSelect, isNull);
    expect(find.byKey(const ValueKey('intro-number-tray')), findsNothing);
    expect(find.textContaining('Toca los lados'), findsNothing);
    for (final size in [const Size(390, 844), const Size(844, 390)]) {
      tester.view.physicalSize = size;
      await _settle(tester);
      expect(tester.element(_board), same(element));
      expect(tester.widget<SudokuBoard>(_board).cells, cells);
      expect(_startBlock.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await _tap(tester, _startBlock);
    expect(tester.element(_board), same(element));
    expect(tester.widget<SudokuBoard>(_board).centerOnly, false);
    for (final i in [30, 31, 32, 39, 40, 41, 48, 49, 50]) {
      expect(tester.widget<SudokuBoard>(_board).cells[i], cells[i]);
    }
    expect(repository.state.sessions, isEmpty);
  });

  testWidgets(
    'welcome and block cannot be skipped while their text is typing',
    (tester) async {
      final repository = GameRepository.memory();
      addTearDown(repository.dispose);
      _configure(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await _showFlow(tester, repository);
      final story = find.byKey(const ValueKey('intro-story-text'));
      String visibleText() =>
          ((tester.widget<Text>(story).textSpan! as TextSpan).children!.first
                  as TextSpan)
              .text!;
      expect(
        tester.widget<IllustratedActionButton>(_continue).onPressed,
        isNull,
      );
      await tester.tap(_continue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 900));
      expect(
        visibleText().length,
        lessThan(TutorialStory.sentences.join('\n').length),
      );
      expect(repository.state.modules, isEmpty);
      await tester.pump(const Duration(seconds: 8));
      await tester.pump();
      expect(
        tester.widget<IllustratedActionButton>(_continue).onPressed,
        isNotNull,
      );
      await _tap(tester, _continue);
      expect(
        tester.widget<IllustratedActionButton>(_startBlock).onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TutorialStoryGestures>(find.byType(TutorialStoryGestures))
            .enabled,
        false,
      );
      await tester.tap(_startBlock);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(
        (repository.state.modules[FirstExperienceController.moduleKey]
            as Map)['step'],
        'blockIntroduction',
      );
      await tester.pump(const Duration(seconds: 8));
      await tester.pump();
      expect(
        tester.widget<IllustratedActionButton>(_startBlock).onPressed,
        isNotNull,
      );
      await _tap(tester, _startBlock);
      expect(
        (repository.state.modules[FirstExperienceController.moduleKey]
            as Map)['step'],
        'expansion',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('legacy partial blocks resume as an automatic explanation', (
    tester,
  ) async {
    final repository = GameRepository.memory();
    addTearDown(repository.dispose);
    await repository.saveModule(FirstExperienceController.moduleKey, {
      'step': 'block',
      'cells': [null, null, null, null, 9, null, null, null, null],
    });
    _configure(tester);
    await _showFlow(tester, repository);
    expect(find.text('Un bloque, 9 casillas'), findsOneWidget);
    expect(tester.widget<SudokuBoard>(_board).onSelect, isNull);
    expect(tester.widget<SudokuBoard>(_board).cells[40], 9);
    expect(find.byKey(const ValueKey('intro-number-tray')), findsNothing);
    await _tap(tester, _startBlock);
    final draft =
        repository.state.modules[FirstExperienceController.moduleKey] as Map;
    expect(draft['step'], 'expansion');
    expect(draft['cells'], unorderedEquals(List.generate(9, (i) => i + 1)));
    expect(tester.widget<SudokuBoard>(_board).cells[40], 9);
  });

  testWidgets(
    'returning to the welcome shows its full text without another wait',
    (tester) async {
      final repository = GameRepository.memory();
      addTearDown(repository.dispose);
      _configure(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await _showFlow(tester, repository);
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();
      await _tap(tester, _continue);
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();
      tester
          .widget<TutorialStoryGestures>(find.byType(TutorialStoryGestures))
          .onPrevious!();
      await _settle(tester);
      final text = tester.widget<Text>(
        find.byKey(const ValueKey('intro-story-text')),
      );
      expect(
        ((text.textSpan! as TextSpan).children!.first as TextSpan).text,
        TutorialStory.sentences.join('\n'),
      );
      expect(
        tester
            .widget<Opacity>(
              find.byKey(const ValueKey('intro-story-conclusion')),
            )
            .opacity,
        1,
      );
      expect(_continue.hitTestable(), findsOneWidget);
    },
  );

  testWidgets(
    'player layout hides DEV controls and development exposes the floating menu',
    (tester) async {
      final repository = GameRepository.memory();
      addTearDown(repository.dispose);
      _configure(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildSunDokuTheme(),
          home: FirstExperienceScreen(
            repository: repository,
            showDeveloperControls: false,
          ),
        ),
      );
      await _settle(tester);
      expect(find.text('DEV · Volver'), findsNothing);
      expect(find.byKey(const ValueKey('dev-floating-button')), findsNothing);
      expect(find.text('Tu primer sudoku'), findsOneWidget);
      await _beginBlock(tester);
      expect(find.text('Un bloque, 9 casillas'), findsOneWidget);
      await _showFlow(tester, repository);
      expect(find.byKey(const ValueKey('dev-floating-button')), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('dev-floating-button')));
      expect(find.byKey(const ValueKey('dev-exit-tutorial')), findsOneWidget);
      expect(find.text('DEV · Volver'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'level one opens one flow and keeps the same board through welcome',
    (tester) async {
      final repository = await GameRepository.open(MemorySaveStore());
      addTearDown(repository.dispose);
      _configure(tester);
      final semantics = tester.ensureSemantics();
      try {
        await _openFromHome(tester, repository);
        expect(
          find.byKey(const ValueKey('first-experience-flow')),
          findsOneWidget,
        );
        expect(find.semantics.byLabel('Siguiente'), findsOne);
        final originalState = tester.state(find.byType(FirstExperienceScreen));
        final originalBoard = tester.element(_board);
        expect(_center.hitTestable(), findsNothing);
        expect(
          find.semantics.byLabel('Fila 5, columna 5, vacía'),
          findsNothing,
        );

        await _beginBlock(tester);
        expect(
          tester.state(find.byType(FirstExperienceScreen)),
          same(originalState),
        );
        expect(tester.element(_board), same(originalBoard));
        expect(
          find.semantics.byLabel('Fila 5, columna 5, vacía'),
          findsNothing,
        );
        expect(tester.widget<SudokuBoard>(_board).cells[40], isNotNull);
        expect(tester.widget<SudokuBoard>(_board).onSelect, isNull);
        await _exitWithDeveloperMenu(tester);
        expect(find.byType(FirstExperienceScreen), findsNothing);
        expect(find.byType(MapScreen), findsOneWidget);
        expect(repository.state.sessions, isEmpty);
        expect(repository.state.totalLights, 0);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'automatic random block survives leaving and reopening the save',
    (tester) async {
      final store = MemorySaveStore();
      var repository = await GameRepository.open(store);
      addTearDown(() => repository.dispose());
      _configure(tester);
      await _openFromHome(tester, repository);
      await _beginBlock(tester);
      final cells = List<int?>.of(tester.widget<SudokuBoard>(_board).cells);
      await _exitWithDeveloperMenu(tester);
      await tester.pumpWidget(const SizedBox());
      await repository.close();
      repository = await GameRepository.open(store);
      await _openFromHome(tester, repository);
      expect(tester.widget<SudokuBoard>(_board).cells, cells);
      expect(tester.widget<SudokuBoard>(_board).onSelect, isNull);
      expect(repository.state.sessions, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed welcome save stays visible and the same CTA retries', (
    tester,
  ) async {
    final store = _FailingStore();
    final repository = await GameRepository.open(store);
    addTearDown(repository.dispose);
    _configure(tester);
    await _showFlow(tester, repository);
    store.fail = true;
    await _beginBlock(tester);
    expect(find.textContaining('No pudimos guardar tu avance'), findsOneWidget);
    expect(_continue.hitTestable(), findsOneWidget);
    expect(_center.hitTestable(), findsNothing);
    expect(repository.state.modules, isEmpty);

    store.fail = false;
    await _beginBlock(tester);
    expect(find.textContaining('No pudimos guardar tu avance'), findsNothing);
    expect(tester.widget<SudokuBoard>(_board).cells.whereType<int>().length, 9);
    expect(tester.widget<SudokuBoard>(_board).onSelect, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'text scaling and failed advancement preserve the automatic block',
    (tester) async {
      final store = _FailingStore();
      final repository = await GameRepository.open(store);
      addTearDown(repository.dispose);
      _configure(tester);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _showFlow(tester, repository);
      await _beginBlock(tester);
      final element = tester.element(_board);
      final cells = List<int?>.of(tester.widget<SudokuBoard>(_board).cells);
      for (final scale in [2.0, 1.0]) {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await _settle(tester);
        expect(tester.element(_board), same(element));
        expect(tester.widget<SudokuBoard>(_board).cells, cells);
        expect(tester.takeException(), isNull);
      }
      store.fail = true;
      await _tap(tester, _startBlock);
      expect(
        find.textContaining('No pudimos guardar tu avance'),
        findsOneWidget,
      );
      expect(tester.widget<SudokuBoard>(_board).cells, cells);
      store.fail = false;
      await _tap(tester, _startBlock);
      expect(find.textContaining('No pudimos guardar tu avance'), findsNothing);
      expect(tester.element(_board), same(element));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tutorial action keeps one-line text and the same home button height',
    (tester) async {
      final repository = await GameRepository.open(MemorySaveStore());
      addTearDown(repository.dispose);
      _configure(tester);
      tester.view.padding = const FakeViewPadding(top: 44, bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 44, bottom: 24);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      Finder pressTarget(Finder control) =>
          find.descendant(of: control, matching: find.byType(JuicyPress));

      for (final size in [
        const Size(390, 844),
        const Size(393, 870),
        const Size(320, 568),
        const Size(844, 390),
      ]) {
        for (final scale in [1.0, 1.1, 2.0]) {
          tester.view.physicalSize = size;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          await tester.pumpWidget(
            MaterialApp(theme: buildSunDokuTheme(), home: const HomeScreen()),
          );
          await _settle(tester);
          final homeAction = pressTarget(
            find.byKey(const ValueKey('home-play')),
          );
          expect(homeAction, findsOneWidget);
          final homeSize = tester.getSize(homeAction);
          expect(tester.takeException(), isNull);

          await _showFlow(tester, repository);
          final tutorialAction = pressTarget(_continue);
          expect(tutorialAction, findsOneWidget);
          final tutorialSize = tester.getSize(tutorialAction);
          final scenario = '$size, text scale $scale';
          if (scale == 1) {
            expect(tutorialSize.height, homeSize.height, reason: scenario);
          }

          final label = find.descendant(
            of: _continue,
            matching: find.byType(Text),
          );
          expect(label, findsOneWidget);
          final text = tester.widget<Text>(label).data!;
          expect(text, isNot(contains('\n')), reason: scenario);
          if (scale <= 1.1) {
            expect(text, 'Siguiente', reason: scenario);
          }
          final paragraph = tester.renderObject<RenderParagraph>(label);
          expect(paragraph.didExceedMaxLines, false, reason: scenario);
          final glyphBoxes = paragraph.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: text.length),
          );
          expect(glyphBoxes, isNotEmpty);
          expect(
            glyphBoxes.every(
              (box) => (box.top - glyphBoxes.first.top).abs() < .01,
            ),
            true,
            reason: 'The label must render on one line: $scenario',
          );
          final actionRect = tester.getRect(tutorialAction);
          expect(actionRect.left, greaterThanOrEqualTo(0), reason: scenario);
          expect(
            actionRect.right,
            lessThanOrEqualTo(size.width),
            reason: scenario,
          );
          expect(
            size.height - 24 - actionRect.bottom,
            inInclusiveRange(0, 28),
            reason: scenario,
          );
          expect(
            tutorialAction.hitTestable(),
            findsOneWidget,
            reason: scenario,
          );
          expect(tester.takeException(), isNull, reason: scenario);
        }
      }
    },
  );

  testWidgets(
    'welcome action stays at the safe bottom while scaled content scrolls',
    (tester) async {
      final repository = await GameRepository.open(MemorySaveStore());
      addTearDown(repository.dispose);
      _configure(tester);
      tester.view.padding = const FakeViewPadding(top: 44, bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 44, bottom: 24);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _showFlow(tester, repository);

      for (final size in [
        const Size(390, 844),
        const Size(393, 870),
        const Size(320, 568),
        const Size(844, 390),
      ]) {
        for (final scale in [1.0, 1.1, 1.3, 2.0]) {
          tester.view.physicalSize = size;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          await _settle(tester);
          final scenario = '$size, text scale $scale';
          expect(tester.takeException(), isNull, reason: scenario);
          expect(_continue.hitTestable(), findsOneWidget, reason: scenario);
          final actionRect = tester.getRect(_continue);
          expect(actionRect.left, greaterThanOrEqualTo(0), reason: scenario);
          expect(
            actionRect.right,
            lessThanOrEqualTo(size.width),
            reason: scenario,
          );
          expect(
            size.height - 24 - actionRect.bottom,
            inInclusiveRange(0, 28),
            reason:
                'The yellow action must remain at the safe bottom: $scenario',
          );

          final scrollable = find.descendant(
            of: find.byKey(const ValueKey('first-experience-flow')),
            matching: find.byType(Scrollable),
          );
          expect(scrollable, findsOneWidget);
          final position = tester.state<ScrollableState>(scrollable).position;
          if (size == const Size(320, 568) && scale == 2) {
            expect(position.maxScrollExtent, greaterThan(0));
          }
          position.jumpTo(position.maxScrollExtent);
          await _settle(tester);
          expect(tester.getRect(_continue), actionRect, reason: scenario);
          expect(_continue.hitTestable(), findsOneWidget, reason: scenario);
          expect(tester.takeException(), isNull, reason: scenario);
          position.jumpTo(0);
          await _settle(tester);
          expect(tester.getRect(_continue), actionRect, reason: scenario);
        }
      }
    },
  );

  testWidgets(
    'large text keeps welcome and block controls reachable on rotation',
    (tester) async {
      final repository = await GameRepository.open(MemorySaveStore());
      addTearDown(repository.dispose);
      _configure(tester, size: const Size(320, 568));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _showFlow(tester, repository);
      final originalState = tester.state(find.byType(FirstExperienceScreen));
      final originalBoard = tester.element(_board);
      await _beginBlock(tester);
      for (final size in [const Size(320, 568), const Size(844, 390)]) {
        tester.view.physicalSize = size;
        await _settle(tester);
        expect(tester.takeException(), isNull);
        expect(_startBlock.hitTestable(), findsOneWidget);
        expect(
          tester.widget<SudokuBoard>(_board).cells.whereType<int>().length,
          9,
        );
        expect(tester.widget<SudokuBoard>(_board).onSelect, isNull);
        expect(
          tester.state(find.byType(FirstExperienceScreen)),
          same(originalState),
        );
        expect(tester.element(_board), same(originalBoard));
        expect(tester.takeException(), isNull);
      }
    },
  );
}
