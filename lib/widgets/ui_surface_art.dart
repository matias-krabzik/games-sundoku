import 'package:flutter/material.dart';

import 'nine_slice_art.dart';

/// Reusable skins, never one image per button or screen.
enum UiSurface {
  goldButton,
  creamPanel,
  goldCreamPanel,
  goldTile,
  creamTile,
  creamPill,
  creamRound,
  goldRound,
  progressTrack,
  progressFill,
}

class UiSurfaceSpec {
  const UiSurfaceSpec(
    this.asset,
    this.imageSize,
    this.region,
    this.centerSlice,
    this.referenceSize,
  );
  final String asset;
  final Size imageSize;
  final Rect region;
  final Rect centerSlice;
  final Size referenceSize;
}

extension UiSurfaceCatalog on UiSurface {
  UiSurfaceSpec get spec => switch (this) {
    UiSurface.goldTile => const UiSurfaceSpec(
      'assets/images/tutorial/block-tiles.png',
      Size(1774, 887),
      Rect.fromLTRB(.030, .080, .465, .910),
      Rect.fromLTRB(.13, .25, .37, .73),
      Size(80, 80),
    ),
    UiSurface.creamTile => const UiSurfaceSpec(
      'assets/images/tutorial/block-tiles.png',
      Size(1774, 887),
      Rect.fromLTRB(.530, .080, .970, .910),
      Rect.fromLTRB(.63, .25, .87, .73),
      Size(80, 80),
    ),
    UiSurface.goldButton => const UiSurfaceSpec(
      'assets/images/home/play-button.png',
      Size(2172, 724),
      Rect.fromLTRB(.115, .160, .88, .850),
      Rect.fromLTRB(.27, .32, .73, .64),
      Size(244, 78),
    ),
    UiSurface.creamPanel => const UiSurfaceSpec(
      'assets/images/home/status-panel.png',
      Size(2181, 721),
      Rect.fromLTRB(.040, .080, .960, .880),
      Rect.fromLTRB(.14, .30, .86, .68),
      Size(300, 90),
    ),
    UiSurface.goldCreamPanel => const UiSurfaceSpec(
      'assets/images/tutorial/gold-cream-panel.png',
      Size(2169, 725),
      Rect.fromLTRB(.020, .145, .980, .835),
      Rect.fromLTRB(.16, .475, .84, .490),
      Size(340, 86),
    ),
    UiSurface.creamPill => const UiSurfaceSpec(
      'assets/images/home/header-surfaces.png',
      Size(1254, 1254),
      Rect.fromLTRB(.089, .584, .911, .846),
      Rect.fromLTRB(.24, .655, .76, .77),
      Size(168, 54),
    ),
    UiSurface.creamRound => const UiSurfaceSpec(
      'assets/images/home/header-surfaces.png',
      Size(1254, 1254),
      Rect.fromLTRB(.322, .137, .673, .487),
      Rect.fromLTRB(.49, .30, .505, .32),
      Size(54, 54),
    ),
    UiSurface.goldRound => const UiSurfaceSpec(
      'assets/images/map/icons.png',
      Size(1254, 1254),
      Rect.fromLTRB(.667, .590, .985, .916),
      Rect.fromLTRB(.815, .743, .837, .765),
      Size(54, 54),
    ),
    UiSurface.progressTrack => const UiSurfaceSpec(
      'assets/images/home/progress.png',
      Size(1536, 1024),
      Rect.fromLTRB(.033, .234, .967, .406),
      Rect.fromLTRB(.12, .28, .88, .36),
      Size(140, 16),
    ),
    UiSurface.progressFill => const UiSurfaceSpec(
      'assets/images/home/progress.png',
      Size(1536, 1024),
      Rect.fromLTRB(.033, .590, .967, .758),
      Rect.fromLTRB(.12, .63, .88, .715),
      Size(140, 16),
    ),
  };
}

class UiSurfaceArt extends StatelessWidget {
  const UiSurfaceArt(this.surface, {super.key, this.referenceSize});
  final UiSurface surface;
  final Size? referenceSize;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      if (bounds.biggest.isEmpty) return const SizedBox.expand();
      final spec = surface.spec;
      var reference = referenceSize ?? spec.referenceSize;
      if (surface == UiSurface.creamRound || surface == UiSurface.goldRound) {
        // Square controls stay circular at every touch-target size.
        reference = Size.square(bounds.biggest.shortestSide);
      } else if (referenceSize == null &&
          (surface == UiSurface.goldTile || surface == UiSurface.creamTile)) {
        // Compact controls shrink the entire corner set proportionally. Keeping
        // 80px caps on a 40px button nearly collapses its middle stretch band.
        final side = bounds.biggest.shortestSide.clamp(
          0.0,
          spec.referenceSize.shortestSide,
        );
        reference = Size.square(side);
      } else if (surface == UiSurface.progressTrack ||
          surface == UiSurface.progressFill) {
        reference = Size(
          spec.referenceSize.aspectRatio * bounds.maxHeight,
          bounds.maxHeight,
        );
      }
      final art = NineSliceArt(
        asset: spec.asset,
        imageSize: spec.imageSize,
        region: spec.region,
        centerSlice: spec.centerSlice,
        referenceSize: reference,
      );
      return surface == UiSurface.progressTrack ||
              surface == UiSurface.progressFill
          ? ClipRRect(borderRadius: BorderRadius.circular(999), child: art)
          : art;
    },
  );
}

/// A live layout over a shared skin. Content determines the panel's dimensions.
class UiSurfacePanel extends StatelessWidget {
  const UiSurfacePanel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.constraints = const BoxConstraints(),
    this.surface = UiSurface.creamPanel,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BoxConstraints constraints;
  final UiSurface surface;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: constraints,
    child: Stack(
      children: [
        Positioned.fill(child: UiSurfaceArt(surface)),
        Padding(padding: padding, child: child),
      ],
    ),
  );
}
