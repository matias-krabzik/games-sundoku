import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/world_overview.dart';
import 'package:sundoku/models/world_overview_fog.dart';
import 'package:sundoku/models/world_overview_camera.dart';

void main() {
  test('fog pieces drift right at distinct speeds without a gap at wrap', () {
    const region = Rect.fromLTWH(20, 30, 400, 360);
    final speeds = <double>{};
    for (final band in overviewFogBands) {
      speeds.add(band.speed);
      final start = band.pieces(region, 0, 3).toList();
      final later = band.pieces(region, .01, 3).toList();
      expect(later.first.left, greaterThan(start.first.left));
      for (final time in [0.0, 1.0, 30.0, 90.0, 1000.0]) {
        final pieces = band.pieces(region, time, 3).toList();
        expect(pieces.first.left, lessThan(region.left));
        expect(pieces.last.right, greaterThan(region.right));
        for (var i = 1; i < pieces.length; i++) {
          expect(pieces[i].left, lessThan(pieces[i - 1].right));
        }
      }
    }
    expect(speeds.length, overviewFogBands.length);
    expect(
      overviewFogBands.map((b) => b.texture).toSet(),
      OverviewFogTexture.values.toSet(),
    );
  });

  test('fog tiles keep their size and drift when the painting zooms', () {
    const viewport = Size(390, 844);
    final camera = WorldOverviewCamera(
      revealedWorlds: {'world-1'},
      initialWorld: 'world-1',
    );
    addTearDown(camera.dispose);
    camera.configure(
      viewport,
      const Rect.fromLTWH(16, 90, 358, 730),
      const WorldOverview(false),
    );
    final painting = camera.image;
    final before = [
      for (final band in overviewFogBands)
        band.screenPieces(viewport, 10, 3).toList(),
    ];
    camera.beginGesture(const Offset(195, 420));
    camera.updateGesture(const Offset(195, 420), 1.6);
    expect(camera.image.width, greaterThan(painting.width));
    for (final (i, band) in overviewFogBands.indexed) {
      final after = band.screenPieces(viewport, 10, 3).toList();
      expect(after, before[i]);
      final later = band.screenPieces(viewport, 10.01, 3).first;
      expect(
        later.left - after.first.left,
        closeTo(.01 * band.speed * viewport.shortestSide * 1.2, .00001),
      );
    }
    final coverage = before.expand((pieces) => pieces);
    for (final y in [0.0, 200.0, 500.0, 844.0]) {
      expect(
        coverage.any((piece) => piece.top <= y && piece.bottom >= y),
        isTrue,
      );
    }
  });

  test('fog covers only unrevealed map zones in both orientations', () {
    for (final landscape in [false, true]) {
      final overview = WorldOverview(landscape);
      for (var i = 1; i < 3; i++) {
        final region = overview.fogRegions['world-${i + 1}']!;
        expect(region.contains(overview.destinations[i]), isTrue);
        expect(region.contains(overview.destinations[0]), isFalse);
      }
      expect(
        overview.fogRegions['world-3']!.contains(overview.destinations[1]),
        isFalse,
      );
    }
  });
}
