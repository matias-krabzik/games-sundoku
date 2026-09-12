import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/widgets/tutorial_story_navigation.dart';

const _surface = ValueKey('story-surface');
final _story = find.byKey(_surface);

Future<void> show(
  WidgetTester tester, {
  VoidCallback? onNext,
  VoidCallback? onPrevious,
  bool enabled = true,
  Widget child = const Center(child: Text('Una fila va de lado a lado.')),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            height: 400,
            child: TutorialStoryGestures(
              key: _surface,
              enabled: enabled,
              onNext: onNext,
              onPrevious: onPrevious,
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('segments announce the current story without a timer', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var advances = 0;
      var returns = 0;
      await show(
        tester,
        onNext: () => advances++,
        onPrevious: () => returns++,
        child: const Column(
          children: [
            TutorialStoryProgress(index: 2, count: 6),
            Text('Una fila va de lado a lado.'),
          ],
        ),
      );
      expect(find.semantics.byLabel('Historia 3 de 6'), findsOneWidget);
      expect(
        find.semantics.byLabel('Una fila va de lado a lado.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(minutes: 1));
      expect(advances, 0);
      expect(find.semantics.byLabel('Historia 3 de 6'), findsOneWidget);
      final navigation = find.semantics.byLabel('Navegación de la historia');
      tester.semantics.customAction(
        navigation,
        const CustomSemanticsAction(label: 'Historia siguiente'),
      );
      tester.semantics.customAction(
        navigation,
        const CustomSemanticsAction(label: 'Historia anterior'),
      );
      expect(advances, 1);
      expect(returns, 1);
      await show(tester, enabled: false, onNext: () => advances++);
      expect(
        tester.getSemantics(_story).getSemanticsData().customSemanticsActionIds,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('left 28 percent goes back; remaining surface goes forward', (
    tester,
  ) async {
    var next = 0;
    var previous = 0;
    await show(tester, onNext: () => next++, onPrevious: () => previous++);
    final topLeft = tester.getTopLeft(_story);
    for (final x in [4.0, 88.0]) {
      await tester.tapAt(topLeft + Offset(x, 20));
    }
    for (final x in [90.0, 160.0, 316.0]) {
      await tester.tapAt(topLeft + Offset(x, 20));
    }
    expect(previous, 2);
    expect(next, 3);
    await tester.tapAt(topLeft - const Offset(15, 0));
    expect(next, 3);
    expect(previous, 2);
  });

  testWidgets('clear horizontal swipes navigate once; short drags do not', (
    tester,
  ) async {
    var next = 0;
    var previous = 0;
    await show(tester, onNext: () => next++, onPrevious: () => previous++);
    await tester.drag(_story, const Offset(-120, 5));
    expect(next, 1);
    expect(previous, 0);
    await tester.drag(_story, const Offset(120, -5));
    expect(previous, 1);
    await tester.drag(_story, const Offset(-35, 0));
    expect(next, 1);
    expect(previous, 1);
  });

  testWidgets('vertical scrolling and child buttons keep their own gestures', (
    tester,
  ) async {
    var next = 0;
    var previous = 0;
    var presses = 0;
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await show(
      tester,
      onNext: () => next++,
      onPrevious: () => previous++,
      child: SingleChildScrollView(
        controller: scroll,
        child: Column(
          children: [
            TextButton(
              onPressed: () => presses++,
              child: const Text('Escuchar otra vez'),
            ),
            const SizedBox(height: 1000),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Escuchar otra vez'));
    expect(presses, 1);
    expect(next, 0);
    await tester.drag(_story, const Offset(4, -220));
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(100));
    expect(next, 0);
    expect(previous, 0);
  });

  testWidgets('local keyboard shortcuts respect child focus and key repeats', (
    tester,
  ) async {
    var next = 0;
    var previous = 0;
    var presses = 0;
    final buttonFocus = FocusNode();
    addTearDown(buttonFocus.dispose);
    await show(
      tester,
      onNext: () => next++,
      onPrevious: () => previous++,
      child: Center(
        child: TextButton(
          focusNode: buttonFocus,
          onPressed: () => presses++,
          child: const Text('Escuchar otra vez'),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    expect(next, 2);
    expect(previous, 1);
    buttonFocus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(presses, 1);
    expect(next, 2);
    expect(buttonFocus.hasFocus, true);
  });

  testWidgets('disabled navigation and unavailable directions do nothing', (
    tester,
  ) async {
    var next = 0;
    var previous = 0;
    await show(tester, onNext: () => next++);
    await tester.tapAt(tester.getTopLeft(_story) + const Offset(20, 20));
    await tester.drag(_story, const Offset(120, 0));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(next, 0);

    await show(
      tester,
      enabled: false,
      onNext: () => next++,
      onPrevious: () => previous++,
    );
    await tester.tap(_story);
    await tester.drag(_story, const Offset(-120, 0));
    await tester.drag(_story, const Offset(120, 0));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(next, 0);
    expect(previous, 0);
    expect(tester.takeException(), isNull);
  });
}
