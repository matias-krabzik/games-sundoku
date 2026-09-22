import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/game_save.dart';
import '../../domain/scoring/sudoku_scoring.dart';
import '../../domain/generation/seeded_sudokus.dart';
import '../../domain/models/game_session.dart';
import '../../domain/models/quick_play_difficulty.dart';
import '../../domain/models/json_data.dart';
import '../../domain/models/player_profile.dart';
import '../../domain/models/sudoku_definition.dart';
import '../../domain/tutorial/tutorial_sudokus.dart';
import '../level_catalog.dart';
import '../services/save_codec.dart';
import '../services/save_store.dart';

class GameRepository extends ChangeNotifier {
  GameRepository._(this._store, this._save, this._codec, this._now);

  factory GameRepository.memory() {
    final store = MemorySaveStore();
    final repo = GameRepository._(
      store,
      _fresh(DateTime.now),
      const SaveCodec(),
      DateTime.now,
    );
    repo._tail = store.write(
      repo._codec.encode(repo._save),
      expectedRevision: -1,
    );
    return repo;
  }

  static Future<GameRepository> open(
    SaveStore store, {
    SaveCodec codec = const SaveCodec(),
    DateTime Function()? now,
  }) async {
    final clock = now ?? DateTime.now;
    try {
      final source = await store.read();
      final save = source == null ? _fresh(clock) : codec.decode(source);
      final repo = GameRepository._(store, save, codec, clock);
      if (source == null) {
        await store.write(codec.encode(save), expectedRevision: -1);
      }
      if (save.sessions.values.any((s) => s.status == PlayStatus.active)) {
        await repo._update(
          (save) => save.copyWith(
            sessions: {
              for (final entry in save.sessions.entries)
                entry.key: _paused(entry.value),
            },
          ),
        );
      }
      return repo;
    } catch (_) {
      await store.close();
      rethrow;
    }
  }

  static GameSave _fresh(DateTime Function() now) => GameSave(
    player: PlayerProfile(id: const Uuid().v4()),
    settings: GameSettings(),
    levels: initialLevelCatalog,
    updatedAt: now().toUtc(),
  );

  final SaveStore _store;
  final SaveCodec _codec;
  final DateTime Function() _now;
  GameSave _save;
  Future<void> _tail = Future.value();
  bool _closed = false;
  GameSave get state => _save;

  Future<void> _update(GameSave Function(GameSave) change) {
    if (_closed) return Future.error(StateError('Repository is closed'));
    final operation = _tail.then((_) async {
      final next = change(_save);
      if (identical(next, _save)) return;
      final stamped = next.copyWith(
        revision: _save.revision + 1,
        updatedAt: _now().toUtc(),
      );
      await _store.write(
        _codec.encode(stamped),
        expectedRevision: _save.revision,
      );
      _save = stamped;
      notifyListeners();
    });
    // A failed write must not poison subsequent attempts or publish unsaved state.
    _tail = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return operation;
  }

  Future<void> flush() => _tail;

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _tail;
    await _store.close();
    super.dispose();
  }

  Future<void> setPlayerName(String name) => _update((save) {
    final trimmed = name.trim();
    return save.copyWith(
      player: PlayerProfile(
        id: save.player.id,
        name: trimmed.isEmpty ? 'Jugador' : trimmed,
        nameChosen: trimmed.isNotEmpty,
        language: save.player.language,
        extra: save.player.extra,
      ),
    );
  });

  Future<void> updateSettings({bool? sound, bool? music, bool? vibration}) =>
      _update(
        (save) => save.copyWith(
          settings: GameSettings(
            sound: sound ?? save.settings.sound,
            music: music ?? save.settings.music,
            vibration: vibration ?? save.settings.vibration,
            extra: save.settings.extra,
          ),
        ),
      );

  Future<void> saveModule(String key, Json data) {
    final snapshot = immutableJson(data);
    return _update(
      (save) => save.copyWith(modules: {...save.modules, key: snapshot}),
    );
  }

  Future<void> addLevel(LevelDefinition level) => _update((save) {
    if (save.levels.containsKey(level.id)) {
      throw StateError('Level ID already exists');
    }
    return save.copyWith(levels: {...save.levels, level.id: level});
  });

  Future<void> registerPuzzles(String levelId, List<SudokuDefinition> puzzles) {
    final definitions = List<SudokuDefinition>.unmodifiable(puzzles);
    return _update((save) {
      final level = save.levels[levelId];
      if (level == null ||
          !listEquals(level.puzzleIds, definitions.map((p) => p.id).toList())) {
        throw ArgumentError('Puzzles must match the ordered level definition');
      }
      final registered = {...save.puzzles};
      for (final puzzle in definitions) {
        final existing = registered[puzzle.id];
        if (existing != null) {
          if (!_samePuzzle(existing, puzzle)) {
            throw StateError('A registered sudoku cannot change');
          }
        } else {
          registered[puzzle.id] = puzzle;
        }
      }
      return save.copyWith(puzzles: registered);
    });
  }

  /// Materialize and save all three definitions before opening the game route.
  Future<GameSession> startGeneratedLevel(int number) async {
    RangeError.checkValueInInterval(number, 2, 10, 'number');
    final id = mapLevelId(number);
    final level = state.levels[id]!;
    final key = 'generatedLevel/$number';
    final savedModule = state.modules[key];
    return startOrResumeLevel(
      id,
      definitions: [
        for (final puzzleId in level.puzzleIds)
          state.puzzles[puzzleId] ??
              SeededSudokus.create(
                id: puzzleId,
                seed: '${state.player.id}/$puzzleId',
              ),
      ],
      moduleKey: key,
      moduleData:
          savedModule is Map &&
              state.sessions.containsKey(savedModule['sessionId'])
          ? jsonObject(savedModule)
          : {'step': 'playing', 'gameIndex': 0, 'started': false},
    );
  }

  GameSession? pendingQuickPlay(QuickPlayDifficulty difficulty) {
    final module = state.modules[difficulty.storageKey];
    if (module is! Map) return null;
    final session = state.sessions[module['sessionId']];
    return session?.canResume == true ? session : null;
  }

  GameSession? get pendingQuickGame {
    final pending =
        state.sessions.values
            .where(
              (session) =>
                  session.canResume &&
                  state.levels[session.levelId]?.worldId == 'quick-play',
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return pending.firstOrNull;
  }

  Future<GameSession> startQuickPlay(
    QuickPlayDifficulty difficulty, {
    bool replacePending = false,
  }) async {
    final pending = pendingQuickGame;
    if (pending != null && !replacePending) {
      if (state.puzzles[pending.puzzles.single.puzzleId]!.difficulty ==
          difficulty.name) {
        return pending;
      }
      throw StateError('Confirm before replacing the pending quick game');
    }
    final id = 'quick-play/${difficulty.name}/${const Uuid().v4()}';
    final puzzle = await compute(_generateQuickPuzzle, (
      id: '$id/sudoku',
      seed: '${state.player.id}/$id',
      difficulty: difficulty,
    ));
    late String sessionId;
    await _update((save) {
      // Do not discard a different save that appeared while generating.
      final existing = pendingQuickGame;
      if (existing?.id != pending?.id) {
        throw StateError('The pending quick game changed');
      }
      if (existing != null && !replacePending) {
        sessionId = existing.id;
        return save;
      }
      sessionId = const Uuid().v4();
      final discarded = {
        if (replacePending)
          for (final session in save.sessions.values)
            if (session.canResume &&
                save.levels[session.levelId]?.worldId == 'quick-play')
              session.levelId,
      };
      final discardedPuzzles = {
        for (final levelId in discarded) ...save.levels[levelId]!.puzzleIds,
      };
      final session = GameSession(
        id: sessionId,
        playerId: save.player.id,
        levelId: id,
        puzzles: [PuzzleProgress.initial(puzzle)],
        startedAt: _now(),
        updatedAt: _now(),
      );
      return save.copyWith(
        levels: {
          for (final entry in save.levels.entries)
            if (!discarded.contains(entry.key)) entry.key: entry.value,
          id: LevelDefinition(
            id: id,
            worldId: 'quick-play',
            puzzleIds: [puzzle.id],
          ),
        },
        puzzles: {
          for (final entry in save.puzzles.entries)
            if (!discardedPuzzles.contains(entry.key)) entry.key: entry.value,
          puzzle.id: puzzle,
        },
        progress: {
          for (final entry in save.progress.entries)
            if (!discarded.contains(entry.key)) entry.key: entry.value,
        },
        sessions: {
          for (final entry in save.sessions.entries)
            if (!discarded.contains(entry.value.levelId))
              entry.key: _paused(entry.value),
          sessionId: session,
        },
        activeSessionId: sessionId,
        modules: {
          for (final entry in save.modules.entries)
            if (!entry.key.startsWith('quickPlay/')) entry.key: entry.value,
          difficulty.storageKey: {
            'sessionId': sessionId,
            'step': 'playing',
            'gameIndex': 0,
            'started': false,
          },
        },
      );
    });
    return state.sessions[sessionId]!;
  }

  static SudokuDefinition _generateQuickPuzzle(
    ({String id, String seed, QuickPlayDifficulty difficulty}) request,
  ) => SeededSudokus.create(
    id: request.id,
    seed: request.seed,
    difficulty: request.difficulty,
  );

  Future<GameSession> startOrResumeLevel(
    String levelId, {
    bool restart = false,
    List<SudokuDefinition>? definitions,
    String? moduleKey,
    Json? moduleData,
  }) async {
    if ((moduleKey == null) != (moduleData == null)) {
      throw ArgumentError('Module key and data must be provided together');
    }
    final definitionSnapshot = definitions == null
        ? null
        : List<SudokuDefinition>.unmodifiable(definitions);
    final moduleSnapshot = moduleData == null
        ? null
        : immutableJson(moduleData);
    late String sessionId;
    await _update((save) {
      if (!save.isUnlocked(levelId)) throw StateError('Level is locked');
      final level = save.levels[levelId]!;
      if (levelId != mapLevelId(1) &&
          level.worldId == 'world-1' &&
          ((save.progress[levelId]?.bestLights ?? 0) >= level.requiredLights ||
              restart)) {
        throw StateError('This level cannot be replayed');
      }
      final registered = {...save.puzzles};
      if (definitionSnapshot != null) {
        if (!listEquals(
          level.puzzleIds,
          definitionSnapshot.map((p) => p.id).toList(),
        )) {
          throw ArgumentError(
            'Puzzles must match the ordered level definition',
          );
        }
        for (final puzzle in definitionSnapshot) {
          final existing = registered[puzzle.id];
          if (existing != null && !_samePuzzle(existing, puzzle)) {
            throw StateError('A registered sudoku cannot change');
          }
          registered[puzzle.id] = puzzle;
        }
      }
      final sessions = {
        for (final e in save.sessions.entries) e.key: _paused(e.value),
      };
      GameSession? pending;
      for (final session in sessions.values) {
        if (session.levelId == levelId && session.canResume) pending = session;
      }
      if (pending != null && !restart) {
        sessionId = pending.id;
      } else {
        if (pending != null) {
          sessions[pending.id] = pending.copyWith(
            status: PlayStatus.abandoned,
            updatedAt: _now(),
          );
        }
        final boards = level.puzzleIds.map((id) {
          final puzzle = registered[id];
          if (puzzle == null) {
            throw StateError('Register the level sudokus before playing');
          }
          return PuzzleProgress.initial(puzzle);
        }).toList();
        sessionId = const Uuid().v4();
        sessions[sessionId] = GameSession(
          id: sessionId,
          playerId: save.player.id,
          levelId: levelId,
          puzzles: boards,
          startedAt: _now(),
          updatedAt: _now(),
        );
      }
      return save.copyWith(
        puzzles: registered,
        sessions: sessions,
        activeSessionId: sessionId,
        modules: moduleKey == null
            ? save.modules
            : {
                ...save.modules,
                moduleKey: {...moduleSnapshot!, 'sessionId': sessionId},
              },
      );
    });
    return _save.sessions[sessionId]!;
  }

  Future<void> activatePuzzle(String sessionId, String puzzleId) =>
      _update((save) {
        final session = _playable(save, sessionId, puzzleId);
        final sessions = {
          for (final e in save.sessions.entries) e.key: _paused(e.value),
        };
        sessions[sessionId] = session.copyWith(
          status: PlayStatus.active,
          updatedAt: _now(),
          puzzles: session.puzzles
              .map(
                (p) => p.puzzleId == puzzleId
                    ? p.copyWith(status: PlayStatus.active)
                    : p,
              )
              .toList(),
        );
        return save.copyWith(sessions: sessions, activeSessionId: sessionId);
      });

  Future<void> pauseSession(String sessionId) => _update((save) {
    final session = save.sessions[sessionId];
    if (session == null || !session.canResume) return save;
    return save.copyWith(
      sessions: {
        ...save.sessions,
        sessionId: _paused(session).copyWith(updatedAt: _now()),
      },
    );
  });

  Future<void> addElapsed(
    String sessionId,
    String puzzleId,
    int milliseconds,
  ) => _update((save) {
    if (milliseconds < 0) throw ArgumentError.value(milliseconds);
    if (milliseconds == 0) return save;
    final session = _playable(save, sessionId, puzzleId);
    final puzzles = session.puzzles
        .map(
          (p) => p.puzzleId == puzzleId
              ? p.copyWith(elapsedMs: p.elapsedMs + milliseconds)
              : p,
        )
        .toList();
    return save.copyWith(
      sessions: {
        ...save.sessions,
        sessionId: session.copyWith(puzzles: puzzles, updatedAt: _now()),
      },
    );
  });

  Future<void> setCell(
    String sessionId,
    String puzzleId,
    int index,
    int? value, {
    bool revealError = true,
  }) => _editCell(
    sessionId,
    puzzleId,
    index,
    value: value,
    revealError: revealError,
  );

  Future<void> setNotes(
    String sessionId,
    String puzzleId,
    int index,
    List<int> notes,
  ) => _editCell(sessionId, puzzleId, index, notes: List.unmodifiable(notes));

  Future<void> debugFillExceptCell(
    String sessionId,
    String puzzleId,
    int emptyIndex,
  ) => _update((save) {
    if (!kDebugMode) throw StateError('Developer controls are unavailable');
    final session = _playable(save, sessionId, puzzleId);
    final definition = save.puzzles[puzzleId]!;
    RangeError.checkValidIndex(emptyIndex, definition.initial);
    if (definition.isFixed(emptyIndex)) {
      throw StateError('The remaining cell must be editable');
    }
    final board = session.puzzles.firstWhere((p) => p.puzzleId == puzzleId);
    final updated = board.copyWith(
      cells: [
        for (var i = 0; i < board.cells.length; i++)
          if (definition.isFixed(i))
            board.cells[i]
          else
            CellProgress(
              value: i == emptyIndex ? null : definition.solution[i],
              extra: board.cells[i].extra,
            ),
      ],
    );
    // Publish one incomplete board; no intermediate move can award a star.
    return _replaceBoard(save, session, updated);
  });

  Future<void> useHint(String sessionId, String puzzleId, int index) =>
      _editCell(sessionId, puzzleId, index, hint: true);

  Future<void> debugRestartPuzzle(
    String sessionId,
    int index, {
    required String moduleKey,
    required Json moduleData,
  }) {
    final moduleSnapshot = immutableJson(moduleData);
    return _update((save) {
      if (!kDebugMode) throw StateError('Developer controls are unavailable');
      final session = save.sessions[sessionId];
      if (session == null || session.status == PlayStatus.abandoned) {
        throw StateError('No session to restart');
      }
      final lastCompleted = session.puzzles.lastIndexWhere(
        (p) => p.status == PlayStatus.completed,
      );
      if (index < 0 || index != lastCompleted) {
        throw StateError('Only the most recently completed sudoku can restart');
      }
      final boards = [
        for (var i = 0; i < session.puzzles.length; i++)
          if (i == index)
            PuzzleProgress.initial(save.puzzles[session.puzzles[i].puzzleId]!)
          else if (session.puzzles[i].status == PlayStatus.active)
            session.puzzles[i].copyWith(status: PlayStatus.paused)
          else
            session.puzzles[i],
      ];
      return save.copyWith(
        activeSessionId: sessionId,
        sessions: {
          for (final entry in save.sessions.entries)
            entry.key: _paused(entry.value),
          sessionId: GameSession(
            id: session.id,
            playerId: session.playerId,
            levelId: session.levelId,
            puzzles: boards,
            startedAt: session.startedAt,
            updatedAt: _now(),
            extra: session.extra,
          ),
        },
        modules: {...save.modules, moduleKey: moduleSnapshot},
      );
    });
  }

  /// Records an explanation-only hint without filling a cell for the player.
  Future<void> recordHint(String sessionId, String puzzleId, {int? index}) =>
      _update((save) {
        final session = _playable(save, sessionId, puzzleId);
        final board = session.puzzles.firstWhere((p) => p.puzzleId == puzzleId);
        return _replaceBoard(
          save,
          session,
          SudokuScoring.hint(board, save.puzzles[puzzleId]!, index: index),
        );
      });

  Future<void> _editCell(
    String sessionId,
    String puzzleId,
    int index, {
    int? value,
    List<int>? notes,
    bool revealError = true,
    bool hint = false,
  }) => _update((save) {
    final session = _playable(save, sessionId, puzzleId);
    final definition = save.puzzles[puzzleId]!;
    RangeError.checkValidIndex(index, definition.initial);
    if (definition.isFixed(index)) {
      throw StateError('Given cells cannot change');
    }
    final board = session.puzzles.firstWhere((p) => p.puzzleId == puzzleId);
    final old = board.cells[index];
    final number = hint ? definition.solution[index] : value;
    if (notes == null && old.value == number && old.notes.isEmpty) return save;
    final isError = notes == null && definition.hasError(index, number);
    final cell = CellProgress(
      value: notes == null ? number : null,
      notes: notes ?? [],
      source: hint ? ValueSource.hint : ValueSource.player,
      errorRevealed: isError && revealError,
      extra: old.extra,
    );
    final cells = [...board.cells]..[index] = cell;
    final updated = SudokuScoring.move(
      puzzle: definition,
      before: board,
      index: index,
      hintUsed: hint,
      isError: isError,
      after: board.copyWith(
        cells: cells,
        mistakes: board.mistakes + (isError && old.value != number ? 1 : 0),
      ),
    );
    updated.validate(definition);
    final solved = List.generate(
      cells.length,
      (i) => cells[i].value == definition.solution[i],
    ).every((v) => v);
    return _replaceBoard(
      save,
      session,
      solved
          ? updated.copyWith(status: PlayStatus.completed, completedAt: _now())
          : updated,
    );
  });

  GameSave _replaceBoard(
    GameSave save,
    GameSession session,
    PuzzleProgress board,
  ) {
    final puzzles = session.puzzles
        .map((p) => p.puzzleId == board.puzzleId ? board : p)
        .toList();
    final done = puzzles.every((p) => p.status == PlayStatus.completed);
    final next = session.copyWith(
      puzzles: puzzles,
      updatedAt: _now(),
      status: done
          ? PlayStatus.completed
          : board.status == PlayStatus.completed
          ? PlayStatus.paused
          : session.status,
      completedAt: done ? _now() : null,
    );
    final record = save.progress[session.levelId] ?? LevelRecord();
    final bestTime = done
        ? math.min(record.bestElapsedMs ?? next.elapsedMs, next.elapsedMs)
        : record.bestElapsedMs;
    return save.copyWith(
      sessions: {...save.sessions, session.id: next},
      progress: {
        ...save.progress,
        session.levelId: LevelRecord(
          bestLights: math.max(record.bestLights, next.lights),
          bestPoints: done
              ? math.max(record.bestPoints, next.points)
              : record.bestPoints,
          bestElapsedMs: bestTime,
          firstCompletedAt: record.firstCompletedAt ?? (done ? _now() : null),
          extra: record.extra,
        ),
      },
      clearActiveSession: done && save.activeSessionId == session.id,
    );
  }

  GameSession _playable(GameSave save, String sessionId, String puzzleId) {
    final session = save.sessions[sessionId];
    if (session == null ||
        !session.canResume ||
        session.nextPuzzleId != puzzleId) {
      throw StateError('Puzzle is not the next playable challenge');
    }
    return session;
  }

  Future<void> recordDebugLights(String levelId, int lights) => _update((save) {
    final level = save.levels[levelId];
    if (level == null) throw ArgumentError.value(levelId);
    RangeError.checkValueInInterval(lights, 0, level.requiredLights, 'lights');
    final previous = save.progress[levelId] ?? LevelRecord();
    if (!save.isUnlocked(levelId) || lights <= previous.bestLights) return save;
    return save.copyWith(
      progress: {
        ...save.progress,
        levelId: LevelRecord(
          bestLights: lights,
          bestPoints: previous.bestPoints,
          bestElapsedMs: previous.bestElapsedMs,
          firstCompletedAt: previous.firstCompletedAt,
          extra: previous.extra,
        ),
      },
    );
  });

  /// Creates a complete, internally consistent attempt with randomized stats.
  Future<void> completeDebugLevel(int number, {math.Random? random}) {
    RangeError.checkValueInInterval(number, 1, 10, 'number');
    final generator = random ?? math.Random();
    return _update((save) => _completedDebugLevel(save, number, generator));
  }

  Future<void> completeDebugWorldExceptLastPuzzle({math.Random? random}) {
    final generator = random ?? math.Random();
    return _update((save) {
      if (!kDebugMode) throw StateError('Developer controls are unavailable');
      var next = save;
      final numbers =
          initialLevelCatalog.keys
              .map((id) => int.parse(id.split('level-').last))
              .toList()
            ..sort();
      for (final number in numbers) {
        next = _completedDebugLevel(next, number, generator);
      }
      final levelId = mapLevelId(numbers.last);
      final moduleKey = 'generatedLevel/${numbers.last}';
      final module = jsonObject(next.modules[moduleKey]);
      final completed = next.sessions[module['sessionId']]!;
      final lastPuzzle = next.puzzles[completed.puzzles.last.puzzleId]!;
      final session = GameSession(
        id: completed.id,
        playerId: completed.playerId,
        levelId: levelId,
        puzzles: [
          ...completed.puzzles.take(completed.puzzles.length - 1),
          PuzzleProgress.initial(lastPuzzle),
        ],
        startedAt: completed.startedAt,
        updatedAt: completed.updatedAt,
      );
      return next.copyWith(
        sessions: {
          for (final entry in next.sessions.entries)
            if (entry.value.levelId != levelId) entry.key: _paused(entry.value),
          session.id: session,
        },
        progress: {
          ...next.progress,
          levelId: LevelRecord(bestLights: session.lights),
        },
        activeSessionId: session.id,
        modules: {
          ...next.modules,
          moduleKey: {
            ...module,
            'step': 'playing',
            'gameIndex': session.puzzles.length - 1,
            'started': true,
          },
        },
      );
    });
  }

  GameSave _completedDebugLevel(
    GameSave save,
    int number,
    math.Random generator,
  ) {
    if (!kDebugMode) throw StateError('Developer controls are unavailable');
    final levelId = mapLevelId(number);
    final level = save.levels[levelId]!;
    if (!save.isUnlocked(levelId)) {
      throw StateError('Complete the previous level first');
    }
    const tutorialCenter = [8, 3, 5, 4, 1, 6, 9, 2, 7];
    final definitions = number == 1
        ? (level.puzzleIds.every(save.puzzles.containsKey)
              ? [for (final id in level.puzzleIds) save.puzzles[id]!]
              : TutorialSudokus.create(tutorialCenter))
        : [
            for (final puzzleId in level.puzzleIds)
              save.puzzles[puzzleId] ??
                  SeededSudokus.create(
                    id: puzzleId,
                    seed: '${save.player.id}/$puzzleId',
                  ),
          ];
    final completedAt = _now();
    final puzzles = [
      for (final definition in definitions)
        PuzzleProgress(
          puzzleId: definition.id,
          cells: [
            for (final value in definition.solution) CellProgress(value: value),
          ],
          status: PlayStatus.completed,
          elapsedMs: 30000 + generator.nextInt(150001),
          mistakes: generator.nextInt(4),
          hintsUsed: generator.nextInt(2),
          points: 501 + generator.nextInt(2000) * 2,
          completedAt: completedAt,
        ),
    ];
    final sessionId = const Uuid().v4();
    final session = GameSession(
      id: sessionId,
      playerId: save.player.id,
      levelId: levelId,
      puzzles: puzzles,
      status: PlayStatus.completed,
      startedAt: completedAt.subtract(
        Duration(milliseconds: puzzles.fold(0, (sum, p) => sum + p.elapsedMs)),
      ),
      updatedAt: completedAt,
      completedAt: completedAt,
    );
    final previous = save.progress[levelId] ?? LevelRecord();
    final sessions = {
      for (final entry in save.sessions.entries)
        entry.key: entry.value.levelId == levelId && entry.value.canResume
            ? entry.value.copyWith(
                status: PlayStatus.abandoned,
                updatedAt: completedAt,
              )
            : entry.value,
      sessionId: session,
    };
    final moduleKey = number == 1
        ? 'firstExperience'
        : 'generatedLevel/$number';
    return save.copyWith(
      puzzles: {
        ...save.puzzles,
        for (final definition in definitions) definition.id: definition,
      },
      sessions: sessions,
      progress: {
        ...save.progress,
        levelId: LevelRecord(
          bestLights: level.requiredLights,
          bestPoints: math.max(previous.bestPoints, session.points),
          bestElapsedMs: math.min(
            previous.bestElapsedMs ?? session.elapsedMs,
            session.elapsedMs,
          ),
          firstCompletedAt: previous.firstCompletedAt ?? completedAt,
          extra: previous.extra,
        ),
      },
      clearActiveSession:
          save.activeSessionId == null ||
          sessions[save.activeSessionId]?.canResume != true,
      modules: {
        ...save.modules,
        moduleKey: {
          'step': 'complete',
          'gameIndex': 2,
          'started': true,
          'sessionId': sessionId,
          if (number == 1) ...{
            'cells': tutorialCenter,
            'briefingAccepted': true,
            'homeIntroductionShown': true,
          },
        },
      },
    );
  }

  Future<void> resetDebugLevels(Set<String> levelIds) => _update((save) {
    final sessions = {...save.sessions}
      ..removeWhere((id, s) => levelIds.contains(s.levelId));
    final resetNumbers = levelIds
        .map((id) => int.tryParse(id.split('level-').last))
        .whereType<int>();
    final firstReset = resetNumbers.isEmpty
        ? 11
        : resetNumbers.reduce(math.min);
    final modules = {...save.modules}
      ..removeWhere(
        (key, _) =>
            (firstReset <= 1 && key == 'firstExperience') ||
            (key.startsWith('generatedLevel/') &&
                (int.tryParse(key.split('/').last) ?? 0) >= firstReset),
      );
    return save.copyWith(
      progress: {...save.progress}
        ..removeWhere((id, _) => levelIds.contains(id)),
      sessions: sessions,
      clearActiveSession: !sessions.containsKey(save.activeSessionId),
      modules: modules,
    );
  });

  Future<void> resetDebugSave() => _update((save) {
    final fresh = _fresh(_now);
    return fresh.copyWith(revision: save.revision);
  });
}

GameSession _paused(GameSession session) => session.status != PlayStatus.active
    ? session
    : session.copyWith(
        status: PlayStatus.paused,
        puzzles: session.puzzles
            .map(
              (p) => p.status == PlayStatus.active
                  ? p.copyWith(status: PlayStatus.paused)
                  : p,
            )
            .toList(),
      );

bool _samePuzzle(SudokuDefinition a, SudokuDefinition b) =>
    a.id == b.id &&
    a.seed == b.seed &&
    a.generatorVersion == b.generatorVersion &&
    a.difficulty == b.difficulty &&
    a.size == b.size &&
    a.boxRows == b.boxRows &&
    a.boxColumns == b.boxColumns &&
    a.variant == b.variant &&
    listEquals(a.initial, b.initial) &&
    listEquals(a.solution, b.solution);
