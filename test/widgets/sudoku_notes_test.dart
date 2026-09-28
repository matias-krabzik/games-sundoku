import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/domain/tutorial/tutorial_sudokus.dart';
import 'package:sundoku/screens/first_experience_screen.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/sudoku_board.dart';
import 'package:sundoku/widgets/sudoku_notes.dart';
import 'package:sundoku/widgets/ui_surface_art.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var n = 0; n < 15; n++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await _settle(tester);
  await tester.tap(target);
  await _settle(tester);
  expect(tester.takeException(), isNull);
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
    'mini notes have distinct stable positions even with enlarged text',
    (tester) async {
      for (final width in [28.0, 42.0, 80.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Center(
                child: SizedBox.square(
                  dimension: width,
                  child: SudokuNotes(
                    notes: List.generate(9, (index) => index + 1),
                  ),
                ),
              ),
            ),
          ),
        );
        final centers = [
          for (var n = 1; n <= 9; n++) tester.getCenter(find.text('$n')),
        ];
        expect(centers.toSet(), hasLength(9));
        expect(centers[0].dy, centers[2].dy);
        expect(centers[0].dx, centers[6].dx);
        expect(centers[8].dx, greaterThan(centers[0].dx));
        expect(centers[8].dy, greaterThan(centers[0].dy));
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'board exposes notes as notes and removes their grid for an answer',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final cells = List<int?>.filled(81, null);
      Widget screen() => MaterialApp(
        home: Center(
          child: SizedBox.square(
            dimension: 360,
            child: SudokuBoard(
              cells: List.of(cells),
              notes: const {
                0: [2, 7],
              },
              selectedIndex: 0,
              notesMode: true,
            ),
          ),
        ),
      );
      await tester.pumpWidget(screen());
      expect(find.byType(SudokuNotes), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp('Fila 1, columna 1, vacía, anotaciones 2 y 7'),
        ),
        findsOneWidget,
      );
      cells[0] = 2;
      await tester.pumpWidget(screen());
      expect(find.byType(SudokuNotes), findsNothing);
      expect(find.bySemanticsLabel(RegExp('anotaciones')), findsNothing);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'existing game gains DEV pencil, notes and erase without replacing its layout',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final repo = GameRepository.memory();
      const center = [8, 3, 5, 4, 1, 6, 9, 2, 7];
      final session = await repo.startOrResumeLevel(
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
      final captureKey = GlobalKey();
      Widget app({double scale = 1}) => RepaintBoundary(
        key: captureKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildSunDokuTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: FirstExperienceScreen(
            repository: repo,
            showDeveloperControls: true,
          ),
        ),
      );
      await tester.pumpWidget(app());
      await _settle(tester);
      expect(find.byKey(const ValueKey('game-notes')), findsNothing);
      await _tap(tester, find.byKey(const ValueKey('dev-floating-button')));
      await _tap(tester, find.byKey(const ValueKey('dev-notes')));
      expect(find.byKey(const ValueKey('game-notes')), findsOneWidget);
      final id = session.nextPuzzleId!;
      final index = repo.state.puzzles[id]!.initial.indexOf(null);
      await _tap(tester, find.byKey(ValueKey('sudoku-cell-$index')));
      await _tap(tester, find.byKey(const ValueKey('game-notes')));
      await _tap(tester, find.byKey(const ValueKey('intro-number-2')));
      await _tap(tester, find.byKey(const ValueKey('intro-number-7')));
      expect(
        repo.state.sessions[session.id]!.puzzles.first.cells[index].notes,
        [2, 7],
      );
      expect(find.text('Anotaciones: 2 y 7'), findsOneWidget);
      expect(find.byType(SudokuNotes), findsOneWidget);
      final boardElement = tester.element(
        find.byKey(const ValueKey('intro-board')),
      );

      for (final sample in [
        (name: 'notes-current-mobile', size: const Size(390, 844), scale: 1.0),
        (name: 'notes-current-tablet', size: const Size(1024, 768), scale: 1.0),
        (name: 'notes-current-small', size: const Size(320, 568), scale: 2.0),
        (
          name: 'notes-current-landscape',
          size: const Size(844, 390),
          scale: 2.0,
        ),
      ]) {
        tester.view.physicalSize = sample.size;
        await tester.pumpWidget(app(scale: sample.scale));
        await _settle(tester);
        expect(
          tester.element(find.byKey(const ValueKey('intro-board'))),
          same(boardElement),
        );
        expect(tester.takeException(), isNull);
        final directory = Platform.environment['NOTES_CAPTURE_DIR'];
        if (directory != null && sample.scale == 1) {
          await tester.runAsync(() async {
            for (final asset in {
              for (final surface in UiSurface.values) surface.spec.asset,
              'assets/images/home-background.png',
              'assets/images/tutorial/notes-pencil.png',
              'assets/images/tutorial/cleaning-brush.png',
              'assets/images/tutorial/lives-icons.png',
              'assets/images/map/icons.png',
              'assets/images/settings/icons.png',
            }) {
              await precacheImage(
                AssetImage(asset),
                captureKey.currentContext!,
              );
            }
          });
          await _settle(tester);
          await tester.runAsync(() async {
            final boundary =
                captureKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory(directory).create(recursive: true);
            await File('$directory/${sample.name}.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpWidget(app());
      await _settle(tester);
      await _tap(tester, find.byKey(const ValueKey('intro-clear')));
      expect(
        repo.state.sessions[session.id]!.puzzles.first.cells[index].notes,
        isEmpty,
      );
      expect(
        repo.state.sessions[session.id]!.puzzles.first.cells[index].value,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
      await repo.flush();
      await repo.close();
    },
  );
}
