import 'dart:math' as math;
import 'dart:ui';

import '../data/valley_map.dart';

enum MapLeafDepth { behindTrees, air, foreground }

enum MapLeafKind { green, pink }

class MapLeaf {
  MapLeaf(
    this.position,
    this.depth,
    this.size,
    this.phase, {
    this.bottom = 735,
    this.kind = MapLeafKind.green,
  });
  final double bottom;
  final MapLeafKind kind;

  Offset position;
  final MapLeafDepth depth;
  final double size;
  final double phase;
  double age = 0;
  double angle = 0;

  double get opacity => position.dy >= bottom ? 0 : (age / .4).clamp(0.0, 1.0);
}

class MapBee {
  MapBee(this.position, this.flower, this.phase)
    : origin = position,
      destination = position;

  Offset position;
  Offset origin;
  Offset destination;
  int flower;
  final double phase;
  double flight = 1;
  double duration = 5;
  double rest = 0;
  double facing = 1;
  double depth = 0;
  double _originDepth = 0;
  double _destinationDepth = 0;
  bool startled = false;
  double _startleScale = 1;
  static const _growthFraction = .24;
  static const _peakScale = 1.85;
  bool get perched => rest > 0;

  double get _escapeProgress =>
      ((flight - _growthFraction) / (1 - _growthFraction)).clamp(0.0, 1.0);

  double get visualScale {
    if (!startled) return _scaleAtDepth(depth);
    if (flight < _growthFraction) {
      final growth = 1 - math.pow(1 - flight / _growthFraction, 3);
      return _startleScale + (_peakScale - _startleScale) * growth;
    }
    final shrink = 1 - math.pow(1 - _escapeProgress, 3);
    return _peakScale +
        (_scaleAtDepth(_destinationDepth) - _peakScale) * shrink;
  }

  static double _scaleAtDepth(double depth) => 1 - .58 * depth;

  double paintedWidth(double scale) =>
      (29 * scale).clamp(18.0, 40.0) * visualScale;
}

class _Gust {
  _Gust(this.position, this.canopyPosition);
  final Offset position;
  final Offset canopyPosition;
  double age = 0;
}

/// Ambient positions use the configured panorama source coordinates.
/// Scrolling only changes which emitters are nearby; it never advances time.
class MapAmbientMotion {
  MapAmbientMotion({
    int? seed,
    this.flowerAnchors = valleyFlowers,
    this.foregroundFlowers = 10,
    this.canopyAnchors = valleyCanopies,
    this.pinkCanopy,
    this.sourceSize = const Size(2172, 724),
  }) : assert(foregroundFlowers > 0),
       assert(foregroundFlowers <= flowerAnchors.length),
       _random = math.Random(seed);
  final List<Offset> flowerAnchors;
  final int foregroundFlowers;
  final List<Offset> canopyAnchors;
  final Offset? pinkCanopy;
  final Size sourceSize;

  static const maxLeaves = 30;
  static const maxGusts = 4;
  static const beeTouchDiameter = 48.0;
  static const foregroundFlowerCount = 10;

  // Compatibility for existing callers of the valley particle layout.
  static const flowers = valleyFlowers;

  final math.Random _random;
  final List<MapLeaf> leaves = [];
  final List<MapBee> bees = [];
  final List<_Gust> _gusts = [];
  Rect _view = Rect.zero;
  Offset _terrainOffset = Offset.zero;
  double _spawnIn = 0;
  double _pinkSpawnIn = 0;
  double time = 0;
  int get gustCount => _gusts.length;

  double get breeze =>
      11 +
      math.sin(time * .29) * 6 +
      math.pow(math.max(0, math.sin(time * .42)), 4) * 25;

  double _flowerDepth(int flower) => flower < foregroundFlowers ? 0 : 1;

  Offset beePosition(MapBee bee, {bool foreground = true}) =>
      bee.position + _terrainOffset * (bee.depth - (foreground ? 0 : 1));

  Offset _flowerPosition(int flower) =>
      flowerAnchors[flower] + _terrainOffset * _flowerDepth(flower);

  void setView(Rect view, {Offset terrainOffset = Offset.zero}) {
    if (view.isEmpty) return;
    final first = _view.isEmpty;
    _view = view;
    _terrainOffset = terrainOffset;
    if (first) {
      for (var i = 0; i < 2; i++) {
        final flower = _nearbyFlower(
          i == 0 ? view.left : view.right,
          foregroundOnly: true,
        );
        final bee = MapBee(
          flowerAnchors[flower] + Offset(i == 0 ? -28 : 34, -35),
          flower,
          i * 2.7,
        );
        bees.add(bee);
        _flyTo(bee, flower);
      }
      for (var i = 0; i < 5; i++) {
        _spawnLeaf(initial: true, foreground: i < 2);
      }
      for (var i = 0; i < 3; i++) {
        _spawnLeaf(initial: true, pink: true);
      }
    }
    // Relocate only completely offscreen bees, to an actual flower near the
    // new viewport. Visible bees keep their current route and full opacity.
    for (final bee in bees) {
      if (!view.inflate(100).contains(beePosition(bee))) {
        final flower = _nearbyFlower(
          view.left + view.width * (bee == bees.first ? .25 : .75),
          foregroundOnly: true,
        );
        bee.position = flowerAnchors[flower] + const Offset(-24, -36);
        bee.depth = 0;
        _flyTo(bee, flower);
      }
    }
  }

  int _nearbyFlower(double x, {int? excluding, bool foregroundOnly = false}) {
    var best = 0;
    var distance = double.infinity;
    for (var i = 0; i < flowerAnchors.length; i++) {
      if (i == excluding) continue;
      if (foregroundOnly && i >= foregroundFlowers) continue;
      final d = (_flowerPosition(i).dx - x).abs();
      if (d < distance) {
        distance = d;
        best = i;
      }
    }
    return best;
  }

  void _flyTo(
    MapBee bee,
    int flower, {
    Offset? destination,
    double? destinationDepth,
  }) {
    bee.origin = bee.position;
    bee._originDepth = bee.depth;
    bee._destinationDepth = destinationDepth ?? _flowerDepth(flower);
    bee.destination = destination ?? flowerAnchors[flower] - const Offset(0, 8);
    bee.flower = flower;
    bee.flight = 0;
    bee.rest = 0;
    bee.startled = false;
    bee.duration =
        3.5 +
        (bee.destination - bee.origin).distance / 65 +
        _random.nextDouble();
    bee.facing = bee.destination.dx >= bee.origin.dx ? 1 : -1;
  }

  /// A direct touch sends just the nearest bee darting across the visible map.
  /// Hit areas retain a finger-sized target even on the smallest distant bees.
  bool startleBeeAt(Offset position, {required double scale}) {
    if (_view.isEmpty || scale <= 0 || !scale.isFinite) return false;
    MapBee? target;
    var nearest = double.infinity;
    for (final bee in bees) {
      final distance = (beePosition(bee) - position).distance;
      final radius =
          math.max(beeTouchDiameter / 2, bee.paintedWidth(scale) * .7) / scale;
      if (distance <= radius && distance < nearest) {
        target = bee;
        nearest = distance;
      }
    }
    if (target == null) return false;
    final area = _view.intersect(
      Rect.fromLTRB(
        24,
        sourceSize.height * (280 / 724),
        sourceSize.width - 24,
        sourceSize.height * (680 / 724),
      ),
    );
    if (area.isEmpty) return false;
    final bounds = area.deflate(math.min(24.0, area.shortestSide * .1));
    final farFlowers = [
      for (var i = foregroundFlowers; i < flowerAnchors.length; i++)
        if (i != target.flower &&
            _view.deflate(16).contains(_flowerPosition(i)) &&
            (_flowerPosition(i) - beePosition(target)).distance > 80)
          i,
    ];
    // Retapping in flight starts from the current position and size.
    final currentScale = target.visualScale;
    if (farFlowers.isNotEmpty && _random.nextBool()) {
      _flyTo(target, farFlowers[_random.nextInt(farFlowers.length)]);
    } else {
      final destination = _escapeDestination(beePosition(target), bounds);
      _flyTo(
        target,
        _nearbyFlower(destination.dx, excluding: target.flower),
        destination: destination - _terrainOffset * target.depth,
        destinationDepth: target.depth,
      );
    }
    target
      ..startled = true
      .._startleScale = currentScale
      ..duration = .85 + _random.nextDouble() * .2;
    return true;
  }

  Offset _escapeDestination(Offset origin, Rect bounds) {
    var destination = bounds.center;
    var farthest = -1.0;
    final minimumDistance = math.min(140.0, bounds.shortestSide * .5);
    for (var attempt = 0; attempt < 16; attempt++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final distance = 180 + _random.nextDouble() * 140;
      final candidate =
          origin + Offset(math.cos(angle), math.sin(angle)) * distance;
      final bounded = Offset(
        candidate.dx.clamp(bounds.left, bounds.right),
        candidate.dy.clamp(bounds.top, bounds.bottom),
      );
      final travel = (bounded - origin).distance;
      if (travel > farthest) {
        destination = bounded;
        farthest = travel;
      }
      // Retry outward directions near an edge instead of barely moving.
      if (travel >= minimumDistance) return bounded;
    }
    return destination;
  }

  /// A short puff from a free-map tap, never a permanent wind acceleration.
  void puff(Offset position, {Offset? canopyPosition}) {
    if (_view.isEmpty) return;
    if (_gusts.length == maxGusts) _gusts.removeAt(0);
    _gusts.add(_Gust(position, canopyPosition ?? position));
    for (final bee in bees) {
      if (bee.startled) continue;
      final delta = beePosition(bee) - position;
      if (delta.distance > 130) continue;
      final away = delta.distance < 1
          ? const Offset(1, -.5)
          : delta / delta.distance;
      _flyTo(
        bee,
        bee.flower,
        destination: Offset(
          (bee.position.dx + away.dx * 65).clamp(20.0, sourceSize.width - 20),
          (bee.position.dy - 35 + away.dy * 15).clamp(
            sourceSize.height * (350 / 724),
            sourceSize.height * (680 / 724),
          ),
        ),
        destinationDepth: bee.depth,
      );
      bee.duration = 1.4;
    }
  }

  Offset windAt(Offset position, {bool foreground = false}) {
    var wind = Offset(breeze, 0);
    for (final gust in _gusts) {
      final delta =
          position - (foreground ? gust.position : gust.canopyPosition);
      final reach = (1 - delta.distance / 220).clamp(0.0, 1.0);
      final strength = reach * math.pow(1 - gust.age / 2, 2) * 95;
      wind += Offset((delta.dx < 0 ? -.6 : 1) * strength, -strength * .6);
    }
    return wind;
  }

  void advance(double seconds) {
    if (_view.isEmpty || seconds <= 0 || !seconds.isFinite) return;
    // No catch-up storm after a suspended app or a very slow frame.
    var remaining = math.min(seconds, .05);
    while (remaining > .00001) {
      final dt = math.min(remaining, 1 / 60);
      _step(dt);
      remaining -= dt;
    }
  }

  void _step(double dt) {
    time += dt;
    for (final gust in _gusts) {
      gust.age += dt;
    }
    _gusts.removeWhere((gust) => gust.age >= 2);
    if (pinkCanopy != null) {
      _pinkSpawnIn -= dt;
      if (_pinkSpawnIn <= 0) {
        _spawnLeaf(pink: true);
        _pinkSpawnIn = .75 + _random.nextDouble() * 1.15;
      }
    }
    _spawnIn -= dt;
    if (_spawnIn <= 0) {
      _spawnLeaf();
      _spawnIn = (1.3 + _random.nextDouble() * 1.4) * (24 / (breeze + 14));
    }
    for (final leaf in leaves) {
      leaf.age += dt;
      final wind = windAt(
        leaf.position,
        foreground: leaf.depth == MapLeafDepth.foreground,
      );
      final flutter = math.sin(time * 2.2 + leaf.phase);
      final fall = leaf.depth == MapLeafDepth.foreground && leaf.age < 1.6
          ? -12.0
          : 14 + leaf.size * .4;
      leaf.position += Offset(wind.dx + flutter * 15, fall + wind.dy) * dt;
      leaf.angle += dt * (.6 + wind.dx * .017 + flutter * .9);
    }
    // A leaf stays in flight across camera movements and is removed only once
    // it reaches the ground. Its age never makes it fade in mid-air.
    leaves.removeWhere((leaf) => leaf.position.dy >= leaf.bottom);
    for (final bee in bees) {
      if (bee.perched) {
        bee.rest -= dt;
        if (bee.rest <= 0) {
          final nearby = [
            for (var i = 0; i < flowerAnchors.length; i++)
              if (i != bee.flower &&
                  _view.inflate(40).contains(_flowerPosition(i)))
                i,
          ];
          final flower = nearby.isEmpty
              ? _nearbyFlower(beePosition(bee).dx, excluding: bee.flower)
              : nearby[_random.nextInt(nearby.length)];
          _flyTo(bee, flower);
        }
        continue;
      }
      bee.flight = math.min(1, bee.flight + dt / bee.duration);
      // The initial pop stays anchored, including when interrupted mid-flight.
      final t = bee.startled ? bee._escapeProgress : bee.flight;
      if (bee.startled && t == 0) continue;
      final ease = bee.startled
          ? 1 - math.pow(1 - t, 3).toDouble()
          : t * t * (3 - 2 * t);
      bee.depth =
          bee._originDepth + (bee._destinationDepth - bee._originDepth) * ease;
      // The escape follows its random heading; only ambient flights bob upward.
      final arc = bee.startled ? 0.0 : math.sin(t * math.pi);
      final wind = windAt(bee.position, foreground: true);
      bee.position =
          Offset.lerp(bee.origin, bee.destination, ease)! +
          Offset(
            (math.sin(time * 2 + bee.phase) * 7 + wind.dx * .32) * arc,
            (-35 + math.sin(time * 3.4 + bee.phase) * 4 + wind.dy * .15) * arc,
          );
      if (t >= 1) {
        bee.startled = false;
        // After avoiding a touch, return to the flower before resting.
        if ((bee.destination - (flowerAnchors[bee.flower] - const Offset(0, 8)))
                .distance >
            1) {
          _flyTo(bee, bee.flower);
        } else {
          bee.rest = 1.6 + _random.nextDouble() * 2.4;
        }
      }
    }
  }

  void _spawnLeaf({bool initial = false, bool? foreground, bool pink = false}) {
    final pinkOrigin = pinkCanopy;
    if (pink &&
        (pinkOrigin == null || !_view.inflate(120).contains(pinkOrigin))) {
      return;
    }
    final localCount = leaves
        .where((leaf) => _view.contains(leaf.position))
        .length;
    final target = (_view.width / 100).round().clamp(6, 12);
    if (leaves.length >= maxLeaves || localCount >= target) return;
    final nearby = canopyAnchors
        .where((p) => p.dx > _view.left - 180 && p.dx < _view.right + 30)
        .toList();
    final front = !pink && (foreground ?? _random.nextDouble() < .35);
    if (!front && nearby.isEmpty) return;
    final origin = pink
        ? pinkOrigin!
        : front
        ? Offset(
            _view.left + _random.nextDouble() * _view.width,
            sourceSize.height * (560 / 724) + _random.nextDouble() * 60,
          )
        : nearby[_random.nextInt(nearby.length)];
    final depth = front
        ? MapLeafDepth.foreground
        : (_random.nextDouble() < (pink ? .45 : .3)
              ? MapLeafDepth.behindTrees
              : MapLeafDepth.air);
    final leaf = MapLeaf(
      origin +
          Offset(_random.nextDouble() * 70 - 35, _random.nextDouble() * 60),
      depth,
      pink
          ? 5.5 + _random.nextDouble() * 2.5
          : front
          ? 13 + _random.nextDouble() * 5
          : 8 + _random.nextDouble() * 5,
      _random.nextDouble() * math.pi * 2,
      bottom: sourceSize.height + 11,
      kind: pink ? MapLeafKind.pink : MapLeafKind.green,
    );
    if (initial) {
      leaf.age = 1 + _random.nextDouble() * 3;
      leaf.position += Offset(
        leaf.age * 15,
        front
            ? -12 * math.min(1.6, leaf.age) + math.max(0, leaf.age - 1.6) * 18
            : leaf.age * 18,
      );
    }
    leaves.add(leaf);
  }
}
