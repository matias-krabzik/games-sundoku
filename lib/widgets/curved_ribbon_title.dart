import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'home_art.dart';

/// Live, accessible lettering following the concave front face of a ribbon.
class CurvedRibbonTitle extends StatelessWidget {
  const CurvedRibbonTitle({
    super.key,
    required this.text,
    required this.fontSize,
  });

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Semantics(
    label: text,
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, bounds) {
          final characters = text.characters.toList();
          if (characters.isEmpty || bounds.biggest.isEmpty) {
            return const SizedBox.shrink();
          }
          final direction = Directionality.of(context);
          final requested = MediaQuery.textScalerOf(context).scale(fontSize);
          final base = homeText(requested, weight: FontWeight.w800);
          final widths = <double>[];
          var height = 0.0;
          for (final character in characters) {
            final painter = TextPainter(
              text: TextSpan(text: character, style: base),
              textDirection: direction,
              maxLines: 1,
            )..layout();
            widths.add(painter.width);
            height = math.max(height, painter.height);
            painter.dispose();
          }
          final total = widths.fold(0.0, (sum, width) => sum + width);
          final sag = math.min(8.0, bounds.maxHeight * .16);
          final fit = math
              .min(
                1.0,
                math.min(
                  (bounds.maxWidth - 4) / math.max(1, total),
                  (bounds.maxHeight - sag - 4) / math.max(1, height),
                ),
              )
              .clamp(0.0, 1.0);
          final style = base.copyWith(fontSize: requested * fit);
          final lineWidth = total * fit;
          var cursor = (bounds.maxWidth - lineWidth) / 2;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < characters.length; i++)
                () {
                  final width = widths[i] * fit;
                  final left = cursor;
                  cursor += width;
                  final unit = lineWidth == 0
                      ? 0.0
                      : (left + width / 2 - bounds.maxWidth / 2) /
                            (lineWidth / 2);
                  return Positioned(
                    left: left,
                    top:
                        (bounds.maxHeight - height * fit - sag) / 2 +
                        sag * (1 - unit * unit),
                    width: width + .5,
                    height: height * fit + 3,
                    child: Transform.rotate(
                      angle: math.atan(
                        -4 * sag * unit / math.max(1, lineWidth),
                      ),
                      child: Stack(
                        children: [
                          Text(
                            characters[i],
                            textScaler: TextScaler.noScaling,
                            maxLines: 1,
                            softWrap: false,
                            style: style.copyWith(
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 1.3
                                ..color = const Color(0xFFD49124),
                              shadows: const [
                                Shadow(
                                  color: Color(0xFF072654),
                                  offset: Offset(0, 2),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            characters[i],
                            textScaler: TextScaler.noScaling,
                            maxLines: 1,
                            softWrap: false,
                            style: style.copyWith(
                              color: const Color(0xFFFFFAE8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }(),
            ],
          );
        },
      ),
    ),
  );
}
