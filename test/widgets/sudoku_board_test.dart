import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/widgets/sudoku_board.dart';
import 'package:sundoku/widgets/sudoku_digit.dart';
import 'package:sundoku/widgets/ui_surface_art.dart';

void main() {
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
