import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/data/repositories/game_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'help is read only and clears on selection, entry, pause, and restart',
    () async {
      final repo = GameRepository.memory();
      final flow = FirstExperienceController(repo);
      addTearDown(flow.dispose);
      addTearDown(repo.close);
      flow.showHelp();
      expect(flow.helpTip, isNull);
      while (flow.isStory) {
        await flow.advance();
      }
      await flow.debugFillExceptOne();
      final selected = flow.gameCell!;
      final board = [...flow.boardValues];
      final saved = repo.state;
      flow.showHelp();
      expect(flow.helpTip?.ruleId, 'last-empty-block');
      expect(flow.boardValues, board);
      expect(repo.state, same(saved));
      flow.dismissHelp();
      expect(flow.helpTip, isNull);
      flow.showHelp();
      flow.selectGameCell(flow.fixedIndices.first);
      expect(flow.helpTip, isNull);
      flow.showHelp();
      expect(flow.helpTip, isNull);
      expect(flow.canShowHelp, isFalse);
      flow.selectGameCell(selected);
      flow.showHelp();
      await flow.pauseGame();
      expect(flow.helpTip, isNull);
      await flow.resumeGame();
      expect(flow.helpTip, isNull);
      flow.showHelp();
      await flow.placeGameNumber(flow.puzzleDefinition!.solution[selected]);
      expect(flow.helpTip, isNull);
    },
  );
}
