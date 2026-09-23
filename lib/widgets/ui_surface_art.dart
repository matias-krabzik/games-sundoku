import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'nine_slice_art.dart';

/// Reusable skins, never one image per button or screen.
enum UiSurface {
  worldFooter,
  blueScoreCapsule,
  goldButton,
  blueButton,
  creamPanel,
  goldCreamPanel,
  goldCreamCard,
  goldTile,
  creamTile,
  creamPill,
  creamCapsule,
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

  UiSurfaceSpec withReferenceSize(Size size) =>
      UiSurfaceSpec(asset, imageSize, region, centerSlice, size);
}

extension UiSurfaceCatalog on UiSurface {
  UiSurfaceSpec get spec => switch (this) {
    UiSurface.blueButton => const UiSurfaceSpec(
      'assets/images/home/blue-button.png',
      Size(2172, 724),
      Rect.fromLTRB(.067, .146, .933, .81),
      Rect.fromLTRB(.18, .35, .82, .65),
      Size(224, 56),
    ),
    UiSurface.worldFooter => const UiSurfaceSpec(
      'assets/images/home/status-panel.png',
      Size(2181, 721),
      Rect.fromLTRB(.20, .14, .80, .65),
      Rect.fromLTRB(.30, .30, .70, .60),
      Size(320, 110),
    ),
    UiSurface.blueScoreCapsule => const UiSurfaceSpec(
      'assets/images/home/play-button.png',
      Size(2172, 724),
      Rect.fromLTRB(.115, .160, .88, .850),
      Rect.fromLTRB(.27, .32, .73, .64),
      Size(170, 48),
    ),
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
    UiSurface.goldCreamCard => UiSurface.goldCreamPanel.spec.withReferenceSize(
      const Size(160, 50),
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
    // Stretch only the center of the circular cream artwork, preserving its
    // rounded ends and continuous upper/lower bevel on short action buttons.
    UiSurface.creamCapsule => const UiSurfaceSpec(
      'assets/images/home/header-surfaces.png',
      Size(1254, 1254),
      Rect.fromLTRB(.322, .137, .673, .487),
      Rect.fromLTRB(.49, .305, .505, .32),
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
      if (surface == UiSurface.goldCreamCard) {
        return ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Color(0xFFFFE9A6),
            BlendMode.modulate,
          ),
          child: art,
        );
      }
      if (surface == UiSurface.worldFooter) {
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFF7DF),
                    Color(0xFFFFF1CA),
                    Color(0xFFF7DA92),
                  ],
                  stops: [0, .55, 1],
                ),
              ),
            ),
            Opacity(opacity: .22, child: art),
            const _AnimatedFooterLight(),
            const Positioned(
              left: 0,
              right: 0,
              top: 9,
              height: 15,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x45975D15), Color(0x00975D15)],
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFF9D0),
                      Color(0xFFFFEE90),
                      Color(0xFFFFD140),
                      Color(0xFFE9A117),
                      Color(0xFFB67410),
                      Color(0xFFFFDF73),
                    ],
                    stops: [0, .14, .36, .64, .86, 1],
                  ),
                ),
              ),
            ),
          ],
        );
      }
      if (surface == UiSurface.blueScoreCapsule) {
        return Stack(
          fit: StackFit.expand,
          children: [
            art,
            Positioned.fill(
              left: 4,
              right: 4,
              top: 4,
              bottom: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(bounds.maxHeight / 2),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF397BCD),
                      Color(0xFF104888),
                      Color(0xFF072958),
                    ],
                    stops: [0, .2, 1],
                  ),
                  border: Border.all(color: const Color(0xFF214F83), width: 1),
                ),
              ),
            ),
          ],
        );
      }
      return surface == UiSurface.progressTrack ||
              surface == UiSurface.progressFill
          ? ClipRRect(borderRadius: BorderRadius.circular(999), child: art)
          : art;
    },
  );
}

/// Low-contrast rays are painted at the available size, keeping the light's
/// origin centered without stretching the artwork or its upper bevel.
class _AnimatedFooterLight extends StatefulWidget {
  const _AnimatedFooterLight();

  @override
  State<_AnimatedFooterLight> createState() => _AnimatedFooterLightState();
}

class _AnimatedFooterLightState extends State<_AnimatedFooterLight>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.maybeOf(context);
    final enabled =
        !(media?.disableAnimations ?? false) &&
        !(media?.accessibleNavigation ?? false) &&
        TickerMode.valuesOf(context).enabled;
    if (enabled) {
      if (!_motion.isAnimating) _motion.repeat();
    } else {
      _motion.stop();
      _motion.value = 0;
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      key: const ValueKey('map-footer-light'),
      painter: _FooterSunrays(_motion),
    ),
  );
}

class _FooterSunrays extends CustomPainter {
  _FooterSunrays(this.motion) : super(repaint: motion);
  final Animation<double> motion;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final origin = Offset(size.width / 2, size.height * .97);
    final radius = size.longestSide * 1.5;
    final wave = math.sin(motion.value * math.pi * 2);
    final rayPaint = Paint()
      ..color = const Color(0xFFFFFBE8).withValues(alpha: .30 + .06 * wave);
    for (var i = 0; i < 18; i++) {
      final angle = i * math.pi * 2 / 18 + wave * .055;
      final edge = angle + math.pi / 18 * .86;
      canvas.drawPath(
        Path()
          ..moveTo(origin.dx, origin.dy)
          ..lineTo(
            origin.dx + math.cos(angle) * radius,
            origin.dy + math.sin(angle) * radius,
          )
          ..lineTo(
            origin.dx + math.cos(edge) * radius,
            origin.dy + math.sin(edge) * radius,
          )
          ..close(),
        rayPaint,
      );
    }
    final glow = Rect.fromCenter(
      center: Offset(size.width * (.5 + wave * .06), size.height * .4),
      width: size.width,
      height: size.height * 2.4,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x99FFFEF3), Color(0x00FFFEF3)],
        ).createShader(glow),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FooterSunrays oldDelegate) =>
      motion != oldDelegate.motion;
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
