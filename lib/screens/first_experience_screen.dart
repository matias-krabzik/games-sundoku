import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../controllers/first_experience_controller.dart';
import 'settings_screen.dart';
import '../widgets/game_navigation_header.dart';
import '../data/repositories/game_repository.dart';
import '../widgets/game_feedback_scope.dart';
import '../domain/models/sudoku_completion.dart';
import '../widgets/home_art.dart';
import '../widgets/illustrated_action_button.dart';
import '../widgets/map_art.dart';
import '../widgets/settings_art.dart';
import '../widgets/sudoku_board.dart';
import '../widgets/tutorial_story.dart';
import '../widgets/tutorial_block_art.dart';
import '../widgets/tutorial_block_controls.dart';
import '../widgets/tutorial_journey.dart';
import '../widgets/tutorial_celebration.dart';
import '../widgets/tutorial_story_navigation.dart';
import '../widgets/ui_surface_art.dart';
import '../widgets/victory_particles.dart';

enum _NextSudokuPhase { leaving, entering }

/// One route owns the introduction and the board it will teach on.
class FirstExperienceScreen extends StatefulWidget {
  const FirstExperienceScreen({
    super.key,
    required this.repository,
    this.showDeveloperControls = kDebugMode,
    this.reviewOnly = false,
  });

  final GameRepository repository;
  final bool reviewOnly;
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
  );
  // Preserve the board and focus when the responsive layout changes parents.
  final _stageKey = GlobalKey();
  final _storyKey = GlobalKey();
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
  bool _boardAnimating = false;
  SudokuCompletion? _pendingBoardCompletion;
  late SudokuCompletion? _previousCompletion = _flow.completion;
  bool get _finishingBoard => _pendingBoardCompletion != null;
  bool get _showGame =>
      _flow.step == FirstExperienceStep.playing || _finishingBoard;
  bool get _navigationBlocked =>
      _settingsOpen ||
      _flow.isBusy ||
      _boardAnimating ||
      _finishingBoard ||
      _rewardFlightFrom != null ||
      _nextPhase != null ||
      _briefingPending ||
      _gameEntrance.isAnimating;

  void _boardAnimationChanged(bool animating) {
    if (mounted && _boardAnimating != animating) {
      setState(() => _boardAnimating = animating);
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
      final box = _rewardBoardSlotKey.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final target = box.localToGlobal(Offset.zero) & box.size;
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
              final layer = _rewardLayerKey.currentContext?.findRenderObject();
              final offset = layer is RenderBox
                  ? layer.localToGlobal(Offset.zero)
                  : Offset.zero;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fromRect(rect: rect.shift(-offset), child: child!),
                ],
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
      await _flow.advance();
      if (!mounted) return;
      if (_flow.step != FirstExperienceStep.playing ||
          _flow.error != null ||
          _reduceAnimations) {
        setState(_clearNextTransition);
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
      final box = _nextBoardSlotKey.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final target = box.localToGlobal(Offset.zero) & box.size;
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
              final layer = _rewardLayerKey.currentContext?.findRenderObject();
              final offset = layer is RenderBox
                  ? layer.localToGlobal(Offset.zero)
                  : Offset.zero;
              final Rect rect;
              final double opacity;
              if (_nextPhase == _NextSudokuPhase.leaving) {
                final progress = Curves.easeInCubic.transform(_nextExit.value);
                rect = from.shift(
                  Offset(-(from.right - offset.dx + 24) * progress, 0),
                );
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
                    rect: rect.shift(-offset),
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
        unawaited(_flow.resumeGame());
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
      _rewardEntrance.value = 1;
      if (_nextPhase == _NextSudokuPhase.leaving) _nextExit.value = 1;
      _nextEntrance.value = 1;
    } else if (!_entranceStarted) {
      _dokuEntrance.forward();
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
        await _flow.resumeGame();
        if (mounted) setState(() => _settingsOpen = false);
      }
    }
  }

  bool get _needsBriefing =>
      !widget.reviewOnly &&
      _flow.gameIndex == 0 &&
      (widget.repository.state.modules[FirstExperienceController.moduleKey]
              as Map?)?['briefingAccepted'] !=
          true;

  Rect? _boardRect() {
    final box = _stageKey.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
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
    if (!identical(_previousCompletion, _flow.completion)) {
      _previousCompletion = _flow.completion;
      _pendingBoardCompletion = _flow.completion?.wholeBoard == true
          ? _flow.completion
          : null;
    }
    if (_previousAttention != _flow.attention) {
      _previousAttention = _flow.attention;
      if (mounted && ModalRoute.of(context)?.isCurrent != false) {
        GameFeedbackScope.error(context);
      }
    }
    if (_previousStep == FirstExperienceStep.givensIntroduction &&
        _flow.step == FirstExperienceStep.playing) {
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
    _gameEntrance.dispose();
    _rewardEntrance.dispose();
    _nextExit.dispose();
    _nextEntrance.dispose();
    super.dispose();
  }

  void _back() {
    if (_navigationBlocked) return;
    if (_flow.isBusy) return;
    if (_welcome ||
        _flow.session != null ||
        _flow.step.index > FirstExperienceStep.expansion.index) {
      Navigator.of(context).maybePop();
    } else if (_flow.step == FirstExperienceStep.expansion) {
      _flow.reviewBlock();
    } else {
      _flow.reviewWelcome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 450);
    final cells = _flow.boardValues;

    return PopScope(
      canPop:
          (_welcome ||
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
              child: LayoutBuilder(
                builder: (context, bounds) {
                  final wide =
                      bounds.maxWidth >= 700 &&
                      bounds.maxWidth > bounds.maxHeight * 1.2;
                  final Widget content;
                  if (_welcome) {
                    content = _explanationLayout(
                      cells,
                      motion,
                      wide: wide,
                      compact: wide || bounds.maxHeight < 650,
                    );
                  } else if (_flow.isStory ||
                      _flow.step.index >= FirstExperienceStep.expansion.index) {
                    content = TutorialJourney(
                      navigationBlocked: _navigationBlocked,
                      finishingBoard: _finishingBoard,
                      flow: _flow,
                      board: _rewardFlightFrom == null && _nextPhase == null
                          ? _stage(cells, motion)
                          : const SizedBox.expand(),
                      rewardAnimation: _rewardEntrance,
                      rewardBoardSlotKey: _rewardBoardSlotKey,
                      rewardActionKey: _rewardActionKey,
                      gameBoardSlotKey: _nextBoardSlotKey,
                      departure: _nextExit,
                      gameEntrance: _nextEntrance,
                      onNextGame: _advanceGame,
                      navigation: _showGame
                          ? GameNavigationHeader(
                              center: kDebugMode && widget.showDeveloperControls
                                  ? _developerFillButton()
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
                          _FlowHeader(
                            welcome: false,
                            title: _finishingBoard
                                ? 'Sudoku ${_flow.gameIndex + 1} de 3'
                                : TutorialJourney.title(_flow),
                            showDeveloperControls:
                                widget.showDeveloperControls && !_showGame,
                            onBack: _navigationBlocked ? null : _back,
                          ),
                          if (kDebugMode &&
                              widget.showDeveloperControls &&
                              !_showGame &&
                              !_flow.isStory)
                            _developerFillButton(),
                        ],
                      ),
                      onExit: () {
                        if (!_navigationBlocked) Navigator.of(context).pop();
                      },
                    );
                  } else {
                    content = _blockLayout(cells, motion);
                  }
                  if (!_flow.isStory) return content;
                  return TutorialStoryGestures(
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
                            if (!_navigationBlocked) _flow.previousStory();
                          }
                        : null,
                    child: content,
                  );
                },
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
          ],
        ),
      ),
    );
  }

  Widget _developerFillButton() => UiSurfacePanel(
    surface: UiSurface.creamPill,
    padding: EdgeInsets.zero,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: TextButton(
            key: const ValueKey('dev-fill-except-one'),
            onPressed: !_navigationBlocked && _flow.readyToPlay
                ? _flow.debugFillExceptOne
                : null,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('DEV · 1 ficha', style: homeText(12)),
            ),
          ),
        ),
        PopupMenuButton<int>(
          key: const ValueKey('dev-game-options'),
          enabled: !_navigationBlocked && _flow.debugPreviousGameIndex != null,
          icon: SizedBox.square(
            dimension: 19,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < 3; i++)
                  const SizedBox.square(
                    dimension: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: homeNavy,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          onSelected: (_) => _flow.debugRestartPrevious(),
          itemBuilder: (context) => [
            if (_flow.debugPreviousGameIndex case final int index)
              PopupMenuItem(
                key: const ValueKey('dev-restart-previous'),
                value: index,
                child: Text(
                  'Reiniciar sudoku ${index + 1}',
                  style: homeText(16),
                ),
              ),
          ],
        ),
      ],
    ),
  );

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
            TutorialStoryProgress(
              index: _flow.storyIndex,
              count: _flow.storyCount,
            ),
            const SizedBox(height: 8),
            _FlowHeader(
              welcome: _welcome,
              showDeveloperControls: widget.showDeveloperControls,
              onBack: _navigationBlocked ? null : _back,
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
            Text(
              'Toca los lados para avanzar o volver',
              textAlign: TextAlign.center,
              style: homeText(13, weight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            IllustratedActionButton(
              key: ValueKey(_welcome ? 'intro-continue' : 'intro-start-block'),
              compact: compact,
              fontSize: 22,
              showPlayIcon: MediaQuery.textScalerOf(context).scale(16) <= 24,
              label: _flow.isBusy ? 'Guardando…' : 'Siguiente',
              onPressed: _flow.isBusy ? null : _flow.advance,
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
              _FlowHeader(
                welcome: false,
                expanded: expanded,
                showDeveloperControls: widget.showDeveloperControls,
                onBack: _navigationBlocked ? null : _back,
              ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _stage(List<int?> cells, Duration motion) => Center(
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
                    dealProgress: _nextPhase == _NextSudokuPhase.entering
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
                      FirstExperienceStep.givensIntroduction =>
                        SudokuBoardReveal.remaining,
                      _ => SudokuBoardReveal.none,
                    },
                    cells: cells,
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
                    highlightedIndices: _flow.highlightedIndices,
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
        _IntroReveal(
          visible: _dokuReady,
          child: TutorialStory(
            key: _storyKey,
            autoplay: _dokuReady,
            interactive: false,
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

/// Keeps its layout space while hiding interaction, focus and semantics.
class _IntroReveal extends StatelessWidget {
  const _IntroReveal({required this.visible, required this.child});
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final duration = reduced
        ? Duration.zero
        : const Duration(milliseconds: 350);
    return IgnorePointer(
      ignoring: !visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: ExcludeFocus(
          excluding: !visible,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: duration,
            child: AnimatedSlide(
              offset: visible ? Offset.zero : const Offset(0, .04),
              duration: duration,
              curve: Curves.easeOut,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
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
    required this.showDeveloperControls,
    required this.onBack,
    this.expanded = false,
    this.title,
  });
  final bool welcome;
  final bool expanded;
  final String? title;
  final bool showDeveloperControls;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
    final blockTitle = Text(
      title ?? (expanded ? 'Tu tablero de sudoku' : 'Empecemos con 9 casillas'),
      key: const ValueKey('intro-header-title'),
      textAlign: TextAlign.center,
      maxLines: largeText ? null : 1,
      style: homeText(largeText ? 18 : 22),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
        if (!welcome)
          Row(
            children: [
              SizedBox(
                key: const ValueKey('intro-header-rays-left'),
                width: 28,
                height: 70,
                child: Transform.flip(
                  flipX: true,
                  child: const TutorialBlockArt(TutorialGlyph.rays),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: UiSurfacePanel(
                  key: const ValueKey('intro-header'),
                  surface: UiSurface.goldCreamPanel,
                  padding: const EdgeInsets.fromLTRB(12, 19, 12, 22),
                  child: SizedBox(
                    width: double.infinity,
                    child: largeText
                        ? blockTitle
                        : FittedBox(fit: BoxFit.scaleDown, child: blockTitle),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              const SizedBox(
                key: ValueKey('intro-header-rays-right'),
                width: 28,
                height: 70,
                child: TutorialBlockArt(TutorialGlyph.rays),
              ),
            ],
          ),
        if (kDebugMode && showDeveloperControls)
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 30,
              child: TextButton.icon(
                key: const ValueKey('intro-back'),
                onPressed: onBack,
                icon: const MapIcon(MapGlyph.back, size: 16),
                label: Text('DEV · Volver', style: homeText(12)),
              ),
            ),
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
            Text(
              'Completa las casillas vacías con los números que faltan.\nToca una casilla y elige un número.\nRecuerda: no repitas números en la fila, la columna ni el bloque.',
              textAlign: TextAlign.center,
              style: homeText(20),
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
              onPressed: _saving
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
