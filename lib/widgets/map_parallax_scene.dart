import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../data/valley_map.dart';
import '../models/world_map_definition.dart';
import '../models/map_ambient_motion.dart';
import 'map_ambient_painter.dart';

/// Separate sky, clouds, mountains, hills, terrain and foreground layers.
/// The interactive world and its lights share the approved terrain transform.
class MapParallaxScene extends StatefulWidget {
  const MapParallaxScene({
    super.key,
    required this.scroll,
    required this.worldSize,
    required this.child,
    this.protectedWorldRects = const [],
    this.definition = valleyMap,
    this.worldTop,
    this.focusY,
    this.childBuilder,
  });

  final WorldMapDefinition definition;
  final double? worldTop;
  final double? focusY;
  final Widget Function(double verticalPan)? childBuilder;
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
  MapAmbientMotion? _ambient;
  late MapAmbientArt _ambientArt;
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
  double? _panY;

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
    _configureAmbient();
  }

  void _configureAmbient() {
    widget.definition.validate();
    final config = widget.definition.ambient;
    _ambient = config == null
        ? null
        : MapAmbientMotion(
            flowerAnchors: config.flowers,
            foregroundFlowers: config.foregroundFlowerCount,
            canopyAnchors: config.canopies,
            canopyLeafStyles: config.canopyLeafStyles,
            pinkCanopy: config.pinkCanopy,
            petalAnchors: config.petalAnchors,
            creatures: config.creatures,
            beeCount: config.beeCount,
            treeLeavesOnly: config.treeLeavesOnly,
            sourceSize: widget.definition.sourceSize,
          );
    _ambientArt = MapAmbientArt(
      leafAsset: config?.leafAsset,
      beeAsset: config?.beeAsset,
      leafAssets: config?.leafAssets ?? const [],
      petalAsset: config?.petalAsset,
      creatureAssets: config?.creatureAssets ?? const {},
      creatureWingAssets: config?.creatureWingAssets ?? const {},
    );
    if (config != null) unawaited(_ambientArt.load());
  }

  @override
  void didUpdateWidget(MapParallaxScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusY != widget.focusY ||
        oldWidget.worldSize != widget.worldSize) {
      _panY = null;
    }
    if (oldWidget.definition != widget.definition) {
      _ambientArt.dispose();
      _configureAmbient();
      _neutral = null;
      _target = _tilt = Offset.zero;
      _seconds = 0;
    }
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
    _ambient?.advance(dt);
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
      final definition = widget.definition;
      final viewport = constraints.biggest;
      final world = widget.worldSize;
      final scale = world.width / definition.sourceSize.width;
      final layers = {
        for (final layer in definition.layers)
          layer.id: RepaintBoundary(
            child: Image.asset(
              layer.asset,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
              excludeFromSemantics: true,
            ),
          ),
      };
      final baseTop = widget.worldTop ?? (viewport.height - world.height) / 2;
      final canPan =
          definition.allowVerticalPan && world.height > viewport.height;
      final focus = (widget.focusY ?? .5) * world.height + baseTop;
      final autoPan = focus < 80
          ? 80 - focus
          : focus > viewport.height - 80
          ? viewport.height - 80 - focus
          : 0.0;
      final pan = canPan
          ? (_panY ?? autoPan).clamp(
              viewport.height - world.height - baseTop,
              -baseTop,
            )
          : 0.0;
      return GestureDetector(
        onVerticalDragUpdate: canPan
            ? (details) {
                setState(
                  () => _panY = (pan + details.delta.dy).clamp(
                    viewport.height - world.height - baseTop,
                    -baseTop,
                  ),
                );
              }
            : null,
        child: MouseRegion(
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
                final scroll =
                    (widget.scroll.hasClients ? widget.scroll.offset : 0.0)
                        .clamp(0.0, maxScroll);
                final enabled = !_reduceMotion;
                final tilt = enabled
                    ? _tilt * math.min(1.0, scale)
                    : Offset.zero;
                final camera = enabled
                    ? pathCameraOffset(scroll, viewport, world, definition)
                    : 0.0;
                final terrain = Offset(
                  tilt.dx * definition.terrainTilt.dx,
                  camera + pan + tilt.dy * definition.terrainTilt.dy,
                );
                final top =
                    widget.worldTop ?? (viewport.height - world.height) / 2;
                Offset deltaFor(MapLayerDefinition layer) =>
                    !enabled || layer.plane == MapLayerPlane.terrain
                    ? Offset.zero
                    : layer.motion.offset(
                        centeredScroll: scroll - maxScroll / 2,
                        inclination: tilt,
                        camera: camera,
                        seconds: _seconds,
                        scale: scale,
                      );
                final ambient = _ambient;
                final ambientLayer = definition.layers
                    .where(
                      (layer) =>
                          layer.id == definition.ambient?.foregroundLayerId,
                    )
                    .firstOrNull;
                final terrainOrigin = Offset(-scroll, top) + terrain;
                final foregroundOrigin =
                    terrainOrigin +
                    (ambientLayer == null
                        ? Offset.zero
                        : deltaFor(ambientLayer));
                final protectedRects = [
                  for (final rect in widget.protectedWorldRects)
                    rect.shift(terrainOrigin),
                ];
                if (enabled && scale > 0) {
                  ambient?.setView(
                    Rect.fromLTWH(
                      -foregroundOrigin.dx / scale,
                      -foregroundOrigin.dy / scale,
                      viewport.width / scale,
                      viewport.height / scale,
                    ),
                    terrainOffset: (terrainOrigin - foregroundOrigin) / scale,
                  );
                }
                Widget atmosphere(MapLeafDepth depth) => Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: MapAmbientPainter(
                          motion: ambient!,
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
                Widget plane(MapLayerDefinition layer) {
                  final paddingX = layer.horizontalPadding * scale;
                  final paddingY = layer.verticalPadding * scale;
                  final delta = deltaFor(layer);
                  return Positioned(
                    key: ValueKey('map-layer-${layer.id}'),
                    left: -scroll - paddingX + terrain.dx + delta.dx,
                    top: top - paddingY + terrain.dy + delta.dy,
                    width: world.width + paddingX * 2,
                    height: world.height + paddingY * 2,
                    child: IgnorePointer(child: layers[layer.id]),
                  );
                }

                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  excludeFromSemantics: true,
                  onTapUp: !enabled || ambient == null
                      ? null
                      : (details) {
                          if (!_active || scale <= 0) return;
                          final position =
                              (details.localPosition - foregroundOrigin) /
                              scale;
                          if (_ambientArt.bee != null &&
                              ambient.startleBeeAt(position, scale: scale)) {
                            return;
                          }
                          ambient.puff(
                            position,
                            canopyPosition:
                                (details.localPosition - terrainOrigin) / scale,
                            scale: scale,
                          );
                        },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      for (final layer in definition.layers)
                        if (layer.plane == MapLayerPlane.background)
                          plane(layer),
                      if (enabled && ambient != null)
                        atmosphere(MapLeafDepth.behindTrees),
                      for (final layer in definition.layers)
                        if (layer.plane == MapLayerPlane.terrain) plane(layer),
                      if (enabled && ambient != null)
                        atmosphere(MapLeafDepth.air),
                      Transform.translate(
                        key: const ValueKey('map-terrain-transform'),
                        offset:
                            terrain -
                            Offset(0, widget.childBuilder == null ? 0 : pan),
                        child: widget.childBuilder?.call(pan) ?? child,
                      ),
                      for (final layer in definition.layers)
                        if (layer.plane == MapLayerPlane.foreground)
                          plane(layer),
                      if (enabled && ambient != null)
                        atmosphere(MapLeafDepth.foreground),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

/// Default valley camera retained for callers that preview it independently.
double mapPathCameraOffset(
  double scroll,
  Size viewport,
  Size world, {
  WorldMapDefinition definition = valleyMap,
}) => pathCameraOffset(scroll, viewport, world, definition);
