import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/models/map_ambient_motion.dart';
import 'package:sundoku/models/world_map_definition.dart';

void advance(MapAmbientMotion motion, double seconds) {
  for (var i = 0; i < (seconds * 60).ceil(); i++) {
    motion.advance(1 / 60);
  }
}

void main() {
  test('pink leaves start at the flowering tree and drift away from it', () {
    const canopy = Offset(295, 265);
    final motion = MapAmbientMotion(
      seed: 8,
      pinkCanopy: canopy,
      sourceSize: const Size(2052, 644),
    )..setView(const Rect.fromLTWH(0, 0, 620, 644));
    final pink = motion.leaves.where((leaf) => leaf.kind == MapLeafKind.pink);
    expect(pink, isNotEmpty);
    expect(
      pink.every((leaf) => (leaf.position - canopy).distance < 150),
      isTrue,
    );
    final first = pink.first;
    final start = first.position;
    advance(motion, 4);
    expect((first.position - start).distance, greaterThan(30));

    motion.setView(const Rect.fromLTWH(1400, 0, 600, 644));
    advance(motion, 26);
    expect(
      motion.leaves.where((leaf) => leaf.kind == MapLeafKind.pink),
      isEmpty,
    );
  });

  test('maps without a flowering tree never emit pink leaves', () {
    final motion = MapAmbientMotion(seed: 8)
      ..setView(const Rect.fromLTWH(0, 0, 620, 724));
    advance(motion, 25);
    expect(
      motion.leaves.where((leaf) => leaf.kind == MapLeafKind.pink),
      isEmpty,
    );
  });

  test('a tap pushes leaves outward in every direction', () {
    final motion = MapAmbientMotion(seed: 3, beeCount: 0)
      ..setView(const Rect.fromLTWH(0, 0, 600, 724));
    motion.leaves.clear();
    const tap = Offset(300, 350);
    final starts = [
      const Offset(260, 350),
      const Offset(340, 350),
      const Offset(300, 310),
      const Offset(300, 390),
    ];
    for (final start in starts) {
      motion.leaves.add(MapLeaf(start, MapLeafDepth.air, 10, 0)..age = 1);
    }

    motion.puff(tap);
    motion.advance(.05);

    for (var i = 0; i < starts.length; i++) {
      final fromTap = starts[i] - tap;
      final travel = motion.leaves[i].position - starts[i];
      expect(fromTap.dx * travel.dx + fromTap.dy * travel.dy, greaterThan(0));
    }
  });

  test('animals receive exactly the leaf impulse and gust on repeated radial taps', () {
    const origin = Offset(800, 500);
    const parallax = Offset(50, -10);
    for (final kind in [null, ...MapCreatureKind.values]) {
      for (final scale in [.5, 2.0]) {
        for (final depth in kind == null ? [0.0, 1.0] : [1.0]) {
          for (final delta in [
            const Offset(-60, -40),
            const Offset(60, -40),
            const Offset(-60, 40),
            const Offset(60, 40),
          ]) {
            final creature = kind == null
                ? null
                : MapCreatureDefinition(
                    kind: kind,
                    center: origin,
                    travel: const Offset(400, 300),
                    size: 30,
                  );
            final motion =
                MapAmbientMotion(
                  seed: 5,
                  beeCount: kind == null ? 1 : 0,
                  creatures: [?creature],
                  sourceSize: const Size(1800, 1200),
                )..setView(
                  const Rect.fromLTWH(0, 0, 1800, 1200),
                  terrainOffset: parallax,
                );
            if (kind == null) {
              motion.bees.single
                ..position = origin
                ..depth = depth
                ..rest = 10;
            }
            final leaf = MapLeaf(
              origin,
              depth == 0 ? MapLeafDepth.foreground : MapLeafDepth.air,
              10,
              .3,
              bottom: 2000,
            )..age = 4;
            motion.leaves
              ..clear()
              ..add(leaf);
            Offset animalPosition() => creature == null
                ? motion.bees.single.position
                : motion.creaturePose(creature).position;
            for (var frame = 0; frame < 90; frame++) {
              final before = animalPosition();
              // Co-locate the leaf each frame to compare the force at the same
              // point, without gravity and flutter changing its test position.
              leaf.position = before;
              if (frame == 0 || frame == 12 || frame == 30) {
                final tapDirection = frame == 30 ? -delta : delta;
                final touch = before - tapDirection + parallax * depth;
                motion.tapAt(
                  touch,
                  canopyPosition: touch - parallax,
                  scale: scale,
                );
              }
              motion.advance(1 / 60);
              final leafDrift =
                  Offset(
                    motion.breeze +
                        math.sin(motion.time * 2.2 + leaf.phase) * 15,
                    14 + leaf.size * .4,
                  ) /
                  60;
              final leafPush = leaf.position - before - leafDrift;
              final animalPush = animalPosition() - before;
              expect(
                (animalPush - leafPush).distance,
                lessThan(1e-8),
                reason: '$kind scale=$scale depth=$depth frame=$frame',
              );
              if (frame < 30) {
                expect(animalPush.dx * delta.dx, greaterThan(0));
                expect(animalPush.dy * delta.dy, greaterThan(0));
              }
            }
          }
        }
      }
    }
  });

  test(
    'leaves stay visible in flight and leave only after reaching ground',
    () {
      final motion = MapAmbientMotion(
        seed: 8,
        pinkCanopy: const Offset(295, 265),
        sourceSize: const Size(2052, 644),
      )..setView(const Rect.fromLTWH(0, 0, 620, 644));
      final leaf = motion.leaves.firstWhere(
        (leaf) => leaf.kind == MapLeafKind.pink,
      );
      leaf.age = 100;
      leaf.position = Offset(leaf.position.dx, leaf.bottom - 2);
      motion.setView(const Rect.fromLTWH(1400, 0, 600, 644));
      motion.advance(1 / 60);
      expect(motion.leaves, contains(leaf));
      expect(leaf.opacity, 1);

      leaf.position = Offset(leaf.position.dx, leaf.bottom);
      motion.advance(1 / 60);
      expect(motion.leaves, isNot(contains(leaf)));
    },
  );

  test('a touched bee grows while immediately moving away, then shrinks', () {
    final motion = MapAmbientMotion(seed: 4);
    const view = Rect.fromLTWH(0, 0, 600, 724);
    motion.setView(view);
    final bee = motion.bees.first;
    for (var i = 0; i < 1000 && !bee.perched; i++) {
      motion.advance(1 / 60);
    }
    final origin = bee.position;
    final flower = bee.flower;
    final otherDestination = motion.bees.last.destination;
    expect(motion.startleBeeAt(origin, scale: 1), isTrue);
    expect(bee.perched, isFalse);
    expect(bee.flower, isNot(flower));
    expect((Offset.zero & motion.sourceSize).contains(bee.destination), isTrue);

    expect(motion.bees.last.destination, otherDestination);
    advance(motion, .15);
    expect((bee.position - origin).distance, inExclusiveRange(15, 40));
    expect(bee.visualScale, greaterThan(1.5));
    advance(motion, .3);
    expect((bee.position - origin).distance, inExclusiveRange(20, 75));
    final departingScale = bee.visualScale;
    advance(motion, .2);
    expect(bee.visualScale, lessThan(departingScale));
    advance(motion, 1.5);
    expect((bee.position - origin).distance, inExclusiveRange(20, 110));
    expect(bee.startled, isFalse);
    expect(bee.visualScale, lessThanOrEqualTo(1));
    for (var i = 0; i < 1000 && !bee.perched; i++) {
      motion.advance(1 / 60);
    }
    expect(bee.perched, isTrue);
    expect(bee.flower, isNot(flower));
    expect(
      bee.position,
      MapAmbientMotion.flowers[bee.flower] - const Offset(0, 8),
    );
  });

  test('each ambient creature pops, flees the touch and resumes its route', () {
    for (final kind in MapCreatureKind.values) {
      final creature = MapCreatureDefinition(
        kind: kind,
        center: const Offset(400, 450),
        travel: kind == MapCreatureKind.fish
            ? const Offset(30, 5)
            : const Offset(45, 24),
        size: 30,
      );
      final motion = MapAmbientMotion(
        seed: 4,
        beeCount: 0,
        creatures: [creature],
      )..setView(const Rect.fromLTWH(0, 0, 800, 724));
      final origin = motion.creaturePose(creature);
      expect(
        motion.startleCreatureAt(
          origin.position - const Offset(10, 0),
          scale: 1,
        ),
        isTrue,
        reason: '$kind',
      );
      final immediate = motion.creaturePose(creature);
      expect(immediate.position, origin.position);
      expect(immediate.visualScale, origin.visualScale);
      expect(immediate.startled, isTrue);

      advance(motion, .12);
      final pop = motion.creaturePose(creature);
      expect(
        (pop.position - origin.position).distance,
        greaterThan(1),
        reason: '$kind',
      );
      expect(pop.visualScale, greaterThan(1.2), reason: '$kind');

      advance(motion, .4);
      final escape = motion.creaturePose(creature);
      expect(
        (escape.position - origin.position).distance,
        greaterThan(4),
        reason: '$kind',
      );
      expect(escape.visualScale, lessThan(pop.visualScale), reason: '$kind');

      advance(motion, 2);
      final resumed = motion.creaturePose(creature);
      expect(resumed.startled, isFalse, reason: '$kind');
      if (kind == MapCreatureKind.fish) {
        expect(resumed.visualScale, 1);
        expect(
          resumed.position.dx,
          inInclusiveRange(
            creature.center.dx - creature.travel.dx,
            creature.center.dx + creature.travel.dx,
          ),
        );
      } else {
        expect(resumed.visualScale, inInclusiveRange(.4, 1.0));
        expect(
          resumed.position.dx,
          inInclusiveRange(0, motion.sourceSize.width),
        );
        expect(
          resumed.position.dy,
          inInclusiveRange(0, motion.sourceSize.height),
        );
      }
    }
  });

  test('only direct taps grow animals; nearby taps flee immediately', () {
    for (final kind in MapCreatureKind.values) {
      for (final nearby in [false, true]) {
        final animal = MapCreatureDefinition(
          kind: kind,
          center: const Offset(600, 400),
          travel: const Offset(350, 300),
          size: 30,
        );
        final far = MapCreatureDefinition(
          kind: kind,
          center: const Offset(1100, 400),
          travel: const Offset(30, 18),
          size: 30,
        );
        final motion = MapAmbientMotion(
          seed: 4,
          beeCount: 0,
          creatures: [animal, far],
          sourceSize: const Size(1400, 900),
        )..setView(const Rect.fromLTWH(0, 0, 1400, 900));
        final origin = motion.creaturePose(animal);
        final touch = origin.position - Offset(nearby ? 85 : 10, 0);
        motion.tapAt(touch, canopyPosition: touch, scale: 1);
        final immediate = motion.creaturePose(animal);
        expect(immediate.startled, isTrue, reason: '$kind nearby=$nearby');
        expect(immediate.position, origin.position);
        expect(immediate.visualScale, origin.visualScale);
        expect(immediate.facing, origin.facing);
        expect(immediate.wingBeat, origin.wingBeat);
        var previous = immediate;
        for (var frame = 1; frame <= 135; frame++) {
          motion.advance(1 / 60);
          final pose = motion.creaturePose(animal);
          expect(
            (pose.position - previous.position).distance,
            lessThan(nearby ? 4.2 : 5),
            reason: '$kind nearby=$nearby jumped at frame $frame',
          );
          expect(
            (pose.visualScale - previous.visualScale).abs(),
            lessThan(.32),
          );
          if (frame == 1) {
            expect(
              (pose.position - origin.position).distance,
              greaterThan(2),
              reason: '$kind nearby=$nearby must respond on its first frame',
            );
          }
          if (frame == 9) {
            if (nearby) {
              expect(pose.visualScale, 1);
              expect(
                pose.position.dx - origin.position.dx,
                inExclusiveRange(12, 32),
              );
            } else {
              expect(
                (pose.position - origin.position).distance,
                inExclusiveRange(15, 40),
              );
              expect(pose.visualScale, greaterThan(1.5));
            }
          } else if (frame == 27) {
            expect(
              (pose.position - origin.position).distance,
              inExclusiveRange(20, nearby ? 60 : 75),
            );
          }
          if (pose.startled) {
            expect(
              (pose.position - origin.position).distance,
              // Direct touches get a modest boost; nearby puffs stay unchanged.
              lessThan(nearby ? 100 : 115),
            );
          }
          if (nearby) expect(pose.visualScale, 1);
          previous = pose;
        }
        expect(motion.creaturePose(animal).visualScale, 1);
        expect(motion.creaturePose(animal).startled, isFalse);
        expect(motion.creaturePose(far).startled, isFalse);
      }
    }
  });

  test(
    'one tap grows only the closest animal and scares neighbors across planes',
    () {
      const butterfly = MapCreatureDefinition(
        kind: MapCreatureKind.butterfly,
        center: Offset(400, 400),
        travel: Offset(30, 20),
        size: 30,
      );
      for (final touchBee in [false, true]) {
        final motion =
            MapAmbientMotion(seed: 3, beeCount: 1, creatures: [butterfly])
              ..setView(
                const Rect.fromLTWH(0, 0, 900, 724),
                terrainOffset: const Offset(50, -10),
              );
        final bee = motion.bees.single
          ..position = const Offset(410, 400)
          ..depth = 1
          ..rest = 10;
        final terrainTouch = touchBee ? bee.position : butterfly.center;
        final foregroundTouch = terrainTouch + const Offset(50, -10);
        final leaf = MapLeaf(
          foregroundTouch + const Offset(0, 30),
          MapLeafDepth.foreground,
          10,
          0,
        );
        motion.leaves
          ..clear()
          ..add(leaf);
        motion.tapAt(foregroundTouch, canopyPosition: terrainTouch, scale: 1);
        expect(bee.startled, isTrue);
        expect(motion.creaturePose(butterfly).startled, isTrue);
        expect(leaf.impulse.dy, greaterThan(0));
        expect(motion.gustCount, 1);
        advance(motion, .15);
        expect(
          bee.visualScale,
          touchBee ? greaterThan(1.5) : closeTo(.42, .00001),
        );
        expect(
          motion.creaturePose(butterfly).visualScale,
          touchBee ? 1 : greaterThan(1.5),
        );
        if (touchBee) {
          expect(
            (bee.position - terrainTouch).distance,
            inExclusiveRange(15, 40),
          );
          expect(
            motion.creaturePose(butterfly).position.dx,
            lessThan(butterfly.center.dx),
          );
        } else {
          expect(
            (motion.creaturePose(butterfly).position - terrainTouch).distance,
            inExclusiveRange(15, 40),
          );
          expect(bee.position.dx, greaterThan(410));
        }
      }
    },
  );

  test('nearby escapes are radial for bees and every creature kind', () {
    for (final kind in [null, ...MapCreatureKind.values]) {
      for (final delta in [
        const Offset(-60, -60),
        const Offset(60, -60),
        const Offset(-60, 60),
        const Offset(60, 60),
      ]) {
        final creature = kind == null
            ? null
            : MapCreatureDefinition(
                kind: kind,
                center: const Offset(500, 400),
                travel: const Offset(400, 300),
                size: 30,
              );
        final motion = MapAmbientMotion(
          seed: 9,
          beeCount: kind == null ? 1 : 0,
          creatures: [?creature],
          sourceSize: const Size(1200, 900),
        )..setView(const Rect.fromLTWH(0, 0, 1200, 900));
        const origin = Offset(500, 400);
        if (kind == null) motion.bees.single.position = origin;
        final touch = origin - delta;
        motion.tapAt(touch, canopyPosition: touch, scale: 1);
        advance(motion, .15);
        final position = creature == null
            ? motion.bees.single.position
            : motion.creaturePose(creature).position;
        final movement = position - origin;
        expect(
          movement.dx * delta.dx,
          greaterThan(0),
          reason: '$kind $delta horizontal',
        );
        expect(
          movement.dy * delta.dy,
          greaterThan(0),
          reason: '$kind $delta vertical',
        );
      }
    }
  });

  test('insects roam far beyond their birth routes but favor home', () {
    for (final kind in [
      MapCreatureKind.butterfly,
      MapCreatureKind.dragonfly,
      MapCreatureKind.mayfly,
    ]) {
      const birthplace = Offset(1200, 360);
      final creature = MapCreatureDefinition(
        kind: kind,
        center: birthplace,
        travel: const Offset(35, 18),
        size: 30,
      );
      var farthest = 0.0;
      var nearHome = 0;
      var farFromHome = 0;
      for (var seed = 0; seed < 4; seed++) {
        final motion = MapAmbientMotion(
          seed: seed,
          beeCount: 0,
          creatures: [creature],
          sourceSize: const Size(2400, 724),
        )..setView(const Rect.fromLTWH(850, 0, 700, 724));
        for (var frame = 0; frame < 10800; frame++) {
          motion.advance(1 / 60);
          if (frame % 30 != 0) continue;
          final position = motion.creaturePose(creature).position;
          expect(position.dx, inInclusiveRange(0, motion.sourceSize.width));
          expect(position.dy, inInclusiveRange(0, motion.sourceSize.height));
          final distance = (position - birthplace).distance;
          if (distance > farthest) farthest = distance;
          if (distance < 220) nearHome++;
          if (distance > 500) farFromHome++;
        }
      }
      expect(
        farthest,
        greaterThan(250),
        reason: '$kind should be able to leave its old travel envelope',
      );
      expect(
        nearHome,
        greaterThan(farFromHome),
        reason: '$kind should be easier to find near its birthplace',
      );
    }
  });

  test('a roaming insect can reach a distant panorama region', () {
    const birthplace = Offset(4070, 360);
    const panorama = Size(8142, 724);
    const butterfly = MapCreatureDefinition(
      kind: MapCreatureKind.butterfly,
      center: birthplace,
      travel: Offset(35, 18),
      size: 30,
    );
    var farthestHorizontal = 0.0;
    for (var seed = 0; seed < 8; seed++) {
      final motion = MapAmbientMotion(
        seed: seed,
        beeCount: 0,
        creatures: [butterfly],
        sourceSize: panorama,
      )..setView(const Rect.fromLTWH(3720, 0, 700, 724));
      for (var frame = 0; frame < 36000; frame++) {
        motion.advance(1 / 60);
        if (frame % 30 != 0) continue;
        final horizontal =
            (motion.creaturePose(butterfly).position.dx - birthplace.dx).abs();
        if (horizontal > farthestHorizontal) farthestHorizontal = horizontal;
      }
    }
    expect(
      farthestHorizontal,
      greaterThan(panorama.width * .25),
      reason: 'birthplace should attract insects without becoming a boundary',
    );
  });

  test(
    'insect flight stays continuous across scrolling and touch recovery',
    () {
      for (final kind in [
        MapCreatureKind.butterfly,
        MapCreatureKind.dragonfly,
        MapCreatureKind.mayfly,
      ]) {
        final creature = MapCreatureDefinition(
          kind: kind,
          center: const Offset(900, 360),
          travel: const Offset(35, 18),
          size: 30,
        );
        final motion = MapAmbientMotion(
          seed: 5,
          beeCount: 0,
          creatures: [creature],
          sourceSize: const Size(1800, 724),
        )..setView(const Rect.fromLTWH(600, 0, 600, 724));
        advance(motion, 3);
        final beforeScroll = motion.creaturePose(creature).position;
        final time = motion.time;
        motion.setView(const Rect.fromLTWH(650, 0, 600, 724));
        expect(motion.time, time, reason: '$kind');
        expect(
          motion.creaturePose(creature).position,
          beforeScroll,
          reason: '$kind',
        );

        motion.puff(beforeScroll + const Offset(30, 0), scale: 1);
        expect(motion.creaturePose(creature).startled, isTrue, reason: '$kind');
        expect(
          motion.creaturePose(creature).position,
          beforeScroll,
          reason: '$kind',
        );
        var previous = beforeScroll;
        for (var frame = 0; frame < 150; frame++) {
          motion.advance(1 / 60);
          final current = motion.creaturePose(creature).position;
          expect(
            (current - previous).distance,
            lessThan(25),
            reason: '$kind must not jump during or after a touch escape',
          );
          previous = current;
        }
        expect(
          motion.creaturePose(creature).startled,
          isFalse,
          reason: '$kind',
        );
      }
    },
  );

  test('repeated short scares can gradually leave the birth area', () {
    for (final kind in [
      MapCreatureKind.butterfly,
      MapCreatureKind.dragonfly,
      MapCreatureKind.mayfly,
    ]) {
      final creature = MapCreatureDefinition(
        kind: kind,
        center: const Offset(900, 360),
        travel: const Offset(35, 18),
        size: 30,
      );
      final motion = MapAmbientMotion(
        seed: 6,
        beeCount: 0,
        creatures: [creature],
        sourceSize: const Size(1800, 724),
      )..setView(const Rect.fromLTWH(550, 0, 700, 724));
      for (var touch = 0; touch < 16; touch++) {
        final current = motion.creaturePose(creature).position;
        final left = (current.dx - 350).clamp(0.0, 1100.0);
        motion.setView(Rect.fromLTWH(left, 0, 700, 724));
        motion.puff(current + const Offset(30, 0), scale: 1);
        expect(motion.creaturePose(creature).startled, isTrue, reason: '$kind');
        advance(motion, 1.25);
        expect(
          (motion.creaturePose(creature).position - current).distance,
          lessThan(71),
          reason: '$kind: each escape must stay short',
        );
      }
      final traveled =
          (motion.creaturePose(creature).position - creature.center).distance;
      expect(
        traveled,
        greaterThan(350),
        reason: '$kind should not be fenced into its birth area',
      );
    }
  });

  test(
    'a fish flees within its water patch and may be retouched in flight',
    () {
      const fish = MapCreatureDefinition(
        kind: MapCreatureKind.fish,
        center: Offset(400, 550),
        travel: Offset(20, 5),
        size: 30,
      );
      final motion = MapAmbientMotion(seed: 8, beeCount: 0, creatures: [fish])
        ..setView(const Rect.fromLTWH(0, 0, 800, 724));
      final origin = motion.creaturePose(fish).position;
      expect(
        motion.startleCreatureAt(origin - const Offset(8, 0), scale: 1),
        isTrue,
      );
      advance(motion, .45);
      final beforeRetouch = motion.creaturePose(fish);
      expect(
        motion.startleCreatureAt(
          beforeRetouch.position - const Offset(8, 0),
          scale: 1,
        ),
        isTrue,
      );
      final afterRetouch = motion.creaturePose(fish);
      expect(afterRetouch.position, beforeRetouch.position);
      expect(
        afterRetouch.visualScale,
        closeTo(beforeRetouch.visualScale, .00001),
      );
      for (var frame = 0; frame < 130; frame++) {
        motion.advance(1 / 60);
        final fishPosition = motion.creaturePose(fish).position;
        // Rounded bank curves can accumulate floating-point round-off.
        expect(fishPosition.dx, inInclusiveRange(380 - 1e-9, 420 + 1e-9));
        expect(fishPosition.dy, inInclusiveRange(545 - 1e-9, 555 + 1e-9));
      }
      expect(motion.creaturePose(fish).startled, isFalse);
    },
  );

  test('a fish at the water edge follows the bank instead of reversing', () {
    const fish = MapCreatureDefinition(
      kind: MapCreatureKind.fish,
      center: Offset(400, 550),
      travel: Offset(20, 5),
      size: 30,
      phase: 1.5707963267948966,
    );
    final motion = MapAmbientMotion(seed: 3, beeCount: 0, creatures: [fish])
      ..setView(const Rect.fromLTWH(0, 0, 800, 724));
    final start = motion.creaturePose(fish).position;
    expect(start.dx, closeTo(420, .00001));
    // The click is inside the water, on the fish's left. Its first requested
    // escape direction is right, but the right edge has no room left.
    motion.puff(start - const Offset(8, 0), scale: 1);
    expect(motion.creaturePose(fish).startled, isTrue);
    // The first movement follows the bank vertically, not back toward the tap.
    var firstMovement = start;
    for (var frame = 0; frame < 20 && firstMovement == start; frame++) {
      motion.advance(1 / 60);
      firstMovement = motion.creaturePose(fish).position;
    }
    expect((firstMovement - start).distance, greaterThan(0));
    expect(
      (firstMovement - start).dy.abs(),
      greaterThan((firstMovement - start).dx.abs()),
    );
    for (var frame = 0; frame < 120; frame++) {
      final position = motion.creaturePose(fish).position;
      expect(position.dx, inInclusiveRange(380, 420));
      expect(position.dy, inInclusiveRange(545, 555));
      motion.advance(1 / 60);
    }
  });

  test('the visible tip of a butterfly wing responds to touch', () {
    const butterfly = MapCreatureDefinition(
      kind: MapCreatureKind.butterfly,
      center: Offset(200, 350),
      travel: Offset(20, 10),
      size: 30,
    );
    final motion = MapAmbientMotion(
      seed: 3,
      beeCount: 0,
      creatures: [butterfly],
    )..setView(const Rect.fromLTWH(0, 0, 450, 724));
    final body = motion.creaturePose(butterfly).position;
    expect(
      motion.startleCreatureAt(body + const Offset(30, 0), scale: 1),
      isTrue,
    );
    expect(motion.creaturePose(butterfly).startled, isTrue);
  });

  test('creature touch chooses one visible target, nearest to the finger', () {
    const near = MapCreatureDefinition(
      kind: MapCreatureKind.butterfly,
      center: Offset(200, 350),
      travel: Offset(20, 10),
      size: 28,
    );
    const far = MapCreatureDefinition(
      kind: MapCreatureKind.dragonfly,
      center: Offset(700, 350),
      travel: Offset(20, 10),
      size: 28,
    );
    final motion = MapAmbientMotion(
      seed: 3,
      beeCount: 0,
      creatures: [near, far],
    )..setView(const Rect.fromLTWH(0, 0, 450, 724));
    expect(motion.startleCreatureAt(const Offset(205, 350), scale: 1), isTrue);
    expect(motion.creaturePose(near).startled, isTrue);
    expect(motion.creaturePose(far).startled, isFalse);
    expect(motion.startleCreatureAt(const Offset(700, 350), scale: 1), isFalse);
  });

  test(
    'nearby map taps startle insects and fish outside their hit targets',
    () {
      for (final kind in MapCreatureKind.values) {
        final near = MapCreatureDefinition(
          kind: kind,
          center: const Offset(250, 350),
          travel: kind == MapCreatureKind.fish
              ? const Offset(20, 5)
              : const Offset(25, 12),
          size: 30,
        );
        final far = MapCreatureDefinition(
          kind: kind,
          center: const Offset(650, 350),
          travel: near.travel,
          size: 30,
        );
        final motion = MapAmbientMotion(
          seed: 4,
          beeCount: 0,
          creatures: [near, far],
        )..setView(const Rect.fromLTWH(0, 0, 850, 724));
        final origin = motion.creaturePose(near).position;
        final tap = origin + Offset(kind == MapCreatureKind.fish ? 65 : 85, 0);
        expect(
          motion.startleCreatureAt(tap, scale: 1),
          isFalse,
          reason: '$kind: tap should miss the direct hit target',
        );

        motion.puff(tap, scale: 1);
        expect(motion.creaturePose(near).startled, isTrue, reason: '$kind');
        expect(motion.creaturePose(far).startled, isFalse, reason: '$kind');
        advance(motion, .4);
        expect(
          (motion.creaturePose(near).position - origin).distance,
          greaterThan(5),
          reason: '$kind: nearby creature should visibly flee',
        );
      }
    },
  );

  test(
    'puff radius matches leaves in map coordinates at every screen scale',
    () {
      for (final kind in MapCreatureKind.values) {
        final near = MapCreatureDefinition(
          kind: kind,
          center: const Offset(200, 350),
          travel: const Offset(20, 5),
          size: 30,
        );
        final offscreen = MapCreatureDefinition(
          kind: kind,
          center: const Offset(900, 350),
          travel: const Offset(20, 5),
          size: 30,
        );
        final motion = MapAmbientMotion(
          seed: 4,
          beeCount: 0,
          creatures: [near, offscreen],
        )..setView(const Rect.fromLTWH(0, 0, 500, 724));
        for (final scale in [.5, 1.0, 2.0]) {
          motion.puff(near.center + const Offset(230, 0), scale: scale);
          expect(
            motion.creaturePose(near).startled,
            isFalse,
            reason: '$kind scale=$scale',
          );
        }
        motion.puff(near.center + const Offset(180, 0), scale: 2);
        expect(motion.creaturePose(near).startled, isTrue, reason: '$kind');
        motion.puff(offscreen.center, scale: .5);
        expect(
          motion.creaturePose(offscreen).startled,
          isFalse,
          reason: '$kind: the offscreen creature should remain undisturbed',
        );
      }
    },
  );

  test('puffs use terrain coordinates and can restart an escape', () {
    const butterfly = MapCreatureDefinition(
      kind: MapCreatureKind.butterfly,
      center: Offset(240, 350),
      travel: Offset(25, 12),
      size: 30,
    );
    final motion =
        MapAmbientMotion(seed: 4, beeCount: 0, creatures: [butterfly])..setView(
          const Rect.fromLTWH(50, 0, 400, 724),
          terrainOffset: const Offset(40, 0),
        );
    final origin = motion.creaturePose(butterfly).position;
    motion.puff(
      const Offset(400, 350),
      canopyPosition: origin + const Offset(85, 0),
      scale: 1,
    );
    expect(motion.creaturePose(butterfly).startled, isTrue);
    advance(motion, .4);
    final beforeRetouch = motion.creaturePose(butterfly);
    motion.puff(
      const Offset(400, 350),
      canopyPosition: beforeRetouch.position + const Offset(50, 0),
      scale: 1,
    );
    final afterRetouch = motion.creaturePose(butterfly);
    expect(afterRetouch.position, beforeRetouch.position);
    expect(
      afterRetouch.visualScale,
      closeTo(beforeRetouch.visualScale, .00001),
    );
    advance(motion, .12);
    expect(motion.creaturePose(butterfly).visualScale, 1);
  });

  test(
    'retapping a flying bee preserves its position and size at map edges',
    () {
      for (final left in [0.0, 1812.0]) {
        final motion = MapAmbientMotion(seed: 4);
        final view = Rect.fromLTWH(left, 250, 360, 400);
        motion.setView(view);
        final bee = motion.bees.first;
        for (var i = 0; i < 10; i++) {
          final position = bee.position;
          motion.setView(
            Rect.fromCenter(center: position, width: 500, height: 600),
          );
          final size = bee.visualScale;
          expect(motion.startleBeeAt(position, scale: .6), isTrue);
          expect(bee.position, position);
          expect(bee.visualScale, closeTo(size, .00001));
          expect(
            (Offset.zero & motion.sourceSize).contains(bee.destination),
            isTrue,
          );
          advance(motion, .4);
          // A nearby puff redirects the escape without resetting position or size.
          motion.puff(bee.position + const Offset(50, 0));
          expect(bee.startled, isTrue);
        }
      }
    },
  );

  test('escape headings vary in all directions from the same position', () {
    final directions = <String>{};
    for (var seed = 0; seed < 60; seed++) {
      final motion = MapAmbientMotion(seed: seed)
        ..setView(const Rect.fromLTWH(400, 100, 800, 600));
      final bee = motion.bees.first..position = const Offset(800, 470);
      motion.startleBeeAt(bee.position, scale: 1);
      final delta = bee.impulse;
      directions.add(delta.dx < 0 ? 'left' : 'right');
      directions.add(delta.dy < 0 ? 'up' : 'down');
    }
    expect(directions, containsAll(['left', 'right', 'up', 'down']));
  });

  test('bees stay small on distant flowers and grow again when touched', () {
    final motion = MapAmbientMotion(seed: 6)
      ..setView(const Rect.fromLTWH(0, 0, 900, 724));
    final bee = motion.bees.first;
    // Let the ordinary flower route reach the background naturally.
    for (
      var frame = 0;
      frame < 18000 && !(bee.perched && bee.depth == 1);
      frame++
    ) {
      motion.advance(1 / 60);
    }
    expect(bee.perched, isTrue);
    expect(bee.depth, 1);
    expect(bee.visualScale, closeTo(.42, .00001));
    final landing = bee.position;
    motion.setView(
      const Rect.fromLTWH(0, 0, 900, 724),
      terrainOffset: const Offset(50, -10),
    );
    expect(motion.beePosition(bee), landing + const Offset(50, -10));
    expect(
      motion.startleBeeAt(
        motion.beePosition(bee) + const Offset(23, 0),
        scale: 1,
      ),
      isTrue,
    );
    advance(motion, .15);
    expect((bee.position - landing).distance, inExclusiveRange(15, 40));
    expect(bee.visualScale, greaterThan(1.5));
  });

  test(
    'long play, repeated taps and scrolling keep finite bounded populations',
    () {
      final motion = MapAmbientMotion(seed: 7);
      var visibleLeaves = 0;
      for (var frame = 0; frame < 18000; frame++) {
        final left = (frame ~/ 600 % 6) * 310.0;
        motion.setView(Rect.fromLTWH(left, 0, 500, 724));
        if (frame % 2 == 0) motion.puff(Offset(left + 240, 560));
        motion.advance(1 / 60);
        expect(motion.bees, hasLength(2));
        expect(
          motion.leaves.length,
          lessThanOrEqualTo(MapAmbientMotion.maxLeaves),
        );
        expect(motion.gustCount, lessThanOrEqualTo(MapAmbientMotion.maxGusts));
        for (final leaf in motion.leaves) {
          expect(
            leaf.position.dx.isFinite && leaf.position.dy.isFinite,
            isTrue,
          );
          expect(leaf.opacity, inInclusiveRange(0, 1));
          if (leaf.opacity > .8) visibleLeaves++;
        }
        for (final bee in motion.bees) {
          expect(bee.position.dx.isFinite && bee.position.dy.isFinite, isTrue);
        }
      }
      expect(visibleLeaves, greaterThan(100));
    },
  );

  test('bees rest on real flowers and visit different blossoms', () {
    final motion = MapAmbientMotion(seed: 12);
    motion.setView(const Rect.fromLTWH(0, 0, 1100, 724));
    final visited = <int>{};
    for (var i = 0; i < 6000; i++) {
      motion.advance(1 / 60);
      for (final bee in motion.bees.where((bee) => bee.perched)) {
        visited.add(bee.flower);
        expect(
          (bee.position -
                  (MapAmbientMotion.flowers[bee.flower] - const Offset(0, 8)))
              .distance,
          lessThan(.001),
        );
      }
    }
    expect(visited.length, greaterThan(2));
  });

  test(
    'a nearby touch interrupts rest, fades its gust, then returns to a flower',
    () {
      final motion = MapAmbientMotion(seed: 4);
      motion.setView(const Rect.fromLTWH(0, 0, 600, 724));
      final bee = motion.bees.first;
      for (var i = 0; i < 1000 && !bee.perched; i++) {
        motion.advance(1 / 60);
      }
      expect(bee.perched, isTrue);
      final flower = bee.position;
      final touch = flower + const Offset(-10, 12);
      motion.puff(touch);
      expect(bee.perched, isFalse);
      expect(motion.windAt(touch).distance, greaterThan(motion.breeze));
      advance(motion, .8);
      expect((bee.position - flower).distance, greaterThan(20));
      advance(motion, 1.4);
      expect(motion.gustCount, 0);
      expect(motion.windAt(touch), Offset(motion.breeze, 0));
      for (var i = 0; i < 1000 && !bee.perched; i++) {
        motion.advance(1 / 60);
      }
      expect(bee.perched, isTrue);
      expect((bee.position - flower).distance, lessThan(.001));
    },
  );

  test('puffs use the correct position in each parallax plane', () {
    final motion = MapAmbientMotion(seed: 4);
    motion.setView(const Rect.fromLTWH(0, 0, 1000, 724));
    const front = Offset(800, 600);
    const canopy = Offset(500, 500);
    motion.puff(front, canopyPosition: canopy);
    expect(motion.windAt(front, foreground: true).dy, lessThan(-30));
    expect(motion.windAt(canopy).dy, lessThan(-30));
    expect(motion.windAt(front).dy, 0);
  });

  test(
    'view changes retain visible world positions and never advance time',
    () {
      final motion = MapAmbientMotion(seed: 4);
      motion.setView(const Rect.fromLTWH(0, 0, 600, 724));
      advance(motion, 2);
      final bee = motion.bees.first;
      final position = bee.position;
      final leaf = motion.leaves.first;
      final leafPosition = leaf.position;
      final time = motion.time;
      motion.setView(const Rect.fromLTWH(30, -8, 650, 740));
      expect(bee.position, position);
      expect(leaf.position, leafPosition);
      expect(motion.time, time);
      motion.advance(100);
      expect(motion.time - time, closeTo(.05, .00001));
    },
  );
}
