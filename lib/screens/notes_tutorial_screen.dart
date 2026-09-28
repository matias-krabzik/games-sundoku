import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/notes_tutorial_controller.dart';
import '../data/repositories/game_repository.dart';
import '../widgets/home_art.dart';
import '../widgets/illustrated_action_button.dart';
import '../widgets/map_chrome.dart';
import '../widgets/settings_art.dart';
import '../widgets/sudoku_board.dart';
import '../widgets/sudoku_notes.dart';
import '../widgets/tutorial_block_controls.dart';
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
  late final flow = NotesTutorialController(
    widget.repository,
    replay: widget.replay,
  );
  bool typed = false;
  bool opening = false;
  @override
  void dispose() {
    flow.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!typed || opening) return;
    final last = flow.step == 7;
    if (!await flow.next() || !mounted) return;
    if (last) {
      setState(() => opening = true);
      try {
        await widget.onFinished();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No pudimos abrir el juego. Toca Practicar otra vez.',
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => opening = false);
      }
    } else {
      setState(() => typed = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2DCAA),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: flow,
        builder: (context, _) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: MapWorldHeader(
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, bounds) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: bounds.maxHeight),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 660),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'El lápiz de las ideas',
                                textAlign: TextAlign.center,
                                style: homeText(28),
                              ),
                              Text(
                                'Paso ${flow.step + 1} de 8',
                                style: homeText(16),
                              ),
                              TutorialStory(
                                key: ValueKey('notes-story-${flow.step}'),
                                lines: [NotesLesson.texts[flow.step]],
                                tip: null,
                                showPanel: false,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                interactive: widget.replay,
                                textStyle: homeText(
                                  18,
                                  weight: FontWeight.w500,
                                ),
                                onFinished: () {
                                  if (mounted) setState(() => typed = true);
                                },
                              ),
                              SizedBox(
                                width: math.min(430, bounds.maxWidth - 32),
                                child: SudokuBoard(
                                  key: const ValueKey('notes-lesson-board'),
                                  cells: flow.cells,
                                  selectedIndex: flow.selected,
                                  fixedIndices: {
                                    for (var i = 0; i < 81; i++)
                                      if (NotesLesson.initial[i] != null) i,
                                  },
                                  notes: {NotesLesson.target: flow.notes},
                                  notesMode: flow.notesMode,
                                  highlightedIndices: flow.highlighted,
                                  highlightKey: flow.step,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: 430,
                                child: TutorialNumberTray(
                                  horizontal: true,
                                  showGuide: false,
                                  available: flow.allowedNumbers,
                                  notesMode: flow.notesMode,
                                  selectedNotes: flow.notes,
                                  onSelected: typed ? flow.number : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SudokuNotesButton(
                                active: flow.notesMode,
                                onPressed: typed && flow.canToggle
                                    ? flow.toggle
                                    : null,
                              ),
                              SudokuNotesReading(
                                notes: flow.notes,
                                active: flow.notesMode,
                              ),
                              if (flow.error != null)
                                Text(
                                  flow.error!,
                                  textAlign: TextAlign.center,
                                  style: homeText(16),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: IllustratedActionButton(
                key: const ValueKey('notes-lesson-next'),
                label: flow.step == 7
                    ? (widget.replay ? 'Terminar repaso' : 'Practicar')
                    : 'Siguiente',
                fontSize: 24,
                compact: true,
                onPressed:
                    typed && flow.actionComplete && !flow.busy && !opening
                    ? _next
                    : null,
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
