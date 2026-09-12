import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/widgets/sudoku_board.dart';

void main() {
  Widget board(bool centerOnly, {bool reduced = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Center(
        child: SizedBox.square(
          dimension: 360,
          child: SudokuBoard(
            cells: List<int?>.filled(81, null),
            centerOnly: centerOnly,
          ),
        ),
      ),
    ),
  );

  double opacity(WidgetTester tester, int index) => tester
      .widget<Opacity>(find.byKey(ValueKey('tile-arrival-$index')))
      .opacity;

  Widget lesson(
    SudokuBoardReveal reveal, {
    bool reduced = false,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Center(
        child: SizedBox.square(
          dimension: 360,
          child: SudokuBoard(
            cells: List<int?>.filled(81, null),
            reveal: reveal,
            highlightedIndices: switch (reveal) {
              SudokuBoardReveal.none => [30, 31, 32, 39, 40, 41, 48, 49, 50],
              SudokuBoardReveal.row => List.generate(9, (i) => 36 + i),
              SudokuBoardReveal.column => List.generate(9, (i) => i * 9 + 4),
              SudokuBoardReveal.remaining => [],
            },
          ),
        ),
      ),
    ),
  );

  double lessonOpacity(WidgetTester tester, int index) => tester
      .widget<Opacity>(find.byKey(ValueKey('lesson-tile-$index')))
      .opacity;

  testWidgets(
    'lesson tiles animate only the affected groups and reverse together',
    (tester) async {
      await tester.pumpWidget(lesson(SudokuBoardReveal.none));
      await tester.pumpAndSettle();
      final center = find.byKey(const ValueKey('sudoku-cell-40'));
      final position = tester.getRect(center);
      await tester.pumpWidget(lesson(SudokuBoardReveal.row));
      expect(lessonOpacity(tester, 36), 0);
      expect(find.byKey(const ValueKey('lesson-tile-0')), findsNothing);
      expect(find.byKey(const ValueKey('lesson-tile-40')), findsNothing);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('lesson-tile-36')), findsNothing);
      await tester.pumpWidget(lesson(SudokuBoardReveal.column));
      expect(lessonOpacity(tester, 36), 1);
      expect(lessonOpacity(tester, 4), 0);
      await tester.pump(const Duration(milliseconds: 400));
      expect(lessonOpacity(tester, 36), 0);
      expect(lessonOpacity(tester, 4), 1);
      expect(tester.getRect(center), position);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(lesson(SudokuBoardReveal.remaining));
      expect(lessonOpacity(tester, 0), 0);
      expect(find.byKey(const ValueKey('lesson-tile-36')), findsNothing);
      // The old column overlay leaves above the stationary board.
      expect(lessonOpacity(tester, 40), 1);
      expect(tester.getRect(center), position);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('lesson-tile-0')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('lesson changes respect reduced motion and rapid navigation', (
    tester,
  ) async {
    await tester.pumpWidget(lesson(SudokuBoardReveal.none, reduced: true));
    await tester.pumpWidget(lesson(SudokuBoardReveal.row, reduced: true));
    expect(find.byKey(const ValueKey('lesson-tile-36')), findsNothing);
    await tester.pumpWidget(lesson(SudokuBoardReveal.column));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(lesson(SudokuBoardReveal.remaining));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(lesson(SudokuBoardReveal.none));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('lesson-tile-0')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('center settles in one second before radial tile placement', (
    tester,
  ) async {
    await tester.pumpWidget(board(true));
    await tester.pumpAndSettle();
    final center = find.byKey(const ValueKey('sudoku-cell-40'));
    final original = tester.getSize(center).width;
    final element = tester.element(center);
    await tester.pumpWidget(board(false));
    expect(tester.element(center), same(element));
    expect(tester.getSize(center).width, original);
    expect(opacity(tester, 0), 0);
    await tester.pump(const Duration(milliseconds: 500));
    final halfway = tester.getSize(center).width;
    expect(halfway, lessThan(original));
    expect(opacity(tester, 22), 0);
    await tester.pump(const Duration(milliseconds: 500));
    final settled = tester.getRect(center);
    expect(settled.width, lessThan(halfway));
    expect(opacity(tester, 22), 0);
    await tester.pump(const Duration(milliseconds: 100));
    expect(opacity(tester, 22), greaterThan(0));
    expect(opacity(tester, 0), 0);
    expect(tester.getRect(center), settled);
    await tester.pump(const Duration(milliseconds: 400));
    for (var index = 0; index < 81; index++) {
      expect(opacity(tester, index), 1);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion and interrupted expansion finish safely', (
    tester,
  ) async {
    await tester.pumpWidget(board(true, reduced: true));
    await tester.pumpWidget(board(false, reduced: true));
    expect(opacity(tester, 0), 1);
    await tester.pumpWidget(board(true));
    await tester.pumpWidget(board(false));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(board(true));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sudoku-cell-0')), findsNothing);
    expect(opacity(tester, 40), 1);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
