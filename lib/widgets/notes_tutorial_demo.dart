import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/notes_tutorial_controller.dart';
import 'game_layout.dart';
import 'home_art.dart';
import 'sudoku_board.dart';
import 'sudoku_digit.dart';
import 'sudoku_notes.dart';
import 'tutorial_block_controls.dart';
import 'ui_surface_art.dart';

/// Read-only, replayable demonstration. Only the parent advances explanations.
class NotesTutorialDemo extends StatelessWidget {
  const NotesTutorialDemo({
    super.key,
    required this.step,
    required this.animation,
    this.explanation,
    this.boardWidth,
  });
  final int step;
  final Animation<double> animation;
  final Widget? explanation;
  final double? boardWidth;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      final reduced =
          MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context);
      final frame = NotesLesson.frameAt(
        step,
        (animation.value * NotesLesson.durations[step]).round(),
      );
      final cell = frame.cells[NotesLesson.target];
      final caption = switch (step) {
        0 => 'Dos posibilidades: 2 o 7',
        1 => frame.notesMode ? 'Lápiz encendido' : 'Encendemos el lápiz',
        2 =>
          frame.notes.isEmpty
              ? 'Guardamos las ideas'
              : 'Anotaciones: ${describeNotes(frame.notes)}',
        3 => frame.notesMode ? 'Apagamos el lápiz' : 'Escribimos respuestas',
        4 =>
          frame.cells[NotesLesson.other] == 7
              ? '7 confirmado'
              : 'Aquí falta el 7',
        5 => frame.notes.contains(7) ? 'Descartamos el 7' : 'Solo queda el 2',
        6 => cell == 2 ? 'Respuesta: 2' : 'De idea a respuesta',
        _ => '¡Ya sabes usar las notas!',
      };
      final parts = <Widget>[
        RepaintBoundary(
          child: SudokuBoard(
            key: const ValueKey('notes-lesson-board'),
            cells: frame.cells,
            selectedIndex: frame.selected,
            fixedIndices: {
              for (var i = 0; i < 81; i++)
                if (NotesLesson.initial[i] != null) i,
            },
            notes: {NotesLesson.target: frame.notes},
            notesMode: frame.notesMode,
            highlightedIndices: frame.highlighted,
            highlightKey: step,
            reveal: step == 4
                ? SudokuBoardReveal.column
                : step == 5
                ? SudokuBoardReveal.row
                : SudokuBoardReveal.none,
          ),
        ),
        const SizedBox(height: 10),
        ExcludeSemantics(
          child: LayoutBuilder(
            builder: (context, bounds) {
              final gap = bounds.maxWidth < 340 ? 2.0 : 4.0;
              final button = math.min(
                GameLayout.controlSize,
                (bounds.maxWidth - gap * 8) / 9,
              );
              final rowWidth = button * 9 + gap * 8;
              final number = frame.cue == 2 || frame.cue == 7
                  ? frame.cue
                  : null;
              return SizedBox(
                height: button,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    TutorialNumberTray(
                      horizontal: true,
                      showGuide: false,
                      available: const [2, 7],
                      notesMode: frame.notesMode,
                      selectedNotes: frame.notes,
                      onSelected: null,
                    ),
                    if (number != null)
                      Positioned(
                        left:
                            (bounds.maxWidth - rowWidth) / 2 +
                            (number - 1) * (button + gap),
                        top: 0,
                        width: button,
                        height: button,
                        child: IgnorePointer(
                          child: _DemoEmphasis(
                            key: ValueKey('notes-demo-number-$number'),
                            active: true,
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        UiSurfacePanel(
          surface: UiSurface.goldCreamCard,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: _DemoEmphasis(
                    active: frame.cue == 0,
                    child: SudokuNotesButton(
                      active: frame.notesMode,
                      onPressed: null,
                      dimWhenDisabled: false,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ExcludeSemantics(
                  child: SizedBox.square(
                    dimension: 66,
                    child: UiSurfacePanel(
                      surface: UiSurface.creamTile,
                      child: AnimatedSwitcher(
                        duration: reduced
                            ? Duration.zero
                            : const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(
                              scale: CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutBack,
                              ),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            ),
                        child: cell == null
                            ? SudokuNotes(
                                key: ValueKey(frame.notes.join(',')),
                                notes: frame.notes,
                              )
                            : Center(
                                key: const ValueKey('notes-demo-answer'),
                                child: SudokuDigit(cell, size: 36),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      caption,
                      key: const ValueKey('notes-demo-caption'),
                      style: homeText(16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
      if (explanation case final story?) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [story, const SizedBox(height: 12), parts.last],
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: boardWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: parts.take(3).toList(),
              ),
            ),
          ],
        );
      }
      return Column(mainAxisSize: MainAxisSize.min, children: parts);
    },
  );
}

class _DemoEmphasis extends StatelessWidget {
  const _DemoEmphasis({super.key, required this.active, required this.child});
  final bool active;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return AnimatedScale(
      scale: active && !reduced ? 1.08 : 1,
      duration: reduced ? Duration.zero : const Duration(milliseconds: 200),
      child: AnimatedContainer(
        duration: reduced ? Duration.zero : const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? homeNavy : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: active ? const Color(0x80FFD34D) : Colors.transparent,
              blurRadius: 10,
              spreadRadius: 3,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
