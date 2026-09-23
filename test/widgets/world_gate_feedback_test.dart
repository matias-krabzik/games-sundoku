import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/widgets/game_feedback_scope.dart';

class _FeedbackSpy extends GameFeedback {
  final sounds = <bool>[];
  int stops = 0;

  @override
  Future<void> worldGate(WorldGateSound cue, {required bool sound}) async {
    sounds.add(sound);
  }

  @override
  Future<void> stopWorldGate() async => stops++;
}

void main() {
  testWidgets('gate audio follows sound settings and foreground state', (
    tester,
  ) async {
    final repository = GameRepository.memory();
    final feedback = _FeedbackSpy();
    await tester.pumpWidget(
      GameFeedbackHost(
        repository: repository,
        output: feedback,
        child: const SizedBox(),
      ),
    );
    final scope = tester.widget<GameFeedbackScope>(
      find.byType(GameFeedbackScope),
    );
    scope.onWorldGate!(WorldGateSound.ignite);
    expect(feedback.sounds, [true]);
    await repository.updateSettings(sound: false);
    expect(feedback.stops, greaterThan(0));
    scope.onWorldGate!(WorldGateSound.sparkle);
    expect(feedback.sounds, [true, false]);
    await repository.updateSettings(sound: true);
    final stops = feedback.stops;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(feedback.stops, greaterThan(stops));
    scope.onWorldGate!(WorldGateSound.sparkle);
    expect(feedback.sounds.length, 2);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    scope.onWorldGate!(WorldGateSound.sparkle);
    expect(feedback.sounds.last, isTrue);
    expect(feedback.sounds.length, 3);
    await tester.pumpWidget(const SizedBox());
    repository.dispose();
  });
}
