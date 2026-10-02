import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/notes_tutorial_controller.dart';
import '../data/repositories/game_repository.dart';
import '../widgets/game_layout.dart';
import '../widgets/game_navigation_header.dart';
import '../widgets/tutorial_activity.dart';
import '../widgets/tutorial_presentation.dart';
import '../widgets/tutorial_story_navigation.dart';
import '../widgets/home_art.dart';
import '../widgets/illustrated_action_button.dart';
import '../widgets/map_chrome.dart';
import '../widgets/notes_tutorial_demo.dart';
import '../widgets/settings_art.dart';
import '../widgets/skip_tutorial_button.dart';
import '../widgets/tutorial_story.dart';

class NotesTutorialScreen extends StatefulWidget {
  const NotesTutorialScreen({
    super.key,
    required this.repository,
    this.replay = false,
    required this.onFinished,
  });
  final GameRepository repository;
  final bool replay;
  final Future<void> Function() onFinished;
  @override
  State<NotesTutorialScreen> createState() => _NotesTutorialScreenState();
}

class _NotesTutorialScreenState extends State<NotesTutorialScreen> {
  final _demoKey = GlobalKey();
  final _storyKey = GlobalKey();
  bool _paused = false;
  late final flow = NotesTutorialController(
    widget.repository,
    replay: widget.replay,
  );
  bool opening = false;

  @override
  void dispose() {
    flow.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (opening || flow.busy) return;
    final last = flow.step == NotesLesson.texts.length - 1;
    if (!await flow.next() || !mounted) return;
    if (last) await _finish();
  }

  Future<void> _skip() async {
    if (opening || flow.busy) return;
    if (await flow.skipTutorial()) {
      if (mounted) await _finish();
    } else if (mounted && flow.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(flow.error!)));
    }
  }

  Future<void> _finish() async {
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

  Widget _explanation(
    TutorialPresentationState presentation, {
    bool compact = false,
  }) {
    final step = flow.step;
    return TutorialReveal(
      visible: presentation.storyVisible,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TutorialStory(
            key: _storyKey,
            lines: [NotesLesson.texts[step]],
            tip: null,
            autoplay: presentation.storyVisible,
            interactive: false,
            onFinished: () {
              if (flow.step == step) presentation.storyFinished();
            },
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: compact ? 12 : 18,
            ),
            textStyle: homeText(compact ? 16 : 18, weight: FontWeight.w500),
          ),
          if (flow.error != null)
            Text(flow.error!, textAlign: TextAlign.center, style: homeText(16)),
        ],
      ),
    );
  }

  double _explanationHeight(BuildContext context, double width) {
    final painter = TextPainter(
      text: TextSpan(
        text: NotesLesson.texts[flow.step],
        style: homeText(18, weight: FontWeight.w500),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: math.max(1, width - 48));
    final height = painter.height + 36;
    painter.dispose();
    return height;
  }

  Widget _actions(bool horizontal) {
    final next = IllustratedActionButton(
      key: const ValueKey('notes-lesson-next'),
      label: flow.step == NotesLesson.texts.length - 1
          ? (widget.replay ? 'Terminar repaso' : 'Practicar')
          : 'Siguiente',
      fontSize: 24,
      compact: true,
      onPressed: flow.busy || opening ? null : _next,
    );
    final skip = SkipTutorialButton(
      key: const ValueKey('notes-lesson-skip'),
      onPressed: flow.busy || opening ? null : _skip,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: horizontal
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
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final short = MediaQuery.sizeOf(context).height < 520;
    final horizontalActions = short && MediaQuery.sizeOf(context).width >= 650;
    return Scaffold(
      backgroundColor: const Color(0xFFF2DCAA),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: Image.asset(
                'assets/images/tutorial/notes-background.png',
                key: const ValueKey('notes-lesson-background'),
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
          ),
          SafeArea(
            child: ListenableBuilder(
              listenable: flow,
              builder: (context, _) => TutorialActivity(
                paused: _paused || flow.busy || opening,
                child: TutorialPresentation(
                  step: flow.step,
                  demonstrationDuration: Duration(
                    milliseconds: NotesLesson.durations[flow.step],
                  ),
                  // Reduced motion removes the writing animation, not reading time.
                  readingPause: Duration(
                    milliseconds: MediaQuery.disableAnimationsOf(context)
                        ? 2000 + NotesLesson.texts[flow.step].length * 32
                        : 2000,
                  ),
                  onAdvance:
                      flow.step < NotesLesson.texts.length - 1 &&
                          flow.error == null
                      ? _next
                      : null,
                  builder: (context, presentation) => Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: short ? 4 : 8,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            MapWorldHeader(
                              compact: short,
                              onBack: () => Navigator.of(context).maybePop(),
                            ),
                            if (flow.step < NotesLesson.texts.length - 1)
                              GameHeaderButton(
                                key: const ValueKey('notes-lesson-pause'),
                                label: _paused
                                    ? 'Continuar tutorial'
                                    : 'Pausar tutorial',
                                onPressed: () =>
                                    setState(() => _paused = !_paused),
                                icon: Icon(
                                  _paused
                                      ? Icons.play_arrow_rounded
                                      : Icons.pause_rounded,
                                  color: homeNavy,
                                  size: 30,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 660),
                          child: TutorialStepHeader(
                            key: const ValueKey('notes-lesson-header'),
                            index: flow.step,
                            count: NotesLesson.texts.length,
                            child: short
                                ? Text(
                                    'El lápiz de las ideas · ${flow.step + 1} / 8',
                                    textAlign: TextAlign.center,
                                    style: homeText(18),
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'El lápiz de las ideas',
                                        textAlign: TextAlign.center,
                                        style: homeText(28),
                                      ),
                                      Text(
                                        'Paso ${flow.step + 1} de ${NotesLesson.texts.length}',
                                        style: homeText(16),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TutorialStoryGestures(
                          key: const ValueKey('notes-story-gestures'),
                          enabled: !flow.busy && !opening,
                          onNext: _next,
                          onPrevious: flow.step > 0 ? flow.previous : null,
                          child: LayoutBuilder(
                            builder: (context, bounds) {
                              final wide =
                                  bounds.maxWidth >= 740 &&
                                  bounds.maxHeight < 650;
                              final contentWidth = math.min(
                                wide ? 1040.0 : 660.0,
                                bounds.maxWidth - 32,
                              );
                              final widthLimit = wide
                                  ? (contentWidth - 24) * .5
                                  : contentWidth;
                              final heightLimit = wide
                                  ? (bounds.maxHeight - 26) / (1 + 1 / 9)
                                  : (bounds.maxHeight -
                                            _explanationHeight(
                                              context,
                                              contentWidth,
                                            ) -
                                            148) /
                                        (1 + 1 / 9);
                              final boardWidth = math.min(
                                GameLayout.maxBoardSize,
                                math.min(
                                  widthLimit,
                                  math.max(wide ? 140.0 : 240.0, heightLimit),
                                ),
                              );
                              final demo = NotesTutorialDemo(
                                key: _demoKey,
                                step: flow.step,
                                animation: presentation.demonstration,
                                boardWidth: boardWidth,
                                explanation: wide
                                    ? _explanation(presentation, compact: short)
                                    : null,
                              );
                              return SingleChildScrollView(
                                key: const ValueKey('notes-lesson-content'),
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
                                      child: FadeTransition(
                                        opacity: presentation.entrance,
                                        child: ScaleTransition(
                                          scale: Tween(
                                            begin: .94,
                                            end: 1.0,
                                          ).animate(presentation.entrance),
                                          child: SizedBox(
                                            width: contentWidth,
                                            child: wide
                                                ? demo
                                                : Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      _explanation(
                                                        presentation,
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      SizedBox(
                                                        width: boardWidth,
                                                        child: demo,
                                                      ),
                                                    ],
                                                  ),
                                          ),
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
                      _actions(horizontalActions),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showNotesUnlock(
  BuildContext context,
  GameRepository repository,
) async {
  if (!repository.notesAnnouncementPending) return;
  final seen = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SettingsPanelSurface(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/tutorial/notes-pencil.png',
                          width: 72,
                          height: 72,
                        ),
                        Text(
                          '¡El lápiz ya es tuyo!',
                          style: homeText(27),
                          textAlign: TextAlign.center,
                        ),
                        TutorialStory(
                          showPanel: false,
                          padding: const EdgeInsets.all(16),
                          lines: const [
                            'Completaste las tres rondas del primer juego. ¡Anotaciones desbloqueadas!',
                          ],
                          tip: 'Puedes usar el lápiz en cualquier juego y en Partida rápida. Enciéndelo para anotar tus ideas y apágalo para poner una respuesta.',
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: IllustratedActionButton(
                    label: '¡A seguir!',
                    compact: true,
                    fontSize: 24,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  if (seen == true) await repository.markNotesAnnounced();
}
