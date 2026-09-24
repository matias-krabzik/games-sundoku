import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../data/level_node.dart';
import '../models/map_ambient_motion.dart';
import 'map_ambient_painter.dart';

const _sourceSize = Size(2172, 724);
// Margins match layer_geometry.py and the foreground outpaint exporter.
const _layers = [
  (name: 'sky', horizontalPadding: 512.0, verticalPadding: 128.0),
  (name: 'clouds', horizontalPadding: 512.0, verticalPadding: 128.0),
  (name: 'mountains', horizontalPadding: 512.0, verticalPadding: 128.0),
  (name: 'distance', horizontalPadding: 512.0, verticalPadding: 48.0),
  (name: 'terrain', horizontalPadding: 128.0, verticalPadding: 128.0),
  (name: 'foreground', horizontalPadding: 128.0, verticalPadding: 80.0),
];

/// Separate sky, clouds, mountains, hills, terrain and foreground layers.
/// The interactive world and its lights share the approved terrain transform.
class MapParallaxScene extends StatefulWidget {
  const MapParallaxScene({
    super.key,
    required this.scroll,
    required this.worldSize,
    required this.child,
    this.protectedWorldRects = const [],
  });

  final ScrollController scroll;
  final Size worldSize;
  final Widget child;
  final List<Rect> protectedWorldRects;

  @override
  State<MapParallaxScene> createState() => _MapParallaxSceneState();
}

class _MapParallaxSceneState extends State<MapParallaxScene>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<double> _frame = ValueNotifier(0);
  final MapAmbientMotion _ambient = MapAmbientMotion();
  final MapAmbientArt _ambientArt = MapAmbientArt();
  StreamSubscription<AccelerometerEvent>? _sensor;
  Offset? _neutral;
  Offset _filtered = Offset.zero;
  Offset _target = Offset.zero;
  Offset _tilt = Offset.zero;
  Duration? _lastFrame;
  Orientation? _orientation;
  bool _visible = false;
  bool _reduceMotion = false;
  bool _failedSensor = false;
  double _seconds = 0;

  bool get _mobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  bool get _active {
    final state = WidgetsBinding.instance.lifecycleState;
    return _visible &&
        !_reduceMotion &&
        (state == null ||
            state == AppLifecycleState.resumed ||
            (!_mobile && state == AppLifecycleState.inactive));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_ambientArt.load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.orientationOf(context);
    if (orientation != _orientation) {
      _orientation = orientation;
      _neutral = null;
      _target = _tilt = Offset.zero;
    }
    _visible =
        TickerMode.valuesOf(context).enabled &&
        ModalRoute.of(context)?.isCurrent != false;
    _reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    _syncMotion();
  }

  void _syncMotion() {
    if (!_active) {
      _ticker.stop();
      _lastFrame = null;
      _neutral = null;
      if (_reduceMotion) _tilt = Offset.zero;
      _target = _tilt;
      unawaited(_sensor?.cancel());
      _sensor = null;
      return;
    }
    _wakeMotion();
    if (_mobile && !_failedSensor && _sensor == null) {
      _sensor =
          accelerometerEventStream(
            samplingPeriod: const Duration(milliseconds: 50),
          ).listen(
            _onSensor,
            onError: (Object _) {
              _failedSensor = true;
              _sensor = null;
              _target = Offset.zero;
              _wakeMotion();
            },
            cancelOnError: true,
          );
    }
  }

  void _onSensor(AccelerometerEvent event) {
    if (!_active) return;
    var reading = Offset(event.x, event.y);
    if (_neutral == null) {
      _neutral = reading;
      _filtered = reading;
    }
    _filtered = Offset.lerp(_filtered, reading, .16)!;
    reading = _filtered - _neutral!;
    if (_orientation == Orientation.landscape) {
      final direction = _neutral!.dx < 0 ? -1.0 : 1.0;
      reading = Offset(reading.dy * direction, -reading.dx * direction);
    }
    _target = Offset(
      (-reading.dx / 3).clamp(-1.0, 1.0),
      (reading.dy / 3).clamp(-1.0, 1.0),
    );
    _wakeMotion();
  }

  void _wakeMotion() {
    if (!_active || _ticker.isActive) {
      return;
    }
    _lastFrame = null;
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    final dt = _lastFrame == null
        ? 0.0
        : ((elapsed - _lastFrame!).inMicroseconds / 1000000).clamp(0.0, .05);
    _lastFrame = elapsed;
    _seconds += dt;
    _ambient.advance(dt);
    _tilt = Offset.lerp(_tilt, _target, 1 - math.exp(-dt * 7))!;
    if ((_target - _tilt).distance < .001) {
      _tilt = _target;
    }
    // Clouds keep drifting after the tilt has settled. Visibility,
    // lifecycle and reduced-motion changes stop this ticker in _syncMotion.
    _frame.value = _seconds;
  }

  void _pointer(Offset point, Size size) {
    if (!_active || _mobile || size.isEmpty) return;
    _target = Offset(
      -(point.dx / size.width * 2 - 1).clamp(-1.0, 1.0),
      -(point.dy / size.height * 2 - 1).clamp(-1.0, 1.0),
    );
    _wakeMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(_syncMotion);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_sensor?.cancel());
    _ticker.dispose();
    _frame.dispose();
    _ambientArt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final viewport = constraints.biggest;
      final world = widget.worldSize;
      final scale = world.width / _sourceSize.width;
      // Images and the interactive subtree are retained between motion frames.
      Widget art(String name) => RepaintBoundary(
        child: Image.asset(
          'assets/images/map/layers/$name.png',
          fit: BoxFit.fill,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
        ),
      );
      final layers = [for (final layer in _layers) art(layer.name)];
      return MouseRegion(
        onEnter: (e) => _pointer(e.localPosition, viewport),
        onHover: (e) => _pointer(e.localPosition, viewport),
        onExit: (_) {
          _target = Offset.zero;
          _wakeMotion();
        },
        child: ClipRect(
          child: AnimatedBuilder(
            animation: Listenable.merge([widget.scroll, _frame]),
            child: widget.child,
            builder: (context, child) {
              final maxScroll = math.max(0.0, world.width - viewport.width);
              // New layout dimensions arrive before the scroll position is
              // clamped. Keep artwork aligned during rotation/resizing too.
              final scroll =
                  (widget.scroll.hasClients ? widget.scroll.offset : 0.0).clamp(
                    0.0,
                    maxScroll,
                  );
              final enabled = !_reduceMotion;
              final tilt = enabled ? _tilt * math.min(1.0, scale) : Offset.zero;
              // Relative horizontal speeds, centered to share overscan at both
              // ends. Far layers travel slower; foreground travels faster.
              final depthScroll = scroll - maxScroll / 2;
              final camera = enabled
                  ? mapPathCameraOffset(scroll, viewport, world)
                  : 0.0;
              final terrain = Offset(tilt.dx * 5, camera + tilt.dy * 3.5);
              final top = (viewport.height - world.height) / 2;
              final foregroundDelta = enabled
                  ? Offset(-depthScroll * .08 + tilt.dx * 14, tilt.dy * 10)
                  : Offset.zero;
              final terrainOrigin = Offset(-scroll, top) + terrain;
              final foregroundOrigin = terrainOrigin + foregroundDelta;
              final protectedRects = [
                for (final rect in widget.protectedWorldRects)
                  rect.shift(terrainOrigin),
              ];
              if (enabled && scale > 0) {
                _ambient.setView(
                  Rect.fromLTWH(
                    -foregroundOrigin.dx / scale,
                    -foregroundOrigin.dy / scale,
                    viewport.width / scale,
                    viewport.height / scale,
                  ),
                );
              }
              Widget atmosphere(MapLeafDepth depth) => Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: MapAmbientPainter(
                        motion: _ambient,
                        art: _ambientArt,
                        depth: depth,
                        origin: depth == MapLeafDepth.foreground
                            ? foregroundOrigin
                            : terrainOrigin,
                        scale: scale,
                        protectedRects: protectedRects,
                        time: _seconds,
                      ),
                    ),
                  ),
                ),
              );
              Widget plane(int index, Offset delta) {
                final horizontalPadding =
                    _layers[index].horizontalPadding * scale;
                final verticalPadding = _layers[index].verticalPadding * scale;
                return Positioned(
                  left: -scroll - horizontalPadding + terrain.dx + delta.dx,
                  top: top - verticalPadding + terrain.dy + delta.dy,
                  width: world.width + horizontalPadding * 2,
                  height: world.height + verticalPadding * 2,
                  child: IgnorePointer(child: layers[index]),
                );
              }

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                excludeFromSemantics: true,
                onTapUp: !enabled
                    ? null
                    : (details) {
                        if (!_active || scale <= 0) return;
                        final position =
                            (details.localPosition - foregroundOrigin) / scale;
                        if (_ambientArt.bee != null &&
                            _ambient.startleBeeAt(position, scale: scale)) {
                          return;
                        }
                        _ambient.puff(
                          position,
                          canopyPosition:
                              (details.localPosition - terrainOrigin) / scale,
                        );
                      },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    plane(
                      0,
                      enabled
                          ? Offset(
                              depthScroll * .45 - tilt.dx * 8,
                              -camera * .30 - tilt.dy * 4,
                            )
                          : Offset.zero,
                    ),
                    plane(
                      1,
                      enabled
                          ? Offset(
                              depthScroll * .40 -
                                  tilt.dx * 7 +
                                  math.sin(_seconds * .20) * 40 * scale,
                              -camera * .25 -
                                  tilt.dy * 4 +
                                  math.sin(_seconds * .16) * 2 * scale,
                            )
                          : Offset.zero,
                    ),
                    plane(
                      2,
                      enabled
                          ? Offset(
                              depthScroll * .35 - tilt.dx * 5,
                              -camera * .18 - tilt.dy * 3,
                            )
                          : Offset.zero,
                    ),
                    plane(
                      3,
                      enabled
                          ? Offset(
                              depthScroll * .18 - tilt.dx * 3,
                              -camera * .08 - tilt.dy * 2,
                            )
                          : Offset.zero,
                    ),
                    if (enabled) atmosphere(MapLeafDepth.behindTrees),
                    plane(4, Offset.zero),
                    if (enabled) atmosphere(MapLeafDepth.air),
                    Transform.translate(
                      key: const ValueKey('map-terrain-transform'),
                      offset: terrain,
                      child: child,
                    ),
                    plane(5, foregroundDelta),
                    if (enabled) atmosphere(MapLeafDepth.foreground),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

/// A bounded, smooth vertical follow of the painted path under the viewport.
/// The vertical overscan covers this camera follow and tilt at both ends.
double mapPathCameraOffset(double scroll, Size viewport, Size world) {
  final x = ((scroll + viewport.width / 2) / world.width).clamp(0.0, 1.0);
  var y = kMap1Nodes.last.y;
  if (x <= kMap1Nodes.first.x) y = kMap1Nodes.first.y;
  for (var i = 1; i < kMap1Nodes.length; i++) {
    final a = kMap1Nodes[i - 1];
    final b = kMap1Nodes[i];
    if (x >= a.x && x <= b.x) {
      final t = (x - a.x) / (b.x - a.x);
      final smooth = t * t * (3 - 2 * t);
      y = a.y + (b.y - a.y) * smooth;
      break;
    }
  }
  return ((.61 - y) * world.height * .35).clamp(
    -world.height * .025,
    world.height * .025,
  );
}
