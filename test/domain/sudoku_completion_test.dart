import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/domain/models/sudoku_completion.dart';

void main() {
  test(
    'every position reaches its entire row, column and block exactly once',
    () {
      for (var origin = 0; origin < 81; origin++) {
        final wave = SudokuCompletion.fromPosition(origin: origin);
        final expected = {
          for (var index = 0; index < 81; index++)
            if (index ~/ 9 == origin ~/ 9 ||
                index % 9 == origin % 9 ||
                (index ~/ 27 == origin ~/ 27 &&
                    index % 9 ~/ 3 == origin % 9 ~/ 3))
              index,
        };
        expect(wave.origin, origin);
        expect(wave.wholeBoard, false);
        expect(wave.cells, expected, reason: 'Origin $origin');
        expect(wave.cells.length, 21);
      }
    },
  );

  test('bottom positions include both lines and all nine block tiles', () {
    final middle = SudokuCompletion.fromPosition(origin: 67);
    expect(middle.cells, containsAll([63, 70, 57, 59, 75, 77, 4, 76]));
    final right = SudokuCompletion.fromPosition(origin: 70);
    expect(right.cells, containsAll([63, 71, 60, 62, 78, 80, 7, 79]));
    final corner = SudokuCompletion.fromPosition(origin: 75);
    expect(corner.cells, containsAll([72, 80, 57, 59, 76, 77, 3, 66]));
  });

  test('the board wave includes every position and keeps its origin', () {
    final wave = SudokuCompletion.fromPosition(origin: 80, wholeBoard: true);
    expect(wave.origin, 80);
    expect(wave.wholeBoard, true);
    expect(wave.cells, {for (var i = 0; i < 81; i++) i});
  });
}
