import 'dart:math' as math;
import 'dart:ui';

import 'map_radial_puff.dart';

/// Shared leaf-like touch physics for bees, flying insects and fish.
/// Species resume their own routes afterwards; fish constrain motion to water.
abstract class MapAnimalMotion {
  MapAnimalMotion(this.position);

  static const touchDiameter = 48.0;
  static const growthDuration = .22;
  static const peakScale = 1.85;
  static const _directStrength = 1.35;

  Offset position;
  Offset impulse = Offset.zero;
  double facing = 1;
  _AnimalTouch? _touch;
  Rect _bounds = Rect.zero;
  double get restingScale => 1;
  bool get startled => _touch != null;
  bool get directlyTouched => _touch?.direct ?? false;
  double get visualScale => _touch?.scale ?? restingScale;

  void cancelEscape() {
    _touch = null;
    impulse = Offset.zero;
  }

  void flee({
    required Offset touch,
    required Rect bounds,
    required math.Random random,
    required bool direct,
  }) {
    if (bounds.isEmpty) return;
    _bounds = bounds;
    final direction = direct
        ? Offset.fromDirection(random.nextDouble() * math.pi * 2)
        : null;
    if (direction != null) {
      // A direct press chooses a fresh heading and a slightly stronger impulse.
      impulse =
          MapRadialPuff.impulseAt(position, position, fallback: direction) *
          _directStrength;
    } else {
      // Nearby taps keep the exact accumulating radial response of leaves.
      impulse += MapRadialPuff.impulseAt(
        position,
        touch,
        fallback: (position - touch).distance < 1
            ? Offset.fromDirection(random.nextDouble() * math.pi * 2)
            : const Offset(0, -1),
      );
    }
    _touch = _AnimalTouch(
      direct: direct,
      origin: position,
      direction: direction,
      startScale: visualScale,
      endScale: restingScale,
    );
  }

  Offset constrainMovement(Offset displacement, Rect bounds) =>
      _bounded(position + displacement, bounds);

  /// Integrates the same impulse and live gust used by the leaves this frame.
  bool advanceEscape(double dt, {Offset gust = Offset.zero}) {
    final touch = _touch;
    if (touch == null) return false;
    touch.elapsed += dt;
    final previous = position;
    // The direct-touch gust follows its random heading, so the click's radial
    // field cannot pull the animal back toward a fixed direction.
    final direction = touch.direction;
    final wind = direction == null
        ? gust
        : direction *
              MapRadialPuff.gustAt(
                position,
                touch.origin,
                touch.elapsed,
              ).distance *
              _directStrength;
    position = constrainMovement((impulse + wind) * dt, _bounds);
    impulse = MapRadialPuff.decay(impulse, dt);
    final heading = position.dx - previous.dx;
    if (heading.abs() > .001) facing = heading.sign;
    if (touch.elapsed >= MapRadialPuff.duration &&
        impulse.distance < .5 &&
        wind.distance < .5) {
      cancelEscape();
    }
    return true;
  }
}

class _AnimalTouch {
  _AnimalTouch({
    required this.direct,
    required this.origin,
    required this.direction,
    required this.startScale,
    required this.endScale,
  });
  final bool direct;
  final Offset origin;
  final Offset? direction;
  final double startScale;
  final double endScale;
  double elapsed = 0;

  double get scale {
    if (direct && elapsed < MapAnimalMotion.growthDuration) {
      final growth =
          1 -
          math.pow(1 - elapsed / MapAnimalMotion.growthDuration, 3).toDouble();
      return startScale + (MapAnimalMotion.peakScale - startScale) * growth;
    }
    final t = ((elapsed - (direct ? MapAnimalMotion.growthDuration : 0)) / .9)
        .clamp(0.0, 1.0);
    final shrink = 1 - math.pow(1 - t, 3).toDouble();
    final start = direct ? MapAnimalMotion.peakScale : startScale;
    return start + (endScale - start) * shrink;
  }
}

/// A bounded, rounded route sampled by distance, so bank turns stay continuous.
class AnimalEscapePath {
  AnimalEscapePath(List<Offset> waypoints) {
    final points = <Offset>[];
    for (final point in waypoints) {
      if (points.isEmpty || (point - points.last).distance > .0001) {
        points.add(point);
      }
    }
    _points.add(points.first);
    for (var i = 1; i < points.length - 1; i++) {
      final corner = points[i];
      final incoming = corner - points[i - 1];
      final outgoing = points[i + 1] - corner;
      final radius = math.min(
        12.0,
        math.min(incoming.distance, outgoing.distance) * .3,
      );
      final before = corner - incoming / incoming.distance * radius;
      final after = corner + outgoing / outgoing.distance * radius;
      _points.add(before);
      for (var part = 1; part <= 8; part++) {
        final t = part / 8;
        _points.add(
          before * ((1 - t) * (1 - t)) +
              corner * (2 * (1 - t) * t) +
              after * (t * t),
        );
      }
    }
    _points.add(points.last);
    for (var i = 1; i < _points.length; i++) {
      _lengths.add(_lengths.last + (_points[i] - _points[i - 1]).distance);
    }
  }
  final _points = <Offset>[];
  final _lengths = <double>[0];
  Offset get end => _points.last;
  double get length => _lengths.last;

  Offset at(double progress) {
    final distance = progress * _lengths.last;
    for (var i = 1; i < _points.length; i++) {
      final length = _lengths[i] - _lengths[i - 1];
      if (length > .0001 && distance <= _lengths[i]) {
        return Offset.lerp(
          _points[i - 1],
          _points[i],
          ((distance - _lengths[i - 1]) / length).clamp(0.0, 1.0),
        )!;
      }
    }
    return end;
  }

  static AnimalEscapePath alongBank(
    Offset origin,
    Offset direction,
    double distance,
    Rect water,
    math.Random random,
  ) {
    final start = _bounded(origin, water);
    final horizontal = direction.dx.abs() < .0001
        ? double.infinity
        : ((direction.dx > 0 ? water.right : water.left) - start.dx) /
              direction.dx;
    final vertical = direction.dy.abs() < .0001
        ? double.infinity
        : ((direction.dy > 0 ? water.bottom : water.top) - start.dy) /
              direction.dy;
    final room = math.max(0.0, math.min(horizontal, vertical));
    // Small pools shorten the route instead of making the fish circle a pool.
    var remaining = math.min(distance, (water.width + water.height) * .8);
    if (remaining <= room) {
      return AnimalEscapePath([start, start + direction * remaining]);
    }
    var contact = _bounded(start + direction * room, water);
    final points = [start, contact];
    remaining -= room;
    // Corners and sides are ordered clockwise: top, right, bottom, left.
    var edge = horizontal < vertical
        ? (direction.dx > 0 ? 1 : 3)
        : (direction.dy > 0 ? 2 : 0);
    const tangents = [Offset(1, 0), Offset(0, 1), Offset(-1, 0), Offset(0, -1)];
    final tangent = tangents[edge];
    final dot = tangent.dx * direction.dx + tangent.dy * direction.dy;
    final clockwise = dot.abs() < .001 ? random.nextBool() : dot > 0;
    final corners = [
      water.topLeft,
      water.topRight,
      water.bottomRight,
      water.bottomLeft,
    ];
    for (var leg = 0; leg < 5 && remaining > .001; leg++) {
      final corner = corners[clockwise ? (edge + 1) % 4 : edge];
      final along = corner - contact;
      final travel = math.min(remaining, along.distance);
      if (along.distance > .001) {
        contact += along / along.distance * travel;
        points.add(contact);
        remaining -= travel;
      }
      edge = (edge + (clockwise ? 1 : 3)) % 4;
    }
    return AnimalEscapePath(points);
  }
}

Offset _bounded(Offset point, Rect bounds) => Offset(
  point.dx.clamp(bounds.left, bounds.right),
  point.dy.clamp(bounds.top, bounds.bottom),
);
