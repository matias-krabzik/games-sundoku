import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/widgets/score_feedback.dart';

void main() {
  testWidgets('reward floats up, fades, disappears and ignores pointer input', (
    tester,
  ) async {
    var taps = 0;
    Future<void> show(ScoreFeedback? feedback) => tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.square(
            dimension: 360,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => taps++,
                    child: const ColoredBox(color: Colors.white),
                  ),
                ),
                Positioned.fill(child: BoardScoreFeedback(feedback: feedback)),
              ],
            ),
          ),
        ),
      ),
    );
    await show(null);
    await show(const ScoreFeedback(1, 40, 53));
    await tester.pump(const Duration(milliseconds: 100));
    final label = find.text('+53');
    expect(label, findsOneWidget);
    final top = tester.getTopLeft(label).dy;
    final alpha = tester
        .widget<Opacity>(find.byKey(const ValueKey('score-popup')))
        .opacity;
    await tester.tapAt(tester.getCenter(label));
    expect(taps, 1);
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getTopLeft(label).dy, lessThan(top));
    expect(
      tester.widget<Opacity>(find.byKey(const ValueKey('score-popup'))).opacity,
      lessThan(alpha),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(label, findsNothing);
    await show(const ScoreFeedback(2, 40, -77));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('−77'), findsOneWidget);
  });

  testWidgets('reduced motion keeps score without floating effects', (
    tester,
  ) async {
    Future<void> show(ScoreFeedback? feedback) => tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Column(
            children: [
              const GameScoreCounter(points: 1231),
              SizedBox.square(
                dimension: 300,
                child: BoardScoreFeedback(feedback: feedback),
              ),
            ],
          ),
        ),
      ),
    );
    await show(null);
    await show(const ScoreFeedback(1, 40, 53));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('1.231 pts'), findsOneWidget);
    expect(find.text('+53'), findsNothing);
  });
}
