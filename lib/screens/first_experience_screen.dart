import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../routes.dart';

import '../controllers/first_experience_controller.dart';
import 'challenge_tutorial_screen.dart';
import 'settings_screen.dart';
import '../widgets/game_navigation_header.dart';
import '../widgets/game_layout.dart';
import '../data/repositories/game_repository.dart';
import '../domain/models/quick_play_difficulty.dart';
import '../widgets/game_feedback_scope.dart';
import '../domain/models/sudoku_completion.dart';
import '../domain/tutorial/tutorial_solution_tour.dart';
import '../widgets/home_art.dart';
import '../widgets/game_pause.dart';
import '../widgets/illustrated_action_button.dart';
import '../widgets/settings_art.dart';
import '../widgets/skip_tutorial_button.dart';
import '../widgets/sudoku_board.dart';
import '../widgets/score_feedback.dart';
import '../data/level_catalog.dart';
import '../widgets/tutorial_story.dart';
import '../widgets/tutorial_block_controls.dart';
import '../widgets/tutorial_journey.dart';
import '../widgets/tutorial_celebration.dart';
import '../widgets/tutorial_story_navigation.dart';
import '../widgets/tutorial_activity.dart';
import '../widgets/tutorial_presentation.dart';
import '../widgets/ui_surface_art.dart';
import '../widgets/victory_particles.dart';
import '../widgets/developer_floating_menu.dart';
import '../widgets/world_journey_route.dart';
import '../widgets/challenge_round_panel.dart';

enum _NextSudokuPhase { leaving, entering }

/// One route owns the introduction and the board it will teach on.
class FirstExperienceScreen extends StatefulWidget {
  const FirstExperienceScreen({
    super.key,
    required this.repository,
    this.showDeveloperControls = kDebugMode,
    this.reviewOnly = false,
    this.levelNumber = 1,
    this.worldId = 'world-1',
    this.quickPlayDifficulty,
    this.notesEnabled = false,
  });

  final GameRepository repository;
  final bool reviewOnly;
  final int levelNumber;
  final String worldId;
  final QuickPlayDifficulty? quickPlayDifficulty;
  final bool notesEnabled;
  final bool showDeveloperControls;

  @override
  State<FirstExperienceScreen> createState() => _FirstExperienceScreenState();
}

class _FirstExperienceScreenState extends State<FirstExperienceScreen>
    with TickerProviderStateMixin {
  static const _center = [30, 31, 32, 39, 40, 41, 48, 49, 50];
  late final _flow = FirstExperienceController(
    widget.repository,
    reviewOnly: widget.reviewOnly,
    levelNumber: widget.levelNumber,
    worldId: widget.worldId,
    quickPlayDifficulty: widget.quickPlayDifficulty,
    notesEnabled: widget.notesEnabled,
  );
  // Preserve the board and focus when the responsive layout changes parents.
  final _stageKey = GlobalKey();
  final _storyKey = GlobalKey();
  final _tutorialStory = TutorialStoryController();
  FirstExperienceStep? _finishedStoryStep;
  late final _blockDeal =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
        value: 1,
      )..addStatusListener((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      });

  late final _blockTour =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 5400),
        value: 1,
      )..addStatusListener((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      });

  bool _blockTourPending = false;

  late final _solutionTour = AnimationController(
    vsync: this,
    duration: TutorialSolutionTour.duration,
    value: 1,
  );

  void _queueBlockTour() {
    _blockTourPending = true;
    _blockTour.value = 1;
    // Allow the board to lay out and report its expansion animation first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startBlockTour());
      WidgetsBinding.instance.scheduleFrame();
    });
  }

  void _startBlockTour() {
    if (!mounted ||
        !_blockTourPending ||
        _boardAnimating ||
        _flow.step != FirstExperienceStep.expansion) {
      return;
    }
    setState(() {
      _blockTourPending = false;
      _blockTour.forward(from: 0);
    });
  }

  List<int> get _lessonHighlights {
    if (_flow.step == FirstExperienceStep.solvedExample) {
      return TutorialSolutionTour(_solutionTour.value).highlightedIndices;
    }
    if (_flow.step != FirstExperienceStep.expansion) {
      return _flow.highlightedIndices;
    }
    if (_reduceAnimations || _blockTourPending || _blockTour.isCompleted) {
      return [];
    }
    final block = (_blockTour.value * 9).floor().clamp(0, 8);
    final row = (block ~/ 3) * 3;
    final column = (block % 3) * 3;
    return [
      for (var r = 0; r < 3; r++)
        for (var c = 0; c < 3; c++) (row + r) * 9 + column + c,
    ];
  }

  void _storyFinished(FirstExperienceStep step) {
    if (mounted && _flow.step == step && _finishedStoryStep != step) {
      setState(() => _finishedStoryStep = step);
    }
  }

  bool _finishTutorialAnimation() {
    var changed = false;
    if (_welcome && !_dokuReady) {
      _dokuEntrance.value = 1;
      _dokuReady = true;
      changed = true;
    }
    if (_flow.step == FirstExperienceStep.blockIntroduction &&
        _blockDeal.isAnimating) {
      _blockDeal.value = 1;
      changed = true;
    }
    if (_flow.step == FirstExperienceStep.expansion &&
        (_blockTourPending || _blockTour.isAnimating)) {
      _blockTourPending = false;
      _blockTour.value = 1;
      changed = true;
    }
    if (_flow.step == FirstExperienceStep.solvedExample &&
        _solutionTour.isAnimating) {
      _solutionTour.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tutorialStory.finish();
      });
      changed = true;
    }
    if (_tutorialStory.finish()) changed = true;
    if (changed && mounted) setState(() {});
    return changed;
  }

  Future<void> _continueTutorial() async {
    if (_flow.isBusy || _skippingTutorial || _settingsOpen) return;
    if (_finishTutorialAnimation()) return;
    if (_navigationBlocked) return;
    await _flow.advance();
  }

  Widget _tutorialSkipButton() => SkipTutorialButton(
    key: const ValueKey('tutorial-skip'),
    onPressed: _skippingTutorial || _flow.isBusy ? null : _skipTutorial,
  );

  late final _dokuEntrance =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 650),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _dokuReady = true);
        }
      });
  late final _gameEntrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    value: 1,
  );
  Offset _gameStartOffset = Offset.zero;
  double _gameStartScale = 1;
  late final _rewardLayerKey = GlobalKey();
  final _rewardActionKey = GlobalKey();
  late final _rewardBoardSlotKey = GlobalKey();
  Rect? _rewardFlightFrom;
  Rect? _rewardFlightTo;
  _NextSudokuPhase? _nextPhase;
  Rect? _nextFrom;
  Rect? _nextTo;
  bool? _nextTargetScheduled;
  late final _nextBoardSlotKey = GlobalKey();
  late final _nextExit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final AnimationController _nextEntrance =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1350),
        value: 1,
      )..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              _nextPhase == _NextSudokuPhase.entering &&
              _nextEntrance.isCompleted) {
            setState(_clearNextTransition);
            if (_flow.isGeneratedLevel) unawaited(_flow.resumeGame());
          }
        });
      });
  bool? _rewardTargetScheduled;
  late final AnimationController _rewardEntrance =
      AnimationController(
        vsync: this,
        duration: tutorialCelebrationDuration,
        value: 1,
      )..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _rewardEntrance.isCompleted) {
            setState(() {
              _rewardFlightFrom = null;
              _rewardFlightTo = null;
            });
          }
        });
      });
  bool _briefingPending = false;
  bool _briefingScheduled = false;
  bool _settingsOpen = false;
  bool _skippingTutorial = false;
  bool _boardAnimating = false;
  SudokuCompletion? _pendingBoardCompletion;
  late SudokuCompletion? _previousCompletion = _flow.completion;
  bool get _finishingBoard => _pendingBoardCompletion != null;
  bool get _needsChallengeLesson =>
      widget.worldId == 'world-3' &&
      _flow.isChallenge &&
      !widget.repository.challengeTutorialCompleted;
  bool get _showGame =>
      _flow.step == FirstExperienceStep.playing ||
      _flow.challengeOverlay ||
      _finishingBoard;
  bool get _showTutorialSkip =>
      !_showGame &&
      (_flow.reviewOnly ||
          (!_flow.isGeneratedLevel &&
              _flow.step.index < FirstExperienceStep.playing.index));
  bool get _canSkipTutorialAnimations =>
      _flow.reviewOnly || _flow.session != null;
  bool get _navigationBlocked =>
      (!_canSkipTutorialAnimations &&
          ((_flow.isStory && _finishedStoryStep != _flow.step) ||
              _blockDeal.isAnimating ||
              _blockTourPending ||
              _blockTour.isAnimating)) ||
      _settingsOpen ||
      _skippingTutorial ||
      _openingNextLevel ||
      _flow.isBusy ||
      (_boardAnimating && (!_flow.isStory || !_canSkipTutorialAnimations)) ||
      _finishingBoard ||
      _rewardFlightFrom != null ||
      _nextPhase != null ||
      _briefingPending ||
      _gameEntrance.isAnimating;

  void _boardAnimationChanged(bool animating) {
    if (mounted && _boardAnimating != animating) {
      setState(() => _boardAnimating = animating);
      if (!animating) _startBlockTour();
    }
  }

  void _completionFinished(SudokuCompletion completion) {
    if (mounted && identical(completion, _pendingBoardCompletion)) {
      final from = _boardRect();
      final reduced =
          MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context);
      setState(() {
        _pendingBoardCompletion = null;
        if (from != null && !reduced) {
          _rewardFlightFrom = from;
          _rewardFlightTo = null;
          _rewardEntrance.value = 0;
        }
      });
    }
  }

  void _measureRewardTarget() {
    if (_rewardTargetScheduled == true) return;
    _rewardTargetScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rewardTargetScheduled = false;
      if (!mounted || _rewardFlightFrom == null) return;
      final target = _rectInBoardLayer(_rewardBoardSlotKey);
      if (target == null) return;
      if (target != _rewardFlightTo) setState(() => _rewardFlightTo = target);
      if (!_rewardEntrance.isAnimating && _rewardEntrance.value == 0) {
        _rewardEntrance.forward();
      }
    });
  }

  Widget _rewardFlight(List<int?> cells, Duration motion) => Positioned.fill(
    child: LayoutBuilder(
      builder: (context, bounds) {
        _measureRewardTarget();
        return IgnorePointer(
          child: AnimatedBuilder(
            animation: _rewardEntrance,
            builder: (context, child) {
              final progress = Curves.easeInOutCubic.transform(
                (_rewardEntrance.value *
                        tutorialCelebrationDuration.inMilliseconds /
                        tutorialBoardFlightDuration)
                    .clamp(0.0, 1.0),
              );
              final rect = Rect.lerp(
                _rewardFlightFrom!,
                _rewardFlightTo ?? _rewardFlightFrom!,
                progress,
              )!;
              return Stack(
                clipBehavior: Clip.none,
                children: [Positioned.fromRect(rect: rect, child: child!)],
              );
            },
            child: _stage(cells, motion),
          ),
        );
      },
    ),
  );

  bool get _reduceAnimations =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);

  void _clearNextTransition() {
    _nextPhase = null;
    _nextFrom = null;
    _nextTo = null;
    _nextExit.value = 0;
    _nextEntrance.value = 1;
  }

  Future<void> _advanceGame() async {
    if (_navigationBlocked || _flow.step != FirstExperienceStep.celebration) {
      return;
    }
    final from = _boardRect();
    if (from == null || _reduceAnimations) {
      await _flow.advance();
      return;
    }
    setState(() {
      _nextFrom = from;
      _nextTo = null;
      _nextPhase = _NextSudokuPhase.leaving;
      _nextExit.value = 0;
      _nextEntrance.value = 0;
    });
    try {
      await _nextExit.forward().orCancel;
      if (!mounted) return;
      await _flow.advance(startClock: !_flow.isGeneratedLevel);
      if (!mounted) return;
      if (_flow.step != FirstExperienceStep.playing ||
          _flow.error != null ||
          _reduceAnimations) {
        setState(_clearNextTransition);
        if (_flow.isGeneratedLevel) await _flow.resumeGame();
      } else {
        setState(() => _nextPhase = _NextSudokuPhase.entering);
      }
    } on TickerCanceled {
      // The route was disposed during the departure.
    }
  }

  void _measureNextTarget() {
    if (_nextPhase != _NextSudokuPhase.entering ||
        _nextTargetScheduled == true) {
      return;
    }
    _nextTargetScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nextTargetScheduled = false;
      if (!mounted || _nextPhase != _NextSudokuPhase.entering) return;
      final target = _rectInBoardLayer(_nextBoardSlotKey);
      if (target == null) return;
      if (_nextTo != target) setState(() => _nextTo = target);
      if (!_nextEntrance.isAnimating && _nextEntrance.value == 0) {
        _nextEntrance.forward();
      }
    });
  }

  Widget _nextBoardFlight(List<int?> cells, Duration motion) => Positioned.fill(
    child: LayoutBuilder(
      builder: (context, bounds) {
        _measureNextTarget();
        return IgnorePointer(
          child: AnimatedBuilder(
            animation: Listenable.merge([_nextExit, _nextEntrance]),
            builder: (context, _) {
              final from = _nextFrom!;
              final Rect rect;
              final double opacity;
              if (_nextPhase == _NextSudokuPhase.leaving) {
                final progress = Curves.easeInCubic.transform(_nextExit.value);
                rect = from.shift(Offset(-(from.right + 24) * progress, 0));
                opacity = 1 - progress;
              } else {
                final target = _nextTo ?? from;
                final start = Rect.fromCenter(
                  center: target.center + Offset(bounds.maxWidth, 0),
                  width: from.width,
                  height: from.height,
                );
                final time = _nextEntrance.value * 1350;
                final progress = Curves.easeInOutCubic.transform(
                  (time / 800).clamp(0.0, 1.0),
                );
                rect = Rect.lerp(start, target, progress)!;
                opacity = (time / 180).clamp(0.0, 1.0);
              }
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fromRect(
                    rect: rect,
                    child: Opacity(
                      key: const ValueKey('next-board-fade'),
                      opacity: opacity,
                      child: _stage(cells, motion),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    ),
  );

  bool _dokuReady = false;
  bool _entranceStarted = false;
  bool _hasLeftWelcome = false;
  late FirstExperienceStep _previousStep;
  late int _previousAttention = _flow.attention;

  bool get _welcome => _flow.step == FirstExperienceStep.welcome;
  bool get _explaining => _welcome;
  int get _activeCell =>
      _flow.selectedCell ??
      (!_flow.cells.contains(null) ? 8 : _flow.cells.indexOf(null));

  Future<void> _placeNumber(int number) async {
    if (_flow.isBusy) return;
    if (_flow.selectedCell == null) _flow.selectCell(_activeCell);
    GameFeedbackScope.tap(context);
    await _flow.placeNumber(number);
  }

  Future<void> _clearNumber() async {
    if (_flow.isBusy) return;
    if (_flow.selectedCell == null) _flow.selectCell(_activeCell);
    GameFeedbackScope.tap(context);
    await _flow.clearSelected();
  }

  @override
  void initState() {
    super.initState();
    _previousStep = _flow.step;
    _previousAttention = _flow.attention;
    _previousCompletion = _flow.completion;
    _briefingPending =
        _flow.step == FirstExperienceStep.playing && _needsBriefing;
    _flow.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (!_needsChallengeLesson &&
            !_flow.challengeOverlay &&
            (!_flow.isPaused || _flow.isQuickPlay)) {
          unawaited(_flow.resumeGame());
        }
        if (_flow.step == FirstExperienceStep.playing && _needsBriefing) {
          _openGameBriefing();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      _dokuEntrance.value = 1;
      _blockDeal.value = 1;
      _blockTourPending = false;
      _blockTour.value = 1;
      _solutionTour.value = 1;
      _rewardEntrance.value = 1;
      if (_nextPhase == _NextSudokuPhase.leaving) _nextExit.value = 1;
      _nextEntrance.value = 1;
    } else if (!_entranceStarted) {
      _dokuEntrance.forward();
      if (_flow.step == FirstExperienceStep.expansion) _queueBlockTour();
      if (_flow.step == FirstExperienceStep.solvedExample) {
        _solutionTour.forward(from: 0);
      }
      if (_flow.step == FirstExperienceStep.blockIntroduction) {
        _blockDeal.forward(from: 0);
      }
    }
    _entranceStarted = true;
  }

  Future<void> _openSettings() async {
    if (_navigationBlocked) return;
    setState(() => _settingsOpen = true);
    try {
      await _flow.pauseGame();
      if (!mounted) return;
      await Navigator.of(context)
          .push(SettingsRoute(repository: widget.repository));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos abrir configuración. Intenta de nuevo.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        if (!_flow.isGeneratedLevel) await _flow.resumeGame();
        if (mounted) setState(() => _settingsOpen = false);
      }
    }
  }

  bool get _needsBriefing =>
      !_flow.isQuickPlay &&
      !widget.reviewOnly &&
      widget.worldId == 'world-1' &&
      widget.levelNumber == 1 &&
      _flow.gameIndex == 0 &&
      (widget.repository.state.modules[FirstExperienceController.moduleKey]
              as Map?)?['briefingAccepted'] !=
          true;

  Rect? _boardRect() => _rectInBoardLayer(_stageKey);

  Rect? _rectInBoardLayer(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    final layer = _rewardLayerKey.currentContext?.findRenderObject();
    if (box is! RenderBox ||
        layer is! RenderBox ||
        !box.attached ||
        !layer.attached ||
        !box.hasSize ||
        !layer.hasSize) {
      return null;
    }
    // Keep board flights in the game Stack's coordinates. Route transforms
    // above it may be replaced before layout when a cinematic closes on iOS.
    return box.localToGlobal(Offset.zero, ancestor: layer) & box.size;
  }

  Future<void> _openGameBriefing({Rect? from}) async {
    if (_briefingScheduled || !mounted) return;
    _briefingScheduled = true;
    setState(() => _briefingPending = true);
    final target = _boardRect();
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (!reduced && from != null && target != null) {
      _gameStartOffset = from.topLeft - target.topLeft;
      _gameStartScale = from.width / target.width;
      try {
        await _gameEntrance.forward(from: 0).orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (!mounted) return;
    if (!_needsBriefing) {
      setState(() => _briefingPending = false);
      _briefingScheduled = false;
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(20),
          child: _GameBriefing(
            onAccept: () async {
              final saved =
                  widget.repository.state.modules[FirstExperienceController
                          .moduleKey]
                      as Map?;
              await widget.repository.saveModule(
                FirstExperienceController.moduleKey,
                {
                  if (saved != null) ...Map<String, dynamic>.from(saved),
                  'briefingAccepted': true,
                },
              );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
          ),
        ),
      ),
    );
    if (mounted) setState(() => _briefingPending = false);
    _briefingScheduled = false;
  }

  void _changed() {
    if (_previousStep != _flow.step) {
      _finishedStoryStep = null;
      if (_flow.step == FirstExperienceStep.solvedExample &&
          !_reduceAnimations) {
        _solutionTour.forward(from: 0);
      } else {
        _solutionTour.value = 1;
      }
      if (_flow.step == FirstExperienceStep.expansion && !_reduceAnimations) {
        _queueBlockTour();
      } else {
        _blockTourPending = false;
        _blockTour.value = 1;
      }
      if (_flow.step == FirstExperienceStep.blockIntroduction) {
        if (_reduceAnimations) {
          _blockDeal.value = 1;
        } else {
          _blockDeal.forward(from: 0);
        }
      }
    }
    if (!identical(_previousCompletion, _flow.completion)) {
      _previousCompletion = _flow.completion;
      _pendingBoardCompletion = _flow.completion?.wholeBoard == true
          ? _flow.completion
          : null;
    }
    if (_previousStep == FirstExperienceStep.playing &&
        (_flow.step == FirstExperienceStep.celebration ||
            _flow.step == FirstExperienceStep.complete) &&
        mounted &&
        ModalRoute.of(context)?.isCurrent != false) {
      GameFeedbackScope.levelCompleted(context);
    }
    if (_previousAttention != _flow.attention) {
      _previousAttention = _flow.attention;
      if (mounted && ModalRoute.of(context)?.isCurrent != false) {
        GameFeedbackScope.error(context);
      }
    }
    if (_previousStep == FirstExperienceStep.givensIntroduction &&
        _flow.step == FirstExperienceStep.playing &&
        _needsBriefing) {
      final from = _boardRect();
      _briefingPending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openGameBriefing(from: from);
      });
    }
    if (_previousStep == FirstExperienceStep.welcome && !_welcome) {
      _hasLeftWelcome = true;
    }
    if (_explaining && _flow.step != _previousStep) {
      _dokuReady = false;
      if (_hasLeftWelcome ||
          MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context)) {
        _dokuReady = true;
        _dokuEntrance.value = 1;
      } else {
        _dokuEntrance.forward(from: 0);
      }
    }
    _previousStep = _flow.step;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _flow.removeListener(_changed);
    _flow.dispose();
    _dokuEntrance.dispose();
    _blockDeal.dispose();
    _blockTour.dispose();
    _solutionTour.dispose();
    _gameEntrance.dispose();
    _rewardEntrance.dispose();
    _nextExit.dispose();
    _nextEntrance.dispose();
    super.dispose();
  }

  Future<void> _back() async {
    if (_navigationBlocked) return;
    if (_flow.isBusy) return;
    if (_welcome ||
        _flow.session != null ||
        _flow.step.index > FirstExperienceStep.expansion.index) {
      try {
        await _flow.pauseGame();
        await _flow.flush();
        if (mounted) Navigator.of(context).maybePop();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No pudimos guardar. Intenta salir otra vez.'),
            ),
          );
        }
      }
    } else if (_flow.step == FirstExperienceStep.expansion) {
      _flow.reviewBlock();
    } else {
      _flow.reviewWelcome();
    }
  }

  Future<void> _developerExit() async {
    try {
      await _flow.pauseGame();
      await _flow.flush();
    } finally {
      if (mounted) {
        setState(() => _developerExiting = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).maybePop();
        });
      }
    }
  }

  bool _developerExiting = false;

  Future<void> _skipTutorial() async {
    if (_skippingTutorial || _flow.isBusy || _settingsOpen) return;
    setState(() => _skippingTutorial = true);
    try {
      if (_flow.reviewOnly) {
        if (mounted) await Navigator.of(context).maybePop();
      } else if (!await _flow.skipTutorial() && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _flow.error ?? 'No pudimos saltar el tutorial. Intenta otra vez.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos saltar el tutorial. Intenta otra vez.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _skippingTutorial = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_needsChallengeLesson) {
      return ChallengeTutorialScreen(
        repository: widget.repository,
        onFinished: () async {
          if (mounted) setState(() {});
        },
      );
    }
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 450);
    final cells = _flow.boardValues;

    return PopScope(
      canPop:
          (_developerExiting ||
              _welcome ||
              _flow.session != null ||
              _flow.step.index > FirstExperienceStep.expansion.index) &&
          !_navigationBlocked,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_navigationBlocked && !_welcome) _back();
      },
      child: Scaffold(
        key: const ValueKey('first-experience-flow'),
        body: Stack(
          key: _rewardLayerKey,
          fit: StackFit.expand,
          children: [
            const _WorldBackdrop(),
            SafeArea(
              child: Flex(
                direction: Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, bounds) {
                        final storyStep = _flow.step;
                        final wide =
                            bounds.maxWidth >= 700 &&
                            bounds.maxWidth > bounds.maxHeight * 1.2;
                        final titleInGameAppBar = _showGame;
                        final largeGameLayout =
                            titleInGameAppBar &&
                            GameLayout.useLargePlayLayout(bounds.biggest);
                        final flowHeader = _FlowHeader(
                          welcome: false,
                          compact: titleInGameAppBar,
                          largeStyle: largeGameLayout,
                          title: !_flow.isQuickPlay
                              ? 'Juego ${_flow.levelNumber}'
                              : TutorialJourney.title(_flow),
                          subtitle: !_flow.isQuickPlay
                              ? 'Ronda ${_flow.gameIndex + 1} de ${_flow.roundCount}'
                              : null,
                        );
                        final Widget content;
                        if (_welcome) {
                          content = _explanationLayout(
                            cells,
                            motion,
                            wide: wide,
                            compact: wide || bounds.maxHeight < 650,
                          );
                        } else if (_flow.isStory ||
                            _flow.step.index >=
                                FirstExperienceStep.expansion.index) {
                          content = TutorialJourney(
                            onLessonFinished: () => _storyFinished(storyStep),
                            storyController: _tutorialStory,
                            onRevealAnimation: _showTutorialSkip
                                ? _finishTutorialAnimation
                                : null,
                            skipAction: _showTutorialSkip
                                ? _tutorialSkipButton()
                                : null,
                            solutionTour: _solutionTour,
                            navigationBlocked: _navigationBlocked,
                            finishingBoard: _finishingBoard,
                            flow: _flow,
                            board:
                                _rewardFlightFrom == null && _nextPhase == null
                                ? _stage(cells, motion)
                                : const SizedBox.expand(),
                            rewardAnimation: _rewardEntrance,
                            rewardBoardSlotKey: _rewardBoardSlotKey,
                            rewardActionKey: _rewardActionKey,
                            gameBoardSlotKey: _nextBoardSlotKey,
                            departure: _nextExit,
                            gameEntrance: _nextEntrance,
                            onNextGame: _advanceGame,
                            nextLevelNumber: _nextLevelNumber,
                            onNextLevel: _openNextLevel,
                            navigation: _showGame
                                ? GameNavigationHeader(
                                    backLabel: _flow.isQuickPlay
                                        ? 'Volver al inicio'
                                        : 'Volver al mapa',
                                    pauseAction: largeGameLayout
                                        ? GamePauseButton(
                                            key: const ValueKey('game-pause'),
                                            flow: _flow,
                                            blocked: _navigationBlocked,
                                          )
                                        : null,
                                    center: titleInGameAppBar
                                        ? flowHeader
                                        : null,
                                    onBack: _navigationBlocked ? null : _back,
                                    onSettings: _navigationBlocked
                                        ? null
                                        : _openSettings,
                                  )
                                : null,
                            header: Column(
                              children: [
                                if (_flow.isStory) ...[
                                  TutorialStoryProgress(
                                    index: _flow.storyIndex,
                                    count: _flow.storyCount,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (!titleInGameAppBar)
                                  _FlowHeader(
                                    welcome: false,
                                    title: _finishingBoard && !_flow.isQuickPlay
                                        ? 'Ronda ${_flow.gameIndex + 1} de 3'
                                        : TutorialJourney.title(_flow),
                                  ),
                              ],
                            ),
                            onExit: () {
                              if (!_navigationBlocked) {
                                Navigator.of(context).pop();
                              }
                            },
                            onWorldCompleted: () {
                              if (!_navigationBlocked) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  AppRoutes.home,
                                  (_) => false,
                                );
                              }
                            },
                          );
                        } else {
                          content = _blockLayout(cells, motion);
                        }
                        if (!_flow.isStory) return content;
                        return TutorialActivity(
                          child: TutorialStoryGestures(
                            key: const ValueKey('tutorial-story-gestures'),
                            enabled: !_navigationBlocked,
                            onNext: () {
                              if (_navigationBlocked) return;
                              if (_flow.reviewOnly &&
                                  _flow.storyIndex == _flow.storyCount - 1) {
                                Navigator.of(context).pop();
                              } else {
                                _flow.advance();
                              }
                            },
                            onPrevious: _flow.storyIndex > 0
                                ? () {
                                    if (!_navigationBlocked) {
                                      _flow.previousStory();
                                    }
                                  }
                                : null,
                            child: content,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_rewardFlightFrom != null) _rewardFlight(cells, motion),
            if (_nextPhase != null) _nextBoardFlight(cells, motion),
            if (!_finishingBoard &&
                (_flow.step == FirstExperienceStep.celebration ||
                    _flow.step == FirstExperienceStep.complete))
              Positioned.fill(
                key: const ValueKey('victory-particles-layer'),
                child: FadeTransition(
                  opacity: ReverseAnimation(_nextExit),
                  child: VictoryParticles(
                    key: ValueKey('victory-particles-${_flow.gameIndex}'),
                    foregroundBounds: () {
                      final action = _rewardActionKey.currentContext
                          ?.findRenderObject();
                      final layer = _rewardLayerKey.currentContext
                          ?.findRenderObject();
                      if (action is! RenderBox ||
                          layer is! RenderBox ||
                          !action.hasSize) {
                        return null;
                      }
                      return action.localToGlobal(
                            Offset.zero,
                            ancestor: layer,
                          ) &
                          action.size;
                    },
                    entrance: _rewardEntrance,
                    grandFinale: _flow.step == FirstExperienceStep.complete,
                  ),
                ),
              ),
            if (_flow.challengeOverlay) ...[
              const Positioned.fill(
                child: ModalBarrier(
                  dismissible: false,
                  color: Color(0x99072346),
                ),
              ),
              Positioned.fill(
                child: BlockSemantics(
                  child: ChallengeRoundPanel(
                    flow: _flow,
                    onExit: () => _back(),
                  ),
                ),
              ),
            ],
            if (kDebugMode &&
                widget.showDeveloperControls &&
                !_flow.challengeOverlay)
              DeveloperFloatingMenu(
                actions: [
                  if (!_navigationBlocked &&
                      _flow.readyToPlay &&
                      !_flow.reviewOnly)
                    DeveloperMenuAction(
                      key: const ValueKey('dev-notes'),
                      label: _flow.notesAvailable
                          ? 'Ocultar lápiz de prueba'
                          : 'Probar anotaciones',
                      icon: Icons.edit_note_rounded,
                      onPressed: _flow.debugToggleNotes,
                    ),
                  if (!_navigationBlocked &&
                      _flow.readyToPlay &&
                      !_flow.reviewOnly)
                    DeveloperMenuAction(
                      key: const ValueKey('dev-fill-except-one'),
                      label: 'Completar menos 1',
                      icon: Icons.grid_on_rounded,
                      onPressed: _flow.debugFillExceptOne,
                    ),
                  if (!_navigationBlocked &&
                      _flow.debugPreviousGameIndex != null)
                    DeveloperMenuAction(
                      key: const ValueKey('dev-restart-previous'),
                      label:
                          'Repetir sudoku ${_flow.debugPreviousGameIndex! + 1}',
                      icon: Icons.replay_rounded,
                      onPressed: _flow.debugRestartPrevious,
                    ),
                  DeveloperMenuAction(
                    key: const ValueKey('dev-exit-tutorial'),
                    label: 'Salir',
                    icon: Icons.exit_to_app_rounded,
                    onPressed: _developerExit,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  int? get _nextLevelNumber {
    if (_flow.isQuickPlay) return null;
    final number = widget.levelNumber + 1;
    if (number > _flow.world.nodes.length ||
        !widget.repository.state.isUnlocked(
          mapLevelId(number, worldId: widget.worldId),
        ) ||
        (widget
                    .repository
                    .state
                    .progress[mapLevelId(number, worldId: widget.worldId)]
                    ?.bestLights ??
                0) >=
            3) {
      return null;
    }
    return number;
  }

  bool _openingNextLevel = false;
  Future<void> _openNextLevel() async {
    final number = _nextLevelNumber;
    if (number == null || _navigationBlocked || _openingNextLevel) return;
    setState(() => _openingNextLevel = true);
    try {
      await _flow.pauseGame();
      await widget.repository.startGeneratedLevel(
        number,
        worldId: widget.worldId,
      );
      if (!mounted) return;
      unawaited(
        Navigator.of(context).pushReplacement<void, void>(
          WorldJourneyRoute(
            settings: const RouteSettings(name: AppRoutes.game),
            reduceMotion: MediaQuery.disableAnimationsOf(context),
            builder: (_) => FirstExperienceScreen(
              repository: widget.repository,
              levelNumber: number,
              worldId: widget.worldId,
              showDeveloperControls: widget.showDeveloperControls,
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos abrir el siguiente nivel. Intenta de nuevo.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _openingNextLevel = false);
    }
  }

  Widget _explanationLayout(
    List<int?> cells,
    Duration motion, {
    required bool wide,
    required bool compact,
  }) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: wide ? 992 : 502),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            TutorialStepHeader(
              index: _flow.storyIndex,
              count: _flow.storyCount,
              child: _FlowHeader(welcome: _welcome),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, bounds) {
                  final artWidth = wide
                      ? (bounds.maxWidth - 24) / 2
                      : bounds.maxWidth;
                  final artHeight = math.min(
                    artWidth / _WelcomeGuide.aspectRatio,
                    math.max(
                      140.0,
                      bounds.maxHeight *
                          (wide
                              ? .95
                              : .48 * (bounds.maxHeight / 480).clamp(.7, 1.0)),
                    ),
                  );
                  // Only the central content scrolls. Text scaling and errors
                  // must never move the primary action away from the bottom.
                  return SingleChildScrollView(
                    key: const ValueKey('intro-scroll'),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: bounds.maxHeight),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (wide)
                              Row(
                                children: [
                                  SizedBox(
                                    width: artWidth,
                                    height: artHeight,
                                    child: _stage(cells, motion),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(child: _instructions(context)),
                                ],
                              )
                            else ...[
                              SizedBox(
                                height: artHeight,
                                child: _stage(cells, motion),
                              ),
                              const SizedBox(height: 20),
                              _instructions(context),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IllustratedActionButton(
                  key: ValueKey(
                    _welcome ? 'intro-continue' : 'intro-start-block',
                  ),
                  compact: compact,
                  fontSize: 22,
                  showPlayIcon:
                      MediaQuery.textScalerOf(context).scale(16) <= 24,
                  label: _flow.isBusy ? 'Guardando…' : 'Siguiente',
                  onPressed: _flow.isBusy || _skippingTutorial
                      ? null
                      : _continueTutorial,
                ),
                const SizedBox(height: 6),
                _tutorialSkipButton(),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _blockLayout(List<int?> cells, Duration motion) {
    final expanded = _flow.step == FirstExperienceStep.expansion;
    final complete = _flow.filledCount == 9 && !expanded;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 502),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              _FlowHeader(welcome: false, expanded: expanded),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, bounds) {
                    final boardSize = math.min(
                      bounds.maxWidth * (expanded ? .94 : .72),
                      math.max(
                        210.0,
                        bounds.maxHeight - (expanded ? 150 : 300),
                      ),
                    );
                    return SingleChildScrollView(
                      key: const ValueKey('intro-scroll'),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: bounds.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!expanded)
                                  Expanded(
                                    child: Center(
                                      child: TutorialEraseButton(
                                        onPressed:
                                            _flow.isBusy ||
                                                _flow.cells[_activeCell] == null
                                            ? null
                                            : _clearNumber,
                                      ),
                                    ),
                                  ),
                                SizedBox.square(
                                  dimension: boardSize,
                                  child: _stage(cells, motion),
                                ),
                                if (!expanded) const SizedBox(width: 18),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (!expanded)
                              TutorialNumberTray(
                                key: const ValueKey('intro-number-tray'),
                                available: [
                                  for (var n = 1; n <= 9; n++)
                                    if (!_flow.cells.contains(n)) n,
                                ],
                                onSelected: _flow.isBusy ? null : _placeNumber,
                              ),
                            const SizedBox(height: 4),
                            TutorialBlockCard(
                              key: const ValueKey('intro-block-card'),
                              filledCount: _flow.filledCount,
                              expanded: expanded,
                            ),
                            TextButton(
                              key: const ValueKey('tutorial-return-story'),
                              onPressed: _flow.isBusy
                                  ? null
                                  : _flow.returnToBlockStory,
                              child: Text(
                                'Volver a la historia',
                                style: homeText(16),
                              ),
                            ),
                            if (_flow.error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    _flow.error!,
                                    textAlign: TextAlign.center,
                                    style: homeText(16),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              AnimatedSwitcher(
                duration: motion,
                child: complete
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: IllustratedActionButton(
                          key: const ValueKey('intro-next'),
                          label: _flow.isBusy ? 'Guardando…' : 'Siguiente',
                          fontSize: 25,
                          onPressed: _flow.isBusy ? null : _flow.expandBoard,
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              if (_showTutorialSkip) ...[
                const SizedBox(height: 6),
                _tutorialSkipButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _stage(List<int?> cells, Duration motion) => AnimatedBuilder(
    animation: Listenable.merge([_blockDeal, _blockTour, _solutionTour]),
    builder: (context, _) => _animatedStage(cells, motion),
  );

  Widget _animatedStage(List<int?> cells, Duration motion) => Center(
    key: _stageKey,
    child: AnimatedBuilder(
      animation: _gameEntrance,
      builder: (_, child) {
        final remaining =
            1 - Curves.easeInOutCubic.transform(_gameEntrance.value);
        return Transform.translate(
          offset: _gameStartOffset * remaining,
          child: Transform.scale(
            alignment: Alignment.topLeft,
            scale: 1 + (_gameStartScale - 1) * remaining,
            child: child,
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            ignoring: _explaining || _navigationBlocked,
            child: ExcludeSemantics(
              excluding: _explaining,
              child: AnimatedOpacity(
                opacity: _explaining ? 0 : 1,
                duration: motion,
                child: Center(
                  child: SudokuBoard(
                    key: const ValueKey('intro-board'),
                    dealProgress:
                        _flow.step == FirstExperienceStep.blockIntroduction
                        ? _blockDeal.value
                        : _nextPhase == _NextSudokuPhase.entering
                        ? ((_nextEntrance.value * 1350 - 800) / 500).clamp(
                            0.0,
                            1.0,
                          )
                        : null,
                    onAnimationChanged: _boardAnimationChanged,
                    reveal: switch (_flow.step) {
                      FirstExperienceStep.rowRule => SudokuBoardReveal.row,
                      FirstExperienceStep.columnRule =>
                        SudokuBoardReveal.column,
                      FirstExperienceStep.solvedExample =>
                        SudokuBoardReveal.remaining,
                      FirstExperienceStep.givensIntroduction =>
                        SudokuBoardReveal.givens,
                      _ => SudokuBoardReveal.none,
                    },
                    cells: cells,
                    notes: _flow.boardNotes,
                    notesMode:
                        _flow.notesMode &&
                        _flow.step == FirstExperienceStep.playing,
                    emphasizedNumber:
                        _flow.step == FirstExperienceStep.solvedExample
                        ? TutorialSolutionTour.number
                        : null,
                    selectedIndex: _explaining
                        ? null
                        : _flow.step == FirstExperienceStep.block
                        ? _center[_activeCell]
                        : _showGame
                        ? _flow.gameCell
                        : _flow.step == FirstExperienceStep.rowRule ||
                              _flow.step == FirstExperienceStep.columnRule
                        ? 40
                        : null,
                    centerOnly:
                        _flow.step.index < FirstExperienceStep.expansion.index,
                    highlightedIndices: _lessonHighlights,
                    helpFocusIndices: _flow.helpTip?.focusIndices ?? const {},
                    helpEmphasizedNumber: _flow.helpTip?.emphasizedNumber,
                    helpTraces: _flow.helpTip?.traces ?? const [],
                    helpArrivalIndex: _flow.helpTip?.arrivalIndex,
                    conflictIndices: _flow.conflicts,
                    errorPulse: _flow.attention,
                    completion: _flow.completion,
                    onCompletionFinished: _completionFinished,
                    fixedIndices: _flow.fixedIndices,
                    highlightKey: _flow.session != null && !_flow.isStory
                        ? FirstExperienceStep.playing
                        : _flow.step,
                    onSelect: _explaining || _navigationBlocked
                        ? null
                        : _flow.step == FirstExperienceStep.playing
                        ? _flow.selectGameCell
                        : _flow.step != FirstExperienceStep.block
                        ? null
                        : (index) {
                            GameFeedbackScope.tap(context);
                            _flow.selectCell(_center.indexOf(index));
                          },
                  ),
                ),
              ),
            ),
          ),
          if (_showGame)
            Positioned.fill(
              child: BoardScoreFeedback(feedback: _flow.scoreFeedback),
            ),
          IgnorePointer(
            child: ExcludeSemantics(
              excluding: !_explaining,
              child: AnimatedOpacity(
                duration: motion,
                opacity: _explaining ? 1 : 0,
                child: FadeTransition(
                  key: const ValueKey('intro-doku-entrance'),
                  opacity: _dokuEntrance,
                  child: ScaleTransition(
                    scale: Tween(begin: .94, end: 1.0).animate(_dokuEntrance),
                    child: const _WelcomeGuide(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _instructions(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (_explaining) ...[
        TutorialReveal(
          visible: _dokuReady,
          child: TutorialStory(
            key: _storyKey,
            controller: _tutorialStory,
            autoplay: _dokuReady,
            interactive: false,
            onFinished: () => _storyFinished(FirstExperienceStep.welcome),
            animate: !_hasLeftWelcome,
            lines: _welcome
                ? TutorialStory.sentences
                : TutorialStory.blockLines,
            tip: _welcome ? TutorialStory.conclusion : TutorialStory.blockTip,
            skipHint: _welcome
                ? 'Toca para mostrar toda la historia'
                : 'Toca para mostrar toda la explicación',
          ),
        ),
      ],
      if (_flow.error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: _IllustratedPanel(
            padding: const EdgeInsets.all(18),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _flow.error!,
                textAlign: TextAlign.center,
                style: homeText(16),
              ),
            ),
          ),
        ),
    ],
  );
}

class _WorldBackdrop extends StatelessWidget {
  const _WorldBackdrop();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Image.asset(
          'assets/images/home-background.png',
          fit: BoxFit.cover,
          excludeFromSemantics: true,
        ),
      ),
      const ColoredBox(color: Color(0x30FFF1CF)),
    ],
  );
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.welcome,
    this.expanded = false,
    this.compact = false,
    this.largeStyle = false,
    this.title,
    this.subtitle,
  });
  final bool welcome;
  final bool expanded;
  final bool compact;
  final bool largeStyle;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
    final shortLandscape = GameLayout.useCompactLandscape(
      MediaQuery.sizeOf(context),
    );
    final blockTitle = Text(
      title ?? (expanded ? 'Tu tablero de sudoku' : 'Empecemos con 9 casillas'),
      key: const ValueKey('intro-header-title'),
      textAlign: TextAlign.center,
      maxLines: compact || !largeText ? 1 : null,
      softWrap: !compact,
      style: homeText(largeText ? 18 : 22),
    );
    return Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.stretch,
      children: [
        if (welcome)
          UiSurfacePanel(
            key: const ValueKey('intro-header'),
            surface: UiSurface.goldCreamPanel,
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 19),
            child: Row(
              children: [
                HomeIcon(HomeGlyph.sun, size: largeText ? 32 : 42),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        welcome
                            ? largeText
                                  ? 'Bienvenida'
                                  : 'Tu primer sudoku'
                            : 'Tu primer bloque',
                        textAlign: TextAlign.center,
                        style: homeText(largeText ? 18 : 23).copyWith(
                          shadows: const [
                            Shadow(
                              color: Color(0x65FFFFFF),
                              offset: Offset(0, -1),
                            ),
                            Shadow(
                              color: Color(0x30001B50),
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        largeText
                            ? 'NIVEL 1 · 1 DE 3'
                            : 'NIVEL 1 · PARTIDA 1 DE 3',
                        textAlign: TextAlign.center,
                        style: homeText(11).copyWith(
                          color: const Color(0xFF4C5164),
                          letterSpacing: .7,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (!welcome && compact && largeStyle)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: UiSurfacePanel(
              key: const ValueKey('intro-header'),
              surface: UiSurface.goldCreamPanel,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              child: Center(
                heightFactor: 1,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      blockTitle,
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          key: const ValueKey('game-round-subtitle'),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: homeText(13, weight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (!welcome && compact && !largeStyle)
          FractionallySizedBox(
            widthFactor: shortLandscape
                ? .55
                : GameLayout.titleWidthFactor(
                    MediaQuery.sizeOf(context).shortestSide,
                  ),
            child: UiSurfacePanel(
              key: const ValueKey('intro-header'),
              surface: UiSurface.goldCreamPanel,
              padding: EdgeInsets.symmetric(
                horizontal: 28,
                vertical: shortLandscape ? 8 : 20.5,
              ),
              child: Center(
                heightFactor: 1,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      blockTitle,
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          key: const ValueKey('game-round-subtitle'),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: homeText(13, weight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (!welcome && !compact)
          TutorialLessonTitle(
            title:
                title ??
                (expanded
                    ? 'Tu tablero de sudoku'
                    : 'Empecemos con 9 casillas'),
          ),
      ],
    );
  }
}

class _WelcomeGuide extends StatelessWidget {
  const _WelcomeGuide();

  static const aspectRatio = 1375 * .948 / (1144 * .974);

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Doku te saluda con un cuaderno de nueve casillas',
    image: true,
    child: Center(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: const SettingsArtRegion(
          key: ValueKey('welcome-guide'),
          asset: 'assets/images/tutorial/welcome-guide.png',
          region: Rect.fromLTRB(.038, .008, .986, .982),
        ),
      ),
    ),
  );
}

class _IllustratedPanel extends StatelessWidget {
  const _IllustratedPanel({required this.child, required this.padding});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(child: HomeArt(HomeSurface.status)),
      SizedBox(
        width: double.infinity,
        child: Padding(padding: padding, child: child),
      ),
    ],
  );
}

class _GameBriefing extends StatefulWidget {
  const _GameBriefing({required this.onAccept});
  final Future<void> Function() onAccept;
  @override
  State<_GameBriefing> createState() => _GameBriefingState();
}

class _GameBriefingState extends State<_GameBriefing> {
  bool _saving = false;
  bool _textReady = false;
  String? _error;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: SingleChildScrollView(
      child: UiSurfacePanel(
        key: const ValueKey('game-briefing'),
        surface: UiSurface.goldCreamPanel,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¡Ahora te toca!',
              textAlign: TextAlign.center,
              style: homeText(28),
            ),
            const SizedBox(height: 12),
            TutorialStory(
              lines: const [
                'Toca una casilla vacía y elige un número.',
                'Las pistas te ayudarán a encontrar su lugar.',
                '¡Recuerda! No repitas números en la fila, la columna ni el bloque.',
              ],
              tip: null,
              interactive: false,
              showPanel: false,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              textStyle: homeText(20).copyWith(height: 1.3),
              onFinished: () {
                if (mounted && !_textReady) setState(() => _textReady = true);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: homeText(16)),
            ],
            const SizedBox(height: 20),
            IllustratedActionButton(
              key: const ValueKey('game-briefing-accept'),
              label: _saving ? 'Guardando…' : '¡A jugar!',
              fontSize: 23,
              onPressed: _saving || !_textReady
                  ? null
                  : () async {
                      setState(() {
                        _saving = true;
                        _error = null;
                      });
                      try {
                        await widget.onAccept();
                      } catch (_) {
                        if (mounted) {
                          setState(() {
                            _saving = false;
                            _error = 'No pudimos guardar. Intenta de nuevo.';
                          });
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    ),
  );
}
