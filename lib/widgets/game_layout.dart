import 'package:flutter/foundation.dart';

abstract final class GameLayout {
  static const maxBoardSize = 430.0;
  static const controlSize = 54.0;
  static const numberGridWidth = controlSize * 3 + 12;
  static const desktopBoardGap = 24.0;
  static const desktopPlayWidth =
      maxBoardSize + desktopBoardGap + numberGridWidth;

  static bool get isDesktop => switch (defaultTargetPlatform) {
    TargetPlatform.macOS ||
    TargetPlatform.windows ||
    TargetPlatform.linux => true,
    _ => false,
  };
}
