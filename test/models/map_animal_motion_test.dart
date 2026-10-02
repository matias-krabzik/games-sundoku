import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/models/map_animal_motion.dart';
import 'package:sundoku/models/map_radial_puff.dart';

class _Animal extends MapAnimalMotion {
  _Animal(super.position);
}

void advanceAnimal(MapAnimalMotion animal, double seconds) {
  for (var frame = 0; frame < (seconds * 60).ceil(); frame++) {
    animal.advanceEscape(1 / 60);
  }
}

void main() {
  const bounds = Rect.fromLTWH(0, 0, 2000, 2000);
  const origin = Offset(1000, 1000);

  test(
    'short escapes react on the first frame and continuously lose speed',
    () {
      for (final direct in [false, true]) {
        for (var seed = 0; seed < 20; seed++) {
          final animal = _Animal(origin)
            ..flee(
              touch: origin - const Offset(60, 0),
              bounds: bounds,
              random: math.Random(seed),
              direct: direct,
            );
          final steps = <double>[];
          var previous = origin;
          for (var frame = 0; frame < 150 && animal.startled; frame++) {
            animal.advanceEscape(1 / 60);
            final step = (animal.position - previous).distance;
            steps.add(step);
            previous = animal.position;
          }
          expect(animal.startled, isFalse);
          expect(
            (animal.position - origin).distance,
            inExclusiveRange(direct ? 75 : 20, direct ? 110 : 30),
          );
          expect(
            steps.first,
            inExclusiveRange(direct ? 4 : 1, direct ? 5 : 1.5),
          );
          expect(steps.last, lessThan(.15));
          for (var frame = 1; frame < steps.length; frame++) {
            expect(steps[frame], lessThan(steps[frame - 1]));
          }
        }
      }
    },
  );

  test('off-center direct taps choose every direction and travel moderately farther', () {
    final quadrants = <String>{};
    final touch = origin - const Offset(10, 0);
    for (var seed = 0; seed < 40; seed++) {
      final direct = _Animal(origin)
        ..flee(
          touch: touch,
          bounds: bounds,
          random: math.Random(seed),
          direct: true,
        );
      final nearby = _Animal(origin)
        ..flee(
          touch: touch,
          bounds: bounds,
          random: math.Random(seed),
          direct: false,
        );
      final heading = direct.impulse / direct.impulse.distance;
      quadrants.add('${heading.dx.sign},${heading.dy.sign}');
      for (var frame = 1; frame <= 120; frame++) {
        final gust = MapRadialPuff.gustAt(nearby.position, touch, frame / 60);
        nearby.advanceEscape(1 / 60, gust: gust);
        direct.advanceEscape(1 / 60, gust: const Offset(95, 0));
        final movement = direct.position - origin;
        expect(
          movement.dx * heading.dy - movement.dy * heading.dx,
          closeTo(0, 1e-8),
          reason: 'radial gusts must not override a direct tap heading',
        );
      }
      final ratio =
          (direct.position - origin).distance /
          (nearby.position - origin).distance;
      expect(ratio, inExclusiveRange(1.15, 1.6));
    }
    expect(quadrants.length, 4);
  });

  test('noncentral touches push along the exact radial direction', () {
    for (var seed = 0; seed < 60; seed++) {
      for (final delta in [
        const Offset(-60, -60),
        const Offset(60, -60),
        const Offset(-60, 60),
        const Offset(60, 60),
        const Offset(1, 100),
        const Offset(100, -1),
      ]) {
        final animal = _Animal(origin)
          ..flee(
            touch: origin - delta,
            bounds: bounds,
            random: math.Random(seed),
            direct: false,
          );
        animal.advanceEscape(.05);
        final movement = animal.position - origin;
        expect(movement.dx * delta.dx, greaterThan(0));
        expect(movement.dy * delta.dy, greaterThan(0));
        expect(animal.visualScale, 1);
        expect(
          movement.dx * delta.dy - movement.dy * delta.dx,
          closeTo(0, 1e-8),
        );
      }
    }
  });

  test('retouching preserves position and scale while restarting the pop', () {
    final random = math.Random(5);
    final animal = _Animal(origin)
      ..flee(touch: origin, bounds: bounds, random: random, direct: true);
    advanceAnimal(animal, .15);
    expect((animal.position - origin).distance, inExclusiveRange(25, 40));
    expect(animal.visualScale, greaterThan(1.5));
    advanceAnimal(animal, .3);
    expect((animal.position - origin).distance, inExclusiveRange(50, 75));
    final beforePosition = animal.position;
    final beforeScale = animal.visualScale;
    animal.flee(
      touch: beforePosition,
      bounds: bounds,
      random: random,
      direct: true,
    );
    expect(animal.position, beforePosition);
    expect(animal.visualScale, beforeScale);
    advanceAnimal(animal, .12);
    expect(
      (animal.position - beforePosition).distance,
      inExclusiveRange(20, 35),
    );
    expect(animal.visualScale, greaterThan(beforeScale));
    advanceAnimal(animal, 2.2);
    expect(animal.startled, isFalse);
    expect(animal.visualScale, 1);
  });

  test('nearby retouch redirects an escape without another growth pulse', () {
    final random = math.Random(3);
    final animal = _Animal(origin)
      ..flee(touch: origin, bounds: bounds, random: random, direct: true);
    advanceAnimal(animal, .15);
    final scale = animal.visualScale;
    animal.flee(
      touch: animal.position - const Offset(0, 80),
      bounds: bounds,
      random: random,
      direct: false,
    );
    expect(animal.visualScale, scale);
    animal.advanceEscape(.05);
    expect(animal.visualScale, lessThan(scale));
    expect(animal.position.dy, greaterThan(origin.dy));
  });

  test('an outward escape at a bank follows it without bouncing inward', () {
    const water = Rect.fromLTWH(200, 400, 160, 80);
    const start = Offset(360, 440);
    final path = AnimalEscapePath.alongBank(
      start,
      const Offset(1, 0),
      25,
      water,
      math.Random(2),
    );
    expect(path.at(0), start);
    expect(path.at(.2).dx, 360);
    expect((path.at(.2).dy - start.dy).abs(), greaterThan(0));
    expect(path.end.dx, 360);
    expect((path.end - start).distance, closeTo(25, .00001));
  });

  test('rounded bank paths stay continuous and inside water at all edges', () {
    const water = Rect.fromLTWH(200, 400, 160, 80);
    for (final start in [
      water.center,
      water.topLeft,
      water.topRight,
      water.bottomLeft,
      water.bottomRight,
      const Offset(360, 440),
    ]) {
      for (var angle = 0; angle < 32; angle++) {
        final path = AnimalEscapePath.alongBank(
          start,
          Offset.fromDirection(angle * math.pi / 16),
          320,
          water,
          math.Random(angle),
        );
        var previous = start;
        for (var step = 0; step <= 200; step++) {
          final point = path.at(step / 200);
          expect(
            point.dx,
            inInclusiveRange(water.left - 1e-9, water.right + 1e-9),
          );
          expect(
            point.dy,
            inInclusiveRange(water.top - 1e-9, water.bottom + 1e-9),
          );
          expect((point - previous).distance, lessThan(1.1));
          previous = point;
        }
      }
    }
  });
}
