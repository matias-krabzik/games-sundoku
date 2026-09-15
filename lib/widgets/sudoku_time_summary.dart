import 'package:flutter/material.dart';

import 'game_pause.dart';
import 'home_art.dart';
import 'score_feedback.dart';
import 'ui_surface_art.dart';

/// Real text and adaptive rows over the shared nine-patch panel.
class SudokuTimeSummary extends StatelessWidget {
  const SudokuTimeSummary({
    super.key,
    required this.elapsedMs,
    required this.levelNumber,
    this.points = const [],
  });

  final List<int> elapsedMs;
  final List<int> points;
  final int levelNumber;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final height = bounds.hasBoundedHeight ? bounds.maxHeight : 340.0;
      final dense = height < 310;
      return SizedBox(
        height: height,
        child: UiSurfacePanel(
          surface: UiSurface.goldCreamPanel,
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 16 : 22,
            vertical: dense ? 12 : 20,
          ),
          child: Column(
            children: [
              if (!dense)
                Expanded(
                  child: _text(
                    '¡Completaste las ${elapsedMs.length} rondas!',
                    22,
                  ),
                ),
              Expanded(
                child: _row(['Ronda', 'Puntos', 'Tiempo'], header: true),
              ),
              for (var i = 0; i < elapsedMs.length; i++)
                Expanded(
                  child: _row([
                    'Ronda ${i + 1}',
                    formatScore(i < points.length ? points[i] : 0),
                    formatPlayTime(elapsedMs[i]),
                  ], index: i),
                ),
              Expanded(
                child: _row([
                  'Total',
                  formatScore(points.fold(0, (sum, value) => sum + value)),
                  formatPlayTime(
                    elapsedMs.fold(0, (sum, value) => sum + value),
                  ),
                ], total: true),
              ),
              Expanded(
                child: _text(
                  levelNumber == 10
                      ? '¡Completaste el Valle del Sol!'
                      : 'El nivel ${levelNumber + 1} ya está abierto.',
                  17,
                ),
              ),
              if (!dense)
                Expanded(
                  child: _text(
                    'Niveles 1–10: los puntos no afectan el avance.',
                    14,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  Widget _text(
    String value,
    double size, {
    Key? valueKey,
    Alignment alignment = Alignment.center,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    child: Align(
      alignment: alignment,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(value, key: valueKey, maxLines: 1, style: homeText(size)),
      ),
    ),
  );

  Widget _row(
    List<String> values, {
    bool header = false,
    bool total = false,
    int? index,
  }) => DecoratedBox(
    decoration: BoxDecoration(
      color: total
          ? const Color(0xFFFFDF7A)
          : header
          ? const Color(0x80FFE9A5)
          : Colors.transparent,
      borderRadius: header || total ? BorderRadius.circular(10) : null,
      border: header || total
          ? null
          : const Border(bottom: BorderSide(color: Color(0x80EFB63B))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var column = 0; column < 3; column++)
          Expanded(
            flex: column == 0 ? 12 : 10,
            child: _text(
              values[column],
              total
                  ? 22
                  : header
                  ? 18
                  : 20,
              alignment: column == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              valueKey: column == 0 || header
                  ? null
                  : ValueKey(
                      total
                          ? 'summary-total-${column == 1 ? 'points' : 'time'}'
                          : 'summary-sudoku-${index! + 1}-${column == 1 ? 'points' : 'time'}',
                    ),
            ),
          ),
      ],
    ),
  );
}
