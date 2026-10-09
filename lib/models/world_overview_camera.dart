import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import '../data/world_overview.dart';

/// One timeline keeps camera travel, rising fog and destination arrival ordered.
abstract final class OverviewDiscovery {
  static const seconds = 1.6;
  static double lift(double progress) =>
      const Interval(.18, .72, curve: Curves.easeInCubic).transform(progress);
  static double arrival(double progress) =>
      const Interval(.72, 1).transform(progress);
}

/// Camera coordinates are normalized to the painting, independent of pixels.
class WorldOverviewCamera extends ChangeNotifier {
  WorldOverviewCamera({
    required Set<String> revealedWorlds,
    required String initialWorld,
  }) : _unlocked = {...revealedWorlds},
       _progress = {for (final id in revealedWorlds) id: 1},
       _focusedWorld = initialWorld;

  Set<String> _unlocked;
  final Map<String, double> _progress;
  String _focusedWorld;
  String? _pendingFocus;
  Size _viewport = Size.zero;
  Rect _usable = Rect.zero;
  double _anchorOffset = 40;
  WorldOverview _overview = const WorldOverview(false);
  Offset _center = const Offset(.377, .74);
  double _zoom = 1.8;
  bool reducedMotion = false;
  Offset? _from;
  Offset? _to;
  double? _fromZoom;
  double? _toZoom;
  double _travel = 0;
  Offset _velocity = Offset.zero;
  double _gestureZoom = 1;
  Offset _gesturePoint = Offset.zero;
  Offset _gestureFocal = Offset.zero;
  bool _gesturing = false;
  String? _entryWorld;

  Rect get image => _imageAt(_center, _zoom);
  Offset get center => _center;
  double get zoom => _zoom;
  String get focusedWorld => _focusedWorld;

  /// Selection survives background taps and free exploration of the map.
  String? get entryWorld => _entryWorld;
  String? get centeredWorld {
    if (_viewport.isEmpty ||
        _gesturing ||
        _to != null ||
        _velocity.distance > 8 ||
        _progress[_focusedWorld] != 1) {
      return null;
    }
    final delta = _center - _focusCenter(_focusedWorld);
    return Offset(delta.dx * image.width, delta.dy * image.height).distance <= 1
        ? _focusedWorld
        : null;
  }

  double get minZoom => _overview.landscape ? 1.8 : 1.6;
  static const maxZoom = 4.0;
  static const _friction = 7.0;
  Map<String, double> get discovery => Map.unmodifiable(_progress);
  Set<String> get revealedWorlds => {
    for (final entry in _progress.entries)
      if (entry.value == 1 && _unlocked.contains(entry.key)) entry.key,
  };
  bool get animating =>
      _to != null ||
      _velocity.distance > 8 ||
      _progress.values.any((value) => value < 1);

  Rect _imageAt(Offset center, double zoom) {
    final base = _overview.imageRect(_viewport).size;
    final size = Size(base.width * zoom, base.height * zoom);
    return Rect.fromLTWH(
      _viewport.width / 2 - center.dx * size.width,
      _viewport.height / 2 - center.dy * size.height,
      size.width,
      size.height,
    );
  }

  void configure(
    Size viewport,
    Rect usable,
    WorldOverview overview, {
    double anchorOffset = 40,
  }) {
    if (_viewport == viewport &&
        _usable == usable &&
        _anchorOffset == anchorOffset &&
        _overview.landscape == overview.landscape) {
      _rememberCentered();
      return;
    }
    final initial = _viewport.isEmpty;
    final wasCentered = centeredWorld != null;
    final rotated = _overview.landscape != overview.landscape;
    _viewport = viewport;
    _usable = usable;
    _anchorOffset = anchorOffset;
    _overview = overview;
    if (initial || rotated || wasCentered) {
      if (initial || rotated) _zoom = overview.landscape ? 2.1 : 1.8;
      _zoom = math.max(_zoom, _minimumFocusZoom(_focusedWorld));
      _center = _focusCenter(_focusedWorld);
      _cancelTravel();
    } else {
      _center = _clamp(_center);
      if (_to != null) {
        _from = _center;
        _fromZoom = _zoom;
        _toZoom = math.max(_zoom, _minimumFocusZoom(_focusedWorld));
        _to = _focusCenter(_focusedWorld, zoom: _toZoom);
        _travel = 0;
      }
    }
    if (_pendingFocus case final id?) {
      _pendingFocus = null;
      focusWorld(id, notify: false);
    }
    _rememberCentered();
  }

  /// These limits allow a glimpse of fog at the frontier, but the camera
  /// cannot be dragged into an undiscovered destination.
  Offset _clamp(Offset value, {double? zoom}) {
    if (_viewport.isEmpty) return value;
    final size = _overview.imageRect(_viewport).size * (zoom ?? _zoom);
    final halfX = _viewport.width / size.width / 2;
    final halfY = _viewport.height / size.height / 2;
    final frontier = !_unlocked.contains('world-2')
        ? (_overview.landscape ? .32 : .61)
        : !_unlocked.contains('world-3')
        ? (_overview.landscape ? .65 : .30)
        : (_overview.landscape ? 1.0 : 0.0);
    return Offset(
      value.dx.clamp(
        halfX,
        _overview.landscape
            ? math.max(halfX, math.min(1 - halfX, frontier))
            : 1 - halfX,
      ),
      value.dy.clamp(
        _overview.landscape
            ? halfY
            : math.min(1 - halfY, math.max(halfY, frontier)),
        1 - halfY,
      ),
    );
  }

  Offset _focusCenter(String id, {double? zoom}) {
    final index = int.parse(id.substring('world-'.length)) - 1;
    final anchor = _overview.destinations[index];
    final size = _overview.imageRect(_viewport).size * (zoom ?? _zoom);
    // Center the medallion and the card as a group below the fixed header.
    final target = _usable.center - Offset(0, _anchorOffset);
    return _clamp(
      anchor +
          Offset(
            (_viewport.width / 2 - target.dx) / size.width,
            (_viewport.height / 2 - target.dy) / size.height,
          ),
      zoom: zoom,
    );
  }

  double _minimumFocusZoom(String id) {
    final index = int.parse(id.substring('world-'.length)) - 1;
    final anchor = _overview.destinations[index];
    final base = _overview.imageRect(_viewport).size;
    final target = _usable.center - Offset(0, _anchorOffset);
    // Make enough room around the actual point to center the entire group
    // without exposing empty canvas at any edge of the painting.
    return [
      minZoom,
      target.dx / (anchor.dx * base.width),
      (_viewport.width - target.dx) / ((1 - anchor.dx) * base.width),
      target.dy / (anchor.dy * base.height),
      (_viewport.height - target.dy) / ((1 - anchor.dy) * base.height),
    ].reduce(math.max).clamp(minZoom, maxZoom);
  }

  void _cancelTravel() {
    _from = _to = null;
    _fromZoom = _toZoom = null;
  }

  void _rememberCentered() {
    if (centeredWorld case final id?) _entryWorld = id;
  }

  void discover(Set<String> unlocked) {
    final newly = unlocked.difference(_unlocked).toList()..sort();
    _unlocked = {...unlocked};
    _progress.removeWhere((id, _) => !unlocked.contains(id));
    if (!unlocked.contains(_entryWorld)) _entryWorld = null;
    for (final id in newly) {
      _progress[id] = reducedMotion ? 1 : 0;
    }
    if (newly.isNotEmpty) {
      focusWorld(newly.last, notify: false);
    } else {
      _center = _clamp(_center);
    }
    notifyListeners();
  }

  void focusWorld(String id, {bool animate = true, bool notify = true}) {
    if (!_unlocked.contains(id)) return;
    if (_viewport.isEmpty) {
      _pendingFocus = id;
      return;
    }
    if (_focusedWorld != id || _progress[id] != 1) _entryWorld = null;
    _focusedWorld = id;
    _gesturing = false;
    final targetZoom = math.max(_zoom, _minimumFocusZoom(id));
    final target = _focusCenter(id, zoom: targetZoom);
    _velocity = Offset.zero;
    if (animate &&
        !reducedMotion &&
        ((_center - target).distance > .00001 ||
            (_zoom - targetZoom).abs() > .00001)) {
      _from = _center;
      _to = target;
      _fromZoom = _zoom;
      _toZoom = targetZoom;
      _travel = 0;
    } else {
      _zoom = targetZoom;
      _center = target;
      _cancelTravel();
      _rememberCentered();
    }
    if (notify) notifyListeners();
  }

  void finishAnimations() {
    for (final id in _progress.keys) {
      _progress[id] = 1;
    }
    if (_to != null) _center = _to!;
    if (_toZoom != null) _zoom = _toZoom!;
    _cancelTravel();
    _velocity = Offset.zero;
    _rememberCentered();
  }

  void advance(double dt) {
    // A ticker's first frame has no elapsed time. It is not a collision with
    // the map boundary and must not discard the release velocity.
    if (!animating || dt <= 0) return;
    if (reducedMotion) {
      finishAnimations();
    } else {
      for (final id in _progress.keys) {
        _progress[id] = math.min(
          1,
          _progress[id]! + dt / OverviewDiscovery.seconds,
        );
      }
      if (_to != null) {
        _travel = math.min(1, _travel + dt / .55);
        final eased = Curves.easeInOutCubic.transform(_travel);
        _zoom = _fromZoom! + (_toZoom! - _fromZoom!) * eased;
        _center = _clamp(Offset.lerp(_from!, _to!, eased)!);
        if (_travel == 1) _cancelTravel();
      } else if (_velocity.distance > 8) {
        final previous = _center;
        final decay = math.exp(-_friction * dt);
        _pan(_velocity * ((1 - decay) / _friction));
        _velocity *= decay;
        if ((_center - previous).distance < .000001) _velocity = Offset.zero;
      }
      _rememberCentered();
    }
    notifyListeners();
  }

  void _pan(Offset delta) {
    final size = image.size;
    _center = _clamp(
      _center - Offset(delta.dx / size.width, delta.dy / size.height),
    );
  }

  void pan(Offset delta) {
    _cancelTravel();
    _velocity = Offset.zero;
    _pan(delta);
    notifyListeners();
  }

  void beginGesture(Offset focal) {
    _gesturing = false;
    stopInertia();
    _gestureZoom = _zoom;
    _gestureFocal = focal;
    final rect = image;
    _gesturePoint = Offset(
      (focal.dx - rect.left) / rect.width,
      (focal.dy - rect.top) / rect.height,
    );
  }

  void updateGesture(Offset focal, double scale) {
    // ScaleRecognizer can report a tap or subpixel finger jitter as a gesture.
    // Neither should disturb the current selection or interrupt centering.
    if (!_gesturing &&
        (focal - _gestureFocal).distance < 3 &&
        (scale - 1).abs() < .005) {
      return;
    }
    _gesturing = true;
    _cancelTravel();
    _zoom = (_gestureZoom * scale).clamp(minZoom, maxZoom);
    final size = _overview.imageRect(_viewport).size * _zoom;
    _center = _clamp(
      _gesturePoint +
          Offset(
            (_viewport.width / 2 - focal.dx) / size.width,
            (_viewport.height / 2 - focal.dy) / size.height,
          ),
    );
    notifyListeners();
  }

  void endGesture(Offset velocity) {
    if (_gesturing && !reducedMotion) {
      _velocity = _limitedVelocity(velocity * .45);
    }
    _gesturing = false;
    notifyListeners();
  }

  Offset _limitedVelocity(Offset velocity) =>
      velocity.distance > 750 ? velocity * (750 / velocity.distance) : velocity;

  void stopInertia() {
    if (_velocity == Offset.zero) return;
    _velocity = Offset.zero;
    notifyListeners();
  }

  /// Wheel scrolling includes a short, bounded tail instead of stopping cold.
  void scroll(Offset delta) {
    if (delta == Offset.zero) return;
    _cancelTravel();
    _pan(delta * (reducedMotion ? 1 : .85));
    _velocity = reducedMotion
        ? Offset.zero
        : _limitedVelocity(_velocity + delta * (.15 * _friction));
    notifyListeners();
  }
}
