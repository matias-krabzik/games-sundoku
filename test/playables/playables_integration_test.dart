import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/bootstrap.dart';
import 'package:sundoku/controllers/game_session_controller.dart';
import 'package:sundoku/data/level_catalog.dart';
import 'package:sundoku/data/repositories/game_repository.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/data/services/save_codec.dart';
import 'package:sundoku/playables/playables_runtime.dart';
import 'package:sundoku/playables/playables_save_codec.dart';
import 'package:sundoku/playables/playables_save_store.dart';
import 'package:sundoku/playables/playables_sdk.dart';
import 'package:sundoku/widgets/game_feedback_scope.dart';
import 'package:sundoku/screens/splash_screen.dart';

import '../fixtures.dart';

class FakePlayablesSdk implements PlayablesSdk {
  String? data;
  Object? loadError;
  Completer<String?>? loadGate;
  Completer<void>? firstSaveGate;
  Object? nextSaveError;
  final events = <String>[];
  final saves = <String>[];
  bool audio = true;
  void Function()? pauseCallback;
  void Function()? resumeCallback;
  void Function(bool)? audioCallback;

  @override
  bool get inPlayablesEnvironment => true;
  @override
  bool get audioEnabled => audio;
  @override
  void registerCallbacks({
    required void Function() onPause,
    required void Function() onResume,
    required void Function(bool) onAudioEnabledChange,
  }) {
    events.add('callbacks');
    pauseCallback = onPause;
    resumeCallback = onResume;
    audioCallback = onAudioEnabledChange;
  }

  @override
  void firstFrameReady() => events.add('firstFrame');
  @override
  void gameReady() => events.add('gameReady');
  @override
  Future<String?> loadData() async {
    events.add('load');
    if (loadError case final error?) throw error;
    return loadGate == null ? data : loadGate!.future;
  }

  @override
  Future<void> saveData(String value) async {
    events.add('save');
    final gate = firstSaveGate;
    firstSaveGate = null;
    if (gate != null) await gate.future;
    if (nextSaveError case final error?) {
      nextSaveError = null;
      throw error;
    }
    saves.add(value);
  }

  void pause() => pauseCallback?.call();
  void resume() => resumeCallback?.call();
  void setAudio(bool enabled) {
    audio = enabled;
    audioCallback?.call(enabled);
  }

  @override
  void dispose() {
    events.add('dispose');
    pauseCallback = null;
    resumeCallback = null;
    audioCallback = null;
  }
}

class FakeClock implements Stopwatch {
  int milliseconds = 0;
  @override
  bool isRunning = false;
  void advance(int value) {
    if (isRunning) milliseconds += value;
  }

  @override
  int get elapsedMilliseconds => milliseconds;
  @override
  int get elapsedMicroseconds => milliseconds * 1000;
  @override
  int get elapsedTicks => milliseconds;
  @override
  int get frequency => 1000;
  @override
  Duration get elapsed => Duration(milliseconds: milliseconds);
  @override
  void reset() => milliseconds = 0;
  @override
  void start() => isRunning = true;
  @override
  void stop() => isRunning = false;
}

class RecordingFeedback extends GameFeedback {
  bool? lastSound;
  bool? suspended;
  @override
  Future<void> tap({required bool sound, required bool vibration}) async {
    lastSound = sound;
  }

  @override
  Future<void> setSuspended(bool value) async => suspended = value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('load must succeed before any cloud write', () async {
    final sdk = FakePlayablesSdk()..loadGate = Completer<String?>();
    final store = PlayablesSaveStore(sdk);
    final loading = store.read();
    await expectLater(
      store.write('{}', expectedRevision: -1),
      throwsStateError,
    );
    expect(sdk.saves, isEmpty);
    sdk.loadGate!.complete(null);
    expect(await loading, isNull);
    await store.write('{"revision":0}', expectedRevision: -1);
    await store.flush();
    expect(sdk.saves, hasLength(1));
    await store.close();
  });

  test('failed and corrupt loads never overwrite cloud data', () async {
    for (final sdk in [
      FakePlayablesSdk()..loadError = StateError('offline'),
      FakePlayablesSdk()..data = '{bad json',
      FakePlayablesSdk()..data = '{"schemaVersion":999}',
    ]) {
      await expectLater(
        GameRepository.open(PlayablesSaveStore(sdk)),
        throwsA(anything),
      );
      expect(sdk.saves, isEmpty);
    }
  });

  test(
    'older save migrates and restores board, notes and elapsed time',
    () async {
      final source = GameRepository.memory();
      await source.registerPuzzles(mapLevelId(1), levelPuzzles());
      final session = await source.startOrResumeLevel(mapLevelId(1));
      await source.debugEnableNotes(session.id);
      final puzzleId = session.nextPuzzleId!;
      await source.setCell(session.id, puzzleId, 0, 1);
      await source.setNotes(session.id, puzzleId, 1, [2, 3]);
      await source.addElapsed(session.id, puzzleId, 4200);
      final legacy = jsonDecode(const SaveCodec().encode(source.state)) as Map;
      legacy['schemaVersion'] = 0;
      final sdk = FakePlayablesSdk()..data = jsonEncode(legacy);
      final restored = await GameRepository.open(
        PlayablesSaveStore(sdk),
        codec: const PlayablesSaveCodec(),
      );
      final board = restored.state.sessions[session.id]!.puzzles.first;
      expect(board.cells[0].value, 1);
      expect(board.cells[1].notes, [2, 3]);
      expect(board.elapsedMs, 4200);
      expect(
        restored.state.revision,
        greaterThanOrEqualTo(source.state.revision),
      );
      await restored.close();
      await source.close();
    },
  );

  test('overlapping flushes cannot replace newer progress', () async {
    final gate = Completer<void>();
    final sdk = FakePlayablesSdk()..firstSaveGate = gate;
    final store = PlayablesSaveStore(sdk);
    await store.read();
    await store.write('first', expectedRevision: -1);
    final first = store.flush();
    await store.write('second', expectedRevision: 0);
    final second = store.flush();
    gate.complete();
    await Future.wait([first, second]);
    expect(sdk.saves, ['first', 'second']);
    await store.close();
  });

  test(
    'failed cloud write retains the latest in-memory save for retry',
    () async {
      final sdk = FakePlayablesSdk()..nextSaveError = StateError('temporary');
      final store = PlayablesSaveStore(sdk);
      await store.read();
      await store.write('latest', expectedRevision: -1);
      await expectLater(store.flush(), throwsStateError);
      expect(store.lastSaveError, isA<StateError>());
      expect(sdk.saves, isEmpty);
      await store.flush();
      expect(sdk.saves, ['latest']);
      await store.close();
    },
  );

  test('SDK pause stops time and manual pause remains in force', () async {
    final sdk = FakePlayablesSdk();
    final runtime = PlayablesRuntime(sdk);
    final repo = GameRepository.memory();
    await repo.registerPuzzles(mapLevelId(1), levelPuzzles());
    final session = await repo.startOrResumeLevel(mapLevelId(1));
    final clock = FakeClock();
    final controller = GameSessionController(
      repo,
      clock: clock,
      playables: runtime,
    );
    await controller.start(session.id);
    clock.advance(2000);
    sdk.pause();
    await controller.flush();
    expect(controller.isRunning, false);
    clock.advance(10000);
    expect(controller.elapsedMs, 2000);
    sdk.resume();
    await controller.flush();
    expect(controller.isRunning, true);
    clock.advance(500);
    await controller.pause();
    sdk.pause();
    sdk.resume();
    await controller.flush();
    expect(controller.isRunning, false);
    expect(repo.state.sessions[session.id]!.elapsedMs, 2500);
    controller.dispose();
    await controller.flush();
    runtime.dispose();
    await repo.close();
  });

  testWidgets('YouTube mute wins over the saved audio setting', (tester) async {
    final sdk = FakePlayablesSdk();
    final runtime = PlayablesRuntime(sdk);
    final repo = GameRepository.memory();
    final feedback = RecordingFeedback();
    await tester.pumpWidget(
      MaterialApp(
        home: GameFeedbackHost(
          repository: repo,
          output: feedback,
          playables: runtime,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => GameFeedbackScope.tap(context),
              child: const Text('Tap'),
            ),
          ),
        ),
      ),
    );
    sdk.setAudio(false);
    await tester.pump();
    await tester.tap(find.text('Tap'));
    await tester.pump();
    expect(feedback.lastSound, false);
    expect(feedback.suspended, true);
    await tester.pumpWidget(const SizedBox());
    runtime.dispose();
    await repo.close();
  });

  testWidgets('readiness follows callbacks, loading frame and usable home', (
    tester,
  ) async {
    final sdk = FakePlayablesSdk()..loadGate = Completer<String?>();
    await tester.pumpWidget(BootstrapApp(playablesSdk: sdk));
    expect(sdk.events, contains('callbacks'));
    expect(sdk.events, contains('firstFrame'));
    expect(sdk.events, isNot(contains('gameReady')));
    expect(find.byType(SplashScreen, skipOffstage: false), findsNothing);
    sdk.pause();
    sdk.loadGate!.complete(null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(sdk.events, isNot(contains('gameReady')));
    sdk.resume();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    expect(find.byType(SplashScreen, skipOffstage: false), findsNothing);
    expect(
      sdk.events.indexOf('firstFrame'),
      lessThan(sdk.events.indexOf('gameReady')),
    );
    expect(
      sdk.events.indexOf('load'),
      lessThan(sdk.events.indexOf('gameReady')),
    );
    await tester.pumpWidget(const SizedBox());
  });
}
