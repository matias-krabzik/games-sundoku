import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/controllers/first_experience_controller.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/save_store.dart';

class _ControlledStore extends MemorySaveStore {
  bool failNext = false;
  Completer<void>? gate;
  Completer<void>? entered;

  @override
  Future<void> write(String data, {required int expectedRevision}) async {
    if (failNext) {
      failNext = false;
      throw const FileSystemException('Simulated full disk');
    }
    final waiting = gate;
    gate = null;
    if (waiting != null) {
      entered!.complete();
      await waiting.future;
    }
    await super.write(data, expectedRevision: expectedRevision);
  }
}

void main() {
  group('FirstExperienceController', () {
    test('successful placements choose random vacant cells without revisiting filled ones', () async {
      final repository = GameRepository.memory();
      addTearDown(repository.close);
      final controller = FirstExperienceController(
        repository,
        random: Random(21),
      );
      addTearDown(controller.dispose);
      await controller.begin();
      await controller.startBlock();
      controller.selectCell(0);
      final visited = <int>[];
      for (var digit = 1; digit <= 9; digit++) {
        final target = controller.selectedCell!;
        expect(controller.cells[target], isNull);
        expect(visited, isNot(contains(target)));
        visited.add(target);
        await controller.placeNumber(digit);
        expect(controller.cells[target], digit);
        if (digit < 9) {
          expect(controller.cells[controller.selectedCell!], isNull);
        }
      }
      expect(visited, isNot(orderedEquals(List.generate(9, (index) => index))));
      expect(
        controller.cells,
        unorderedEquals(List.generate(9, (index) => index + 1)),
      );
      final last = controller.selectedCell;
      await controller.placeNumber(9);
      expect(controller.selectedCell, last);
    });

    test('expansion requires a full block, retries failed saves and resumes in place', () async {
      final store = _ControlledStore();
      final repository = await GameRepository.open(store);
      addTearDown(repository.close);
      final controller = FirstExperienceController(repository);
      addTearDown(controller.dispose);
      await controller.begin();
      await controller.startBlock();
      await controller.expandBoard();
      expect(controller.step, FirstExperienceStep.block);
      const order = [8, 3, 5, 4, 1, 6, 9, 2, 7];
      for (var i = 0; i < 9; i++) {
        controller.selectCell(i);
        await controller.placeNumber(order[i]);
      }
      store.failNext = true;
      await controller.expandBoard();
      expect(controller.step, FirstExperienceStep.block);
      expect(controller.error, isNotEmpty);
      await controller.expandBoard();
      expect(controller.step, FirstExperienceStep.expansion);
      final resumed = FirstExperienceController(repository);
      addTearDown(resumed.dispose);
      expect(resumed.step, FirstExperienceStep.expansion);
      expect(resumed.cells, order);
      expect(repository.state.sessions, isEmpty);
      expect(repository.state.totalLights, 0);
    });
    test(
      'reopening resumes the block and preserves its chosen positions',
      () async {
        final store = MemorySaveStore();
        var repository = await GameRepository.open(store);
        var controller = FirstExperienceController(repository);
        expect(controller.step, FirstExperienceStep.welcome);
        expect(controller.cells, List<int?>.filled(9, null));
        expect(controller.selectedCell, isNull);
        expect(repository.state.modules, isEmpty);

        await controller.begin();
        await controller.startBlock();
        controller.selectCell(4);
        await controller.placeNumber(1);
        controller.selectCell(0);
        await controller.placeNumber(8);
        final savedRevision = repository.state.revision;
        controller.reviewWelcome();
        expect(controller.step, FirstExperienceStep.welcome);
        expect(controller.filledCount, 2);
        expect(repository.state.revision, savedRevision);
        await controller.begin();
        expect(controller.step, FirstExperienceStep.blockIntroduction);
        await controller.startBlock();
        expect(controller.step, FirstExperienceStep.block);
        expect(controller.cells, [
          8,
          null,
          null,
          null,
          1,
          null,
          null,
          null,
          null,
        ]);
        expect(repository.state.revision, savedRevision);

        controller.reviewWelcome();
        controller.dispose();
        await repository.close();
        repository = await GameRepository.open(store);
        controller = FirstExperienceController(repository);
        addTearDown(repository.close);
        addTearDown(controller.dispose);
        expect(controller.step, FirstExperienceStep.block);
        expect(controller.cells, [
          8,
          null,
          null,
          null,
          1,
          null,
          null,
          null,
          null,
        ]);
        expect(controller.selectedCell, isNull);
        expect(controller.filledCount, 2);
      },
    );

    test(
      'nine unique digits stay a draft without sessions or rewards',
      () async {
        final repository = await GameRepository.open(MemorySaveStore());
        addTearDown(repository.close);
        await repository.setPlayerName('Sol');
        await repository.updateSettings(sound: false);
        final playerBefore = repository.state.player.toJson();
        final settingsBefore = repository.state.settings.toJson();
        final controller = FirstExperienceController(repository);
        addTearDown(controller.dispose);
        await controller.begin();
        await controller.startBlock();
        const order = [8, 3, 5, 4, 1, 6, 9, 2, 7];
        for (var index = 0; index < 9; index++) {
          controller.selectCell(index);
          await controller.placeNumber(order[index]);
        }
        expect(controller.cells, order);
        expect(controller.filledCount, 9);
        expect(controller.step, FirstExperienceStep.block);
        expect(repository.state.sessions, isEmpty);
        expect(repository.state.progress, isEmpty);
        expect(repository.state.puzzles, isEmpty);
        expect(repository.state.totalLights, 0);
        expect(repository.state.player.toJson(), playerBefore);
        expect(repository.state.settings.toJson(), settingsBefore);

        final revision = repository.state.revision;
        controller.selectCell(0);
        await controller.placeNumber(3);
        expect(controller.cells, order);
        expect(repository.state.revision, revision);
        expect(controller.error, isNull);
        await controller.clearSelected();
        expect(controller.filledCount, 8);
        controller.selectCell(1);
        await controller.placeNumber(8);
        controller.selectCell(0);
        await controller.placeNumber(3);
        expect(controller.cells, [3, 8, 5, 4, 1, 6, 9, 2, 7]);
        expect(() => controller.cells[0] = 9, throwsUnsupportedError);
      },
    );

    test(
      'failed writes preserve the visible and stored state until retry',
      () async {
        final store = _ControlledStore();
        final repository = await GameRepository.open(store);
        addTearDown(repository.close);
        final controller = FirstExperienceController(repository);
        addTearDown(controller.dispose);

        store.failNext = true;
        await controller.begin();
        expect(controller.step, FirstExperienceStep.welcome);
        expect(controller.error, isNotEmpty);
        expect(controller.isBusy, false);
        expect(repository.state.modules, isEmpty);
        await controller.begin();
        expect(controller.step, FirstExperienceStep.blockIntroduction);
        controller.selectCell(0);
        await controller.placeNumber(1);
        expect(controller.filledCount, 0);
        final resumed = FirstExperienceController(repository);
        expect(resumed.step, FirstExperienceStep.blockIntroduction);
        resumed.dispose();
        store.failNext = true;
        await controller.startBlock();
        expect(controller.step, FirstExperienceStep.blockIntroduction);
        expect(controller.error, isNotEmpty);
        await controller.startBlock();
        expect(controller.step, FirstExperienceStep.block);
        expect(controller.error, isNull);

        controller.selectCell(2);
        final before = await store.read();
        store.failNext = true;
        await controller.placeNumber(5);
        expect(controller.cells[2], isNull);
        expect(controller.selectedCell, 2);
        expect(controller.error, isNotEmpty);
        expect(await store.read(), before);
        await controller.placeNumber(5);
        expect(controller.cells[2], 5);
        expect(controller.error, isNull);

        controller.selectCell(2);
        store.failNext = true;
        await controller.clearSelected();
        expect(controller.cells[2], 5);
        expect(controller.error, isNotEmpty);
        await controller.clearSelected();
        expect(controller.cells[2], isNull);
        expect(controller.error, isNull);
      },
    );

    test(
      'pending writes ignore duplicate actions and keep input on its cell',
      () async {
        final store = _ControlledStore();
        final repository = await GameRepository.open(store);
        addTearDown(repository.close);
        final controller = FirstExperienceController(repository);
        addTearDown(controller.dispose);
        final revision = repository.state.revision;
        var gate = store.gate = Completer<void>();
        var entered = store.entered = Completer<void>();
        final beginning = controller.begin();
        await entered.future;
        await controller.begin();
        expect(controller.isBusy, true);
        expect(controller.step, FirstExperienceStep.welcome);
        gate.complete();
        await beginning;
        expect(repository.state.revision, revision + 1);
        await controller.startBlock();

        controller.selectCell(0);
        gate = store.gate = Completer<void>();
        entered = store.entered = Completer<void>();
        final placing = controller.placeNumber(8);
        await entered.future;
        controller.selectCell(1);
        controller.reviewWelcome();
        await controller.placeNumber(3);
        await controller.clearSelected();
        expect(controller.selectedCell, 0);
        expect(controller.step, FirstExperienceStep.block);
        expect(controller.filledCount, 0);
        gate.complete();
        await placing;
        expect(controller.cells, [
          8,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
        ]);
        expect(repository.state.revision, revision + 3);
        expect(controller.isBusy, false);
      },
    );

    test(
      'edits preserve unknown module fields and unrelated modules',
      () async {
        final repository = await GameRepository.open(MemorySaveStore());
        addTearDown(repository.close);
        const key = FirstExperienceController.moduleKey;
        await repository.saveModule(key, {
          'step': 'welcome',
          'narration': {'enabled': true},
        });
        await repository.saveModule('story', {'scene': 4});
        final controller = FirstExperienceController(repository);
        addTearDown(controller.dispose);
        await controller.begin();
        await controller.startBlock();
        await repository.saveModule(key, {
          ...(repository.state.modules[key] as Map<String, Object?>),
          'futureStep': {'visited': false},
        });
        controller.selectCell(3);
        await controller.placeNumber(4);
        final module = repository.state.modules[key] as Map<String, Object?>;
        expect(module['narration'], {'enabled': true});
        expect(module['futureStep'], {'visited': false});
        expect(repository.state.modules['story'], {'scene': 4});
      },
    );

    test(
      'disposing during a write still saves without notifying disposed UI',
      () async {
        final store = _ControlledStore();
        final repository = await GameRepository.open(store);
        addTearDown(repository.close);
        final controller = FirstExperienceController(repository);
        final gate = store.gate = Completer<void>();
        final entered = store.entered = Completer<void>();
        final beginning = controller.begin();
        await entered.future;
        controller.dispose();
        gate.complete();
        await beginning;
        final reopened = FirstExperienceController(repository);
        addTearDown(reopened.dispose);
        expect(reopened.step, FirstExperienceStep.blockIntroduction);
      },
    );
  });
}
