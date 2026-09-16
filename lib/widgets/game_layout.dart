import 'package:flutter/foundation.dart';

abstract final class GameLayout {
  static const maxBoardSize = 430.0;
  static const mobileBoardWidthFraction = 7 / 8;
  static const controlSize = 54.0;
  static const _boardContentFraction = 1 - .045 * 2 - .008 * 2 - .007 * 2;
  static const maxBoardCellSize = maxBoardSize * _boardContentFraction / 9;
  static const numberGridWidth = maxBoardCellSize * 3 + 12;
  static const desktopBoardGap = 24.0;
  static const desktopPlayWidth =
      maxBoardSize + desktopBoardGap + numberGridWidth;

  static double mobileBoardSize(double viewportWidth) =>
      viewportWidth * mobileBoardWidthFraction;

  static double boardCellSize(double boardSize) =>
      boardSize * _boardContentFraction / 9;

  static bool get isDesktop => switch (defaultTargetPlatform) {
    TargetPlatform.macOS ||
    TargetPlatform.windows ||
    TargetPlatform.linux => true,
    _ => false,
  };
}
