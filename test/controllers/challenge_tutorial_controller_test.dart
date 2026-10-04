import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/controllers/challenge_tutorial_controller.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/domain/tutorial/challenge_lesson.dart';

import '../support/challenge_repository.dart';
import '../data/game_repository_test.dart' show FailingStore;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'progress restores; skip recognizes once without awarding anything',
    () async {
      final store = MemorySaveStore();
      var repo = await challengeRepository(store);
      final flow = ChallengeTutorialController(repo);
      final progress = repo.state.progress;
      await flow.next();
      await flow.next();
      expect(flow.step, 2);
      flow.dispose();
      await repo.close();
      repo = await GameRepository.open(store, enableWorld3Challenges: true);
      final restored = ChallengeTutorialController(repo);
      expect(restored.step, 2);
      await restored.skip();
      expect(repo.challengeTutorialCompleted, true);
      expect(repo.needsChallengeTutorial(1), false);
      expect(repo.state.sessions, isEmpty);
      expect(repo.state.progress.keys, progress.keys);
      restored.dispose();
      await repo.close();
    },
  );
  test(
    'failed acknowledgement stays pending; replay never changes saves',
    () async {
      final store = FailingStore();
      final repo = await challengeRepository(store);
      final session = await repo.startGeneratedLevel(1, worldId: 'world-3');
      final flow = ChallengeTutorialController(repo);
      store.failNext = true;
      expect(await flow.skip(), false);
      expect(flow.step, 0);
      expect(repo.challengeTutorialCompleted, false);
      expect(flow.error, isNotNull);
      final saved = repo.state.toJson();
      final replay = ChallengeTutorialController(repo, replay: true);
      for (var i = 0; i < 4; i++) {
        expect(await replay.next(), true);
      }
      await replay.skip();
      expect(repo.state.toJson(), saved);
      expect(repo.state.sessions[session.id]!.lights, 0);
      replay.dispose();
      flow.dispose();
      await repo.close();
    },
  );
  test('locked worlds cannot open lesson or replay', () async {
    final repo = GameRepository.memory();
    expect(() => ChallengeTutorialController(repo), throwsStateError);
    expect(
      () => ChallengeTutorialController(repo, replay: true),
      throwsStateError,
    );
    expect(repo.needsChallengeTutorial(1), false);
    await repo.close();
  });
  test(
    'deterministic demo uses actual scoring and threshold with one error',
    () {
      expect(
        ChallengeLesson.frameAt(0, .5).timeMs,
        ChallengeLesson.frameAt(0, 1).timeMs,
      );
      expect(ChallengeLesson.frameAt(0, 1).paused, true);
      expect(ChallengeLesson.frameAt(1, 1).points, greaterThan(0));
      expect(ChallengeLesson.frameAt(2, .6).lives, 2);
      expect(ChallengeLesson.frameAt(2, .6).error, true);
      final done = ChallengeLesson.frameAt(3, 1);
      expect(done.cells, ChallengeLesson.solution);
      expect(done.earned, true);
      expect(
        done.points,
        greaterThanOrEqualTo(ChallengeLesson.rules.targetPoints),
      );
      expect(ChallengeLesson.solved.mistakes, 1);
    },
  );
}
