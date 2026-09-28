import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'home_art.dart';
import 'game_layout.dart';
import 'juicy_press.dart';
import 'sudoku_digit.dart';
import 'tutorial_block_art.dart';
import 'ui_surface_art.dart';

class TutorialNumberTray extends StatelessWidget {
  const TutorialNumberTray({
    super.key,
    required this.available,
    required this.onSelected,
    this.horizontal = false,
    this.showGuide = true,
    this.buttonExtent,
    this.notesMode = false,
    this.selectedNotes = const [],
  });
  final bool horizontal;
  final bool showGuide;
  final double? buttonExtent;
  final bool notesMode;
  final List<int> selectedNotes;
  final List<int> available;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      if (horizontal) {
        final gap = bounds.maxWidth < 340 ? 2.0 : 4.0;
        final availableWidth = (bounds.maxWidth - gap * 8) / 9;
        final width = math.min(
          buttonExtent ?? math.min(availableWidth, GameLayout.controlSize),
          availableWidth,
        );
        return SizedBox(
          height: width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var number = 1; number <= 9; number++) ...[
                if (number > 1) SizedBox(width: gap),
                SizedBox(
                  width: width,
                  child: _NumberButton(
                    number: number,
                    notesMode: notesMode,
                    noteSelected: selectedNotes.contains(number),
                    placed: !available.contains(number),
                    onSelected: onSelected,
                  ),
                ),
              ],
            ],
          ),
        );
      }
      if (!showGuide) {
        return Center(
          child: SizedBox(
            width: math.min(
              bounds.maxWidth,
              buttonExtent == null
                  ? GameLayout.numberGridWidth
                  : buttonExtent! * 3 + 12,
            ),
            child: _grid(),
          ),
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: bounds.maxWidth * .40,
            height: 128,
            child: OverflowBox(
              minHeight: 184,
              maxHeight: 184,
              child: Transform.translate(
                offset: const Offset(0, -18),
                child: const TutorialBlockArt(TutorialGlyph.guide),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: GameLayout.numberGridWidth,
                ),
                child: _grid(),
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _grid() => GridView.count(
    crossAxisCount: 3,
    crossAxisSpacing: 6,
    mainAxisSpacing: 6,
    shrinkWrap: true,
    primary: false,
    padding: EdgeInsets.zero,
    physics: const NeverScrollableScrollPhysics(),
    children: [
      for (var number = 1; number <= 9; number++)
        _NumberButton(
          number: number,
          notesMode: notesMode,
          noteSelected: selectedNotes.contains(number),
          placed: !available.contains(number),
          onSelected: onSelected,
        ),
    ],
  );
}

class _NumberButton extends StatelessWidget {
  const _NumberButton({
    required this.number,
    required this.placed,
    required this.onSelected,
    this.notesMode = false,
    this.noteSelected = false,
  });
  final int number;
  final bool placed;
  final bool notesMode;
  final bool noteSelected;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, bounds) => JuicyPress(
      key: ValueKey('intro-number-$number'),
      label: notesMode
          ? '${noteSelected ? 'Quitar anotación' : 'Anotar'} $number'
          : placed
          ? '$number ya colocado'
          : 'Colocar $number',
      toggled: notesMode ? noteSelected : null,
      onPressed: placed || onSelected == null
          ? null
          : () => onSelected!(number),
      builder: (_, _) => Stack(
        fit: StackFit.expand,
        children: [
          UiSurfaceArt(placed ? UiSurface.creamTile : UiSurface.goldTile),
          Center(
            child: Opacity(
              opacity: placed ? .38 : 1,
              child: SudokuDigit(number, size: bounds.maxWidth * .55),
            ),
          ),
          if (notesMode && noteSelected)
            Positioned(
              right: 3,
              top: 3,
              child: Icon(
                Icons.check,
                size: bounds.maxWidth * .24,
                color: homeNavy,
              ),
            ),
        ],
      ),
    ),
  );
}

class TutorialEraseButton extends StatelessWidget {
  const TutorialEraseButton({
    super.key,
    required this.onPressed,
    this.iconSize = 40,
    this.surface = UiSurface.creamRound,
    this.dimension = 52,
  });
  final VoidCallback? onPressed;
  final double iconSize;
  final UiSurface surface;
  final double dimension;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: dimension,
    child: JuicyPress(
      key: const ValueKey('intro-clear'),
      label: 'Borrar número seleccionado',
      onPressed: onPressed,
      builder: (_, _) => Stack(
        fit: StackFit.expand,
        children: [
          UiSurfaceArt(surface),
          Center(
            child: Opacity(
              opacity: onPressed == null ? .5 : 1,
              child: Image.asset(
                'assets/images/tutorial/cleaning-brush.png',
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class TutorialBlockCard extends StatelessWidget {
  const TutorialBlockCard({
    super.key,
    required this.filledCount,
    this.expanded = false,
  });
  final int filledCount;
  final bool expanded;

  @override
  Widget build(BuildContext context) => UiSurfacePanel(
    surface: UiSurface.goldCreamPanel,
    padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          expanded
              ? 'Tu bloque está en el centro.'
              : 'Del 1 al 9, una vez cada uno.',
          textAlign: TextAlign.center,
          style: homeText(21),
        ),
        const SizedBox(height: 4),
        Text(
          expanded
              ? 'El tablero tiene 9 bloques de 9 casillas.'
              : 'Coloca los números del 1 al 9.',
          textAlign: TextAlign.center,
          style: homeText(19, weight: FontWeight.w700),
        ),
        if (!expanded) ...[
          const SizedBox(height: 12),
          Semantics(
            label: 'Progreso del bloque',
            value: '$filledCount de 9',
            child: SizedBox(
              height: 17,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const HomeArt(HomeSurface.progressTrack),
                  Padding(
                    padding: const EdgeInsets.all(2),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: filledCount / 9),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 280),
                        builder: (_, progress, _) => FractionallySizedBox(
                          key: const ValueKey('intro-block-progress'),
                          widthFactor: progress,
                          heightFactor: 1,
                          child: const HomeArt(HomeSurface.progressFill),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Semantics(
            liveRegion: true,
            child: Text('$filledCount de 9 colocados', style: homeText(16)),
          ),
        ],
      ],
    ),
  );
}
