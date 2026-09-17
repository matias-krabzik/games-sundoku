import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Travels through clouds so different landscapes meet under full cover.
class WorldJourneyRoute extends MaterialPageRoute<void> {
  WorldJourneyRoute({
    required super.builder,
    super.settings,
    this.reduceMotion = false,
    this.showClouds = true,
  });

  final bool reduceMotion;

  /// Disable for a route inserted underneath another simultaneous journey.
  final bool showClouds;
  int _cloudSeed = math.Random().nextInt(1 << 30);
  final Completer<bool> _entered = Completer<bool>();
  Future<bool> get entered => _entered.future;

  @override
  Duration get transitionDuration =>
      Duration(milliseconds: reduceMotion ? 0 : 1600);

  @override
  Duration get reverseTransitionDuration => transitionDuration;

  @override
  TickerFuture didPush() {
    final result = super.didPush();
    result.whenCompleteOrCancel(() {
      if (!_entered.isCompleted) {
        _entered.complete(isCurrent && animation!.value == 1);
      }
    });
    return result;
  }

  @override
  bool didPop(void result) {
    // Keep an interrupted journey continuous; vary a fresh return trip.
    if (animation!.isCompleted) _cloudSeed = math.Random().nextInt(1 << 30);
    return super.didPop(result);
  }

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      (context, animation, secondaryAnimation, allowSnapshotting, child) {
        if (reduceMotion) return child;
        return AnimatedBuilder(
          animation: secondaryAnimation,
          child: child,
          builder: (context, child) => Transform.scale(
            scale:
                1 + .09 * Curves.easeInOut.transform(secondaryAnimation.value),
            alignment: const Alignment(0, -.2),
            child: child,
          ),
        );
      };

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reduceMotion) return child;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = animation.value;
        final journeyProgress = animation.status == AnimationStatus.reverse
            ? 1 - t
            : t;
        // Fade only after the swap, while the clouds still cover much of the
        // screen. Closing remains opaque for both forward and return journeys.
        final cloudOpacity =
            1 -
            Curves.easeInOutCubic.transform(
              ((journeyProgress - .56) / .27).clamp(0.0, 1.0),
            );
        final arrival = Curves.easeOutCubic.transform(
          ((t - .5) * 2).clamp(0, 1),
        );
        return AbsorbPointer(
          absorbing: t < 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: Curves.easeInOut.transform(
                  ((t - .47) / .06).clamp(0.0, 1.0),
                ),
                child: Transform.scale(
                  scale: 1.07 - .07 * arrival,
                  alignment: const Alignment(0, -.2),
                  child: child,
                ),
              ),
              if ((showClouds || animation.status == AnimationStatus.reverse) &&
                  t > 0 &&
                  t < 1)
                IgnorePointer(
                  child: Opacity(
                    key: const ValueKey('journey-cloud-opacity'),
                    opacity: cloudOpacity,
                    child: CustomPaint(painter: _JourneyClouds(t, _cloudSeed)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _JourneyClouds extends CustomPainter {
  const _JourneyClouds(this.progress, this.seed);
  final double progress;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    // A short fully covered interval conceals the landscape swap in both directions.
    final cover = progress < .44
        ? Curves.easeInOutCubic.transform(progress / .44)
        : progress > .56
        ? Curves.easeInOutCubic.transform((1 - progress) / .44)
        : 1.0;
    final width = math.max(240.0, size.shortestSide * .62);
    final height = width * .62;
    final bankWidth = size.width * .64;
    for (final right in [false, true]) {
      canvas.save();
      if (right) {
        canvas.translate(size.width, 0);
        canvas.scale(-1, 1);
      }
      // Separate clusters overlap like a bank of cumulus, with staggered edges.
      canvas.translate(-(bankWidth + width * 1.5) * (1 - cover), 0);
      for (
        var row = -2;
        row < (size.height / (height * .43)).ceil() + 2;
        row++
      ) {
        final rowRandom = math.Random(
          seed ^ (row * 7919) ^ (right ? 104729 : 0),
        );
        final stagger = rowRandom.nextDouble() * 2 - 1;
        for (var col = -2; col < (bankWidth / (width * .57)).ceil(); col++) {
          // Seed per cluster keeps random choices stable across frames and resize.
          final random = math.Random(
            seed ^ (row * 7919) ^ (col * 15485863) ^ (right ? 104729 : 0),
          );
          final variation = random.nextDouble() * 2 - 1;
          final phase = random.nextDouble() * math.pi * 2;
          final drift = math.sin(progress * math.pi * 2 + phase);
          final x =
              col * width * .57 + stagger * width * .15 + drift * width * .035;
          final y =
              row * height * .43 +
              (right ? -height * .21 : 0) +
              (random.nextDouble() - .5) * height * .12 +
              math.cos(progress * math.pi + phase) * height * .055;
          _paintCluster(
            canvas,
            Rect.fromLTWH(
              x,
              y,
              width * (1 + variation * .12),
              height * (1 + random.nextDouble() * .15),
            ),
            random.nextBool(),
          );
        }
      }
      canvas.restore();
    }
  }

  void _paintCluster(Canvas canvas, Rect bounds, bool warm) {
    canvas.save();
    canvas.translate(bounds.left, bounds.top);
    canvas.scale(bounds.width, bounds.height);
    final shape = Path()
      ..moveTo(.12, .85)
      ..cubicTo(-.06, .83, -.03, .48, .14, .46)
      ..cubicTo(.10, .24, .29, .14, .40, .28)
      ..cubicTo(.42, -.06, .73, -.04, .76, .29)
      ..cubicTo(.91, .22, 1.02, .42, .93, .56)
      ..cubicTo(1.10, .74, .94, .94, .79, .90)
      ..cubicTo(.58, 1.01, .31, .86, .12, .85)
      ..close();
    canvas.drawPath(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: warm
              ? const [
                  Color(0xFFFFF3CA),
                  Color(0xFFFFE0BB),
                  Color(0xFFE6B9B8),
                  Color(0xFFAABCD5),
                ]
              : const [
                  Color(0xFFFFF4D9),
                  Color(0xFFF4D5C4),
                  Color(0xFFC6BBD5),
                  Color(0xFF92B7D1),
                ],
          stops: const [0, .38, .72, 1],
        ).createShader(const Rect.fromLTWH(0, 0, 1, 1)),
    );
    // Soft highlights follow individual lobes instead of flattening the bank.
    canvas.save();
    canvas.clipPath(shape);
    canvas.drawOval(
      const Rect.fromLTWH(.34, .01, .43, .62),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x99FFF8DE), Color(0x00FFF8DE)],
        ).createShader(const Rect.fromLTWH(.29, -.06, .55, .76)),
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_JourneyClouds oldDelegate) =>
      progress != oldDelegate.progress || seed != oldDelegate.seed;
}
