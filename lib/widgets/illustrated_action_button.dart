import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_feedback_scope.dart';
import 'home_art.dart';
import 'juicy_press.dart';

/// Fits its label while nine-patch artwork preserves the home button's corners.
class IllustratedActionButton extends StatelessWidget {
  const IllustratedActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.compact = false,
    this.fontSize = 34,
    this.showPlayIcon = true,
    this.leadingIcon,
  });

  final String label;
  final FutureOr<void> Function()? onPressed;
  final bool compact;
  final double fontSize;
  final bool showPlayIcon;
  final Widget? leadingIcon;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final referenceSize = compact ? const Size(224, 70) : const Size(244, 78);
      final textStyle = homeText(fontSize);
      final hasIcon = leadingIcon != null || showPlayIcon;
      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.maybeLocaleOf(context),
        maxLines: 1,
      )..layout();
      final width = bounds.constrainWidth(
        math.max(
          referenceSize.width,
          (textPainter.width + 48 + (hasIcon ? 51 : 0)).ceilToDouble(),
        ),
      );
      final height = math.max(referenceSize.height, textPainter.height + 27);
      textPainter.dispose();
      return SizedBox(
        width: width,
        height: height,
        child: JuicyPress(
          label: label,
          onFeedback: () => GameFeedbackScope.tap(context),
          onPressed: onPressed,
          builder: (_, _) => Stack(
            fit: StackFit.expand,
            children: [
              HomeArt(HomeSurface.play, playReferenceSize: referenceSize),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 17),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasIcon) ...[
                        leadingIcon ?? const HomeIcon(HomeGlyph.play, size: 34),
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
      );
    },
  );
}
