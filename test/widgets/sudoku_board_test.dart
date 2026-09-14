import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/widgets/sudoku_board.dart';
import 'package:sundoku/widgets/sudoku_digit.dart';
import 'package:sundoku/widgets/ui_surface_art.dart';
import 'package:sundoku/domain/models/sudoku_completion.dart';

void main() {
  testWidgets(
    'selection highlights spread radially within 180ms and matches crossfade without jumps',
    (tester) async {
      final cells = List<int?>.filled(81, null)
        ..[0] = 1
        ..[80] = 1
        ..[8] = 2
        ..[72] = 2;
      int? selected;
      var reduced = false;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 360,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    update = setState;
                    return MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(disableAnimations: reduced),
                      child: SudokuBoard(
                        cells: cells,
                        selectedIndex: selected,
                        fixedIndices: {0, 8, 72, 80},
                        onSelect: (index) => setState(() => selected = index),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Finder cell(int index) => find.byKey(ValueKey('sudoku-cell-$index'));
      ColorFilter tint(int index) => tester
          .widget<ColorFiltered>(
            find.descendant(
              of: cell(index),
              matching: find.byType(ColorFiltered),
            ),
          )
          .colorFilter;
      double gold(int index) {
        final fade = find.byKey(ValueKey('sudoku-match-fade-$index'));
        return fade.evaluate().isEmpty
            ? 0
            : tester.widget<Opacity>(fade).opacity;
      }

      Finder digit(int index) =>
          find.descendant(of: cell(index), matching: find.byType(SudokuDigit));
      final neutral = {for (var i = 0; i < 81; i++) i: tint(i)};
      final matchingDigit = tester.element(digit(80));

      await tester.tap(cell(40));
      await tester.pump();
      expect(tint(39), neutral[39]);
      await tester.pump(const Duration(milliseconds: 25));
      expect(tint(39), isNot(neutral[39]));
      expect(tint(31), tint(39));
      expect(tint(30), neutral[30]);
      expect(tint(36), neutral[36]);
      await tester.pump(const Duration(milliseconds: 25));
      expect(tint(30), isNot(neutral[30]));
      expect(tint(36), neutral[36]);
      expect(tint(0), neutral[0]);
      await tester.pump(const Duration(milliseconds: 130));
      expect(
        tint(36),
        const ColorFilter.mode(Color(0xFFFFF0AD), BlendMode.modulate),
      );
      expect(tint(4), tint(36));
      expect(
        tint(30),
        const ColorFilter.mode(Color(0xFFCDDDC3), BlendMode.modulate),
      );

      await tester.tap(cell(0));
      await tester.pump();
      expect(gold(80), 0);
      await tester.pump(const Duration(milliseconds: 60));
      final fadingIn = gold(80);
      expect(fadingIn, inExclusiveRange(0, 1));
      final colorBeforeRetarget = tester.widget<SudokuDigit>(digit(0)).color;
      expect(colorBeforeRetarget, isNot(Colors.white));
      expect(tester.element(digit(80)), same(matchingDigit));

      await tester.tap(cell(8));
      await tester.pump();
      expect(gold(80), fadingIn);
      expect(tester.widget<SudokuDigit>(digit(0)).color, colorBeforeRetarget);
      await tester.pump(const Duration(milliseconds: 60));
      expect(gold(80), inExclusiveRange(0, fadingIn));
      expect(gold(72), inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 120));
      expect(gold(80), 0);
      expect(gold(72), 1);
      expect(tester.element(digit(80)), same(matchingDigit));

      update(() => cells[8] = null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(gold(72), inExclusiveRange(0, 1));
      update(() => reduced = true);
      await tester.pump();
      expect(gold(72), 0);
      await tester.tap(cell(0));
      await tester.pump();
      expect(gold(80), 1);
      expect(
        tint(18),
        const ColorFilter.mode(Color(0xFFFFF0AD), BlendMode.modulate),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'completion waves move radially, including both sides of the bottom block',
    (tester) async {
      SudokuCompletion? completion;
      var reduced = false;
      final finished = <SudokuCompletion>[];
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 360,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    update = setState;
                    return MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(disableAnimations: reduced),
                      child: SudokuBoard(
                        cells: List<int?>.filled(81, 1),
                        completion: completion,
                        onCompletionFinished: finished.add,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Offset motion(int index) {
        final matrix = tester
            .widget<Transform>(
              find.byKey(ValueKey('sudoku-completion-motion-$index')),
            )
            .transform;
        return Offset(matrix.storage[12], matrix.storage[13]);
      }

      double scale(int index) => tester
          .widget<Transform>(
            find.byKey(ValueKey('sudoku-completion-scale-$index')),
          )
          .transform
          .storage[0];

      update(
        () => completion = SudokuCompletion(
          origin: 30,
          cells: {30, 31, 32, 39, 40, 41, 48, 49, 50},
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(scale(30), greaterThan(1));
      expect(scale(31), 1);
      expect(scale(50), 1);
      expect(motion(29), Offset.zero);
      await tester.pump(const Duration(milliseconds: 85));
      expect(motion(31).dx, greaterThan(0));
      expect(motion(31).dy, 0);
      expect(motion(39).dy, closeTo(motion(31).dx, .0001));
      expect(scale(50), 1);
      await tester.pump(const Duration(milliseconds: 395));
      expect(finished, [completion]);
      expect(scale(30), 1);

      for (final cells in [
        {for (var c = 0; c < 9; c++) 36 + c},
        {for (var r = 0; r < 9; r++) r * 9 + 4},
      ]) {
        update(() => completion = SudokuCompletion(origin: 40, cells: cells));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 25));
        expect(scale(40), greaterThan(1));
        expect(motion(cells.first), Offset.zero);
        expect(motion(0), Offset.zero);
        await tester.pump(const Duration(milliseconds: 495));
        expect(scale(40), 1);
      }
      expect(finished.length, 3);

      update(() => completion = SudokuCompletion.fromPosition(origin: 67));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(motion(66).dx, lessThan(0));
      expect(motion(68).dx, greaterThan(0));
      expect(motion(66).dx, closeTo(-motion(68).dx, .0001));
      expect(motion(58).dy, closeTo(motion(66).dx, .0001));
      expect(motion(76).dy, closeTo(motion(68).dx, .0001));
      for (final index in [57, 58, 59, 66, 67, 68, 75, 76, 77]) {
        expect(
          scale(index),
          greaterThan(1),
          reason: 'Bottom block tile $index',
        );
      }
      await tester.pump(const Duration(milliseconds: 50));
      expect(motion(63).dx, lessThan(0));
      expect(motion(70).dx, greaterThan(0));
      expect(motion(49).dy, lessThan(0));
      expect(motion(62), Offset.zero);
      await tester.pump(const Duration(milliseconds: 370));
      expect(finished.length, 4);

      update(
        () => completion = SudokuCompletion(
          origin: 80,
          cells: {for (var i = 0; i < 81; i++) i},
          wholeBoard: true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(scale(80), greaterThan(1));
      expect(motion(70), Offset.zero);
      expect(motion(0), Offset.zero);
      await tester.pump(const Duration(milliseconds: 80));
      expect(motion(70).dx, lessThan(0));
      expect(motion(70).dy, lessThan(0));
      expect(motion(0), Offset.zero);
      await tester.pump(const Duration(milliseconds: 600));
      expect(motion(0).dx, lessThan(0));
      expect(motion(0).dy, lessThan(0));
      expect(scale(80), 1);
      expect(finished.length, 4);
      await tester.pump(const Duration(milliseconds: 200));
      expect(finished.length, 5);
      expect(motion(0), Offset.zero);
      update(() {});
      await tester.pump(const Duration(milliseconds: 100));
      expect(finished.length, 5);
      update(() => reduced = true);
      await tester.pump();
      update(() => completion = SudokuCompletion(origin: 40, cells: {40, 41}));
      await tester.pump();
      expect(scale(40), 1);
      expect(finished.length, 6);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'error buzz moves only the new wrong tile and respects reduced motion',
    (tester) async {
      final cells = List<int?>.filled(81, null)
        ..[11] = 1
        ..[14] = 1;
      var selected = 11;
      var errors = <int>{11};
      var pulse = 5;
      var reduced = false;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 360,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    update = setState;
                    return MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(disableAnimations: reduced),
                      child: SudokuBoard(
                        cells: cells,
                        selectedIndex: selected,
                        conflictIndices: errors,
                        errorPulse: pulse,
                        onSelect: (index) => setState(() => selected = index),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      double offset(int index) => tester
          .widget<Transform>(find.byKey(ValueKey('sudoku-error-buzz-$index')))
          .transform
          .storage[12];
      expect(offset(11), 0, reason: 'Saved errors must not buzz on opening');
      update(() => pulse++);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(offset(11), greaterThan(1));
      expect(offset(14), 0);
      await tester.pump(const Duration(milliseconds: 40));
      expect(offset(11), lessThan(-1));
      await tester.pump(const Duration(milliseconds: 400));
      expect(offset(11), 0);
      await tester.tap(find.byKey(const ValueKey('sudoku-cell-14')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('sudoku-cell-11')));
      await tester.pump(const Duration(milliseconds: 20));
      expect(offset(11), 0, reason: 'Selection does not replay an error');

      update(() => pulse++);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(offset(11), isNot(0));
      update(() {
        cells[11] = 3;
        errors = {};
      });
      await tester.pump();
      expect(offset(11), 0, reason: 'Correction stops an active buzz');
      update(() => reduced = true);
      await tester.pump();
      update(() {
        cells[11] = 1;
        errors = {11};
        pulse++;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(offset(11), 0);
      expect(find.text('1'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  setUpAll(() async {
    final font = FontLoader('Baloo2')
      ..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'));
    await font.load();
  });

  testWidgets(
    'selection overrides matches, lines override the selected block',
    (tester) async {
      final cells = <int?>[
        7,
        null,
        3,
        5,
        4,
        1,
        null,
        6,
        2,
        6,
        9,
        2,
        7,
        8,
        3,
        4,
        5,
        1,
        5,
        4,
        1,
        6,
        9,
        2,
        8,
        null,
        3,
        9,
        2,
        7,
        8,
        3,
        5,
        1,
        4,
        6,
        null,
        null,
        null,
        4,
        1,
        6,
        2,
        9,
        7,
        4,
        1,
        null,
        9,
        2,
        7,
        3,
        8,
        5,
        2,
        7,
        8,
        3,
        5,
        4,
        6,
        1,
        9,
        3,
        5,
        4,
        1,
        6,
        9,
        7,
        null,
        null,
        1,
        6,
        9,
        null,
        7,
        8,
        5,
        null,
        null,
      ];
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: boundaryKey,
                child: SizedBox.square(
                  dimension: 430,
                  child: SudokuBoard(
                    cells: cells,
                    selectedIndex: 40,
                    onSelect: (_) {},
                    fixedIndices: {
                      for (var i = 0; i < 81; i++)
                        if (cells[i] != null) i,
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Finder cell(int index) => find.byKey(ValueKey('sudoku-cell-$index'));
      ColorFilter tint(int index) => tester
          .widget<ColorFiltered>(
            find
                .descendant(
                  of: cell(index),
                  matching: find.byType(ColorFiltered),
                )
                .first,
          )
          .colorFilter;
      expect(
        tint(40),
        const ColorFilter.mode(Color(0xFFCB8A16), BlendMode.modulate),
      );
      expect(
        tint(30),
        const ColorFilter.mode(Color(0xFFCDDDC3), BlendMode.modulate),
      );
      expect(
        tint(31),
        const ColorFilter.mode(Color(0xFFFFF0AD), BlendMode.modulate),
      );
      expect(tint(39), tint(31));
      expect(tint(4), tint(31));
      expect(
        tint(33),
        const ColorFilter.mode(Colors.white, BlendMode.modulate),
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is UiSurfaceArt &&
              w.key.toString().contains('sudoku-matching-number-'),
        ),
        findsNWidgets(9),
      );
      expect(
        tester
            .widget<SudokuDigit>(
              find.descendant(of: cell(40), matching: find.byType(SudokuDigit)),
            )
            .color,
        Colors.white,
      );
      final directory = Platform.environment['TUTORIAL_CAPTURE_DIR'];
      if (directory != null) {
        await tester.runAsync(() async {
          for (final surface in [UiSurface.goldTile, UiSurface.creamTile]) {
            await precacheImage(
              AssetImage(surface.spec.asset),
              boundaryKey.currentContext!,
            );
          }
        });
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          await Directory(directory).create(recursive: true);
          await File('$directory/board-palette.png')
              .writeAsBytes(data!.buffer.asUint8List());
        });
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'central cells retain their global indices when the board expands',
    (tester) async {
      final cells = List<int?>.filled(81, null);
      var centerOnly = true;
      int? selected;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 300,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    update = setState;
                    return SudokuBoard(
                      cells: cells,
                      centerOnly: centerOnly,
                      selectedIndex: selected,
                      onSelect: (index) => setState(() {
                        selected = index;
                        cells[index] = 8;
                      }),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsNWidgets(9));
      expect(find.byKey(const ValueKey('sudoku-cell-0')), findsNothing);
      final middleRight = find.byKey(const ValueKey('sudoku-cell-41'));
      final originalElement = tester.element(middleRight);
      expect(tester.getSize(middleRight).width, greaterThanOrEqualTo(48));
      await tester.tap(middleRight);
      await tester.pump();
      expect(selected, 41);
      expect(cells[41], 8);
      expect(find.bySemanticsLabel('Fila 5, columna 6, 8'), findsOneWidget);

      update(() => centerOnly = false);
      await tester.pump();
      expect(find.byType(InkWell), findsNWidgets(81));
      expect(identical(tester.element(middleRight), originalElement), isTrue);
      expect(find.bySemanticsLabel('Fila 5, columna 6, 8'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.tap(find.byKey(const ValueKey('sudoku-cell-80')));
      await tester.pump();
      expect(selected, 80);
      expect(cells[41], 8);
      expect(cells[80], 8);
      expect(
        find.byKey(const ValueKey('sudoku-matching-number-41')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('sudoku-matching-number-80')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('sudoku-matching-number-0')),
        findsNothing,
      );
      // Selecting the bottom-right cell lights its row, column and block.
      for (final index in [72, 8, 60, 70, 79]) {
        expect(find.byKey(ValueKey('sudoku-peer-$index')), findsOneWidget);
      }
      for (final index in [0, 41, 59, 80]) {
        expect(find.byKey(ValueKey('sudoku-peer-$index')), findsNothing);
      }
      await tester.tap(find.byKey(const ValueKey('sudoku-cell-40')));
      await tester.pump();
      expect(find.byKey(const ValueKey('sudoku-peer-80')), findsNothing);
      expect(find.byKey(const ValueKey('sudoku-peer-30')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'keyboard selects cells and a board without onSelect is read only',
    (tester) async {
      final selected = <int>[];
      Widget board(ValueChanged<int>? onSelect) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox.square(
              dimension: 180,
              child: SudokuBoard(
                cells: List<int?>.filled(81, null),
                centerOnly: true,
                onSelect: onSelect,
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(board(selected.add));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, [30]);

      await tester.pumpWidget(board(null));
      final cell = find.byKey(const ValueKey('sudoku-cell-31'));
      await tester.tap(cell);
      await tester.pump();
      final control = tester.widget<InkWell>(
        find.descendant(of: cell, matching: find.byType(InkWell)),
      );
      expect(control.onTap, isNull);
      expect(control.canRequestFocus, isFalse);
      expect(selected, [30]);
      expect(tester.takeException(), isNull);
    },
  );
}
