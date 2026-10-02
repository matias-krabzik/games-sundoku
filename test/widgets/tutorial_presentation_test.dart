import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/widgets/tutorial_activity.dart';
import 'package:sundoku/widgets/tutorial_presentation.dart';
import 'package:sundoku/widgets/tutorial_story.dart';

Future<void> frames(WidgetTester tester, int milliseconds) async {
  for (var i = 0; i < milliseconds; i += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

String writing(WidgetTester tester) {
  final span =
      tester
              .widget<Text>(
                find.byKey(
                  const ValueKey('intro-story-text'),
                  skipOffstage: false,
                ),
              )
              .textSpan!
          as TextSpan;
  return (span.children!.first as TextSpan).text!;
}

void main() {
  testWidgets('only a new scene repeats the entrance between steps', (
    tester,
  ) async {
    var step = 0;
    var scene = 'board';
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return TutorialPresentation(
              step: step,
              scene: scene,
              demonstrationDuration: const Duration(seconds: 1),
              builder: (context, presentation) => FadeTransition(
                opacity: presentation.entrance,
                child: const SizedBox.square(dimension: 100),
              ),
            );
          },
        ),
      ),
    );
    final state = tester.state<TutorialPresentationState>(
      find.byType(TutorialPresentation),
    );
    await frames(tester, 800);
    state.storyFinished();
    await frames(tester, 400);
    expect(state.demonstration.value, greaterThan(0));
    update(() => step++);
    await tester.pump();
    expect(state.entrance.value, 1);
    expect(state.storyVisible, isTrue);
    expect(state.demonstration.value, 0);
    await frames(tester, 400);
    expect(state.demonstration.value, 0);
    state.storyFinished();
    await frames(tester, 400);
    expect(state.demonstration.value, greaterThan(0));

    update(() => scene = 'another-layout');
    await tester.pump();
    expect(state.entrance.value, 0);
    expect(state.storyVisible, isFalse);
    expect(state.demonstration.value, 0);
    await frames(tester, 800);
    expect(state.entrance.value, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shared sequence pauses writing behind a route and in background', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    var step = 0;
    var advances = 0;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return Scaffold(
              body: TutorialActivity(
                child: TutorialPresentation(
                  step: step,
                  demonstrationDuration: const Duration(milliseconds: 1000),
                  readingPause: const Duration(milliseconds: 500),
                  onAdvance: () {
                    advances++;
                    update(() => step++);
                  },
                  builder: (context, presentation) => Column(
                    children: [
                      TutorialStepHeader(
                        index: step,
                        count: 10,
                        child: Text('Paso $step'),
                      ),
                      TutorialReveal(
                        visible: presentation.storyVisible,
                        child: TutorialStory(
                          lines: [
                            'Paso $step: esperamos a que termine la explicación antes de mostrar la acción.',
                          ],
                          tip: null,
                          interactive: false,
                          autoplay: presentation.storyVisible,
                          onFinished: presentation.storyFinished,
                        ),
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
    await frames(tester, 1400);
    final partial = writing(tester);
    expect(partial, isNotEmpty);
    expect(partial.length, lessThan(40));
    final state = tester.state<TutorialPresentationState>(
      find.byType(TutorialPresentation),
    );
    expect(state.demonstration.value, 0);
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Ajustes')),
      ),
    );
    await frames(tester, 500);
    final covered = writing(tester);
    await frames(tester, 6000);
    expect(writing(tester), covered);
    expect(advances, 0);
    navigator.currentState!.pop();
    await frames(tester, 600);
    expect(writing(tester).length, greaterThan(covered.length));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final paused = writing(tester);
    await frames(tester, 6000);
    expect(writing(tester), paused);
    expect(advances, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await frames(tester, 4300);
    expect(advances, 1);
    expect(step, 1);
    await tester.pumpWidget(const SizedBox());
    await frames(tester, 10000);
    expect(advances, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'changing steps during the reading pause cancels its old advance',
    (tester) async {
      var step = 0;
      var advances = 0;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: TutorialActivity(
                  child: TutorialPresentation(
                    step: step,
                    demonstrationDuration: const Duration(milliseconds: 100),
                    readingPause: const Duration(seconds: 1),
                    onAdvance: () => advances++,
                    builder: (context, presentation) => TutorialStory(
                      lines: ['$step'],
                      tip: null,
                      autoplay: presentation.storyVisible,
                      onFinished: presentation.storyFinished,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await frames(tester, 800);
      update(() => step = 1);
      await frames(tester, 800);
      expect(advances, 0);
      await frames(tester, 800);
      expect(advances, 1);
      await frames(tester, 4000);
      expect(advances, 1);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
