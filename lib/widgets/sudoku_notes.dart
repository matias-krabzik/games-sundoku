import 'package:flutter/material.dart';

import 'game_feedback_scope.dart';
import 'home_art.dart';
import 'juicy_press.dart';
import 'ui_surface_art.dart';

String describeNotes(List<int> notes) {
  if (notes.isEmpty) return 'Sin anotaciones';
  if (notes.length == 1) return '${notes.single}';
  return '${notes.take(notes.length - 1).join(', ')} y ${notes.last}';
}

/// Nine stable positions, separated by a small hash-shaped grid.
class SudokuNotes extends StatelessWidget {
  const SudokuNotes({super.key, required this.notes, this.selected = false});

  final List<int> notes;
  final bool selected;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: LayoutBuilder(
      builder: (context, bounds) => Padding(
        padding: EdgeInsets.all(bounds.maxWidth * .12),
        child: CustomPaint(
          painter: _NotesGrid(selected: selected),
          child: LayoutBuilder(
            builder: (context, inner) => Stack(
              children: [
                for (final number in notes)
                  Positioned(
                    key: ValueKey('note-$number'),
                    left: (number - 1) % 3 * inner.maxWidth / 3,
                    top: (number - 1) ~/ 3 * inner.maxHeight / 3,
                    width: inner.maxWidth / 3,
                    height: inner.maxHeight / 3,
                    child: Center(
                      child: Text(
                        '$number',
                        textScaler: TextScaler.noScaling,
                        style: homeText(
                          bounds.maxWidth * .26,
                        ).copyWith(color: selected ? Colors.white : homeNavy),
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
}

class _NotesGrid extends CustomPainter {
  const _NotesGrid({required this.selected});
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (selected ? Colors.white : homeNavy).withValues(alpha: .28)
      ..strokeWidth = .6
      ..strokeCap = StrokeCap.round;
    for (final division in [1, 2]) {
      final x = size.width * division / 3;
      final y = size.height * division / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_NotesGrid oldDelegate) =>
      selected != oldDelegate.selected;
}

class SudokuNotesButton extends StatelessWidget {
  const SudokuNotesButton({
    super.key,
    required this.active,
    required this.onPressed,
    this.dimension = 52,
    this.sound = true,
  });

  final bool active;
  final VoidCallback? onPressed;
  final double dimension;
  final bool sound;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: dimension,
    child: JuicyPress(
      label: active ? 'Desactivar anotaciones' : 'Activar anotaciones',
      toggled: active,
      onPressed: onPressed,
      onFeedback: () =>
          GameFeedbackScope.toggle(context, enabled: !active, sound: sound),
      builder: (_, _) => Stack(
        fit: StackFit.expand,
        children: [
          UiSurfaceArt(active ? UiSurface.goldTile : UiSurface.creamTile),
          Center(
            child: Opacity(
              opacity: onPressed == null ? .45 : 1,
              child: Image.asset(
                'assets/images/tutorial/notes-pencil.png',
                width: dimension * .75,
                height: dimension * .75,
                excludeFromSemantics: true,
              ),
            ),
          ),
          if (active)
            Positioned(
              right: 0,
              top: 0,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: homeNavy,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.check,
                    size: dimension * .22,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Readable companion to the intentionally small notes inside a cell.
class SudokuNotesReading extends StatelessWidget {
  const SudokuNotesReading({
    super.key,
    required this.notes,
    required this.active,
  });
  final List<int> notes;
  final bool active;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        notes.isNotEmpty
            ? 'Anotaciones: ${describeNotes(notes)}'
            : active
            ? 'Lápiz activo. Toca un número para anotar.'
            : 'Toca el lápiz para guardar posibilidades.',
        style: homeText(16),
        textAlign: TextAlign.center,
      ),
    ),
  );
}
