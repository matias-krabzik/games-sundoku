import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/models/map_ambient_motion.dart';

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

  test('a touched bee grows in place, then shrinks as it flies away', () {
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
    expect(view.contains(bee.destination), isTrue);
    expect(motion.bees.last.destination, otherDestination);
    advance(motion, .15);
    expect(bee.position, origin);
    expect(bee.visualScale, greaterThan(1.5));
    advance(motion, .3);
    expect((bee.position - origin).distance, greaterThan(50));
    final departingScale = bee.visualScale;
    advance(motion, .2);
    expect(bee.visualScale, lessThan(departingScale));
    advance(motion, .5);
    expect((bee.position - origin).distance, greaterThan(100));
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
          final size = bee.visualScale;
          expect(motion.startleBeeAt(position, scale: .6), isTrue);
          expect(bee.position, position);
          expect(bee.visualScale, closeTo(size, .00001));
          expect(view.contains(bee.destination), isTrue);
          advance(motion, .4);
          // A nearby map puff must not cancel the direct-touch reaction.
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
      final delta = bee.destination - bee.origin;
      directions.add(delta.dx < 0 ? 'left' : 'right');
      directions.add(delta.dy < 0 ? 'up' : 'down');
    }
    expect(directions, containsAll(['left', 'right', 'up', 'down']));
  });

  test('bees stay small on distant flowers and grow again when touched', () {
    var distantLandings = 0;
    for (var seed = 0; seed < 20; seed++) {
      final motion = MapAmbientMotion(seed: seed)
        ..setView(const Rect.fromLTWH(0, 0, 900, 724));
      final bee = motion.bees.first;
      motion.startleBeeAt(bee.position, scale: 1);
      if (bee.flower < MapAmbientMotion.foregroundFlowerCount ||
          bee.destination !=
              MapAmbientMotion.flowers[bee.flower] - const Offset(0, 8)) {
        continue;
      }
      advance(motion, .3);
      var previousScale = bee.visualScale;
      for (var frame = 0; frame < 90 && !bee.perched; frame++) {
        motion.advance(1 / 60);
        expect(bee.visualScale, lessThanOrEqualTo(previousScale + .00001));
        previousScale = bee.visualScale;
      }
      expect(bee.perched, isTrue);
      expect(bee.visualScale, closeTo(.42, .00001));
      final landing = bee.position;
      // Terrain movement carries perched bees and their finger-sized targets.
      motion.setView(
        const Rect.fromLTWH(0, 0, 900, 724),
        terrainOffset: const Offset(50, -10),
      );
      expect(motion.beePosition(bee), landing + const Offset(50, -10));
      advance(motion, .3);
      expect(bee.position, landing);
      expect(bee.visualScale, closeTo(.42, .00001));
      expect(
        motion.startleBeeAt(
          motion.beePosition(bee) + const Offset(23, 0),
          scale: 1,
        ),
        isTrue,
      );
      advance(motion, .15);
      expect(bee.position, landing);
      expect(bee.visualScale, greaterThan(1.5));
      distantLandings++;
    }
    expect(distantLandings, greaterThan(0));
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
