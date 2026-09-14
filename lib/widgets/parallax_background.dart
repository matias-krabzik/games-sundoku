import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Moves only the scenery, using device motion on mobile and hover elsewhere.
class ParallaxBackground extends StatefulWidget {
  const ParallaxBackground({
    super.key,
    required this.child,
    this.backgroundAsset = 'assets/images/home-background.png',
    this.maxX = 22.0,
    this.maxY = 16.0,
    this.backgroundFit = BoxFit.cover,
    this.backgroundAlignment,
    this.mobileSensorEnabled = true,
    this.scaleBase = 1.1,
  });

  final Widget child;
  final String backgroundAsset;
  final double maxX;
  final double maxY;
  final BoxFit backgroundFit;
  final Alignment? backgroundAlignment;
  final bool mobileSensorEnabled;
  final double scaleBase;

  @override
  State<ParallaxBackground> createState() => _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends State<ParallaxBackground>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  double get _maxX => widget.maxX;
  double get _maxY => widget.maxY;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  late final Ticker _motionTicker;
  Duration? _lastFrame;
  DateTime? _lastSensorEvent;
  Offset _sensorInput = Offset.zero;
  Offset _pointerTarget = Offset.zero;
  Offset _position = Offset.zero;
  Offset _velocity = Offset.zero;
  bool _visible = true;
  bool _sensorFailed = false;

  bool get _mobile => switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    _ => false,
  };
  bool get _enabled {
    final state = WidgetsBinding.instance.lifecycleState;
    // Desktop windows still receive hover while visible without input focus.
    final acceptsInput =
        state == null ||
        state == AppLifecycleState.resumed ||
        (!_mobile && state == AppLifecycleState.inactive);
    return _visible && acceptsInput;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _motionTicker = createTicker(_advanceMotion);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible =
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context);
    _syncInput();
  }

  void _syncInput() {
    if (!_enabled || !_mobile || !widget.mobileSensorEnabled) {
      unawaited(_gyroscopeSubscription?.cancel());
      _gyroscopeSubscription = null;
      _sensorInput = Offset.zero;
      _lastSensorEvent = null;
    } else if (!_sensorFailed && _gyroscopeSubscription == null) {
      _gyroscopeSubscription =
          gyroscopeEventStream(samplingPeriod: SensorInterval.gameInterval)
              .listen(
                _handleGyroscope,
                onError: (Object _) {
                  _sensorFailed = true;
                  _gyroscopeSubscription = null;
                  _sensorInput = Offset.zero;
                },
                cancelOnError: true,
              );
    }
    if (!_enabled) {
      _motionTicker.stop();
      _lastFrame = null;
      _pointerTarget = Offset.zero;
      _position = Offset.zero;
      _velocity = Offset.zero;
    }
  }

  void _handleGyroscope(GyroscopeEvent event) {
    if (!mounted || !_enabled || !_mobile) return;
    final raw = Offset(
      (-event.y).clamp(-2.5, 2.5),
      (-event.x).clamp(-2.5, 2.5),
    );
    final reading = raw.distance < .025 ? Offset.zero : raw;
    _sensorInput = Offset.lerp(_sensorInput, reading, .35)!;
    if (_sensorInput.distance < .01) _sensorInput = Offset.zero;
    _lastSensorEvent = DateTime.now();
    _startMotion();
  }

  void _handlePointer(Offset localPosition, Size size) {
    if (!_enabled || _mobile || size.isEmpty) return;
    _pointerTarget = Offset(
      -(localPosition.dx / size.width * 2 - 1).clamp(-1.0, 1.0) * _maxX,
      -(localPosition.dy / size.height * 2 - 1).clamp(-1.0, 1.0) * _maxY,
    );
    _startMotion();
  }

  void _clearPointer() {
    if (!_enabled || _mobile) return;
    _pointerTarget = Offset.zero;
    _startMotion();
  }

  void _startMotion() {
    if (_motionTicker.isActive) return;
    if (_sensorInput == Offset.zero &&
        (_pointerTarget - _position).distance < .12 &&
        _velocity.distance < .12) {
      return;
    }
    _lastFrame = null;
    _motionTicker.start();
  }

  void _advanceMotion(Duration elapsed) {
    final previousFrame = _lastFrame;
    _lastFrame = elapsed;
    if (previousFrame == null) return;
    final dt = ((elapsed - previousFrame).inMicroseconds / 1000000).clamp(
      1 / 240,
      1 / 30,
    );
    if (_lastSensorEvent == null ||
        DateTime.now().difference(_lastSensorEvent!) >
            const Duration(milliseconds: 120)) {
      _sensorInput = Offset.zero;
    }
    // Preserve the mobile spring; hover follows a stable position more closely.
    final target = _mobile ? Offset.zero : _pointerTarget;
    final acceleration = _mobile
        ? _sensorInput * 280 - _position * 12 - _velocity * 5.5
        : (target - _position) * 90 - _velocity * 19;
    _velocity += acceleration * dt;
    final next = _position + _velocity * dt;
    final clamped = Offset(
      next.dx.clamp(-_maxX, _maxX),
      next.dy.clamp(-_maxY, _maxY),
    );
    if (next.dx != clamped.dx) {
      _velocity = Offset(-_velocity.dx * .18, _velocity.dy);
    }
    if (next.dy != clamped.dy) {
      _velocity = Offset(_velocity.dx, -_velocity.dy * .18);
    }
    final settled =
        _sensorInput.distance < .01 &&
        _velocity.distance < .12 &&
        (target - clamped).distance < .12;
    setState(() {
      _position = settled ? target : clamped;
      if (settled) {
        _velocity = Offset.zero;
        _motionTicker.stop();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(_syncInput);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_gyroscopeSubscription?.cancel());
    _motionTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final size = bounds.biggest;
      final scale = math.max(
        widget.scaleBase,
        1.0 +
            2 *
                math.max(
                  _maxX / math.max(1, size.width),
                  _maxY / math.max(1, size.height),
                ),
      );
      final alignment = widget.backgroundAlignment ??
          (size.aspectRatio > 1.2
              ? const Alignment(0, .5)
              : Alignment.topCenter);
      // An ancestor region receives hover even over buttons, without taking taps.
      return MouseRegion(
        onEnter: (event) => _handlePointer(event.localPosition, size),
        onHover: (event) => _handlePointer(event.localPosition, size),
        onExit: (_) => _clearPointer(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: Transform.translate(
                key: const ValueKey('parallax-offset'),
                offset: _position,
                child: Transform.scale(
                  scale: scale,
                  child: Image.asset(
                    widget.backgroundAsset,
                    fit: widget.backgroundFit,
                    alignment: alignment,
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        ),
      );
    },
  );
}
