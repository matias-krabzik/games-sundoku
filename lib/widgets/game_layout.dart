import 'dart:math' as math;
import 'dart:ui';

abstract final class GameLayout {
  static const maxBoardSize = 430.0; // Tutorial scenes.
  static const maxTutorialTextWidth = 470.0;
  static const playBoardWidthFraction = .95;
  static const largePlayBoardWidthFraction = .8;
  static const controlSize = 54.0;
  static const mobileHeaderInset = 16.0;
  static const playStatusBoardGap = 24.0;
  static const playBoardControlsGap = 28.0;
  static const largePlayStatusPadding = 8.0;
  static const _boardContentFraction = 1 - .045 * 2 - .008 * 2 - .007 * 2;
  static const maxBoardCellSize = maxBoardSize * _boardContentFraction / 9;
  static const numberGridWidth = maxBoardCellSize * 3 + 12;

  static bool useLargePlayLayout(Size size) =>
      size.width >= 700 && size.height >= 600;

  static bool useCompactLandscape(Size size) =>
      size.height < 600 && size.width > size.height * 1.2;

  static bool useMobilePlayHeader(Size size) => size.shortestSide < 600;

  static double playBoardWidthFactor(Size size) => useMobilePlayHeader(size)
      ? playBoardWidthFraction
      : largePlayBoardWidthFraction;

  static double playStatusScale(Size size) =>
      useMobilePlayHeader(size) ? 1 : 1.35;

  static double playHeaderHeight(Size size) => useMobilePlayHeader(size)
      ? controlSize + mobileHeaderInset * 2
      : controlSize;

  static double titleWidthFactor(double shortestSide) =>
      shortestSide >= 600 ? .7 : 1;

  static double boardCellSize(double boardSize) =>
      boardSize * _boardContentFraction / 9;

  static double playStatusHeight({
    required bool compact,
    required double textHeight,
    bool large = false,
  }) =>
      math.max(compact ? 52.0 : 76.0, textHeight + (compact ? 20 : 36)) +
      (large ? largePlayStatusPadding * 2 : 0);

  /// Use 80% of the safe width on large windows and 95% on phones, fitting height.
  static double playBoardSize({
    required Size viewport,
    required Size body,
    double extraHeight = 0,
  }) {
    final widthLimit = math.min(
      viewport.width * playBoardWidthFactor(viewport),
      body.width,
    );
    final compact = useCompactLandscape(viewport);
    final spacing =
        (compact ? 12 : playStatusBoardGap) +
        (compact ? 20 : playBoardControlsGap) +
        16 + // Gap and padding around the tool row.
        16; // Breathing room above and below the play group.
    final heightLimit =
        (body.height - spacing - extraHeight) /
        (1 + 2 * _boardContentFraction / 9);
    return math.min(widthLimit, math.max(1, heightLimit));
  }
}
