import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/level_catalog.dart';
import '../data/repositories/game_repository.dart';
import '../domain/models/game_session.dart';
import '../domain/models/json_data.dart';
import '../domain/models/sudoku_definition.dart';
import '../domain/tutorial/tutorial_steps.dart';
import '../domain/tutorial/tutorial_sudokus.dart';
import 'game_session_controller.dart';

export '../domain/tutorial/tutorial_steps.dart';

/// Owns the wizard; real play and rewards stay in the session repository.
class FirstExperienceController extends ChangeNotifier {
  FirstExperienceController(
    this.repository, {
    Random? random,
    this.reviewOnly = false,
  }) : _random = random ?? Random() {
    final saved = _module;
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

  final GameRepository repository;
  final bool reviewOnly;
  final Random _random;
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
  Set<int> _conflicts = {};
  int _attention = 0;

  FirstExperienceStep get step =>
      _step == FirstExperienceStep.playing &&
          puzzleProgress?.status == PlayStatus.completed
      ? gameIndex == 2
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
  int get gameIndex => (_module['gameIndex'] as int? ?? 0).clamp(0, 2);
  PuzzleProgress? get puzzleProgress => session?.puzzles[gameIndex];
  SudokuDefinition? get puzzleDefinition =>
      repository.state.puzzles[puzzleProgress?.puzzleId];
  TutorialLesson? get lesson => lessonFor(step, _cells[4] ?? 1);
  int get storyIndex => tutorialStorySteps.indexOf(step);
  int get storyCount => tutorialStorySteps.length;
  bool get isStory => storyIndex >= 0;
  bool get readyToPlay =>
      step == FirstExperienceStep.playing &&
      !_isBusy &&
      _play?.isRunning == true;
  int? get gameCell => _gameCell;
  int get attention => _attention;
  Set<int> get conflicts => _conflicts;
  bool get hasGameBoard =>
      step == FirstExperienceStep.givensIntroduction ||
      (session != null && step.index >= FirstExperienceStep.playing.index);

  /// A read-only example fills gaps while keeping every previously chosen digit.
  List<int> get exampleCenter {
    final chosen = [..._cells];
    final missing = [
      for (final n in [8, 3, 5, 4, 1, 6, 9, 2, 7])
        if (!chosen.contains(n)) n,
    ];
    var next = 0;
    return [for (final value in chosen) value ?? missing[next++]];
  }

  SudokuDefinition get _storyPuzzle =>
      puzzleDefinition ?? TutorialSudokus.create(exampleCenter).first;

  List<int?> get boardValues => hasGameBoard
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

  Future<void> advance() async {
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
        await begin();
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
        gameIndex == 2
            ? FirstExperienceStep.complete
            : FirstExperienceStep.playing,
        _cells,
        changes: {'gameIndex': gameIndex == 2 ? 2 : gameIndex + 1},
      );
      if (_error == null && step == FirstExperienceStep.playing) {
        await resumeGame();
      }
    }
  }

  Future<void> _prepareGames() async {
    if (session != null) {
      await _save(FirstExperienceStep.playing, exampleCenter);
      if (_error == null) await resumeGame();
      return;
    }
    await _run(() async {
      await repository.startOrResumeLevel(
        mapLevelId(1),
        definitions: TutorialSudokus.create(exampleCenter),
        moduleKey: moduleKey,
        moduleData: {
          ..._module,
          'step': FirstExperienceStep.playing.name,
          'cells': exampleCenter,
          'gameIndex': 0,
        },
      );
      _cells = List.unmodifiable(exampleCenter);
      _step = _savedStep = FirstExperienceStep.playing;
    });
    if (!_disposed && _error == null) await resumeGame();
  }

  GameSessionController get _player {
    _play ??= GameSessionController(repository)..addListener(_sessionChanged);
    return _play!;
  }

  void _sessionChanged() {
    if (!_disposed) notifyListeners();
  }

  Future<void> resumeGame() async {
    if (_disposed ||
        _isBusy ||
        step != FirstExperienceStep.playing ||
        session == null) {
      return;
    }
    await _run(() async {
      await _player.start(session!.id);
      _resetMoveFeedback();
    });
  }

  Future<void> pauseGame() async {
    if (_play != null) await _play!.pause();
  }

  void _resetMoveFeedback() {
    _feedback = null;
    _conflicts = {};
  }

  void selectGameCell(int index) {
    RangeError.checkValueInInterval(index, 0, 80, 'index');
    if (!readyToPlay) return;
    _gameCell = index;
    _feedback = null;
    _conflicts = {};
    notifyListeners();
  }

  Future<void> placeGameNumber(int number) async {
    RangeError.checkValueInInterval(number, 1, 9, 'number');
    final index = _gameCell;
    if (!readyToPlay || index == null || fixedIndices.contains(index)) {
      return;
    }
    final board = boardValues;
    if (board[index] == number) return;
    for (final group in SudokuGroup.values) {
      final duplicates = groupCells(
        index,
        group,
      ).where((i) => i != index && board[i] == number).toSet();
      if (duplicates.isNotEmpty) {
        _conflicts = {index, ...duplicates};
        _feedback =
            'Ya hay un $number en ${group.demonstrative} ${group.nameForChild}.\nPrueba otro número.';
        _attention++;
        notifyListeners();
        return;
      }
    }
    if (number != puzzleDefinition!.solution[index]) {
      _conflicts = {index};
      _feedback = 'Ese número no encaja aquí.';
      notifyListeners();
      return;
    }
    await _run(() async {
      await _player.setCell(index, number);
      _resetMoveFeedback();
    });
  }

  Future<void> clearGameCell() async {
    final index = _gameCell;
    if (!readyToPlay ||
        index == null ||
        fixedIndices.contains(index) ||
        boardValues[index] == null) {
      return;
    }
    await _run(() async {
      await _player.setCell(index, null);
      _feedback = null;
      _conflicts = {};
    });
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
    final value = repository.state.modules[moduleKey];
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

  Future<void> begin() async {
    if (_disposed || _isBusy || _step != FirstExperienceStep.welcome) return;
    if (!reviewOnly && _savedStep != FirstExperienceStep.welcome) {
      _step = _savedStep == FirstExperienceStep.block
          ? FirstExperienceStep.blockIntroduction
          : _savedStep;
      _error = null;
      notifyListeners();
      return;
    }
    await _save(FirstExperienceStep.blockIntroduction, _cells);
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
    _step = FirstExperienceStep.block;
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
    _isBusy = true;
    _error = null;
    notifyListeners();
    try {
      await repository.saveModule(moduleKey, {
        ..._module,
        ...changes,
        'step': nextStep.name,
        'cells': snapshot,
      });
      _savedStep = nextStep;
      _step = nextStep;
      _cells = snapshot;
      _feedback = null;
      _conflicts = {};
      _gameCell = null;
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
