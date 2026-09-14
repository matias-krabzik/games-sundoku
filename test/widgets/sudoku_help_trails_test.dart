import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/domain/help/sudoku_help_motion.dart';
import 'package:sundoku/widgets/sudoku_help_trails.dart';

void main() {
  testWidgets(
    'trails finish, survive equivalent rebuilds, and cancel on close',
    (tester) async {
      var open = true;
      var target = 8;
      var reduced = false;
      var extent = 30.0;
      var taps = 0;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(disableAnimations: reduced),
                child: Center(
                  child: SizedBox.square(
                    dimension: extent * 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => taps++,
                        ),
                        SudokuHelpTrails(
                          traces: open ? [connectHelpCells(0, target)] : [],
                          arrivalIndex: open ? target : null,
                          centers: [
                            for (var i = 0; i < 81; i++)
                              Offset(
                                (i % 9 + .5) * extent,
                                (i ~/ 9 + .5) * extent,
                              ),
                          ],
                          cellExtent: extent,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      SudokuHelpTrailPainter painter() =>
          tester
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('help-trails-paint')),
                  )
                  .painter!
              as SudokuHelpTrailPainter;
      await tester.pump(const Duration(milliseconds: 450));
      final progress = painter().progress.value;
      expect(progress, inExclusiveRange(0, 1));
      await tester.tapAt(tester.getCenter(find.byType(SudokuHelpTrails)));
      expect(taps, 1);
      update(() => extent = 32);
      await tester.pump();
      expect(painter().progress.value, greaterThanOrEqualTo(progress));
      await tester.pumpAndSettle();
      expect(painter().progress.value, 1);
      update(() {});
      await tester.pump();
      expect(painter().progress.value, 1);
      update(() => target = 7);
      await tester.pump();
      expect(painter().progress.value, 0);
      await tester.pump(const Duration(milliseconds: 250));
      update(() => open = false);
      await tester.pumpAndSettle();
      expect(painter().progress.value, 1);
      expect(painter().traces, isEmpty);
      update(() {
        open = true;
        reduced = true;
      });
      await tester.pumpAndSettle();
      expect(painter().progress.value, 1);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );
}
