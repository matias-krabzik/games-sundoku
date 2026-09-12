import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../controllers/first_experience_controller.dart';
import '../data/repositories/game_repository.dart';
import '../widgets/game_feedback_scope.dart';
import '../widgets/home_art.dart';
import '../widgets/illustrated_action_button.dart';
import '../widgets/map_art.dart';
import '../widgets/settings_art.dart';
import '../widgets/sudoku_board.dart';
import '../widgets/tutorial_story.dart';
import '../widgets/tutorial_block_art.dart';
import '../widgets/tutorial_block_controls.dart';
import '../widgets/tutorial_journey.dart';
import '../widgets/tutorial_story_navigation.dart';
import '../widgets/ui_surface_art.dart';

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
    with SingleTickerProviderStateMixin {
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
  bool _dokuReady = false;
  bool _entranceStarted = false;
  bool _hasLeftWelcome = false;
  late FirstExperienceStep _previousStep;

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
    _flow.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_flow.resumeGame());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      _dokuEntrance.value = 1;
    } else if (!_entranceStarted) {
      _dokuEntrance.forward();
    }
    _entranceStarted = true;
  }

  void _changed() {
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
    super.dispose();
  }

  void _back() {
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
          !_flow.isBusy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_flow.isBusy && !_welcome) _back();
      },
      child: Scaffold(
        key: const ValueKey('first-experience-flow'),
        body: Stack(
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
                      flow: _flow,
                      board: _stage(cells, motion),
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
                            title: TutorialJourney.title(_flow),
                            showDeveloperControls: widget.showDeveloperControls,
                            onBack: _flow.isBusy ? null : _back,
                          ),
                        ],
                      ),
                      onExit: () => Navigator.of(context).pop(),
                    );
                  } else {
                    content = _blockLayout(cells, motion);
                  }
                  if (!_flow.isStory) return content;
                  return TutorialStoryGestures(
                    key: const ValueKey('tutorial-story-gestures'),
                    enabled: !_flow.isBusy,
                    onNext: () {
                      if (_flow.reviewOnly &&
                          _flow.storyIndex == _flow.storyCount - 1) {
                        Navigator.of(context).pop();
                      } else {
                        _flow.advance();
                      }
                    },
                    onPrevious: _flow.storyIndex > 0
                        ? _flow.previousStory
                        : null,
                    child: content,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
            TutorialStoryProgress(
              index: _flow.storyIndex,
              count: _flow.storyCount,
            ),
            const SizedBox(height: 8),
            _FlowHeader(
              welcome: _welcome,
              showDeveloperControls: widget.showDeveloperControls,
              onBack: _flow.isBusy ? null : _back,
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
                onBack: _flow.isBusy ? null : _back,
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
    child: Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          ignoring: _explaining || _flow.isBusy,
          child: ExcludeSemantics(
            excluding: _explaining,
            child: AnimatedOpacity(
              opacity: _explaining ? 0 : 1,
              duration: motion,
              child: Center(
                child: SudokuBoard(
                  key: const ValueKey('intro-board'),
                  reveal: switch (_flow.step) {
                    FirstExperienceStep.rowRule => SudokuBoardReveal.row,
                    FirstExperienceStep.columnRule => SudokuBoardReveal.column,
                    FirstExperienceStep.givensIntroduction =>
                      SudokuBoardReveal.remaining,
                    _ => SudokuBoardReveal.none,
                  },
                  cells: cells,
                  selectedIndex: _explaining
                      ? null
                      : _flow.step == FirstExperienceStep.block
                      ? _center[_activeCell]
                      : _flow.step == FirstExperienceStep.playing
                      ? _flow.gameCell
                      : _flow.step == FirstExperienceStep.rowRule ||
                            _flow.step == FirstExperienceStep.columnRule
                      ? 40
                      : null,
                  centerOnly:
                      _flow.step.index < FirstExperienceStep.expansion.index,
                  highlightedIndices: _flow.highlightedIndices,
                  conflictIndices: _flow.conflicts,
                  fixedIndices: _flow.fixedIndices,
                  highlightKey: '${_flow.step}-${_flow.attention}',
                  onSelect: _explaining || _flow.isBusy
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
