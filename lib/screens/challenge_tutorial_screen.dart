import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../controllers/challenge_tutorial_controller.dart';
import '../data/repositories/game_repository.dart';
import '../domain/tutorial/challenge_lesson.dart';
import '../widgets/challenge_award.dart';
import '../widgets/game_layout.dart';
import '../widgets/game_pause.dart';
import '../widgets/home_art.dart';
import '../widgets/illustrated_action_button.dart';
import '../widgets/challenge_lives.dart';
import '../widgets/skip_tutorial_button.dart';
import '../widgets/sudoku_board.dart';
import '../widgets/sudoku_help.dart';
import '../widgets/sudoku_notes.dart';
import '../widgets/tutorial_activity.dart';
import '../widgets/tutorial_lesson_card.dart';
import '../widgets/tutorial_presentation.dart';
import '../widgets/tutorial_story.dart';
import '../widgets/tutorial_story_navigation.dart';
import '../widgets/ui_surface_art.dart';

class ChallengeTutorialScreen extends StatefulWidget {
  const ChallengeTutorialScreen({
    super.key,
    required this.repository,
    required this.onFinished,
    this.replay = false,
  });
  final GameRepository repository;
  final Future<void> Function() onFinished;
  final bool replay;
  @override
  State<ChallengeTutorialScreen> createState() =>
      _ChallengeTutorialScreenState();
}

class _ChallengeTutorialScreenState extends State<ChallengeTutorialScreen> {
  late final flow = ChallengeTutorialController(
    widget.repository,
    replay: widget.replay,
  );
  final _presentation = GlobalKey<TutorialPresentationState>();
  final _story = TutorialStoryController();
  bool opening = false;
  @override
  void dispose() {
    flow.dispose();
    super.dispose();
  }

  Future<void> _next({bool skip = false}) async {
    if (opening || flow.busy) return;
    if (!skip && _presentation.currentState?.finishAnimations(_story) == true) {
      return;
    }
    final finish = skip || flow.step == 3;
    if (!(await (skip ? flow.skip() : flow.next())) || !mounted || !finish) {
      return;
    }
    setState(() => opening = true);
    try {
      await widget.onFinished();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos abrir el juego. Intenta otra vez.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  double _textHeight(BuildContext context, double width) {
    final padding = TutorialStory.paddingOf(context);
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    var height = 0.0;
    for (final text in ChallengeLesson.texts) {
      painter.text = TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style
            .merge(TutorialLessonCard.textStyle),
      );
      painter.layout(maxWidth: math.max(1, width - padding.horizontal));
      height = math.max(height, painter.height);
    }
    painter.dispose();
    return height + padding.vertical + 122;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF83CDE7)),
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (final layer in ['background', 'terrain', 'foreground'])
                Image.asset(
                  'assets/images/map/crossed-rivers/$layer.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(-.45, 0),
                  excludeFromSemantics: true,
                  key: ValueKey('challenge-lesson-$layer'),
                ),
            ],
          ),
        ),
        const ColoredBox(color: Color(0x33FFF8DE)),
        SafeArea(
          child: ListenableBuilder(
            listenable: flow,
            builder: (context, _) => TutorialActivity(
              paused: flow.busy || opening,
              child: TutorialPresentation(
                key: _presentation,
                step: flow.step,
                scene: 'challenge-lesson-board',
                demonstrationDuration: Duration(
                  milliseconds: ChallengeLesson.durations[flow.step],
                ),
                // Each explanation advances explicitly; its demonstration is automatic.
                builder: (context, presentation) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: GameLayout.maxTutorialTextWidth,
                        ),
                        child: TutorialStepHeader(
                          index: flow.step,
                          count: 4,
                          child: TutorialLessonTitle(
                            title: ChallengeLesson.titles[flow.step],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TutorialStoryGestures(
                        enabled: !flow.busy && !opening,
                        onNext: _next,
                        onPrevious: flow.step > 0 ? flow.previous : null,
                        child: LayoutBuilder(
                          builder: (context, bounds) {
                            final width = math.min(
                              GameLayout.maxTutorialTextWidth,
                              bounds.maxWidth - 32,
                            );
                            final textHeight = _textHeight(context, width);
                            final boardWidth = math.min(
                              width,
                              math.min(
                                360.0,
                                math.max(
                                  180.0,
                                  bounds.maxHeight - textHeight - 92,
                                ),
                              ),
                            );
                            final step = flow.step;
                            return SingleChildScrollView(
                              key: const ValueKey('challenge-lesson-content'),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: bounds.maxHeight,
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: SizedBox(
                                      width: width,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FadeTransition(
                                            opacity: presentation.entrance,
                                            child: SizedBox(
                                              width: boardWidth,
                                              child: ChallengeTutorialDemo(
                                                step: step,
                                                animation:
                                                    presentation.demonstration,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          TutorialReveal(
                                            visible: presentation.storyVisible,
                                            child: SizedBox(
                                              height: textHeight,
                                              child: Center(
                                                child: TutorialLessonCard(
                                                  message: ChallengeLesson
                                                      .texts[step],
                                                  messageKey:
                                                      'challenge-lesson-$step',
                                                  footer:
                                                      ChallengeTutorialSummary(
                                                        step: step,
                                                        animation: presentation
                                                            .demonstration,
                                                      ),
                                                  controller: _story,
                                                  autoplay:
                                                      presentation.storyVisible,
                                                  onFinished: () {
                                                    if (step == flow.step) {
                                                      presentation
                                                          .storyFinished();
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (flow.error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            flow.error!,
                            textAlign: TextAlign.center,
                            style: homeText(16),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: _actions(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _actions(BuildContext context) {
    final next = IllustratedActionButton(
      key: const ValueKey('challenge-lesson-next'),
      label: flow.step == 3
          ? (widget.replay ? 'Terminar repaso' : 'Vamos a jugar')
          : 'Siguiente',
      compact: true,
      fontSize: 23,
      onPressed: opening || flow.busy ? null : _next,
    );
    final skip = SkipTutorialButton(
      key: const ValueKey('challenge-lesson-skip'),
      onPressed: opening || flow.busy ? null : () => _next(skip: true),
    );
    return MediaQuery.sizeOf(context).height < 520 &&
            MediaQuery.sizeOf(context).width >= 600
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: next),
              const SizedBox(width: 16),
              Flexible(child: skip),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [next, const SizedBox(height: 6), skip],
          );
  }
}

class ChallengeTutorialDemo extends StatelessWidget {
  const ChallengeTutorialDemo({
    super.key,
    required this.step,
    required this.animation,
  });
  final int step;
  final Animation<double> animation;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      final frame = ChallengeLesson.frameAt(step, animation.value);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 64,
            width: double.infinity,
            child: UiSurfacePanel(
              surface: UiSurface.creamPanel,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      ChallengeLives(remaining: frame.lives, total: 3),
                      const SizedBox(width: 12),
                      Text(
                        '${frame.points} / ${ChallengeLesson.rules.targetPoints}',
                        style: homeText(19),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatPlayTime(frame.timeMs),
                        key: const ValueKey('challenge-demo-time'),
                        style: homeText(19),
                      ),
                      if (frame.paused)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 5,
                                height: 16,
                                child: ColoredBox(color: homeNavy),
                              ),
                              SizedBox(width: 3),
                              SizedBox(
                                width: 5,
                                height: 16,
                                child: ColoredBox(color: homeNavy),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 1,
            child: SudokuBoard(
              key: const ValueKey('challenge-lesson-board'),
              cells: frame.cells,
              fixedIndices: {for (var i = 3; i < 81; i++) i},
              selectedIndex: step == 2 ? 1 : 0,
              highlightedIndices: step == 2
                  ? [1]
                  : step == 1
                  ? [0]
                  : const [],
              conflictIndices: frame.error ? {1} : const {},
            ),
          ),
        ],
      );
    },
  );
}

class ChallengeTutorialSummary extends StatelessWidget {
  const ChallengeTutorialSummary({
    super.key,
    required this.step,
    required this.animation,
  });
  final int step;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      final frame = ChallengeLesson.frameAt(step, animation.value);
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 100),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: 280,
              child: step == 3
                  ? ChallengeAward(
                      stars: frame.earned ? 1 : 0,
                      size: 36,
                      points: frame.points,
                      target: ChallengeLesson.rules.targetPoints,
                      ceiling: ChallengeLesson.rules.perfectPoints,
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          step == 0
                              ? (frame.paused
                                    ? 'Ejemplo · En pausa'
                                    : 'Ejemplo · El tiempo cuenta')
                              : step == 1
                              ? 'Cada respuesta suma'
                              : frame.lives == 2
                              ? 'Un error: una vida menos'
                              : 'Empezamos con tres vidas',
                          textAlign: TextAlign.center,
                          style: homeText(18),
                        ),
                        if (step == 1)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SudokuNotesButton(
                                  active: false,
                                  onPressed: null,
                                  dimension: 32,
                                  dimWhenDisabled: false,
                                ),
                                SizedBox(width: 20),
                                SudokuHelpButton(
                                  onPressed: null,
                                  dimension: 32,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      );
    },
  );
}
