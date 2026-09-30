import 'dart:math' as math;
import 'dart:ui';

import '../data/valley_map.dart';
import 'world_map_definition.dart';

enum MapLeafDepth { behindTrees, air, foreground }

enum MapLeafKind { green, pink, petal }

class MapLeaf {
  MapLeaf(
    this.position,
    this.depth,
    this.size,
    this.phase, {
    this.bottom = 735,
    this.kind = MapLeafKind.green,
    this.spriteIndex = 0,
  });
  final double bottom;
  final MapLeafKind kind;
  final int spriteIndex;

  Offset position;
  final MapLeafDepth depth;
  final double size;
  final double phase;
  double age = 0;
  double angle = 0;
  Offset impulse = Offset.zero;

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

class _CreatureReaction {
  _CreatureReaction({
    required this.origin,
    required this.destination,
    required this.startTime,
    required this.startScale,
  });

  final Offset origin;
  final Offset destination;
  final double startTime;
  final double startScale;

  static const popDuration = .18;
  static const escapeDuration = .72;
  static const returnDuration = .9;
  static const totalDuration = popDuration + escapeDuration + returnDuration;
}

enum _CreatureRoute { nearHome, exploring, returning }

class _CreatureFlight {
  _CreatureFlight(this.position, this.excursionIn) : target = position;

  Offset position;
  Offset target;
  double excursionIn;
  double facing = 1;
  _CreatureRoute route = _CreatureRoute.nearHome;
}

/// Ambient positions use the configured panorama source coordinates.
/// Scrolling only changes which emitters are nearby; it never advances time.
class MapAmbientMotion {
  MapAmbientMotion({
    int? seed,
    this.flowerAnchors = valleyFlowers,
    this.foregroundFlowers = 10,
    this.canopyAnchors = valleyCanopies,
    this.canopyLeafStyles = const [],
    this.pinkCanopy,
    this.petalAnchors = const [],
    this.creatures = const [],
    this.beeCount = 2,
    this.treeLeavesOnly = false,
    this.sourceSize = const Size(2172, 724),
  }) : assert(foregroundFlowers > 0),
       assert(foregroundFlowers <= flowerAnchors.length),
       assert(beeCount >= 0),
       assert(
         canopyLeafStyles.isEmpty ||
             canopyLeafStyles.length == canopyAnchors.length,
       ),
       _random = math.Random(seed) {
    for (final creature in creatures) {
      if (creature.kind == MapCreatureKind.fish) continue;
      final flight = _CreatureFlight(
        creature.center,
        22 + _random.nextDouble() * 20,
      );
      _creatureFlights[creature] = flight;
      _chooseFlightTarget(creature, flight);
    }
  }
  final List<Offset> flowerAnchors;
  final int foregroundFlowers;
  final List<Offset> canopyAnchors;
  final List<int> canopyLeafStyles;
  final Offset? pinkCanopy;
  final List<Offset> petalAnchors;
  final List<MapCreatureDefinition> creatures;
  final int beeCount;
  final bool treeLeavesOnly;
  final Size sourceSize;

  static const maxLeaves = 36;
  static const maxGusts = 4;
  static const beeTouchDiameter = 48.0;
  static const foregroundFlowerCount = 10;

  // Compatibility for existing callers of the valley particle layout.
  static const flowers = valleyFlowers;

  final math.Random _random;
  final List<MapLeaf> leaves = [];
  final List<MapBee> bees = [];
  final List<_Gust> _gusts = [];
  final Map<MapCreatureDefinition, _CreatureReaction> _creatureReactions = {};
  final Map<MapCreatureDefinition, _CreatureFlight> _creatureFlights = {};
  Rect _view = Rect.zero;
  Offset _terrainOffset = Offset.zero;
  double _spawnIn = 0;
  double _pinkSpawnIn = 0;
  double _petalSpawnIn = 0;
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

  // Flight lives in panorama coordinates, independently of the camera. Birth
  // points attract insects, but only the panorama itself limits their range.
  Rect get _flightBounds => Rect.fromLTRB(
    16,
    math.min(90.0, sourceSize.height * .16),
    sourceSize.width - 16,
    sourceSize.height - 24,
  );

  Offset _insideFlightBounds(Offset point) => Offset(
    point.dx.clamp(_flightBounds.left, _flightBounds.right),
    point.dy.clamp(_flightBounds.top, _flightBounds.bottom),
  );

  Offset _nearBirthplace(MapCreatureDefinition creature) => _insideFlightBounds(
    creature.center +
        Offset(
          (_random.nextDouble() * 2 - 1) *
              math.max(55.0, creature.travel.dx.abs() * 1.8),
          (_random.nextDouble() * 2 - 1) *
              math.max(30.0, creature.travel.dy.abs() * 1.8),
        ),
  );

  void _chooseFlightTarget(
    MapCreatureDefinition creature,
    _CreatureFlight flight,
  ) {
    if (flight.route == _CreatureRoute.exploring) {
      flight
        ..route = _CreatureRoute.returning
        ..target = _nearBirthplace(creature);
      return;
    }
    if (flight.route == _CreatureRoute.returning) {
      flight
        ..route = _CreatureRoute.nearHome
        ..excursionIn = 55 + _random.nextDouble() * 55;
    }
    if (flight.excursionIn > 0) {
      flight.target = _nearBirthplace(creature);
      return;
    }

    // An occasional excursion crosses other level areas. Most waypoints stay
    // near the birthplace, so it remains the most likely place to find one.
    flight.route = _CreatureRoute.exploring;
    final global = sourceSize.width > 1000 && _random.nextDouble() < .12;
    double x;
    if (global) {
      x = _flightBounds.left + _random.nextDouble() * _flightBounds.width;
    } else {
      final maximum = math.min(950.0, sourceSize.width * .45);
      final distance =
          320 + _random.nextDouble() * math.max(0.0, maximum - 320);
      var direction = _random.nextBool() ? 1.0 : -1.0;
      final room = direction > 0
          ? _flightBounds.right - creature.center.dx
          : creature.center.dx - _flightBounds.left;
      final otherRoom = direction > 0
          ? creature.center.dx - _flightBounds.left
          : _flightBounds.right - creature.center.dx;
      if (room < 250 && otherRoom > room) direction = -direction;
      x = creature.center.dx + direction * distance;
    }
    final y = global
        ? _flightBounds.top + _random.nextDouble() * _flightBounds.height
        : creature.center.dy + (_random.nextDouble() * 2 - 1) * 110;
    flight.target = _insideFlightBounds(Offset(x, y));
  }

  void _advanceCreatureFlight(
    MapCreatureDefinition creature,
    _CreatureFlight flight,
    double dt,
  ) {
    if (flight.route == _CreatureRoute.nearHome) {
      flight.excursionIn -= dt;
    }
    final speed = switch (creature.kind) {
      MapCreatureKind.butterfly => 64.0,
      MapCreatureKind.dragonfly => 105.0,
      MapCreatureKind.mayfly => 76.0,
      MapCreatureKind.fish => 0.0,
    };
    var remaining = dt;
    for (var leg = 0; leg < 3 && remaining > 0; leg++) {
      final delta = flight.target - flight.position;
      final distance = delta.distance;
      if (distance < .001) {
        _chooseFlightTarget(creature, flight);
        continue;
      }
      if (delta.dx.abs() > .01) flight.facing = delta.dx.sign;
      final travel = math.min(distance, speed * remaining);
      flight.position += delta * (travel / distance);
      remaining -= travel / speed;
      if (travel < distance) break;
      _chooseFlightTarget(creature, flight);
    }
  }

  void setView(Rect view, {Offset terrainOffset = Offset.zero}) {
    if (view.isEmpty) return;
    final first = _view.isEmpty;
    _view = view;
    _terrainOffset = terrainOffset;
    if (first) {
      for (var i = 0; i < beeCount; i++) {
        final flower = _nearbyFlower(
          beeCount == 2
              ? (i == 0 ? view.left : view.right)
              : view.left + view.width * (i + 1) / (beeCount + 1),
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
      for (var i = 0; i < 3; i++) {
        _spawnLeaf(initial: true, petal: true);
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

  /// Startles the nearest visible creature touched in terrain coordinates.
  /// The hit target remains finger-sized even when the sprite is small.
  bool startleCreatureAt(Offset position, {required double scale}) {
    if (_view.isEmpty || scale <= 0 || !scale.isFinite) return false;
    final terrainView = _view.shift(-_terrainOffset);
    MapCreatureDefinition? target;
    var nearest = double.infinity;
    for (final creature in creatures) {
      final pose = creaturePose(creature);
      if (!terrainView.contains(pose.position)) continue;
      final distance = (pose.position - position).distance;
      final spriteReach = creature.kind == MapCreatureKind.butterfly ? 1.1 : .7;
      final radius =
          math.max(
            beeTouchDiameter / 2,
            creature.size * scale * pose.visualScale * spriteReach,
          ) /
          scale;
      if (distance <= radius && distance < nearest) {
        target = creature;
        nearest = distance;
      }
    }
    if (target == null) return false;
    _startleCreature(target, position, terrainView);
    return true;
  }

  void _startleCreature(
    MapCreatureDefinition creature,
    Offset touch,
    Rect terrainView,
  ) {
    final pose = creaturePose(creature);
    final isFish = creature.kind == MapCreatureKind.fish;
    // Fish keep their water patch. Insects can escape anywhere in the map,
    // including beyond the current camera view or their birthplace.
    final reachX = creature.travel.dx.abs();
    final habitat = Rect.fromLTRB(
      creature.center.dx - reachX,
      creature.center.dy - creature.travel.dy.abs(),
      creature.center.dx + reachX,
      creature.center.dy + creature.travel.dy.abs(),
    );
    final bounds = isFish ? habitat.intersect(terrainView) : _flightBounds;
    if (bounds.isEmpty) return;
    final fromTouch = pose.position - touch;
    final direction = isFish
        ? Offset(
            fromTouch.dx.abs() < .001
                ? (_random.nextBool() ? 1 : -1)
                : fromTouch.dx.sign,
            0,
          )
        : fromTouch.distance < .001
        ? Offset.fromDirection(_random.nextDouble() * math.pi * 2)
        : fromTouch / fromTouch.distance;
    final distance = isFish ? reachX * 1.5 : 135.0;
    final desired = pose.position + direction * distance;
    var destination = Offset(
      desired.dx.clamp(bounds.left, bounds.right),
      desired.dy.clamp(bounds.top, bounds.bottom),
    );
    // At a habitat edge an outward touch can otherwise clamp the escape to
    // the current point. Turn within the same water patch or flight area so
    // the animal still makes a visible dart without crossing the boundary.
    final minimumDart = isFish ? math.min(12.0, bounds.width * .3) : 25.0;
    if ((destination - pose.position).distance < minimumDart) {
      if (isFish) {
        final leftRoom = pose.position.dx - bounds.left;
        final rightRoom = bounds.right - pose.position.dx;
        destination = Offset(
          leftRoom >= rightRoom ? bounds.left : bounds.right,
          pose.position.dy.clamp(bounds.top, bounds.bottom),
        );
      } else {
        destination = _insideFlightBounds(pose.position - direction * distance);
      }
    }
    // Retouching begins from the current interpolated position and scale.
    _creatureReactions[creature] = _CreatureReaction(
      origin: pose.position,
      destination: destination,
      startTime: time,
      startScale: pose.visualScale,
    );
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
  /// Nearby visible creatures react within a radius measured on the screen.
  void puff(Offset position, {Offset? canopyPosition, double scale = 1}) {
    if (_view.isEmpty) return;
    if (_gusts.length == maxGusts) _gusts.removeAt(0);
    _gusts.add(_Gust(position, canopyPosition ?? position));
    for (final leaf in leaves) {
      final center = leaf.depth == MapLeafDepth.foreground
          ? position
          : (canopyPosition ?? position);
      final delta = leaf.position - center;
      final distance = delta.distance;
      if (distance >= 220) continue;
      final away = distance < 1 ? const Offset(0, -1) : delta / distance;
      leaf.impulse += away * (115 * (1 - distance / 220));
    }
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
    if (scale <= 0 || !scale.isFinite) return;
    final terrainTouch = canopyPosition ?? position;
    final terrainView = _view.shift(-_terrainOffset);
    for (final creature in creatures) {
      final pose = creaturePose(creature);
      if (!terrainView.contains(pose.position)) continue;
      final radius = switch (creature.kind) {
        MapCreatureKind.butterfly => 105.0,
        MapCreatureKind.dragonfly => 100.0,
        MapCreatureKind.mayfly => 95.0,
        MapCreatureKind.fish => 80.0,
      };
      if ((pose.position - terrainTouch).distance * scale > radius) continue;
      _startleCreature(creature, terrainTouch, terrainView);
    }
  }

  Offset windAt(Offset position, {bool foreground = false}) {
    var wind = Offset(breeze, 0);
    for (final gust in _gusts) {
      final delta =
          position - (foreground ? gust.position : gust.canopyPosition);
      final reach = (1 - delta.distance / 220).clamp(0.0, 1.0);
      final strength = reach * math.pow(1 - gust.age / 2, 2) * 95;
      final away = delta.distance < 1
          ? const Offset(0, -1)
          : delta / delta.distance;
      wind += away * strength;
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
    for (final entry in _creatureReactions.entries.toList()) {
      final insect = entry.key.kind != MapCreatureKind.fish;
      final duration = insect
          ? _CreatureReaction.popDuration + _CreatureReaction.escapeDuration
          : _CreatureReaction.totalDuration;
      if (time - entry.value.startTime < duration) continue;
      if (insect) {
        _creatureFlights[entry.key]?.position = entry.value.destination;
      }
      _creatureReactions.remove(entry.key);
    }
    for (final entry in _creatureFlights.entries) {
      if (_creatureReactions.containsKey(entry.key)) continue;
      _advanceCreatureFlight(entry.key, entry.value, dt);
    }
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
    if (petalAnchors.isNotEmpty) {
      _petalSpawnIn -= dt;
      if (_petalSpawnIn <= 0) {
        _spawnLeaf(petal: true);
        _petalSpawnIn = .8 + _random.nextDouble() * 1.2;
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
      leaf.position +=
          (Offset(wind.dx + flutter * 15, fall + wind.dy) + leaf.impulse) * dt;
      leaf.impulse *= math.exp(-dt * 3.5);
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

  void _spawnLeaf({
    bool initial = false,
    bool? foreground,
    bool pink = false,
    bool petal = false,
  }) {
    if (petal && petalAnchors.isEmpty) return;
    final pinkOrigin = pinkCanopy;
    if (pink &&
        (pinkOrigin == null || !_view.inflate(120).contains(pinkOrigin))) {
      return;
    }
    final localCount = leaves
        .where((leaf) => _view.contains(leaf.position))
        .length;
    final target =
        (_view.width / 100).round().clamp(6, 12) +
        (petalAnchors.isEmpty ? 0 : 4);
    if (leaves.length >= maxLeaves || localCount >= target) return;
    final nearby = [
      for (var i = 0; i < canopyAnchors.length; i++)
        if (canopyAnchors[i].dx > _view.left - 180 &&
            canopyAnchors[i].dx < _view.right + 30)
          i,
    ];
    final nearPetals = petalAnchors
        .where((p) => p.dx > _view.left - 80 && p.dx < _view.right + 80)
        .toList();
    if (petal && nearPetals.isEmpty) return;
    final front =
        !pink &&
        !petal &&
        !treeLeavesOnly &&
        (foreground ?? _random.nextDouble() < .35);
    if (!front && !pink && !petal && nearby.isEmpty) return;
    final canopyIndex = nearby.isEmpty
        ? 0
        : nearby[_random.nextInt(nearby.length)];
    final spriteIndex = canopyLeafStyles.isEmpty
        ? 0
        : canopyLeafStyles[canopyIndex];
    final origin = pink
        ? pinkOrigin!
        : petal
        ? nearPetals[_random.nextInt(nearPetals.length)]
        : front
        ? Offset(
            _view.left + _random.nextDouble() * _view.width,
            sourceSize.height * (560 / 724) + _random.nextDouble() * 60,
          )
        : canopyAnchors[canopyIndex];
    final depth = front
        ? MapLeafDepth.foreground
        : (_random.nextDouble() <
                  (pink
                      ? .45
                      : petal
                      ? .15
                      : .3)
              ? MapLeafDepth.behindTrees
              : MapLeafDepth.air);
    final size = pink
        ? 5.5 + _random.nextDouble() * 2.5
        : petal
        ? 7 + _random.nextDouble() * 3
        : front
        ? 13 + _random.nextDouble() * 5
        : spriteIndex == 2
        ? 7 + _random.nextDouble() * 4
        : 8 + _random.nextDouble() * 6;
    final leaf = MapLeaf(
      origin +
          Offset(_random.nextDouble() * 70 - 35, _random.nextDouble() * 60),
      depth,
      size,
      _random.nextDouble() * math.pi * 2,
      bottom: sourceSize.height + 11,
      kind: pink
          ? MapLeafKind.pink
          : petal
          ? MapLeafKind.petal
          : MapLeafKind.green,
      spriteIndex: spriteIndex,
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

  /// Position and appearance of a creature, including a temporary touch escape.
  ({
    Offset position,
    double facing,
    double wingBeat,
    double visualScale,
    bool startled,
  })
  creaturePose(MapCreatureDefinition creature) {
    final speed = switch (creature.kind) {
      MapCreatureKind.butterfly => .85,
      MapCreatureKind.dragonfly => 1.3,
      MapCreatureKind.mayfly => 1.7,
      MapCreatureKind.fish => .55,
    };
    final phase = time * speed + creature.phase;
    final flight = _creatureFlights[creature];
    final ambientPosition =
        flight?.position ??
        creature.center +
            Offset(
              math.sin(phase) * creature.travel.dx,
              math.sin(phase * .55) * creature.travel.dy,
            );
    final ambientFacing = flight?.facing ?? (math.cos(phase) >= 0 ? 1.0 : -1.0);
    final reaction = _creatureReactions[creature];
    final beatSpeed = switch (creature.kind) {
      MapCreatureKind.butterfly => 22.0,
      MapCreatureKind.dragonfly => 58.0,
      MapCreatureKind.mayfly => 38.0,
      MapCreatureKind.fish => 13.0,
    };
    if (reaction == null) {
      return (
        position: ambientPosition,
        facing: ambientFacing,
        wingBeat: math.sin(time * beatSpeed + creature.phase),
        visualScale: 1.0,
        startled: false,
      );
    }
    final elapsed = time - reaction.startTime;
    final peakScale = creature.kind == MapCreatureKind.fish ? 1.35 : 1.75;
    Offset position;
    double visualScale;
    if (elapsed < _CreatureReaction.popDuration) {
      final t = (elapsed / _CreatureReaction.popDuration).clamp(0.0, 1.0);
      final ease = 1 - math.pow(1 - t, 3).toDouble();
      position = reaction.origin;
      visualScale =
          reaction.startScale + (peakScale - reaction.startScale) * ease;
    } else if (elapsed <
        _CreatureReaction.popDuration + _CreatureReaction.escapeDuration) {
      final t =
          ((elapsed - _CreatureReaction.popDuration) /
                  _CreatureReaction.escapeDuration)
              .clamp(0.0, 1.0);
      final ease = 1 - math.pow(1 - t, 3).toDouble();
      position = Offset.lerp(reaction.origin, reaction.destination, ease)!;
      visualScale = peakScale + (1 - peakScale) * ease;
    } else if (creature.kind != MapCreatureKind.fish) {
      position = reaction.destination;
      visualScale = 1;
    } else {
      final t =
          ((elapsed -
                      _CreatureReaction.popDuration -
                      _CreatureReaction.escapeDuration) /
                  _CreatureReaction.returnDuration)
              .clamp(0.0, 1.0);
      final ease = t * t * (3 - 2 * t);
      position = Offset.lerp(reaction.destination, ambientPosition, ease)!;
      visualScale = 1;
    }
    final heading =
        creature.kind != MapCreatureKind.fish ||
            elapsed <
                _CreatureReaction.popDuration + _CreatureReaction.escapeDuration
        ? reaction.destination.dx - reaction.origin.dx
        : ambientPosition.dx - reaction.destination.dx;
    return (
      position: position,
      facing: heading.abs() < .001 ? ambientFacing : heading.sign,
      wingBeat: math.sin(time * beatSpeed * 1.6 + creature.phase),
      visualScale: visualScale,
      startled: true,
    );
  }
}
