import 'dart:math' as math;
import 'dart:ui';

abstract final class GameLayout {
  static const maxBoardSize = 430.0; // Compact game and tutorial.
  static const maxPlayBoardSize = 540.0;
  static const maxTutorialTextWidth = 470.0;
  static const mobileBoardWidthFraction = 7 / 8;
  static const playBoardWidthFraction = .8;
  static const controlSize = 54.0;
  static const _boardContentFraction = 1 - .045 * 2 - .008 * 2 - .007 * 2;
  static const maxBoardCellSize = maxBoardSize * _boardContentFraction / 9;
  static const numberGridWidth = maxBoardCellSize * 3 + 12;

  static double mobileBoardSize(double viewportWidth) =>
      viewportWidth * mobileBoardWidthFraction;

  static bool useLargePlayLayout(Size size) =>
      size.width >= 700 && size.height >= 600;

  static bool useCompactLandscape(Size size) =>
      size.height < 600 && size.width > size.height * 1.2;

  static double titleWidthFactor(double shortestSide) =>
      shortestSide >= 600 ? .7 : 1;

  static double boardCellSize(double boardSize) =>
      boardSize * _boardContentFraction / 9;

  /// Fit the board, number row, and tool row in the space below the HUD.
  static double playBoardSize({
    required Size viewport,
    required Size body,
    double extraHeight = 0,
  }) {
    final maxSize = useLargePlayLayout(viewport)
        ? maxPlayBoardSize
        : maxBoardSize;
    final widthLimit = math.min(
      maxSize,
      math.min(viewport.width * playBoardWidthFraction, body.width),
    );
    const spacing = 48.0; // Board/controls gaps and vertical breathing room.
    final heightLimit =
        (body.height - spacing - extraHeight) /
        (1 + 2 * _boardContentFraction / 9);
    return math.min(widthLimit, math.max(1, heightLimit));
  }
}
