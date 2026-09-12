import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/widgets/sudoku_board.dart';

void main() {
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
