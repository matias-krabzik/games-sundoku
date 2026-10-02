import 'dart:math' as math;
import 'dart:ui';

import '../data/valley_map.dart';
import 'map_animal_motion.dart';
import 'map_radial_puff.dart';
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

class MapBee extends MapAnimalMotion {
  MapBee(Offset position, this.flower, this.phase)
    : origin = position,
      destination = position,
      super(position);

  Offset origin;
  Offset destination;
  int flower;
  final double phase;
  double flight = 1;
  double duration = 5;
  double rest = 0;
  double depth = 0;
  double _originDepth = 0;
  double _destinationDepth = 0;
  bool get perched => rest > 0;

  @override
  double get restingScale => 1 - .58 * depth;

  double paintedWidth(double scale) =>
      (29 * scale).clamp(18.0, 40.0) * visualScale;
}

class _Gust {
  _Gust(this.position, this.canopyPosition);
  final Offset position;
  final Offset canopyPosition;
  double age = 0;
}

enum _CreatureRoute { nearHome, exploring, returning }

class _CreatureFlight extends MapAnimalMotion {
  _CreatureFlight(Offset position, this.excursionIn, this.wingPhase)
    : target = position,
      super(position);

  Offset target;
  double excursionIn;
  double wingPhase;
  double resumeProgress = 1;
  _CreatureRoute route = _CreatureRoute.nearHome;
}

class _FishFlight extends _CreatureFlight {
  _FishFlight(Offset position, double phase, this.habitat)
    : super(position, 0, phase);

  final Rect habitat;
  AnimalEscapePath? _waterRoute;
  double _waterTravel = 0;
  math.Random? _waterRandom;

  @override
  void flee({
    required Offset touch,
    required Rect bounds,
    required math.Random random,
    required bool direct,
  }) {
    super.flee(touch: touch, bounds: bounds, random: random, direct: direct);
    _waterTravel = 0;
    _waterRoute = null;
    _waterRandom = random;
  }

  @override
  Offset constrainMovement(Offset displacement, Rect bounds) {
    var route = _waterRoute;
    if (route == null) {
      final desired = position + displacement;
      if (desired.dx >= habitat.left &&
          desired.dx <= habitat.right &&
          desired.dy >= habitat.top &&
          desired.dy <= habitat.bottom) {
        return desired;
      }
      if (displacement.distance < .001) return position;
      route = AnimalEscapePath.alongBank(
        position,
        displacement / displacement.distance,
        MapRadialPuff.radius * 2,
        habitat,
        _waterRandom!,
      );
      _waterRoute = route;
    }
    _waterTravel += displacement.distance;
    final point = route.at(
      route.length < .001 ? 1 : (_waterTravel / route.length).clamp(0.0, 1.0),
    );
    return Offset(
      point.dx.clamp(habitat.left, habitat.right),
      point.dy.clamp(habitat.top, habitat.bottom),
    );
  }
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
      if (creature.kind == MapCreatureKind.fish) {
        _creatureFlights[creature] = _FishFlight(
          _fishPosition(creature, 0),
          creature.phase,
          Rect.fromCenter(
            center: creature.center,
            width: creature.travel.dx.abs() * 2,
            height: creature.travel.dy.abs() * 2,
          ),
        );
        continue;
      }
      final flight = _CreatureFlight(
        creature.center,
        22 + _random.nextDouble() * 20,
        creature.phase,
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
  static const beeTouchDiameter = MapAnimalMotion.touchDiameter;
  static const foregroundFlowerCount = 10;

  // Compatibility for existing callers of the valley particle layout.
  static const flowers = valleyFlowers;

  final math.Random _random;
  final List<MapLeaf> leaves = [];
  final List<MapBee> bees = [];
  final List<_Gust> _gusts = [];
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
    flight.resumeProgress = math.min(1, flight.resumeProgress + dt / .6);
    final resume = flight.resumeProgress;
    final speedFactor = resume * resume * (3 - 2 * resume);
    if (creature.kind == MapCreatureKind.fish) {
      // Resume swimming from the escape endpoint without snapping back to the
      // old route. Both points stay inside the same water patch.
      final delta = _fishPosition(creature, time) - flight.position;
      flight.position += delta * (1 - math.exp(-dt * 1.4 * speedFactor));
      if (delta.dx.abs() > .01) flight.facing = delta.dx.sign;
      return;
    }
    if (flight.route == _CreatureRoute.nearHome) {
      flight.excursionIn -= dt;
    }
    final cruisingSpeed = switch (creature.kind) {
      MapCreatureKind.butterfly => 64.0,
      MapCreatureKind.dragonfly => 105.0,
      MapCreatureKind.mayfly => 76.0,
      MapCreatureKind.fish => 0.0,
    };
    final speed = cruisingSpeed * speedFactor;
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

  static Offset _fishPosition(MapCreatureDefinition creature, double time) {
    final phase = time * .55 + creature.phase;
    return creature.center +
        Offset(
          math.sin(phase) * creature.travel.dx,
          math.sin(phase * .55) * creature.travel.dy,
        );
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
      if (!bee.startled && !view.inflate(100).contains(beePosition(bee))) {
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

  void _flyTo(MapBee bee, int flower) {
    bee.origin = bee.position;
    bee._originDepth = bee.depth;
    bee._destinationDepth = _flowerDepth(flower);
    bee.destination = flowerAnchors[flower] - const Offset(0, 8);
    bee.flower = flower;
    bee.flight = 0;
    bee.rest = 0;
    bee.cancelEscape();
    bee.duration =
        3.5 +
        (bee.destination - bee.origin).distance / 65 +
        _random.nextDouble();
    bee.facing = bee.destination.dx >= bee.origin.dx ? 1 : -1;
  }

  Iterable<
    ({MapAnimalMotion animal, Offset touch, double distance, double radius})
  >
  _animalHits(Offset foregroundTouch, Offset terrainTouch, double scale) sync* {
    for (final bee in bees) {
      final paintedPosition = beePosition(bee);
      final radius = math.max(
        beeTouchDiameter / 2,
        bee.paintedWidth(scale) * .7,
      );
      if (!_view.inflate(radius / scale).contains(paintedPosition)) continue;
      yield (
        animal: bee,
        touch: foregroundTouch - _terrainOffset * bee.depth,
        distance: (paintedPosition - foregroundTouch).distance * scale,
        radius: radius,
      );
    }
    final terrainView = _view.shift(-_terrainOffset);
    for (final creature in creatures) {
      final flight = _creatureFlights[creature]!;
      final spriteReach = creature.kind == MapCreatureKind.butterfly ? 1.1 : .7;
      final radius = math.max(
        beeTouchDiameter / 2,
        creature.size * scale * flight.visualScale * spriteReach,
      );
      if (!terrainView.inflate(radius / scale).contains(flight.position))
        continue;
      yield (
        animal: flight,
        touch: terrainTouch,
        distance: (flight.position - terrainTouch).distance * scale,
        radius: radius,
      );
    }
  }

  void _reactAnimal(
    MapAnimalMotion animal,
    Offset touch, {
    required bool direct,
  }) {
    animal.flee(
      touch: touch,
      bounds: _flightBounds,
      random: _random,
      direct: direct,
    );
    if (animal is MapBee) {
      animal
        ..rest = 0
        ..origin = animal.position;
      if (direct) {
        animal.flower = _nearbyFlower(
          beePosition(animal).dx,
          excluding: animal.flower,
        );
      }
    }
  }

  /// Isolated direct-hit helpers. Scene taps use [tapAt] so neighbors and leaves
  /// also react, and only the nearest animal across all species grows.
  bool startleBeeAt(Offset position, {required double scale}) =>
      _directHit(position, position - _terrainOffset, scale, beesOnly: true);

  bool startleCreatureAt(Offset position, {required double scale}) =>
      _directHit(position + _terrainOffset, position, scale, beesOnly: false);

  bool _directHit(
    Offset foreground,
    Offset terrain,
    double scale, {
    required bool beesOnly,
  }) {
    if (_view.isEmpty || scale <= 0 || !scale.isFinite) return false;
    final hits =
        _animalHits(foreground, terrain, scale)
            .where(
              (hit) =>
                  (hit.animal is MapBee) == beesOnly &&
                  hit.distance <= hit.radius,
            )
            .toList()
          ..sort((a, b) => a.distance.compareTo(b.distance));
    if (hits.isEmpty) return false;
    _reactAnimal(hits.first.animal, hits.first.touch, direct: true);
    return true;
  }

  void tapAt(
    Offset position, {
    required Offset canopyPosition,
    required double scale,
  }) {
    if (_view.isEmpty) return;
    _puffLeaves(position, canopyPosition);
    _reactAt(position, canopyPosition, scale, allowDirect: true);
  }

  /// A free-map puff only startles nearby animals; it does not grow them.
  void puff(Offset position, {Offset? canopyPosition, double scale = 1}) {
    if (_view.isEmpty) return;
    _puffLeaves(position, canopyPosition ?? position);
    _reactAt(position, canopyPosition ?? position, scale, allowDirect: false);
  }

  void _reactAt(
    Offset foreground,
    Offset terrain,
    double scale, {
    required bool allowDirect,
  }) {
    if (scale <= 0 || !scale.isFinite) return;
    final hits = _animalHits(foreground, terrain, scale).toList();
    MapAnimalMotion? directTarget;
    var nearest = double.infinity;
    if (allowDirect) {
      for (final hit in hits) {
        if (hit.distance <= hit.radius && hit.distance < nearest) {
          directTarget = hit.animal;
          nearest = hit.distance;
        }
      }
    }
    for (final hit in hits) {
      final direct = identical(hit.animal, directTarget);
      if (direct || hit.distance / scale < MapRadialPuff.radius) {
        _reactAnimal(hit.animal, hit.touch, direct: direct);
      }
    }
  }

  void _puffLeaves(Offset position, Offset canopyPosition) {
    if (_gusts.length == maxGusts) _gusts.removeAt(0);
    _gusts.add(_Gust(position, canopyPosition));
    for (final leaf in leaves) {
      final center = leaf.depth == MapLeafDepth.foreground
          ? position
          : canopyPosition;
      leaf.impulse += MapRadialPuff.impulseAt(leaf.position, center);
    }
  }

  Offset windAt(Offset position, {bool foreground = false}) =>
      Offset(breeze, 0) + _tapWindAt(position, depth: foreground ? 0 : 1);

  Offset _tapWindAt(Offset position, {required double depth}) {
    var wind = Offset.zero;
    for (final gust in _gusts) {
      wind += MapRadialPuff.gustAt(
        position,
        Offset.lerp(gust.position, gust.canopyPosition, depth)!,
        gust.age,
      );
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
    _gusts.removeWhere((gust) => gust.age >= MapRadialPuff.duration);
    for (final entry in _creatureFlights.entries) {
      final flight = entry.value;
      final beatSpeed = switch (entry.key.kind) {
        MapCreatureKind.butterfly => 22.0,
        MapCreatureKind.dragonfly => 58.0,
        MapCreatureKind.mayfly => 38.0,
        MapCreatureKind.fish => 13.0,
      };
      flight.wingPhase += dt * beatSpeed * (flight.startled ? 1.6 : 1);
      final previous = flight.position;
      if (flight.advanceEscape(
        dt,
        gust: _tapWindAt(flight.position, depth: 1),
      )) {
        if (!flight.startled) flight.resumeProgress = 0;
        if (!flight.startled && entry.key.kind != MapCreatureKind.fish) {
          final heading = flight.position - previous;
          final forward = heading.distance < .000001
              ? Offset(flight.facing, 0)
              : heading / heading.distance;
          flight.target = _insideFlightBounds(flight.position + forward * 24);
          if ((flight.target - flight.position).distance < 12) {
            _chooseFlightTarget(entry.key, flight);
          }
        }
        continue;
      }
      _advanceCreatureFlight(entry.key, flight, dt);
    }
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
      leaf.impulse = MapRadialPuff.decay(leaf.impulse, dt);
      leaf.angle += dt * (.6 + wind.dx * .017 + flutter * .9);
    }
    // A leaf stays in flight across camera movements and is removed only once
    // it reaches the ground. Its age never makes it fade in mid-air.
    leaves.removeWhere((leaf) => leaf.position.dy >= leaf.bottom);
    for (final bee in bees) {
      if (bee.advanceEscape(
        dt,
        gust: _tapWindAt(bee.position, depth: bee.depth),
      )) {
        if (!bee.startled) _flyTo(bee, bee.flower);
        continue;
      }
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
      final t = bee.flight;
      final ease = t * t * (3 - 2 * t);
      bee.depth =
          bee._originDepth + (bee._destinationDepth - bee._originDepth) * ease;
      final arc = math.sin(t * math.pi);
      final wind = windAt(bee.position, foreground: true);
      bee.position =
          Offset.lerp(bee.origin, bee.destination, ease)! +
          Offset(
            (math.sin(time * 2 + bee.phase) * 7 + wind.dx * .32) * arc,
            (-35 + math.sin(time * 3.4 + bee.phase) * 4 + wind.dy * .15) * arc,
          );
      if (t >= 1) {
        bee.rest = 1.6 + _random.nextDouble() * 2.4;
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
    final flight = _creatureFlights[creature]!;
    return (
      position: flight.position,
      facing: flight.facing,
      wingBeat: math.sin(flight.wingPhase),
      visualScale: flight.visualScale,
      startled: flight.startled,
    );
  }
}
