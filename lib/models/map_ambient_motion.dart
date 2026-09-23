import 'dart:math' as math;
import 'dart:ui';

enum MapLeafDepth { behindTrees, air, foreground }

class MapLeaf {
  MapLeaf(this.position, this.depth, this.size, this.phase, this.lifetime);

  Offset position;
  final MapLeafDepth depth;
  final double size;
  final double phase;
  final double lifetime;
  double age = 0;
  double angle = 0;

  double get opacity =>
      (age / .7).clamp(0.0, 1.0) *
      ((lifetime - age) / 2).clamp(0.0, 1.0) *
      ((735 - position.dy) / 45).clamp(0.0, 1.0);
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
  bool get perched => rest > 0;
}

class _Gust {
  _Gust(this.position, this.canopyPosition);
  final Offset position;
  final Offset canopyPosition;
  double age = 0;
}

/// Ambient positions use the original panorama's 2172 × 724 coordinates.
/// Scrolling only changes which emitters are nearby; it never advances time.
class MapAmbientMotion {
  MapAmbientMotion({int? seed}) : _random = math.Random(seed);

  static const maxLeaves = 18;
  static const maxGusts = 4;

  // Centers of blossoms in foreground.png, excluding its overscan margins.
  static const flowers = <Offset>[
    Offset(98, 516),
    Offset(295, 638),
    Offset(809, 612),
    Offset(964, 662),
    Offset(1129, 654),
    Offset(1307, 673),
    Offset(1394, 685),
    Offset(1908, 637),
    Offset(1935, 627),
    Offset(2082, 600),
  ];
  static const _canopies = <Offset>[
    Offset(115, 155),
    Offset(485, 260),
    Offset(741, 330),
    Offset(1420, 324),
    Offset(1758, 244),
    Offset(2138, 243),
  ];

  final math.Random _random;
  final List<MapLeaf> leaves = [];
  final List<MapBee> bees = [];
  final List<_Gust> _gusts = [];
  Rect _view = Rect.zero;
  double _spawnIn = 0;
  double time = 0;
  int get gustCount => _gusts.length;

  double get breeze =>
      11 +
      math.sin(time * .29) * 6 +
      math.pow(math.max(0, math.sin(time * .42)), 4) * 25;

  void setView(Rect view) {
    if (view.isEmpty) return;
    final first = _view.isEmpty;
    _view = view;
    if (first) {
      for (var i = 0; i < 2; i++) {
        final flower = _nearbyFlower(i == 0 ? view.left : view.right);
        final bee = MapBee(
          flowers[flower] + Offset(i == 0 ? -28 : 34, -35),
          flower,
          i * 2.7,
        );
        bees.add(bee);
        _flyTo(bee, flower);
      }
      for (var i = 0; i < 5; i++) {
        _spawnLeaf(initial: true, foreground: i < 2);
      }
    }
    // Relocate only completely offscreen bees, to an actual flower near the
    // new viewport. Visible bees keep their current route and full opacity.
    for (final bee in bees) {
      if (!view.inflate(100).contains(bee.position)) {
        final flower = _nearbyFlower(
          view.left + view.width * (bee == bees.first ? .25 : .75),
        );
        bee.position = flowers[flower] + const Offset(-24, -36);
        _flyTo(bee, flower);
      }
    }
  }

  int _nearbyFlower(double x, {int? excluding}) {
    var best = 0;
    var distance = double.infinity;
    for (var i = 0; i < flowers.length; i++) {
      if (i == excluding) continue;
      final d = (flowers[i].dx - x).abs();
      if (d < distance) {
        distance = d;
        best = i;
      }
    }
    return best;
  }

  void _flyTo(MapBee bee, int flower, {Offset? destination}) {
    bee.origin = bee.position;
    bee.destination = destination ?? flowers[flower] - const Offset(0, 8);
    bee.flower = flower;
    bee.flight = 0;
    bee.rest = 0;
    bee.duration =
        3.5 +
        (bee.destination - bee.origin).distance / 65 +
        _random.nextDouble();
    bee.facing = bee.destination.dx >= bee.origin.dx ? 1 : -1;
  }

  /// A short puff from a free-map tap, never a permanent wind acceleration.
  void puff(Offset position, {Offset? canopyPosition}) {
    if (_view.isEmpty) return;
    if (_gusts.length == maxGusts) _gusts.removeAt(0);
    _gusts.add(_Gust(position, canopyPosition ?? position));
    for (final bee in bees) {
      final delta = bee.position - position;
      if (delta.distance > 130) continue;
      final away = delta.distance < 1
          ? const Offset(1, -.5)
          : delta / delta.distance;
      _flyTo(
        bee,
        bee.flower,
        destination: Offset(
          (bee.position.dx + away.dx * 65).clamp(20.0, 2152.0),
          (bee.position.dy - 35 + away.dy * 15).clamp(350.0, 680.0),
        ),
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
    leaves.removeWhere(
      (leaf) =>
          leaf.age >= leaf.lifetime ||
          leaf.position.dy > 740 ||
          !_view.inflate(300).contains(leaf.position),
    );
    for (final bee in bees) {
      if (bee.perched) {
        bee.rest -= dt;
        if (bee.rest <= 0) {
          final margin = math.min(25.0, _view.width * .1);
          final x = (bee.position.dx + (_random.nextBool() ? 200 : -200)).clamp(
            _view.left + margin,
            _view.right - margin,
          );
          _flyTo(bee, _nearbyFlower(x, excluding: bee.flower));
        }
        continue;
      }
      bee.flight = math.min(1, bee.flight + dt / bee.duration);
      final t = bee.flight;
      final ease = t * t * (3 - 2 * t);
      final arc = math.sin(t * math.pi);
      final wind = windAt(bee.position, foreground: true);
      bee.position =
          Offset.lerp(bee.origin, bee.destination, ease)! +
          Offset(
            (math.sin(time * 2 + bee.phase) * 7 + wind.dx * .32) * arc,
            (-35 + math.sin(time * 3.4 + bee.phase) * 4 + wind.dy * .15) * arc,
          );
      if (t >= 1) {
        // After avoiding a touch, return to the flower before resting.
        if ((bee.destination - (flowers[bee.flower] - const Offset(0, 8)))
                .distance >
            1) {
          _flyTo(bee, bee.flower);
        } else {
          bee.rest = 1.6 + _random.nextDouble() * 2.4;
        }
      }
    }
  }

  void _spawnLeaf({bool initial = false, bool? foreground}) {
    final localCount = leaves
        .where((leaf) => _view.contains(leaf.position))
        .length;
    final target = (_view.width / 100).round().clamp(6, 12);
    if (leaves.length >= maxLeaves || localCount >= target) return;
    final nearby = _canopies
        .where((p) => p.dx > _view.left - 180 && p.dx < _view.right + 30)
        .toList();
    final front = foreground ?? _random.nextDouble() < .35;
    if (!front && nearby.isEmpty) return;
    final origin = front
        ? Offset(
            _view.left + _random.nextDouble() * _view.width,
            560 + _random.nextDouble() * 60,
          )
        : nearby[_random.nextInt(nearby.length)];
    final depth = front
        ? MapLeafDepth.foreground
        : (_random.nextDouble() < .3
              ? MapLeafDepth.behindTrees
              : MapLeafDepth.air);
    final leaf = MapLeaf(
      origin +
          Offset(_random.nextDouble() * 70 - 35, _random.nextDouble() * 60),
      depth,
      front ? 13 + _random.nextDouble() * 5 : 8 + _random.nextDouble() * 5,
      _random.nextDouble() * math.pi * 2,
      front ? 8 : 18 + _random.nextDouble() * 7,
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
