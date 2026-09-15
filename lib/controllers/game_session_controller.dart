import 'dart:ui' show AppExitResponse;
import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/repositories/game_repository.dart';

/// Persists active play time and serializes input for the future Sudoku screen.
class GameSessionController extends ChangeNotifier with WidgetsBindingObserver {
  GameSessionController(
    this.repository, {
    Stopwatch? clock,
    this.resumeOnForeground = true,
    Duration checkpointInterval = const Duration(seconds: 5),
  }) : _clock = clock ?? Stopwatch() {
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(checkpointInterval, (_) {
      if (_clock.isRunning) unawaited(checkpoint().catchError((Object _) {}));
    });
  }

  final GameRepository repository;
  final bool resumeOnForeground;
  final Stopwatch _clock;
  late final Timer _timer;
  String? _sessionId;
  String? _puzzleId;
  int _savedMs = 0;
  Future<void> _tail = Future.value();
  bool _disposed = false;
  bool _foreground = true;
  bool _wantsToPlay = false;
  Object? lastError;

  bool get isRunning => _clock.isRunning;
  bool get isPaused => _sessionId != null && _puzzleId != null && !_wantsToPlay;
  int get elapsedMs {
    final boards = repository.state.sessions[_sessionId]?.puzzles;
    final saved = boards?.where((p) => p.puzzleId == _puzzleId).firstOrNull;
    return (saved?.elapsedMs ?? 0) + _clock.elapsedMilliseconds - _savedMs;
  }

  Future<void> _enqueue(Future<void> Function() action) {
    if (_disposed) return Future.error(StateError('Controller is disposed'));
    final task = _tail.then((_) => action());
    _tail = task.then<void>(
      (_) {
        lastError = null;
        if (!_disposed) notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        lastError = error;
        if (!_disposed) notifyListeners();
      },
    );
    return task;
  }

  Future<void> start(String sessionId) {
    _wantsToPlay = resumeOnForeground || _foreground;
    return _enqueue(() async {
      await _pause();
      final puzzleId = repository.state.sessions[sessionId]?.nextPuzzleId;
      if (puzzleId == null) throw StateError('No pending sudoku');
      _sessionId = sessionId;
      _puzzleId = puzzleId;
      _clock.reset();
      _savedMs = 0;
      if (_foreground && !_disposed && _wantsToPlay) {
        await repository.activatePuzzle(sessionId, puzzleId);
        if (_foreground && !_disposed && _wantsToPlay) _clock.start();
      }
    });
  }

  Future<void> _checkpoint() async {
    final session = _sessionId;
    final puzzle = _puzzleId;
    if (session == null || puzzle == null) return;
    final elapsed = _clock.elapsedMilliseconds;
    final delta = elapsed - _savedMs;
    if (delta <= 0) return;
    await repository.addElapsed(session, puzzle, delta);
    _savedMs = elapsed;
  }

  Future<void> checkpoint() => _enqueue(_checkpoint);

  Future<void> _pause() async {
    _clock.stop();
    await _checkpoint();
    if (_sessionId != null) await repository.pauseSession(_sessionId!);
  }

  Future<void> pause() {
    _clock.stop();
    _wantsToPlay = false;
    return _enqueue(_pause);
  }

  Future<void> _input(Future<void> Function(String, String) action) =>
      _enqueue(() async {
        if (!_clock.isRunning || _sessionId == null || _puzzleId == null) {
          throw StateError('Start the sudoku before editing');
        }
        // Stop before saving so I/O latency and the completion animation aren't play time.
        _clock.stop();
        try {
          await _checkpoint();
          await action(_sessionId!, _puzzleId!);
        } finally {
          final next = repository.state.sessions[_sessionId]?.nextPuzzleId;
          if (next != _puzzleId) {
            _wantsToPlay = false;
            _clock.reset();
            _savedMs = 0;
            _puzzleId = null;
          } else if (_foreground && !_disposed && _wantsToPlay) {
            _clock.start();
          }
        }
      });

  Future<void> setCell(int index, int? value, {bool revealError = true}) =>
      _input(
        (session, puzzle) => repository.setCell(
          session,
          puzzle,
          index,
          value,
          revealError: revealError,
        ),
      );

  Future<void> setNotes(int index, List<int> notes) {
    final snapshot = List<int>.unmodifiable(notes);
    return _input(
      (session, puzzle) =>
          repository.setNotes(session, puzzle, index, snapshot),
    );
  }

  Future<void> debugFillExceptCell(int emptyIndex) => _input(
    (session, puzzle) =>
        repository.debugFillExceptCell(session, puzzle, emptyIndex),
  );

  Future<void> useHint(int index) =>
      _input((session, puzzle) => repository.useHint(session, puzzle, index));

  Future<void> recordHint({int? index}) => _input(
    (session, puzzle) => repository.recordHint(session, puzzle, index: index),
  );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      if (!resumeOnForeground) _wantsToPlay = false;
      _clock.stop();
      if (!_disposed) notifyListeners();
      unawaited(_enqueue(_pause).catchError((Object _) {}));
    } else if (_wantsToPlay && _sessionId != null) {
      unawaited(start(_sessionId!).catchError((Object _) {}));
    }
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    try {
      await pause();
      await repository.flush();
      return AppExitResponse.exit;
    } catch (_) {
      return AppExitResponse.cancel;
    }
  }

  Future<void> flush() => _tail;

  @override
  void dispose() {
    _wantsToPlay = false;
    _clock.stop();
    _timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_enqueue(_pause).catchError((Object _) {}));
    _disposed = true;
    super.dispose();
  }
}
