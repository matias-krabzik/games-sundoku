import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Nine-patch painting of a region in an existing transparent image atlas.
/// The source PNG and its alpha are kept intact; only the center and edges grow.
class NineSliceArt extends StatelessWidget {
  const NineSliceArt({
    super.key,
    required this.asset,
    required this.imageSize,
    required this.region,
    required this.centerSlice,
    required this.referenceSize,
  });

  final String asset;
  final Size imageSize;
  final Rect region;
  final Rect centerSlice;
  final Size referenceSize;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: LayoutBuilder(
      builder: (context, bounds) {
        if (bounds.biggest.isEmpty) return const SizedBox.expand();
        final source = Rect.fromLTRB(
          region.left * imageSize.width,
          region.top * imageSize.height,
          region.right * imageSize.width,
          region.bottom * imageSize.height,
        );
        final fixedWidth =
            referenceSize.width *
            (region.width - centerSlice.width) /
            region.width;
        final fixedHeight =
            referenceSize.height *
            (region.height - centerSlice.height) /
            region.height;
        // Very short progress fills and compact panels must also remain valid
        // nine-patches: shrink the corner set uniformly only if it cannot fit.
        final cornerScale = math.min(
          1.0,
          math.min(
            bounds.maxWidth / (fixedWidth + .001),
            bounds.maxHeight / (fixedHeight + .001),
          ),
        );
        final scaleX = referenceSize.width / source.width * cornerScale;
        final scaleY = referenceSize.height / source.height * cornerScale;
        // Atlas margins stay at their original size. Normalized destination
        // cropping would otherwise eat into the corners as the button grows.
        final fullWidth =
            bounds.maxWidth / scaleX + imageSize.width - source.width;
        final fullHeight =
            bounds.maxHeight / scaleY + imageSize.height - source.height;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: fullWidth,
            maxWidth: fullWidth,
            minHeight: fullHeight,
            maxHeight: fullHeight,
            child: Transform.translate(
              offset: Offset(-source.left * scaleX, -source.top * scaleY),
              child: Transform.scale(
                alignment: Alignment.topLeft,
                scaleX: scaleX,
                scaleY: scaleY,
                child: Image.asset(
                  asset,
                  scale: 1,
                  width: fullWidth,
                  height: fullHeight,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                  // With no stretching, use one texture draw instead of nine
                  // adjoining patches (avoids GPU seams on compact squares).
                  centerSlice:
                      referenceSize.width == referenceSize.height &&
                          (bounds.maxWidth - referenceSize.width).abs() <
                              .001 &&
                          (bounds.maxHeight - referenceSize.height).abs() < .001
                      ? null
                      : Rect.fromLTRB(
                          centerSlice.left * imageSize.width,
                          centerSlice.top * imageSize.height,
                          centerSlice.right * imageSize.width,
                          centerSlice.bottom * imageSize.height,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
