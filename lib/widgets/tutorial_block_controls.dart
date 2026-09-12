import 'package:flutter/material.dart';

import 'home_art.dart';
import 'juicy_press.dart';
import 'map_art.dart';
import 'sudoku_digit.dart';
import 'tutorial_block_art.dart';
import 'ui_surface_art.dart';

class TutorialNumberTray extends StatelessWidget {
  const TutorialNumberTray({
    super.key,
    required this.available,
    required this.onSelected,
  });
  final List<int> available;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
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
                constraints: const BoxConstraints(maxWidth: 192),
                child: GridView.count(
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
                        placed: !available.contains(number),
                        onSelected: onSelected,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _NumberButton extends StatelessWidget {
  const _NumberButton({
    required this.number,
    required this.placed,
    required this.onSelected,
  });
  final int number;
  final bool placed;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, bounds) => JuicyPress(
      key: ValueKey('intro-number-$number'),
      label: placed ? '$number ya colocado' : 'Colocar $number',
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
              child: SudokuDigit(number, size: bounds.maxWidth * .69),
            ),
          ),
          if (placed)
            const Positioned(
              right: 5,
              bottom: 5,
              child: MapIcon(MapGlyph.lock, size: 13),
            ),
        ],
      ),
    ),
  );
}

class TutorialEraseButton extends StatelessWidget {
  const TutorialEraseButton({super.key, required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Borrar número',
    child: SizedBox.square(
      dimension: 52,
      child: JuicyPress(
        key: const ValueKey('intro-clear'),
        label: 'Borrar número seleccionado',
        onPressed: onPressed,
        builder: (_, _) => Stack(
          fit: StackFit.expand,
          children: [
            const UiSurfaceArt(UiSurface.creamRound),
            Center(
              child: Opacity(
                opacity: onPressed == null ? .5 : 1,
                child: Image.asset(
                  'assets/images/tutorial/cleaning-brush.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ],
        ),
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
              : 'Elige el orden que quieras.',
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
