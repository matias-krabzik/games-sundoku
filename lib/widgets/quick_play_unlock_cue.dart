import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'home_art.dart';
import 'ui_surface_art.dart';

/// Celebrates only after the home route has finished arriving on screen.
class QuickPlayUnlockCue extends StatefulWidget {
  const QuickPlayUnlockCue({
    super.key,
    required this.isNew,
    required this.celebrate,
    required this.child,
    this.onCelebrated,
  });

  final bool isNew;
  final bool celebrate;
  final VoidCallback? onCelebrated;
  final Widget child;

  @override
  State<QuickPlayUnlockCue> createState() => _QuickPlayUnlockCueState();
}

class _QuickPlayUnlockCueState extends State<QuickPlayUnlockCue>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  ModalRoute<dynamic>? _route;
  bool _started = false;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      _route?.animation?.removeStatusListener(_routeChanged);
      _route?.secondaryAnimation?.removeStatusListener(_routeChanged);
      _route = route;
      _route?.animation?.addStatusListener(_routeChanged);
      _route?.secondaryAnimation?.addStatusListener(_routeChanged);
    }
    _schedule();
  }

  @override
  void didUpdateWidget(QuickPlayUnlockCue oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedule();
  }

  void _routeChanged(AnimationStatus _) => _schedule();

  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final arrived =
          (_route?.isCurrent ?? true) &&
          (_route?.animation == null || _route!.animation!.isCompleted) &&
          (_route?.secondaryAnimation == null ||
              _route!.secondaryAnimation!.isDismissed);
      if (!arrived || !widget.isNew) {
        _pulse.stop();
        return;
      }
      final reduced =
          MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context);
      if (!_started && widget.celebrate) {
        _started = true;
        if (!reduced) _pulse.forward(from: 0);
        widget.onCelebrated?.call();
      } else if (_started &&
          !reduced &&
          !_pulse.isCompleted &&
          !_pulse.isAnimating) {
        _pulse.forward();
      }
      if (reduced) _pulse.value = 1;
    });
  }

  @override
  void dispose() {
    _route?.animation?.removeStatusListener(_routeChanged);
    _route?.secondaryAnimation?.removeStatusListener(_routeChanged);
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (widget.isNew) ...[
        Semantics(
          liveRegion: true,
          child: UiSurfacePanel(
            surface: UiSurface.goldCreamPanel,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Text(
              '¡Nuevo!',
              key: const ValueKey('home-quick-play-new'),
              textAlign: TextAlign.center,
              style: homeText(18),
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
      AnimatedBuilder(
        animation: _pulse,
        child: widget.child,
        builder: (_, child) {
          final strength = !widget.isNew || _pulse.isCompleted
              ? 0.0
              : math.pow(math.sin(_pulse.value * math.pi * 3), 2).toDouble();
          return Transform.scale(
            key: const ValueKey('home-quick-play-pulse'),
            scale: 1 + strength * .025,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD442)
                        .withValues(alpha: strength * .6),
                    blurRadius: 20,
                    spreadRadius: strength * 3,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
      ),
    ],
  );
}
