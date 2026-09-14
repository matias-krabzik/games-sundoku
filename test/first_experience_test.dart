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
import 'package:sundoku/widgets/sudoku_board.dart';
import 'package:sundoku/widgets/tutorial_story.dart';
import 'package:sundoku/widgets/tutorial_story_navigation.dart';

final _continue = find.byKey(const ValueKey('intro-continue'));
final _startBlock = find.byKey(const ValueKey('tutorial-choose-order'));
final _back = find.byKey(const ValueKey('intro-back'));
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
  if (_startBlock.evaluate().isNotEmpty) {
    await _tap(tester, _startBlock);
  }
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
    Navigator.of(tester.element(find.byType(FirstExperienceScreen))).pop();
    await _settle(tester);
    expect(find.byType(MapScreen), findsOneWidget);
    final back = find.byKey(const ValueKey('map-back'));
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
    expect(
      tester
          .widget<FirstExperienceScreen>(find.byType(FirstExperienceScreen))
          .reviewOnly,
      true,
    );
    await _tap(tester, _continue);
    expect(_startBlock, findsNothing);
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

  testWidgets(
    'numbers sit between board and progress, then next expands the same chosen block',
    (tester) async {
      final repository = GameRepository.memory();
      addTearDown(repository.dispose);
      _configure(tester);
      await _showFlow(tester, repository);
      final boardElement = tester.element(_board);
      await _tap(tester, _continue);
      expect(
        find.textContaining('En un bloque van los números del 1 al 9.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('intro-number-tray')), findsNothing);
      expect(tester.widget<SudokuBoard>(_board).onSelect, isNull);
      expect(_startBlock.hitTestable(), findsOneWidget);
      expect(tester.element(_board), same(boardElement));
      final introductoryDraft =
          repository.state.modules[FirstExperienceController.moduleKey] as Map;
      expect(introductoryDraft['step'], 'blockIntroduction');
      await _tap(tester, _startBlock);
      final tray = find.byKey(const ValueKey('intro-number-tray'));
      final card = find.byKey(const ValueKey('intro-block-card'));
      final clear = find.byKey(const ValueKey('intro-clear'));
      for (final size in [
        const Size(390, 844),
        const Size(430, 932),
        const Size(844, 390),
      ]) {
        tester.view.physicalSize = size;
        await _settle(tester);
        final buttons = [
          for (var n = 1; n <= 9; n++)
            tester.getRect(find.byKey(ValueKey('intro-number-$n'))),
        ];
        for (var i = 0; i < 9; i++) {
          expect(buttons[i].top, closeTo(buttons[(i ~/ 3) * 3].top, .01));
          expect(buttons[i].left, closeTo(buttons[i % 3].left, .01));
        }
        expect(buttons[3].top, greaterThan(buttons[0].bottom));
        expect(
          tester.getRect(clear).right,
          lessThan(tester.getRect(_board).left),
        );
        final header = find.byKey(const ValueKey('intro-header'));
        final title = find.byKey(const ValueKey('intro-header-title'));
        expect(
          tester.getCenter(title).dx,
          closeTo(tester.getCenter(header).dx, .01),
        );
        expect(tester.getCenter(header).dx, closeTo(size.width / 2, .01));
        expect(
          find.descendant(of: clear, matching: find.byType(Text)),
          findsNothing,
        );
      }
      tester.view.physicalSize = const Size(390, 844);
      await _settle(tester);
      expect(
        tester.getRect(tray).top,
        greaterThan(tester.getRect(_board).bottom),
      );
      expect(
        tester.getRect(card).top,
        greaterThanOrEqualTo(tester.getRect(tray).bottom),
      );
      expect(find.byKey(const ValueKey('intro-next')), findsNothing);
      const order = [8, 3, 5, 4, 1, 6, 9, 2, 7];
      final expectedCells = List<int?>.filled(81, null);
      for (var i = 0; i < order.length; i++) {
        final target = tester.widget<SudokuBoard>(_board).selectedIndex!;
        expect(expectedCells[target], isNull);
        expectedCells[target] = order[i];
        final number = find.byKey(ValueKey('intro-number-${order[i]}'));
        await _tap(tester, number);
        expect(number, findsOneWidget);
        expect(tester.widget<JuicyPress>(number).onPressed, isNull);
        expect(find.text('${i + 1} de 9 colocados'), findsOneWidget);
        expect(
          tester
              .widget<FractionallySizedBox>(
                find.byKey(const ValueKey('intro-block-progress')),
              )
              .widthFactor,
          closeTo((i + 1) / 9, .001),
        );
        if (i < 8) {
          expect(find.byKey(const ValueKey('intro-next')), findsNothing);
        }
      }
      // The complete keypad stays visible and cannot place a digit again.
      for (var n = 1; n <= 9; n++) {
        final number = find.byKey(ValueKey('intro-number-$n'));
        expect(tester.widget<JuicyPress>(number).onPressed, isNull);
      }
      await _tap(tester, clear);
      final seven = find.byKey(const ValueKey('intro-number-7'));
      expect(tester.widget<JuicyPress>(seven).onPressed, isNotNull);
      expect(find.text('8 de 9 colocados'), findsOneWidget);
      expect(find.byKey(const ValueKey('intro-next')), findsNothing);
      await _tap(tester, seven);
      await _tap(tester, find.byKey(const ValueKey('intro-next')));
      expect(tester.element(_board), same(boardElement));
      expect(tester.widget<SudokuBoard>(_board).centerOnly, false);
      expect(find.byKey(const ValueKey('sudoku-cell-80')), findsOneWidget);
      final cells = tester.widget<SudokuBoard>(_board).cells;
      expect(
        [
          for (final i in [30, 31, 32, 39, 40, 41, 48, 49, 50]) cells[i],
        ],
        [
          for (final i in [30, 31, 32, 39, 40, 41, 48, 49, 50])
            expectedCells[i],
        ],
      );
      expect(repository.state.sessions, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Doku and the story animate while next remains available without waiting',
    (tester) async {
      final repository = GameRepository.memory();
      addTearDown(repository.dispose);
      _configure(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildSunDokuTheme(),
          home: FirstExperienceScreen(
            repository: repository,
            showDeveloperControls: false,
          ),
        ),
      );
      final story = find.byKey(const ValueKey('intro-story-text'));
      final tip = find.byKey(const ValueKey('intro-story-conclusion'));
      String visibleText() =>
          ((tester.widget<Text>(story).textSpan! as TextSpan).children!.first
                  as TextSpan)
              .text!;
      Future<void> advance(int milliseconds) async {
        for (var time = 0; time < milliseconds; time += 50) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      expect(visibleText(), isEmpty);
      expect(_continue.hitTestable(), findsOneWidget);
      await advance(300);
      final doku = tester.widget<FadeTransition>(
        find.byKey(const ValueKey('intro-doku-entrance')),
      );
      expect(doku.opacity.value, inExclusiveRange(0, 1));
      expect(visibleText(), isEmpty);
      expect(
        find.byKey(const ValueKey('intro-story')).hitTestable(),
        findsNothing,
      );
      await advance(1200);
      expect(doku.opacity.value, 1);
      expect(visibleText(), startsWith('Antes'));
      expect(tester.widget<Opacity>(tip).opacity, 0);
      expect(_continue.hitTestable(), findsOneWidget);
      await advance(3500);
      expect(visibleText(), TutorialStory.sentences.join('\n'));
      expect(tester.widget<Opacity>(tip).opacity, inExclusiveRange(0, 1));
      expect(_continue.hitTestable(), findsOneWidget);
      await advance(1000);
      expect(tester.widget<Opacity>(tip).opacity, 1);
      expect(_continue.hitTestable(), findsOneWidget);
      await _tap(tester, _continue);
      expect(find.byKey(const ValueKey('intro-number-tray')), findsNothing);
      expect(find.text('Un bloque, 9 casillas'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('tutorial-next')).hitTestable(),
        findsOneWidget,
      );
      expect(_startBlock.hitTestable(), findsOneWidget);
      await _tap(tester, _startBlock);
      expect(find.text('Empecemos con 9 casillas'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the optional editor can return to stories with a partial draft intact',
    (tester) async {
      final repository = GameRepository.memory();
      addTearDown(repository.dispose);
      _configure(tester);
      await _showFlow(tester, repository);
      await _beginBlock(tester);
      await _tap(tester, _center);
      await _tap(tester, find.byKey(const ValueKey('intro-number-9')));
      await _tap(tester, find.byKey(const ValueKey('tutorial-return-story')));
      expect(find.text('Un bloque, 9 casillas'), findsOneWidget);
      expect(tester.widget<SudokuBoard>(_board).onSelect, isNull);
      final draft =
          repository.state.modules[FirstExperienceController.moduleKey] as Map;
      expect((draft['cells'] as List).whereType<int>(), [9]);
      await _tap(tester, find.byKey(const ValueKey('tutorial-next')));
      expect(find.text('El tablero completo'), findsOneWidget);
      expect(tester.widget<SudokuBoard>(_board).cells[40], 9);
      expect(repository.state.sessions, isEmpty);
    },
  );

  testWidgets(
    'returning to the welcome shows its full text without another wait',
    (tester) async {
      final repository = GameRepository.memory();
      addTearDown(repository.dispose);
      _configure(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await _showFlow(tester, repository);
      await _tap(tester, _continue);
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
    'player layout has no back control; development exposes a labeled helper',
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
      expect(_back, findsNothing);
      expect(find.text('DEV · Volver'), findsNothing);
      expect(find.text('Tu primer sudoku'), findsOneWidget);
      await _beginBlock(tester);
      expect(_back, findsNothing);
      expect(find.text('Empecemos con 9 casillas'), findsOneWidget);
      await _showFlow(tester, repository);
      expect(_back, findsOneWidget);
      expect(find.text('DEV · Volver'), findsOneWidget);
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
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('intro-number-1')).hitTestable(),
          findsOneWidget,
        );
        await _tap(tester, _back);
        expect(
          tester.state(find.byType(FirstExperienceScreen)),
          same(originalState),
        );
        expect(tester.element(_board), same(originalBoard));
        expect(find.semantics.byLabel('Siguiente'), findsOne);
        expect(
          find.semantics.byLabel('Fila 5, columna 5, vacía'),
          findsNothing,
        );
        await _tap(tester, _back);
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
    'a chosen central number survives leaving and reopening the save',
    (tester) async {
      final store = MemorySaveStore();
      var repository = await GameRepository.open(store);
      addTearDown(() => repository.dispose());
      _configure(tester);
      await _openFromHome(tester, repository);
      await _beginBlock(tester);
      await _tap(tester, _center);
      await _tap(tester, find.byKey(const ValueKey('intro-number-1')));
      expect(tester.widget<SudokuBoard>(_board).cells[40], 1);
      final draft =
          repository.state.modules[FirstExperienceController.moduleKey]
              as Map<String, Object?>;
      expect((draft['cells'] as List)[4], 1);

      await _tap(tester, _back);
      await _tap(tester, _back);
      await tester.pumpWidget(const SizedBox());
      await repository.close();
      repository = await GameRepository.open(store);
      await _openFromHome(tester, repository);
      expect(tester.widget<SudokuBoard>(_board).cells[40], 1);
      await _tap(tester, _center);
      await _tap(tester, find.byKey(const ValueKey('intro-clear')));
      expect(tester.widget<SudokuBoard>(_board).cells[40], isNull);
      expect(repository.state.sessions, isEmpty);
      expect(repository.state.totalLights, 0);
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
    expect(
      find.byKey(const ValueKey('intro-number-1')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'text scaling and save errors retain the mounted board and selected value',
    (tester) async {
      final store = _FailingStore();
      final repository = await GameRepository.open(store);
      addTearDown(repository.dispose);
      _configure(tester);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _showFlow(tester, repository);
      await _beginBlock(tester);
      await _tap(tester, _center);
      await _tap(tester, find.byKey(const ValueKey('intro-number-1')));
      await _tap(tester, _center);
      final originalState = tester.state(find.byType(FirstExperienceScreen));
      final originalBoard = tester.element(_board);
      final originalCell = tester.element(_center);

      void expectRetainedBoard() {
        expect(
          tester.state(find.byType(FirstExperienceScreen)),
          same(originalState),
        );
        expect(tester.element(_board), same(originalBoard));
        expect(tester.element(_center), same(originalCell));
        expect(tester.widget<SudokuBoard>(_board).cells[40], 1);
        expect(tester.widget<SudokuBoard>(_board).selectedIndex, 40);
        expect(tester.takeException(), isNull);
      }

      tester.platformDispatcher.textScaleFactorTestValue = 2;
      await _settle(tester);
      expectRetainedBoard();
      tester.platformDispatcher.textScaleFactorTestValue = 1;
      await _settle(tester);
      expectRetainedBoard();

      store.fail = true;
      await _tap(tester, find.byKey(const ValueKey('intro-clear')));
      expect(
        find.textContaining('No pudimos guardar tu avance'),
        findsOneWidget,
      );
      expectRetainedBoard();
      final draft =
          repository.state.modules[FirstExperienceController.moduleKey]
              as Map<String, Object?>;
      expect((draft['cells'] as List)[4], 1);

      store.fail = false;
      await _tap(tester, find.byKey(const ValueKey('intro-clear')));
      expect(find.textContaining('No pudimos guardar tu avance'), findsNothing);
      expect(tester.element(_board), same(originalBoard));
      expect(tester.element(_center), same(originalCell));
      expect(tester.widget<SudokuBoard>(_board).cells[40], isNull);
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
      for (final size in [const Size(320, 568), const Size(844, 390)]) {
        tester.view.physicalSize = size;
        await _settle(tester);
        expect(tester.takeException(), isNull);
        await _beginBlock(tester);
        await _tap(tester, _center);
        await _tap(tester, find.byKey(const ValueKey('intro-number-1')));
        expect(tester.widget<SudokuBoard>(_board).cells[40], 1);
        await _tap(tester, _center);
        await _tap(tester, find.byKey(const ValueKey('intro-clear')));
        await _tap(tester, _back);
        expect(
          tester.state(find.byType(FirstExperienceScreen)),
          same(originalState),
        );
        expect(tester.element(_board), same(originalBoard));
        await tester.ensureVisible(_continue);
        await _settle(tester);
        expect(_continue.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
