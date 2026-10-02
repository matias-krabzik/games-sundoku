import 'dart:math';
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/world_catalog.dart';
import '../data/level_catalog.dart';
import '../data/repositories/game_repository.dart';
import '../domain/models/game_session.dart';
import '../domain/models/quick_play_difficulty.dart';
import '../domain/help/sudoku_help.dart';
import '../domain/models/json_data.dart';
import '../domain/models/sudoku_definition.dart';
import '../domain/models/sudoku_completion.dart';
import '../domain/tutorial/tutorial_steps.dart';
import '../domain/tutorial/tutorial_sudokus.dart';
import 'game_session_controller.dart';

export '../domain/tutorial/tutorial_steps.dart';

class ScoreFeedback {
  const ScoreFeedback(this.id, this.origin, this.points);
  final int id;
  final int origin;
  final int points;
}

/// Owns the wizard; real play and rewards stay in the session repository.
class FirstExperienceController extends ChangeNotifier {
  FirstExperienceController(
    this.repository, {
    Random? random,
    this.reviewOnly = false,
    this.levelNumber = 1,
    this.worldId = 'world-1',
    this.quickPlayDifficulty,
    this.notesEnabled = false,
    this.helpEngine = const SudokuHelpEngine(),
  }) : _random = random ?? Random() {
    RangeError.checkValueInInterval(
      levelNumber,
      1,
      adventureWorld(worldId).nodes.length,
      'levelNumber',
    );
    if (worldId == 'world-2' &&
        (!repository.forestUnlocked ||
            !repository.notesTutorialCompleted ||
            session == null)) {
      throw StateError('Enter the forest through its notes lesson first');
    }
    final saved = _module;
    _paused = isGeneratedLevel && saved['started'] == true;
    _gameCell =
        puzzleProgress?.extra['selectedCell'] as int? ??
        saved['selectedCell'] as int?;
    _cells = _readCells(saved['cells']);
    _savedStep = FirstExperienceStep.values.firstWhere(
      (step) => step.name == saved['step'],
      orElse: () => FirstExperienceStep.welcome,
    );
    _savedStep = normalizeTutorialStep(
      _savedStep,
      gameIndex: gameIndex,
      hasSession: session != null,
    );
    _step = reviewOnly ? FirstExperienceStep.welcome : _savedStep;
  }

  static const moduleKey = 'firstExperience';
  final int levelNumber;
  final String worldId;
  AdventureWorld get world => adventureWorld(worldId);
  final QuickPlayDifficulty? quickPlayDifficulty;

  /// Supplied by the adventure unlock/practice flow once that world is available.
  final bool notesEnabled;
  bool get isQuickPlay => quickPlayDifficulty != null;
  int get roundCount => isQuickPlay ? 1 : 3;
  bool get isGeneratedLevel =>
      isQuickPlay || worldId != 'world-1' || levelNumber > 1;
  String get storageKey =>
      quickPlayDifficulty?.storageKey ??
      adventureModuleKey(worldId, levelNumber);
  bool _paused = false;
  bool get isPaused =>
      step == FirstExperienceStep.playing &&
      (_paused || _play?.isPaused == true);
  int get elapsedMs => puzzleProgress?.status == PlayStatus.completed
      ? puzzleProgress!.elapsedMs
      : _play?.elapsedMs ?? puzzleProgress?.elapsedMs ?? 0;

  final GameRepository repository;
  final bool reviewOnly;
  final SudokuHelpEngine helpEngine;
  bool _helpVisible = false;
  final Random _random;
  late final List<int> _exampleOrder = List.generate(9, (index) => index + 1)
    ..shuffle(_random);
  late FirstExperienceStep _savedStep;
  late FirstExperienceStep _step;
  late List<int?> _cells;
  int? _selectedCell;
  bool _isBusy = false;
  bool _disposed = false;
  String? _error;
  GameSessionController? _play;
  int? _gameCell;
  String? _feedback;
  int _attention = 0;
  SudokuCompletion? _completion;
  ScoreFeedback? scoreFeedback;
  int _scoreSequence = 0;
  int get points => puzzleProgress?.points ?? 0;

  void _scoreChanged(int previous, int origin) {
    final delta = points - previous;
    if (delta != 0) {
      scoreFeedback = ScoreFeedback(++_scoreSequence, origin, delta);
    }
  }

  FirstExperienceStep get step =>
      _step == FirstExperienceStep.playing &&
          puzzleProgress?.status == PlayStatus.completed
      ? gameIndex == roundCount - 1
            ? FirstExperienceStep.complete
            : FirstExperienceStep.celebration
      : _step;
  List<int?> get cells => _cells;
  int? get selectedCell => _selectedCell;
  bool get isBusy => _isBusy;
  String? get error =>
      _error ??
      (_play?.lastError == null
          ? null
          : 'No pudimos guardar. Toca Reintentar.');
  int get filledCount => _cells.whereType<int>().length;

  GameSession? get session => repository.state.sessions[_module['sessionId']];
  int get gameIndex =>
      (_module['gameIndex'] as int? ?? 0).clamp(0, roundCount - 1);
  PuzzleProgress? get puzzleProgress => session?.puzzles[gameIndex];
  SudokuDefinition? get puzzleDefinition =>
      repository.state.puzzles[puzzleProgress?.puzzleId];
  TutorialLesson? get lesson => lessonFor(step, exampleCenter);
  int get storyIndex => tutorialStorySteps.indexOf(step);
  int get storyCount => tutorialStorySteps.length;
  bool get isLastLevel => !isQuickPlay && levelNumber == world.nodes.length;
  bool get isFirstSudokuVictory =>
      !isQuickPlay &&
      worldId == 'world-1' &&
      levelNumber == 1 &&
      gameIndex == 0 &&
      session != null &&
      !repository.state.sessions.values.any(
        (other) => other.id != session!.id && other.lights > 0,
      );
  bool get isStory => storyIndex >= 0;
  bool get readyToPlay =>
      step == FirstExperienceStep.playing &&
      !_isBusy &&
      _play?.acceptingInput == true;
  bool get notesAvailable =>
      !reviewOnly &&
      (repository.notesAllowedFor(session?.levelId) ||
          notesEnabled ||
          (kDebugMode && _module['debugNotes'] == true));
  bool get notesMode =>
      notesAvailable && puzzleProgress?.extra['notesMode'] == true;
  Map<int, List<int>> get boardNotes => !hasGameBoard || isStory
      ? {}
      : {
          for (var i = 0; i < (puzzleProgress?.cells.length ?? 0); i++)
            if (puzzleProgress!.cells[i].notes.isNotEmpty)
              i: puzzleProgress!.cells[i].notes,
        };
  List<int> get selectedNotes =>
      _gameCell == null ? const [] : boardNotes[_gameCell] ?? const [];
  bool get canClearGameCell =>
      readyToPlay &&
      _gameCell != null &&
      !fixedIndices.contains(_gameCell) &&
      (boardValues[_gameCell!] != null || selectedNotes.isNotEmpty);

  Future<void> toggleNotesMode() async {
    if (!readyToPlay || !notesAvailable) return;
    await _run(() async {
      await _player.setInputState(
        notesMode: !notesMode,
        selectedIndex: _gameCell,
      );
      _completion = null;
      _feedback =
          notesMode && _gameCell != null && boardValues[_gameCell!] != null
          ? 'Elige una casilla vacía para anotar.'
          : null;
    });
  }

  Future<void> debugToggleNotes() async {
    if (!kDebugMode || !readyToPlay || reviewOnly) return;
    await _run(() async {
      final enabled = _module['debugNotes'] != true;
      if (!enabled) await _player.setInputState(notesMode: false);
      await repository.saveModule(storageKey, {
        ..._module,
        'debugNotes': enabled,
      });
    });
  }

  int? get gameCell => _gameCell;
  bool get canShowHelp =>
      readyToPlay && _gameCell != null && boardValues[_gameCell!] == null;
  SudokuHelpTip? get helpTip => !_helpVisible || !canShowHelp
      ? null
      : helpEngine.explain(
          SudokuHelpContext(
            cells: boardValues,
            selectedIndex: _gameCell!,
            fixedIndices: fixedIndices,
          ),
        );

  Future<void> showHelp() async {
    if (!canShowHelp || _helpVisible) return;
    final index = _gameCell!;
    final previous = points;
    _helpVisible = true;
    await _run(() async {
      await _player.recordHint(index: index);
      _scoreChanged(previous, index);
      if (_gameCell == index) _helpVisible = true;
    });
    if (!_disposed) notifyListeners();
  }

  void dismissHelp() {
    if (!_helpVisible) return;
    _helpVisible = false;
    notifyListeners();
  }

  int get attention => _attention;
  SudokuCompletion? get completion => _completion;
  Set<int> get conflicts {
    if (isStory) return {};
    final progress = puzzleProgress;
    if (progress == null) return {};
    return {
      for (var i = 0; i < progress.cells.length; i++)
        if (progress.cells[i].errorRevealed) i,
    };
  }

  List<int> get availableGameNumbers {
    if (notesMode) return List.generate(9, (index) => index + 1);
    final board = boardValues;
    final solution = puzzleDefinition?.solution;
    final correctCounts = List<int>.filled(10, 0);
    for (var i = 0; i < board.length; i++) {
      final value = board[i];
      if (value != null && value == solution?[i]) correctCounts[value]++;
    }
    return [
      for (var number = 1; number <= 9; number++)
        if (correctCounts[number] < 9) number,
    ];
  }

  bool get hasGameBoard =>
      step == FirstExperienceStep.givensIntroduction ||
      (session != null && step.index >= FirstExperienceStep.playing.index);

  /// A read-only example fills gaps while keeping every previously chosen digit.
  List<int> get exampleCenter {
    final chosen = [..._cells];
    final missing = [
      for (final n in _exampleOrder)
        if (!chosen.contains(n)) n,
    ];
    var next = 0;
    return [for (final value in chosen) value ?? missing[next++]];
  }

  SudokuDefinition get _storyPuzzle =>
      puzzleDefinition ?? TutorialSudokus.create(exampleCenter).first;

  List<int?> get boardValues => step == FirstExperienceStep.solvedExample
      ? _storyPuzzle.solution
      : hasGameBoard
      ? step == FirstExperienceStep.givensIntroduction
            ? _storyPuzzle.initial
            : puzzleProgress!.cells.map((c) => c.value).toList(growable: false)
      : [
          for (var i = 0; i < 81; i++)
            TutorialSudokus.centerIndices.contains(i)
                ? (isStory && step != FirstExperienceStep.welcome
                      ? exampleCenter
                      : _cells)[TutorialSudokus.centerIndices.indexOf(i)]
                : null,
        ];
  Set<int> get fixedIndices {
    if (!hasGameBoard) return {};
    final definition = _storyPuzzle;
    return {
      for (var i = 0; i < 81; i++)
        if (definition.isFixed(i)) i,
    };
  }

  List<int> get highlightedIndices {
    final current = lesson;
    if (current?.group != null) {
      return groupCells(current!.anchor, current.group!);
    }
    return [];
  }

  int get remaining => boardValues.where((n) => n == null).length;
  String get playMessage => _feedback ?? '';

  String get lessonMessage => _feedback ?? lesson?.message ?? '';

  Future<void> previousStory() async {
    if (_disposed || _isBusy || storyIndex <= 0) return;
    await _save(tutorialStorySteps[storyIndex - 1], _cells);
  }

  Future<void> advance({bool startClock = true}) async {
    if (_disposed || _isBusy) return;
    if (reviewOnly) {
      if (storyIndex >= 0 && storyIndex < storyCount - 1) {
        await _save(tutorialStorySteps[storyIndex + 1], exampleCenter);
      }
      return;
    }
    final current = step;
    if (isStory) {
      if (current == FirstExperienceStep.welcome) {
        await begin(automaticBlock: true);
      } else if (current == FirstExperienceStep.blockIntroduction &&
          !reviewOnly) {
        await _save(FirstExperienceStep.expansion, exampleCenter);
      } else if (current == FirstExperienceStep.givensIntroduction) {
        if (session?.status == PlayStatus.completed) {
          await _save(FirstExperienceStep.complete, _cells);
        } else {
          await _prepareGames();
        }
      } else {
        await _save(tutorialStorySteps[storyIndex + 1], exampleCenter);
      }
    } else if (current == FirstExperienceStep.celebration) {
      await _save(
        gameIndex == roundCount - 1
            ? FirstExperienceStep.complete
            : FirstExperienceStep.playing,
        _cells,
        changes: {
          'gameIndex': gameIndex == roundCount - 1 ? gameIndex : gameIndex + 1,
        },
      );
      if (startClock && _error == null && step == FirstExperienceStep.playing) {
        await resumeGame();
      }
    }
  }

  /// Goes straight from any lesson to its playable board without awarding progress.
  Future<bool> skipTutorial() async {
    if (_disposed ||
        _isBusy ||
        reviewOnly ||
        isGeneratedLevel ||
        step.index >= FirstExperienceStep.playing.index) {
      return false;
    }
    await _prepareGames(briefingAccepted: true);
    return _error == null && step == FirstExperienceStep.playing;
  }

  /// Starts another practice session while preserving earned stars and unlocks.
  Future<void> restartGames() async {
    if (isGeneratedLevel) throw StateError('This level cannot be replayed');
    final center = exampleCenter;
    await repository.startOrResumeLevel(
      mapLevelId(1),
      restart: true,
      definitions: TutorialSudokus.create(center),
      moduleKey: storageKey,
      moduleData: {
        ..._module,
        'step': FirstExperienceStep.playing.name,
        'cells': center,
        'gameIndex': 0,
        'briefingAccepted': true,
      },
    );
  }

  Future<void> _prepareGames({bool briefingAccepted = false}) async {
    if (session != null) {
      await _save(
        FirstExperienceStep.playing,
        exampleCenter,
        changes: {if (briefingAccepted) 'briefingAccepted': true},
      );
      if (_error == null) await resumeGame();
      return;
    }
    await _run(() async {
      await repository.startOrResumeLevel(
        mapLevelId(1),
        definitions: TutorialSudokus.create(exampleCenter),
        moduleKey: storageKey,
        moduleData: {
          ..._module,
          'step': FirstExperienceStep.playing.name,
          'cells': exampleCenter,
          'gameIndex': 0,
          if (briefingAccepted) 'briefingAccepted': true,
        },
      );
      _cells = List.unmodifiable(exampleCenter);
      _step = _savedStep = FirstExperienceStep.playing;
    });
    if (!_disposed && _error == null) await resumeGame();
  }

  GameSessionController get _player {
    _play ??= GameSessionController(
      repository,
      resumeOnForeground: !isGeneratedLevel,
      checkpointInterval: Duration(seconds: isGeneratedLevel ? 1 : 5),
    )..addListener(_sessionChanged);
    return _play!;
  }

  void _sessionChanged() {
    if (!_disposed) notifyListeners();
  }

  Future<void> resumeGame() async {
    if (_disposed || _isBusy || step != FirstExperienceStep.playing) {
      return;
    }
    // A developer reset can remove the session while retaining the tutorial's
    // playing step and chosen center. Rebuild the practice before starting it.
    if (session == null) {
      if (!isGeneratedLevel) await _prepareGames();
      return;
    }
    if (kDebugMode && notesEnabled && session != null) {
      await repository.debugEnableNotes(session!.id);
    }
    await _run(() async {
      if (isGeneratedLevel) {
        await repository.saveModule(storageKey, {..._module, 'started': true});
      }
      await _player.start(session!.id);
      _paused = false;
      _resetMoveFeedback();
    });
  }

  Future<void> requestPause() => _run(pauseGame);

  Future<void> pauseGame() async {
    if (isGeneratedLevel) _paused = true;
    if (_play != null) await _play!.pause();
    if (!_disposed) notifyListeners();
  }

  void _resetMoveFeedback() {
    _feedback = null;
  }

  void selectGameCell(int index) {
    RangeError.checkValueInInterval(index, 0, 80, 'index');
    if (!readyToPlay) return;
    _gameCell = index;
    unawaited(
      _player.setInputState(selectedIndex: index).catchError((Object _) {
        _error = 'No pudimos guardar tu selección. Intenta de nuevo.';
        if (!_disposed) notifyListeners();
      }),
    );
    _helpVisible = false;
    _feedback = null;
    notifyListeners();
  }

  Future<void> placeGameNumber(int number) async {
    RangeError.checkValueInInterval(number, 1, 9, 'number');
    final index = _gameCell;
    if (!readyToPlay || index == null || fixedIndices.contains(index)) {
      return;
    }
    dismissHelp();
    final board = boardValues;
    if (notesMode) {
      if (board[index] != null) {
        _feedback = 'Elige una casilla vacía para anotar.';
        notifyListeners();
        return;
      }
      _completion = null;
      _feedback = null;
      _error = null;
      try {
        await _player.toggleNote(index, number);
      } catch (_) {
        _error = 'No pudimos guardar tu anotación. Intenta de nuevo.';
      }
      if (!_disposed) notifyListeners();
      return;
    }
    if (board[index] == number) {
      if (conflicts.contains(index)) {
        _attention++;
        notifyListeners();
      }
      return;
    }
    String? feedback;
    final incorrect = puzzleDefinition!.hasError(index, number);
    if (incorrect) {
      for (final group in SudokuGroup.values) {
        final hasDuplicate = groupCells(
          index,
          group,
        ).any((i) => i != index && board[i] == number);
        if (hasDuplicate) {
          feedback =
              'Ya hay un $number en ${group.demonstrative} ${group.nameForChild}.\nPrueba otro número.';
          break;
        }
      }
      feedback ??= 'Ese número no encaja aquí. Prueba otro.';
    }
    await _run(() async {
      final previous = points;
      await _player.setCell(index, number);
      _scoreChanged(previous, index);
      _feedback = feedback;
      if (incorrect) {
        _attention++;
        _completion = null;
      } else {
        _completion = SudokuCompletion.fromPosition(
          origin: index,
          wholeBoard: puzzleProgress!.status == PlayStatus.completed,
        );
      }
    });
  }

  Future<void> clearGameCell() async {
    final index = _gameCell;
    if (!canClearGameCell || index == null) {
      return;
    }
    await _run(() async {
      if (boardValues[index] == null) {
        await _player.setNotes(index, const []);
      } else {
        await _player.setCell(index, null);
      }
      _feedback = null;
      _completion = null;
    });
  }

  Future<void> debugFillExceptOne() async {
    if (!kDebugMode || _disposed || reviewOnly || !readyToPlay) return;
    final fixed = fixedIndices;
    final editable = [
      for (var i = 0; i < 81; i++)
        if (!fixed.contains(i)) i,
    ];
    if (editable.isEmpty) return;
    final selected = _gameCell;
    final board = boardValues;
    final emptyIndex = selected != null && !fixed.contains(selected)
        ? selected
        : editable.firstWhere(
            (i) => board[i] == null,
            orElse: () => editable.first,
          );
    await _run(() async {
      await _player.debugFillExceptCell(emptyIndex);
      _gameCell = emptyIndex;
      _feedback = null;
      _completion = null;
    });
  }

  int? get debugPreviousGameIndex {
    if (!kDebugMode || reviewOnly || _disposed || _isBusy || session == null) {
      return null;
    }
    final index = step == FirstExperienceStep.playing
        ? gameIndex - 1
        : (step == FirstExperienceStep.celebration ||
              step == FirstExperienceStep.complete)
        ? gameIndex
        : -1;
    return index >= 0 && session!.puzzles[index].status == PlayStatus.completed
        ? index
        : null;
  }

  Future<void> debugRestartPrevious() async {
    final index = debugPreviousGameIndex;
    if (index == null) return;
    await _run(() async {
      await _play?.pause();
      await repository.debugRestartPuzzle(
        session!.id,
        index,
        moduleKey: storageKey,
        moduleData: {
          ..._module,
          'step': FirstExperienceStep.playing.name,
          'gameIndex': index,
          'briefingAccepted': true,
        },
      );
      _step = _savedStep = FirstExperienceStep.playing;
      _gameCell = null;
      _feedback = null;
      _completion = null;
    });
    if (!_disposed && _error == null) await resumeGame();
  }

  Future<void> repeatLessons() async {
    if (_disposed || _isBusy || step != FirstExperienceStep.complete) return;
    await _save(
      FirstExperienceStep.expansion,
      _cells,
      changes: {'accepted': false},
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    _helpVisible = false;
    _isBusy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } catch (_) {
      _error = 'No pudimos guardar tu avance. Intenta de nuevo.';
    } finally {
      _isBusy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> flush() async {
    await _play?.flush();
    await repository.flush();
  }

  Json get _module {
    final value = repository.state.modules[storageKey];
    return value is Map ? jsonObject(value) : {};
  }

  static List<int?> _readCells(Object? value) {
    final used = <int>{};
    return List<int?>.unmodifiable(
      List<int?>.generate(9, (index) {
        final number = value is List && value.length == 9 ? value[index] : null;
        return number is int && number >= 1 && number <= 9 && used.add(number)
            ? number
            : null;
      }),
    );
  }

  Future<void> begin({bool automaticBlock = false}) async {
    if (_disposed || _isBusy || _step != FirstExperienceStep.welcome) return;
    if (!reviewOnly && _savedStep != FirstExperienceStep.welcome) {
      _step = _savedStep == FirstExperienceStep.block
          ? FirstExperienceStep.blockIntroduction
          : _savedStep;
      _error = null;
      notifyListeners();
      return;
    }
    await _save(
      FirstExperienceStep.blockIntroduction,
      automaticBlock ? exampleCenter : _cells,
    );
  }

  Future<void> startBlock() async {
    if (_disposed ||
        _isBusy ||
        _step != FirstExperienceStep.blockIntroduction) {
      return;
    }
    if (_savedStep == FirstExperienceStep.block) {
      _step = FirstExperienceStep.block;
      _error = null;
      notifyListeners();
      return;
    }
    await _save(FirstExperienceStep.block, _cells);
  }

  Future<void> returnToBlockStory() async {
    if (!_canEdit) return;
    await _save(FirstExperienceStep.blockIntroduction, _cells);
  }

  Future<void> expandBoard() async {
    if (!_canEdit || filledCount != 9) return;
    await _save(FirstExperienceStep.expansion, _cells);
  }

  void reviewBlock() {
    if (_disposed ||
        _isBusy ||
        _step != FirstExperienceStep.expansion ||
        session != null) {
      return;
    }
    _step = FirstExperienceStep.blockIntroduction;
    _error = null;
    notifyListeners();
  }

  void selectCell(int index) {
    RangeError.checkValidIndex(index, _cells);
    if (!_canEdit || _selectedCell == index) return;
    _selectedCell = index;
    notifyListeners();
  }

  /// Ignores a digit already used elsewhere; clearing a cell frees its digit.
  Future<void> placeNumber(int number) async {
    RangeError.checkValueInInterval(number, 1, 9, 'number');
    final selected = _selectedCell;
    if (!_canEdit || selected == null || _cells.contains(number)) return;
    final next = [..._cells]..[selected] = number;
    await _save(FirstExperienceStep.block, next, advanceSelection: true);
  }

  Future<void> clearSelected() async {
    final selected = _selectedCell;
    if (!_canEdit || selected == null || _cells[selected] == null) return;
    final next = [..._cells]..[selected] = null;
    await _save(FirstExperienceStep.block, next);
  }

  /// Revisits the welcome without changing the saved step or block draft.
  void reviewWelcome() {
    if (_disposed || _isBusy || _step == FirstExperienceStep.welcome) return;
    _step = FirstExperienceStep.welcome;
    _error = null;
    notifyListeners();
  }

  bool get _canEdit =>
      !_disposed &&
      !_isBusy &&
      _step == FirstExperienceStep.block &&
      session == null;

  Future<void> _save(
    FirstExperienceStep nextStep,
    List<int?> nextCells, {
    bool advanceSelection = false,
    Json changes = const {},
  }) async {
    final snapshot = List<int?>.unmodifiable(nextCells);
    if (reviewOnly) {
      _step = nextStep;
      _cells = snapshot;
      notifyListeners();
      return;
    }
    _helpVisible = false;
    _isBusy = true;
    _error = null;
    notifyListeners();
    try {
      await repository.saveModule(storageKey, {
        ..._module,
        ...changes,
        'selectedCell': null,
        'step': nextStep.name,
        'cells': snapshot,
      });
      _savedStep = nextStep;
      _step = nextStep;
      _cells = snapshot;
      _feedback = null;
      _gameCell = null;
      _completion = null;
      if (advanceSelection) {
        final empty = [
          for (var i = 0; i < _cells.length; i++)
            if (_cells[i] == null) i,
        ];
        if (empty.isNotEmpty) {
          _selectedCell = empty[_random.nextInt(empty.length)];
        }
      }
    } catch (_) {
      _error = 'No pudimos guardar tu avance. Intenta de nuevo.';
    } finally {
      _isBusy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _play?.removeListener(_sessionChanged);
    _play?.dispose();
    super.dispose();
  }
}
