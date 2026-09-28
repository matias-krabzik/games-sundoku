import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/domain/tutorial/tutorial_sudokus.dart';

const _center = [8, 3, 5, 4, 1, 6, 9, 2, 7];

Future<FirstExperienceController> _playing(
  GameRepository repo, {
  bool enabled = true,
}) async {
  await repo.startOrResumeLevel(
    mapLevelId(1),
    definitions: TutorialSudokus.create(_center),
    moduleKey: FirstExperienceController.moduleKey,
    moduleData: {
      'step': 'playing',
      'gameIndex': 0,
      'cells': _center,
      'briefingAccepted': true,
    },
  );
  final flow = FirstExperienceController(repo, notesEnabled: enabled);
  await flow.resumeGame();
  return flow;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'notes toggle rapidly, persist and cannot overwrite an answer',
    () async {
      final repo = GameRepository.memory();
      final flow = await _playing(repo);
      final index = flow.boardValues.indexOf(null);
      flow.selectGameCell(index);
      await flow.toggleNotesMode();
      final points = flow.points;
      await Future.wait([
        flow.placeGameNumber(2),
        flow.placeGameNumber(7),
        flow.placeGameNumber(2),
      ]);
      expect(flow.selectedNotes, [7]);
      expect(flow.boardValues[index], isNull);
      expect(flow.points, points);
      expect(flow.completion, isNull);
      await flow.pauseGame();
      await flow.placeGameNumber(3);
      expect(flow.selectedNotes, [7]);
      flow.dispose();
      await flow.flush();
      final reopened = FirstExperienceController(repo, notesEnabled: true);
      expect(reopened.notesMode, true);
      expect(reopened.gameCell, index);
      await reopened.resumeGame();
      await reopened.clearGameCell();
      expect(reopened.selectedNotes, isEmpty);
      await reopened.placeGameNumber(7);
      await reopened.toggleNotesMode();
      await reopened.placeGameNumber(
        reopened.puzzleDefinition!.solution[index],
      );
      expect(reopened.selectedNotes, isEmpty);
      final answer = reopened.boardValues[index];
      await reopened.toggleNotesMode();
      await reopened.placeGameNumber(2);
      expect(reopened.boardValues[index], answer);
      expect(reopened.playMessage, contains('casilla vacía'));
      reopened.dispose();
      await reopened.flush();
      await repo.close();
    },
  );

  test(
    'default play stays unchanged and DEV scopes the pencil to its level',
    () async {
      final repo = GameRepository.memory();
      final flow = await _playing(repo, enabled: false);
      expect(flow.notesAvailable, false);
      await flow.toggleNotesMode();
      expect(flow.notesMode, false);
      await flow.debugToggleNotes();
      expect(flow.notesAvailable, true);
      await flow.toggleNotesMode();
      expect(flow.notesMode, true);
      await flow.debugToggleNotes();
      expect(flow.notesAvailable, false);
      expect(flow.notesMode, false);
      final review = FirstExperienceController(
        repo,
        notesEnabled: true,
        reviewOnly: true,
      );
      expect(review.notesAvailable, false);
      review.dispose();
      flow.dispose();
      await flow.flush();
      await repo.close();
    },
  );
}
