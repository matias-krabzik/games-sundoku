// Isolated visual QA entrypoint. Uses only MemorySaveStore, never player storage.
// flutter run -t tool/validate_world3.dart -d <simulator>
import 'package:flutter/material.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/domain/tutorial/challenge_lesson.dart';
import 'package:sundoku/screens/first_experience_screen.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/game_feedback_scope.dart';

import '../test/support/challenge_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = await challengeRepository(MemorySaveStore());
  await repo.saveModule(ChallengeLesson.key, {
    'version': 1,
    'completed': true,
    'step': 3,
  });
  await repo.startGeneratedLevel(1, worldId: 'world-3');
  runApp(
    GameFeedbackHost(
      repository: repo,
      output: const GameFeedback(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildSunDokuTheme(),
        home: FirstExperienceScreen(
          repository: repo,
          worldId: 'world-3',
          levelNumber: 1,
          showDeveloperControls: true,
        ),
      ),
    ),
  );
}
