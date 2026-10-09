import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../data/world_overview.dart';
import '../models/map_ambient_motion.dart';
import '../models/world_map_definition.dart';
import '../playables/playables_runtime.dart';
import 'map_ambient_painter.dart';
import 'world_overview_fog.dart';

/// Static landscape plus independent, touch-transparent animation layers.
class WorldOverviewScene extends StatefulWidget {
  const WorldOverviewScene({
    super.key,
    required this.overview,
    required this.child,
    required this.protectedRects,
    this.lockedWorlds = const {},
    this.cameraImage,
    this.discovery = const {},
  });
  final WorldOverview overview;
  final Widget child;
  final List<Rect> protectedRects;
  final Set<String> lockedWorlds;
  final Rect? cameraImage;
  final Map<String, double> discovery;

  @override
  State<WorldOverviewScene> createState() => WorldOverviewSceneState();
}

class WorldOverviewSceneState extends State<WorldOverviewScene>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<double> _frame = ValueNotifier(0);
  final _fogArt = OverviewFogArt();
  late MapAmbientMotion _motion;
  final _art = MapAmbientArt(
    leafAssets: const [
      'assets/images/map/crossed-rivers/ambient/leaf-round.png',
    ],
    petalAsset: 'assets/images/map/crossed-rivers/ambient/petal.png',
    creatureAssets: const {
      MapCreatureKind.butterfly:
          'assets/images/map/crossed-rivers/ambient/butterfly-body-v2.png',
      MapCreatureKind.dragonfly:
          'assets/images/map/crossed-rivers/ambient/dragonfly-body-v2.png',
      MapCreatureKind.fish: 'assets/images/map/crossed-rivers/ambient/fish.png',
    },
    creatureWingAssets: const {
      MapCreatureKind.butterfly:
          'assets/images/map/crossed-rivers/ambient/butterfly-wing-v2.png',
      MapCreatureKind.dragonfly:
          'assets/images/map/crossed-rivers/ambient/dragonfly-wing-v2.png',
    },
  );
  Duration? _last;
  bool _visible = false;
  bool _reduced = false;
  late final PlayablesRuntime? _runtime = PlayablesRuntime.active;
  double get seconds => _frame.value;
  bool get isAnimating => _ticker.isActive;
  MapAmbientMotion get motion => _motion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runtime?.addListener(_runtimeChanged);
    _configure();
    unawaited(_art.load());
    unawaited(_fogArt.load());
  }

  void _configure() {
    final overview = widget.overview;
    final trees = overview.canopies.map(overview.pixels).toList();
    final pond = overview.water.first;
    final fishCenter = overview.pixels(pond.center);
    final fishTravel = overview.pixels(
      Offset(pond.width * .25, pond.height * .25),
    );
    _motion = MapAmbientMotion(
      seed: 71,
      sourceSize: overview.sourceSize,
      flowerAnchors: trees,
      foregroundFlowers: trees.length,
      canopyAnchors: trees,
      pinkCanopy: trees[1],
      petalAnchors: [trees[1], trees[2]],
      treeLeavesOnly: true,
      beeCount: 1,
      creatures: [
        MapCreatureDefinition(
          kind: MapCreatureKind.butterfly,
          center: trees[0],
          travel: const Offset(75, 40),
          size: 24,
        ),
        MapCreatureDefinition(
          kind: MapCreatureKind.dragonfly,
          center: fishCenter,
          travel: const Offset(80, 45),
          size: 24,
          phase: 2,
        ),
        MapCreatureDefinition(
          kind: MapCreatureKind.fish,
          center: fishCenter,
          travel: fishTravel,
          size: 24,
          phase: 1,
        ),
      ],
    )..setView(Offset.zero & overview.sourceSize);
  }

  @override
  void didUpdateWidget(WorldOverviewScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    unawaited(_fogArt.load());
    if (oldWidget.overview.landscape != widget.overview.landscape) _configure();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible =
        TickerMode.valuesOf(context).enabled &&
        ModalRoute.of(context)?.isCurrent != false;
    _reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    _sync();
  }

  void _sync() {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final mobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final foreground =
        lifecycle == null ||
        lifecycle == AppLifecycleState.resumed ||
        (!mobile && lifecycle == AppLifecycleState.inactive);
    final active =
        _visible && !_reduced && foreground && _runtime?.isPaused != true;
    if (active && !_ticker.isActive) {
      _last = null;
      _ticker.start();
    } else if (!active && _ticker.isActive) {
      _ticker.stop();
      _last = null;
    }
  }

  void _runtimeChanged() {
    if (mounted) setState(_sync);
  }

  void _tick(Duration elapsed) {
    final dt = _last == null
        ? 0.0
        : ((elapsed - _last!).inMicroseconds / 1e6).clamp(0.0, .05);
    _last = elapsed;
    _motion.advance(dt);
    _frame.value += dt;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => setState(_sync);

  @override
  void dispose() {
    _runtime?.removeListener(_runtimeChanged);
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _art.dispose();
    _fogArt.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final size = bounds.biggest;
      final overview = widget.overview;
      final image = widget.cameraImage ?? overview.imageRect(size);
      final scale = image.width / overview.sourceSize.width;
      return ClipRect(
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) {
            if (!_ticker.isActive) return;
            final point = (event.localPosition - image.topLeft) / scale;
            _motion.tapAt(point, canopyPosition: point, scale: scale);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fromRect(
                rect: image,
                child: RepaintBoundary(
                  child: Image.asset(
                    overview.asset,
                    fit: BoxFit.fill,
                    excludeFromSemantics: true,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: OverviewWaterPainter(
                        overview: overview,
                        image: image,
                        frame: _frame,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _frame,
                      builder: (context, _) => Stack(
                        fit: StackFit.expand,
                        children: [
                          for (final depth in MapLeafDepth.values)
                            CustomPaint(
                              painter: MapAmbientPainter(
                                motion: _motion,
                                art: _art,
                                depth: depth,
                                origin: image.topLeft,
                                scale: scale,
                                protectedRects: widget.protectedRects,
                                time: seconds,
                              ),
                            ),
                          for (var i = 0; i < 2; i++)
                            Positioned(
                              left:
                                  (i == 0 ? -.16 : .73) * size.width +
                                  math.sin(seconds * .07 + i * 2) * 24,
                              top:
                                  (i == 0 ? .04 : .87) * size.height +
                                  math.cos(seconds * .05 + i) * 8,
                              width: size.width * .48,
                              height: size.width * .13,
                              child: Opacity(
                                opacity: .42,
                                child: Image.asset(
                                  'assets/images/world-selection/cloud.png',
                                  fit: BoxFit.contain,
                                  excludeFromSemantics: true,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              TickerMode(
                enabled: _ticker.isActive,
                child: WorldOverviewFog(
                  key: const ValueKey('world-overview-fog'),
                  overview: overview,
                  image: image,
                  lockedWorlds: widget.lockedWorlds,
                  frame: _frame,
                  art: _fogArt,
                  discovery: widget.discovery,
                ),
              ),
              TickerMode(enabled: _ticker.isActive, child: widget.child),
            ],
          ),
        ),
      );
    },
  );
}

/// Highlights remain registered to small patches of actual water, never grass.
class OverviewWaterPainter extends CustomPainter {
  OverviewWaterPainter({
    required this.overview,
    required this.image,
    required this.frame,
  }) : super(repaint: frame);
  final WorldOverview overview;
  final Rect image;
  final ValueListenable<double> frame;

  @override
  void paint(Canvas canvas, Size size) {
    final t = frame.value;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < overview.water.length; i++) {
      final pond = overview.water[i];
      final rect = Rect.fromLTWH(
        image.left + pond.left * image.width,
        image.top + pond.top * image.height,
        pond.width * image.width,
        pond.height * image.height,
      );
      canvas.save();
      canvas.clipPath(Path()..addOval(rect));
      for (var n = 0; n < 5; n++) {
        final phase = (t * .14 + n * .2 + i * .17) % 1;
        final center = Offset(
          rect.left + rect.width * ((n * .31 + i * .13) % 1),
          rect.top + rect.height * phase,
        );
        line
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(
            alpha: math.sin(phase * math.pi) * .48,
          );
        canvas.drawArc(
          Rect.fromCenter(
            center: center,
            width: rect.width * .30,
            height: rect.height * .32,
          ),
          .2,
          2.7,
          false,
          line,
        );
      }
      canvas.restore();
    }
    for (final (start, end) in overview.waterfalls) {
      final a = overview.project(start, image);
      final b = overview.project(end, image);
      for (var n = 0; n < 4; n++) {
        final phase = (t * .5 + n * .25) % 1;
        final shift = Offset((n - 1.5) * 2, 0);
        line
          ..strokeWidth = 1.8
          ..color = const Color(0xFFE3FFFF)
              .withValues(alpha: math.sin(phase * math.pi) * .55);
        canvas.drawLine(
          Offset.lerp(a, b, phase)! + shift,
          Offset.lerp(a, b, math.min(1, phase + .16))! + shift,
          line,
        );
      }
    }
  }

  @override
  bool shouldRepaint(OverviewWaterPainter oldDelegate) =>
      oldDelegate.overview.landscape != overview.landscape ||
      oldDelegate.image != image;
}
