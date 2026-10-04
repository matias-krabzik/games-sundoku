import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/widgets/challenge_result_reveal.dart';
import 'package:sundoku/widgets/victory_particles.dart';

import 'support/challenge_repository.dart';
import 'world3_gameplay_widget_test.dart' as game;
import 'tutorial_journey_widget_test.dart' as scene;
import 'widgets/tutorial_presentation_test.dart' show frames;

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Baloo2',
    )..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final won in [true, false]) {
    testWidgets('record real result ${won ? "won" : "failed"}', (tester) async {
      scene.configure(tester, reduced: false);
      final repo = await challengeRepository(MemorySaveStore());
      final session = await repo.startGeneratedLevel(1, worldId: 'world-3');
      await game.showChallenge(tester, repo);
      await scene.tap(tester, find.byKey(const ValueKey('challenge-primary')));
      final flow = game.flowOf(tester);
      await flow.debugFillExceptOne();
      final puzzle = flow.puzzleDefinition!;
      final empty = flow.boardValues.indexOf(null);
      if (won) {
        flow.selectGameCell(empty);
        await flow.placeGameNumber(puzzle.solution[empty]);
      } else {
        await flow.pauseGame();
        await repo.addElapsed(
          session.id,
          puzzle.id,
          flow.challengeRules!.timeLimitMs,
        );
      }
      await tester.pump();
      final saved = repo.state.toJson();
      for (var frame = 0; frame <= 20; frame++) {
        if (Platform.environment['TUTORIAL_CAPTURE_DIR'] != null) {
          await scene.capture(
            tester,
            '${won ? "won" : "failed"}-frame-${frame.toString().padLeft(3, '0')}',
            settleAnimations: false,
          );
        }
        await frames(tester, 200);
      }
      expect(repo.state.toJson(), saved);
      expect(
        tester
            .state<ChallengeResultRevealState>(
              find.byType(ChallengeResultReveal),
            )
            .complete,
        true,
      );
      expect(find.byType(VictoryParticles), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    });
  }
}
