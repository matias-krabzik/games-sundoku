import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/widgets/tutorial_story.dart';

final _story = find.byKey(const ValueKey('intro-story'));
final _text = find.byKey(const ValueKey('intro-story-text'));
final _tip = find.byKey(const ValueKey('intro-story-conclusion'));

String visibleText(WidgetTester tester) {
  final span = tester.widget<Text>(_text).textSpan! as TextSpan;
  return (span.children!.first as TextSpan).text!;
}

Future<void> show(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 350, child: TutorialStory())),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'writes progressively, then animates the tip without moving the card',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await show(tester);
        final card = tester.getRect(_story);
        expect(visibleText(tester), isEmpty);
        expect(tester.widget<Opacity>(_tip).opacity, 0);
        expect(
          find.semantics.byLabel(TutorialStory.semanticLabel),
          findsOneWidget,
        );
        await tester.pump(const Duration(milliseconds: 1000));
        final first = visibleText(tester);
        expect(first, startsWith('Antes'));
        expect(
          first.length,
          lessThan(TutorialStory.sentences.join('\n').length),
        );
        expect(tester.widget<Opacity>(_tip).opacity, 0);
        expect(tester.getRect(_story), card);
        await tester.pump(const Duration(milliseconds: 1000));
        expect(visibleText(tester).length, greaterThan(first.length));
        expect(tester.widget<Opacity>(_tip).opacity, 0);
        // Advance in small steps until all text is visible; the tip must wait.
        for (
          var frame = 0;
          frame < 200 &&
              visibleText(tester) != TutorialStory.sentences.join('\n');
          frame++
        ) {
          expect(tester.widget<Opacity>(_tip).opacity, 0);
          await tester.pump(const Duration(milliseconds: 32));
        }
        expect(visibleText(tester), TutorialStory.sentences.join('\n'));
        expect(tester.widget<Opacity>(_tip).opacity, 0);
        await tester.pump(const Duration(milliseconds: 350));
        expect(tester.widget<Opacity>(_tip).opacity, inExclusiveRange(0, 1));
        await tester.pumpAndSettle();
        expect(tester.widget<Opacity>(_tip).opacity, 1);
        expect(tester.getRect(_story), card);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('touch reveals the complete story and tip immediately', (
    tester,
  ) async {
    await show(tester);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(_story);
    await tester.pump();
    expect(visibleText(tester), TutorialStory.sentences.join('\n'));
    expect(tester.widget<Opacity>(_tip).opacity, 1);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reduced motion and accessible navigation show all copy immediately',
    (tester) async {
      for (final features in [
        const FakeAccessibilityFeatures(disableAnimations: true),
        const FakeAccessibilityFeatures(accessibleNavigation: true),
      ]) {
        tester.platformDispatcher.accessibilityFeaturesTestValue = features;
        await show(tester);
        expect(visibleText(tester), TutorialStory.sentences.join('\n'));
        expect(tester.widget<Opacity>(_tip).opacity, 1);
        await tester.pumpWidget(const SizedBox());
      }
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('leaving during typing disposes the animation', (tester) async {
    await show(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 8));
    expect(tester.takeException(), isNull);
  });
}
