import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_feedback_scope.dart';
import 'home_art.dart';
import 'juicy_press.dart';
import 'ui_surface_art.dart';

/// Fits its label while nine-patch artwork preserves the home button's corners.
class IllustratedActionButton extends StatelessWidget {
  const IllustratedActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.compact = false,
    this.fontSize = 34,
    this.showPlayIcon = true,
    this.fitToLabel = false,
    this.leadingIcon,
    this.secondary = false,
    this.surface,
    this.artPadding = EdgeInsets.zero,
    this.contentPadding = const EdgeInsets.fromLTRB(24, 10, 24, 17),
    this.hitPadding = EdgeInsets.zero,
  });

  final String label;
  final FutureOr<void> Function()? onPressed;
  final bool compact;
  final double fontSize;
  final bool showPlayIcon;

  /// Use the label and side padding instead of the artwork's minimum width.
  final bool fitToLabel;
  final Widget? leadingIcon;
  final bool secondary;

  /// Overrides the artwork without changing the button's size.
  final UiSurface? surface;
  final EdgeInsets artPadding;
  final EdgeInsets contentPadding;

  /// Extra tappable space outside the illustrated surface.
  final EdgeInsets hitPadding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final referenceSize = secondary
          ? const Size(224, 56)
          : compact
          ? const Size(224, 70)
          : const Size(244, 78);
      final textStyle = homeText(fontSize);
      final hasIcon = leadingIcon != null || showPlayIcon;
      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.maybeLocaleOf(context),
        maxLines: 1,
      )..layout();
      final sidePadding = fitToLabel ? contentPadding.horizontal : 48.0;
      final naturalWidth = math.max(
        fitToLabel ? 0.0 : referenceSize.width,
        (textPainter.width + sidePadding + (hasIcon ? 51 : 0)).ceilToDouble(),
      );
      final width = bounds.constrainWidth(naturalWidth + hitPadding.horizontal);
      final height =
          math.max(referenceSize.height, textPainter.height + 27) +
          hitPadding.vertical;
      textPainter.dispose();
      return SizedBox(
        width: width,
        height: height,
        child: JuicyPress(
          label: label,
          onFeedback: () => GameFeedbackScope.tap(context),
          onPressed: onPressed,
          builder: (_, _) => Padding(
            padding: hitPadding,
            child: Opacity(
              opacity: onPressed == null ? .45 : 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: artPadding,
                    child: UiSurfaceArt(
                      surface ??
                          (secondary
                              ? UiSurface.blueButton
                              : UiSurface.goldButton),
                      referenceSize: referenceSize,
                    ),
                  ),
                  Padding(
                    padding: contentPadding,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasIcon) ...[
                            leadingIcon ??
                                const HomeIcon(HomeGlyph.play, size: 34),
                            const SizedBox(width: 17),
                          ],
                          Text(
                            label,
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.center,
                            style: textStyle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
