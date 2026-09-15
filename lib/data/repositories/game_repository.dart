import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/game_save.dart';
import '../../domain/scoring/sudoku_scoring.dart';
import '../../domain/generation/seeded_sudokus.dart';
import '../../domain/models/game_session.dart';
import '../../domain/models/json_data.dart';
import '../../domain/models/player_profile.dart';
import '../../domain/models/sudoku_definition.dart';
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

  Future<void> resetDebugLevels(Set<String> levelIds) => _update((save) {
    final sessions = {...save.sessions}
      ..removeWhere((id, s) => levelIds.contains(s.levelId));
    return save.copyWith(
      progress: {...save.progress}
        ..removeWhere((id, _) => levelIds.contains(id)),
      sessions: sessions,
      clearActiveSession: !sessions.containsKey(save.activeSessionId),
    );
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
