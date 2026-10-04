import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/challenge_result_reveal.dart';
import 'package:sundoku/widgets/challenge_award.dart';
import 'package:sundoku/widgets/game_feedback_scope.dart';
import 'package:sundoku/widgets/illustrated_action_button.dart';
import 'package:sundoku/widgets/tutorial_activity.dart';
import 'package:sundoku/widgets/victory_particles.dart';

import 'tutorial_presentation_test.dart' show frames;

void main() {
  int sounds = 0, transitions = 0;
  Future<void> show(
    WidgetTester tester, {
    int points = 1200,
    int target = 1000,
    bool won = true,
    bool animate = true,
    bool reduced = false,
    bool accessible = false,
  }) async {
    sounds = transitions = 0;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(
          disableAnimations: reduced,
          accessibleNavigation: accessible,
        );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildSunDokuTheme(),
        home: GameFeedbackScope(
          onTap: () {},
          onLevelCompleted: () {
            sounds++;
          },
          child: Scaffold(
            body: TutorialActivity(
              child: ChallengeResultReveal(
                points: points,
                target: target,
                won: won,
                animate: animate,
                builder: (context, reveal) => Center(
                  child: SizedBox(
                    width: 320,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ChallengeAward(
                          stars: 2 + (reveal.earned ? 1 : 0),
                          points: reveal.points,
                          target: target,
                          ceiling: points > 1500 ? points : 1500,
                          pulseIndex: 2,
                          pulseScale: reveal.pulse,
                        ),
                        IllustratedActionButton(
                          key: const ValueKey('action'),
                          label: reveal.complete
                              ? 'Continuar'
                              : 'Mostrar resultado',
                          onPressed: reveal.complete
                              ? () {
                                  transitions++;
                                }
                              : reveal.finish,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  ChallengeResultRevealState state(WidgetTester tester) =>
      tester.state(find.byType(ChallengeResultReveal));
  testWidgets(
    'monotonic count, fixed threshold, one sound and only new star pulses',
    (tester) async {
      await show(tester);
      var last = 0;
      var earned = false;
      final marker = tester.getCenter(
        find.byKey(const ValueKey('challenge-score-threshold')),
      );
      for (var i = 0; i < 32; i++) {
        await frames(tester, 50);
        final reveal = state(tester);
        expect(reveal.points, greaterThanOrEqualTo(last));
        last = reveal.points;
        expect(
          tester.getCenter(
            find.byKey(const ValueKey('challenge-score-threshold')),
          ),
          marker,
        );
        expect(
          tester.widget<ChallengeAward>(find.byType(ChallengeAward)).stars,
          reveal.earned ? 3 : 2,
        );
        if (reveal.points >= 1000) earned = true;
        expect(sounds, earned ? 1 : 0);
        expect(
          tester
              .widget<Transform>(find.byKey(const ValueKey('challenge-star-0')))
              .transform
              .getMaxScaleOnAxis(),
          1,
        );
      }
      expect(last, 1200);
      expect(state(tester).complete, true);
      await frames(tester, 1500);
      expect(find.byType(VictoryParticles), findsNothing);
      expect(sounds, 1);
    },
  );
  testWidgets('exact target waits for the final count frame', (tester) async {
    await show(tester, points: 1000);
    await frames(tester, 1450);
    expect(state(tester).earned, false);
    expect(sounds, 0);
    await frames(tester, 100);
    expect(state(tester).earned, true);
    expect(sounds, 1);
  });
  testWidgets(
    'exact threshold lights at end; first action reveals, second advances',
    (tester) async {
      await show(tester, points: 1000);
      await frames(tester, 300);
      expect(state(tester).earned, false);
      await tester.tap(find.byKey(const ValueKey('action')));
      await frames(tester, 600);
      expect(state(tester).points, 1000);
      expect(state(tester).earned, true);
      expect(transitions, 0);
      expect(sounds, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await frames(tester, 600);
      expect(transitions, 1);
    },
  );
  testWidgets('press near end cannot turn reveal into continue mid-press', (
    tester,
  ) async {
    await show(tester);
    await frames(tester, 1250);
    expect(state(tester).complete, false);
    await tester.tap(find.byKey(const ValueKey('action')));
    await frames(tester, 600);
    expect(state(tester).complete, true);
    expect(transitions, 0);
  });
  for (final points in [0, 900, 1000000]) {
    testWidgets(
      'failed result $points never earns or celebrates even above threshold',
      (tester) async {
        await show(tester, points: points, won: false);
        await frames(tester, 1800);
        expect(state(tester).points, points);
        expect(state(tester).earned, false);
        expect(state(tester).complete, true);
        expect(sounds, 0);
        expect(find.byType(VictoryParticles), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'pause freezes count, resize preserves it, resumption sounds once',
    (tester) async {
      await show(tester);
      await frames(tester, 200);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final before = state(tester).points;
      await frames(tester, 3000);
      expect(state(tester).points, before);
      tester.view.physicalSize = const Size(1000, 700);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pump();
      expect(state(tester).points, before);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await frames(tester, 1800);
      expect(sounds, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await frames(tester, 300);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await frames(tester, 1800);
      expect(sounds, 1);
    },
  );
  testWidgets('accessible navigation reveals without waiting or celebration', (
    tester,
  ) async {
    await show(tester, accessible: true);
    await tester.pump();
    expect(state(tester).complete, true);
    expect(state(tester).earned, true);
    expect(sounds, 0);
  });
  for (final reduced in [false, true]) {
    testWidgets(
      'restored/reduced result completes without sound: reduced=$reduced',
      (tester) async {
        await show(tester, animate: reduced, reduced: reduced);
        await tester.pump();
        expect(state(tester).complete, true);
        expect(state(tester).earned, true);
        expect(sounds, 0);
        expect(find.byType(VictoryParticles), findsNothing);
      },
    );
  }
}
