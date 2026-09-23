import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/models/map_ambient_motion.dart';

void advance(MapAmbientMotion motion, double seconds) {
  for (var i = 0; i < (seconds * 60).ceil(); i++) {
    motion.advance(1 / 60);
  }
}

void main() {
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
