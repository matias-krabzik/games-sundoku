import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/services/game_feedback.dart';
import 'game_feedback_scope.dart';
import 'juicy_press.dart';

/// Sun center in the unpadded 2172 × 724 map artwork.
const mapWorldGateAnchor = Offset(1982 / 2172, 179 / 724);

/// Scales with the arch while retaining a 48 px minimum touch target.
double mapWorldGateArtworkSize(double worldHeight) => 104 * worldHeight / 724;
double mapWorldGateTouchSize(double worldHeight) =>
    math.max(48, mapWorldGateArtworkSize(worldHeight));

/// The original arch emblem, illuminated after all of the world's rounds.
/// Navigation stays disabled until a next-world destination is supplied.
class MapWorldGate extends StatefulWidget {
  const MapWorldGate({
    super.key,
    required this.unlocked,
    required this.artworkSize,
    this.onPressed,
    this.ignitionPending = false,
    this.ignite = false,
    this.onIgnited,
    this.assetPath = asset,
    this.worldNumber = 1,
  });

  final bool unlocked;
  final String assetPath;
  final int worldNumber;
  final double artworkSize;
  final FutureOr<void> Function()? onPressed;
  final bool ignitionPending;
  final bool ignite;
  final VoidCallback? onIgnited;

  static const asset = 'assets/images/map/gate-sun.png';
  static const ignitionDuration = Duration(milliseconds: 1100);
  static const rotationDuration = Duration(seconds: 24);

  @override
  State<MapWorldGate> createState() => _MapWorldGateState();
}

class _MapWorldGateState extends State<MapWorldGate>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final _ignition =
      AnimationController(
          vsync: this,
          duration: MapWorldGate.ignitionDuration,
          value: widget.unlocked && !widget.ignitionPending ? 1 : 0,
        )
        ..addStatusListener(_ignitionChanged)
        ..addListener(_ignitionProgress);
  late final _rotation = AnimationController(
    vsync: this,
    duration: MapWorldGate.rotationDuration,
  );
  bool _reduced = false;
  bool _visible = false;
  bool _completionSent = false;
  bool _syncQueued = false;
  bool _igniteSoundSent = false;
  bool _sparkleSoundSent = false;
  void Function(WorldGateSound)? _playSound;
  VoidCallback? _stopSound;
  ModalRoute<dynamic>? _route;

  bool get _foreground {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return lifecycle == null ||
        lifecycle == AppLifecycleState.resumed ||
        lifecycle == AppLifecycleState.inactive;
  }

  bool get _active =>
      _visible &&
      _foreground &&
      (_route?.isCurrent ?? true) &&
      (_route?.animation == null || _route!.animation!.isCompleted) &&
      (_route?.secondaryAnimation == null ||
          _route!.secondaryAnimation!.isDismissed);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final feedback = context
        .dependOnInheritedWidgetOfExactType<GameFeedbackScope>();
    _playSound = feedback?.onWorldGate;
    _stopSound = feedback?.onStopWorldGate;
    _visible = TickerMode.valuesOf(context).enabled;
    _reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final route = ModalRoute.of(context);
    if (_route != route) {
      _route?.animation?.removeStatusListener(_routeChanged);
      _route?.secondaryAnimation?.removeStatusListener(_routeChanged);
      _route = route;
      _route?.animation?.addStatusListener(_routeChanged);
      _route?.secondaryAnimation?.addStatusListener(_routeChanged);
    }
    _scheduleSync();
  }

  @override
  void didUpdateWidget(MapWorldGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.unlocked ||
        (!oldWidget.ignitionPending && widget.ignitionPending)) {
      _completionSent = false;
      _igniteSoundSent = false;
      _sparkleSoundSent = false;
      _stopSound?.call();
      _ignition.value = 0;
      _rotation.value = 0;
    }
    _scheduleSync();
  }

  void _routeChanged(AnimationStatus _) => _scheduleSync();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _scheduleSync();

  void _scheduleSync() {
    if (_syncQueued) return;
    _syncQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncQueued = false;
      if (mounted) _sync();
    });
  }

  void _sync() {
    if (!_active || !widget.unlocked) {
      _stopSound?.call();
      _ignition.stop(canceled: false);
      _rotation.stop(canceled: false);
      return;
    }
    if (widget.ignitionPending) {
      if (widget.ignite && !_ignition.isCompleted && !_ignition.isAnimating) {
        _ignition.duration = _reduced
            ? const Duration(milliseconds: 450)
            : MapWorldGate.ignitionDuration;
        if (!_igniteSoundSent) {
          _igniteSoundSent = true;
          // Reduced motion uses only the short final chime.
          if (!_reduced) _playSound?.call(WorldGateSound.ignite);
        }
        _ignition.forward();
      }
    } else {
      _ignition.value = 1;
    }
    if (_reduced) {
      _rotation.stop();
      _rotation.value = 0;
    } else if (_ignition.isCompleted && !_rotation.isAnimating) {
      _rotation.repeat();
    }
  }

  void _ignitionProgress() {
    if (!widget.ignite || !widget.unlocked || !_active) return;
    if (!_sparkleSoundSent && _ignition.value >= .65) {
      _sparkleSoundSent = true;
      _playSound?.call(WorldGateSound.sparkle);
    }
  }

  void _ignitionChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (widget.ignite && !_completionSent && _active) {
      _completionSent = true;
      widget.onIgnited?.call();
    }
    _scheduleSync();
  }

  @override
  void dispose() {
    _stopSound?.call();
    WidgetsBinding.instance.removeObserver(this);
    _route?.animation?.removeStatusListener(_routeChanged);
    _route?.secondaryAnimation?.removeStatusListener(_routeChanged);
    _ignition.dispose();
    _rotation.dispose();
    super.dispose();
  }

  // Restore the original gold evenly across the whole RGBA artwork.
  static ColorFilter _saturation(double amount) {
    final muted = 1 - amount;
    final red = .2126 * muted;
    final green = .7152 * muted;
    final blue = .0722 * muted;
    return ColorFilter.matrix([
      red + amount,
      green,
      blue,
      0,
      0,
      red,
      green + amount,
      blue,
      0,
      0,
      red,
      green,
      blue + amount,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final artworkSize = widget.artworkSize;
    final artwork = Image.asset(
      widget.assetPath,
      width: artworkSize,
      height: artworkSize,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
    return Semantics(
      value: widget.unlocked
          ? 'Mundo ${widget.worldNumber} completado'
          : 'Completa todas las rondas del mundo ${widget.worldNumber}',
      child: JuicyPress(
        label: 'Próximo mundo',
        onPressed: widget.unlocked && !widget.ignitionPending
            ? widget.onPressed
            : null,
        onFeedback: () => GameFeedbackScope.tap(context),
        builder: (context, depression) => SizedBox.square(
          dimension: math.max(48, artworkSize),
          child: Center(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([_ignition, _rotation]),
                builder: (context, _) {
                  final progress = widget.unlocked ? _ignition.value : 0.0;
                  final turn = _reduced ? 0.0 : _rotation.value;
                  final lit = Curves.easeOutCubic.transform(progress);
                  final growth = Curves.elasticOut.transform(progress);
                  return Transform.scale(
                    key: const ValueKey('map-gate-growth'),
                    scale: _reduced ? 1 : 1 + .18 * growth,
                    child: SizedBox.square(
                      dimension: artworkSize,
                      child: Stack(
                        clipBehavior: Clip.none,
                        fit: StackFit.expand,
                        children: [
                          Positioned.fill(
                            left: -artworkSize * .35,
                            right: -artworkSize * .35,
                            top: -artworkSize * .35,
                            bottom: -artworkSize * .35,
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: MapGateRadiance(
                                  progress: progress,
                                  turn: turn,
                                  reduced: _reduced,
                                ),
                              ),
                            ),
                          ),
                          Transform.rotate(
                            key: const ValueKey('map-gate-rotation'),
                            angle: turn * math.pi * 2,
                            child: ColorFiltered(
                              colorFilter: _saturation(lit),
                              child: artwork,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A soft halo fades in with the sun, with a single sparse burst near ignition.
class MapGateRadiance extends CustomPainter {
  const MapGateRadiance({
    required this.progress,
    required this.turn,
    required this.reduced,
  });

  final double progress;
  final double turn;
  final bool reduced;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = size.center(Offset.zero);
    final diameter = size.shortestSide / 1.7;
    final lit = Curves.easeInOut.transform(progress);
    final breath = progress < 1 || reduced
        ? 0.0
        : math.sin(turn * math.pi * 16);
    final radius = diameter * (.76 + breath * .015);
    final strength = (lit * .57 + breath * .06).clamp(0.0, 1.0);
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF4B5).withValues(alpha: strength),
            const Color(0xFFFFC53D).withValues(alpha: strength * .6),
            const Color(0x00FFC53D),
          ],
          stops: const [0, .35, 1],
        ).createShader(bounds),
    );
    if (reduced || progress >= 1) return;
    for (var i = 0; i < 8; i++) {
      final t = ((progress - .65 - (i % 3) * .035) / .27).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      final angle = i * math.pi / 4 + .19;
      final point =
          center +
          Offset(math.cos(angle), math.sin(angle)) *
              diameter *
              (.38 + Curves.easeOut.transform(t) * .32);
      final alpha = math.sin(t * math.pi);
      final sparkSize = diameter * (.013 + (i % 2) * .006) * alpha;
      final paint = Paint()
        ..color = const Color(0xFFFFF3C0).withValues(alpha: alpha);
      final path = Path()
        ..moveTo(point.dx, point.dy - sparkSize * 2)
        ..lineTo(point.dx + sparkSize * .6, point.dy - sparkSize * .6)
        ..lineTo(point.dx + sparkSize * 2, point.dy)
        ..lineTo(point.dx + sparkSize * .6, point.dy + sparkSize * .6)
        ..lineTo(point.dx, point.dy + sparkSize * 2)
        ..lineTo(point.dx - sparkSize * .6, point.dy + sparkSize * .6)
        ..lineTo(point.dx - sparkSize * 2, point.dy)
        ..lineTo(point.dx - sparkSize * .6, point.dy - sparkSize * .6)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(MapGateRadiance oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.turn != turn ||
      oldDelegate.reduced != reduced;
}
