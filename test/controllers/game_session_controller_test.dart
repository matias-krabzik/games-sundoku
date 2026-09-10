import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/controllers/game_session_controller.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/save_store.dart';
import 'package:sundoku/domain/models/game_session.dart';

import '../fixtures.dart';

class DelayedStore extends MemorySaveStore {
  Completer<void>? gate;
  Completer<void>? entered;

  @override
  Future<void> write(String data, {required int expectedRevision}) async {
    final waiting = gate;
    gate = null;
    if (waiting != null) {
      entered!.complete();
      await waiting.future;
    }
    await super.write(data, expectedRevision: expectedRevision);
  }
}

class TestClock implements Stopwatch {
  int time = 0;
  @override
  bool isRunning = false;
  void advance(int ms) {
    if (isRunning) time += ms;
  }

  @override
  int get elapsedMilliseconds => time;
  @override
  Duration get elapsed => Duration(milliseconds: time);
  @override
  int get elapsedMicroseconds => time * 1000;
  @override
  int get elapsedTicks => time;
  @override
  int get frequency => 1000;
  @override
  void reset() {
    time = 0;
  }

  @override
  void start() {
    isRunning = true;
  }

  @override
  void stop() {
    isRunning = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('backgrounding during a failed checkpoint retains time and resumes correctly', () async {
    final store = DelayedStore();
    final repo = await GameRepository.open(store);
    await repo.registerPuzzles(mapLevelId(1), levelPuzzles());
    final session = await repo.startOrResumeLevel(mapLevelId(1));
    final clock = TestClock();
    final controller = GameSessionController(repo, clock: clock);
    await controller.start(session.id);
    clock.advance(1000);
    final gate = store.gate = Completer<void>();
    final entered = store.entered = Completer<void>();
    final input = controller.setCell(0, 1);
    final expectedFailure = expectLater(
      input,
      throwsA(isA<FileSystemException>()),
    );
    await entered.future;
    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    gate.completeError(const FileSystemException('Disk full'));
    await expectedFailure;
    await controller.flush();
    expect(repo.state.sessions[session.id]!.elapsedMs, 1000);
    expect(
      repo.state.sessions[session.id]!.puzzles.first.cells.first.value,
      isNull,
    );
    expect(controller.isRunning, false);
    clock.advance(10000);
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await controller.flush();
    expect(controller.isRunning, true);
    clock.advance(500);
    await controller.pause();
    expect(repo.state.sessions[session.id]!.elapsedMs, 1500);
    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await controller.flush();
    expect(controller.isRunning, false); // an explicit pause must stay paused
    controller.dispose();
    await controller.flush();
    await repo.close();
  });

  test(
    'time checkpoints survive pause, exclude background and stop on completion',
    () async {
      final repo = GameRepository.memory();
      await repo.registerPuzzles(mapLevelId(1), levelPuzzles());
      final session = await repo.startOrResumeLevel(mapLevelId(1));
      final clock = TestClock();
      final controller = GameSessionController(repo, clock: clock);
      await controller.start(session.id);
      clock.advance(2500);
      await controller.checkpoint();
      await controller.checkpoint();
      expect(repo.state.sessions[session.id]!.elapsedMs, 2500);
      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      clock.advance(10000);
      await controller.flush();
      expect(controller.isRunning, false);
      expect(repo.state.sessions[session.id]!.elapsedMs, 2500);
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await controller.flush();
      clock.advance(1500);
      await controller.setCell(0, 1);
      clock.advance(1000);
      await controller.setCell(1, 2);
      expect(controller.isRunning, false);
      expect(repo.state.sessions[session.id]!.puzzles.first.elapsedMs, 5000);
      expect(
        repo.state.sessions[session.id]!.puzzles.first.status,
        PlayStatus.completed,
      );
      clock.advance(10000);
      await controller.checkpoint();
      expect(repo.state.sessions[session.id]!.elapsedMs, 5000);
      controller.dispose();
      await controller.flush();
      await repo.close();
    },
  );
}
