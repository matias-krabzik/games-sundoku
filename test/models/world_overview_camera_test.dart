import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:sundoku/data/world_overview.dart';
import 'package:sundoku/models/world_overview_camera.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1210, 834)]) {
    final landscape = size.width > size.height;
    test('camera explores both axes within discovered land at $size', () {
      final camera = WorldOverviewCamera(
        revealedWorlds: {'world-1'},
        initialWorld: 'world-1',
      );
      addTearDown(camera.dispose);
      camera.configure(
        size,
        Rect.fromLTWH(16, 90, size.width - 32, size.height - 110),
        WorldOverview(landscape),
      );
      final start = camera.center;
      camera.pan(const Offset(-30, 30));
      expect(camera.center.dx, isNot(start.dx));
      expect(camera.center.dy, isNot(start.dy));
      // All four drag extremes stay inside the painting, with the discovery
      // frontier stopping the camera before the next destination.
      for (final delta in [const Offset(1e5, 1e5), const Offset(-1e5, -1e5)]) {
        camera.pan(delta);
        expect(camera.image.left, lessThanOrEqualTo(.001));
        expect(camera.image.top, lessThanOrEqualTo(.001));
        expect(camera.image.right, greaterThanOrEqualTo(size.width - .001));
        expect(camera.image.bottom, greaterThanOrEqualTo(size.height - .001));
        if (landscape) {
          expect(camera.center.dx, lessThanOrEqualTo(.32));
        } else {
          expect(camera.center.dy, greaterThanOrEqualTo(.61));
        }
      }
      camera.reducedMotion = true;
      camera.discover({'world-1', 'world-2'});
      camera.pan(const Offset(-1e5, 1e5));
      if (landscape) {
        expect(camera.center.dx, closeTo(.65, .001));
      } else {
        expect(camera.center.dy, closeTo(.30, .001));
      }
    });
  }

  test(
    'entry remains selected after centering, dragging and background taps',
    () {
      final camera = WorldOverviewCamera(
        revealedWorlds: {'world-1', 'world-2', 'world-3'},
        initialWorld: 'world-1',
      );
      addTearDown(camera.dispose);
      camera.configure(
        const Size(390, 844),
        const Rect.fromLTWH(16, 96, 358, 712),
        const WorldOverview(false),
        anchorOffset: 84,
      );
      expect(camera.centeredWorld, 'world-1');
      camera.focusWorld('world-2');
      expect(camera.focusedWorld, 'world-2');
      expect(camera.centeredWorld, isNull);
      camera.advance(.3);
      expect(camera.centeredWorld, isNull);
      camera.advance(.3);
      expect(camera.centeredWorld, 'world-2');
      camera.beginGesture(const Offset(195, 420));
      expect(camera.centeredWorld, 'world-2');
      expect(camera.entryWorld, 'world-2');
      camera.updateGesture(const Offset(165, 460), 1);
      camera.endGesture(Offset.zero);
      expect(camera.centeredWorld, isNull);
      expect(camera.entryWorld, 'world-2');
      camera.focusWorld('world-2', animate: false);
      expect(camera.centeredWorld, 'world-2');
      camera.pan(const Offset(0, 30));
      expect(camera.centeredWorld, isNull);
      camera.focusWorld('world-3', animate: false);
      expect(camera.centeredWorld, 'world-3');
      camera.focusWorld('world-3');
      expect(
        camera.centeredWorld,
        'world-3',
        reason: 'Reselecting the centered card must not hide its entry',
      );
    },
  );

  test(
    'all destinations really center at the viewport target without blank edges',
    () {
      for (final size in [
        const Size(390, 844),
        const Size(568, 320),
        const Size(834, 1210),
        const Size(1210, 834),
      ]) {
        final overview = WorldOverview(size.width > size.height * 1.12);
        final camera = WorldOverviewCamera(
          revealedWorlds: {'world-1', 'world-2', 'world-3'},
          initialWorld: 'world-1',
        );
        final usable = Rect.fromLTRB(16, 96, size.width - 16, size.height - 36);
        const offset = 65.0;
        camera.configure(size, usable, overview, anchorOffset: offset);
        for (var i = 0; i < 3; i++) {
          camera.focusWorld('world-${i + 1}');
          camera.advance(.6);
          final point = overview.project(
            overview.destinations[i],
            camera.image,
          );
          expect(
            (point + const Offset(0, offset) - usable.center).distance,
            lessThan(.01),
            reason: 'world-${i + 1} at $size',
          );
          expect(camera.image.left, lessThanOrEqualTo(.001));
          expect(camera.image.top, lessThanOrEqualTo(.001));
          expect(camera.image.right, greaterThanOrEqualTo(size.width - .001));
          expect(camera.image.bottom, greaterThanOrEqualTo(size.height - .001));
        }
        camera.dispose();
      }
    },
  );

  test('small taps preserve selection and inertia decays independently of frame rate', () {
    WorldOverviewCamera setup() {
      final camera = WorldOverviewCamera(
        revealedWorlds: {'world-1', 'world-2', 'world-3'},
        initialWorld: 'world-2',
      );
      camera.configure(
        const Size(390, 844),
        const Rect.fromLTWH(16, 96, 358, 712),
        const WorldOverview(false),
      );
      return camera;
    }

    final a = setup();
    final b = setup();
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    final initial = a.center;
    a.beginGesture(const Offset(200, 200));
    a.updateGesture(const Offset(201, 201), 1);
    a.endGesture(Offset.zero);
    expect(a.center, initial);
    expect(a.entryWorld, 'world-2');
    for (final camera in [a, b]) {
      camera.beginGesture(const Offset(200, 200));
      camera.updateGesture(const Offset(175, 175), 1);
      camera.endGesture(const Offset(-700, -700));
    }
    final released = a.center;
    a.advance(0);
    expect(
      a.animating,
      isTrue,
      reason: 'The first ticker frame must preserve inertia',
    );
    a.advance(.2);
    for (var i = 0; i < 10; i++) {
      b.advance(.02);
    }
    expect((a.center - b.center).distance, lessThan(.00001));
    expect((a.center - released).distance, greaterThan(0));
    a.stopInertia();
    final stopped = a.center;
    a.advance(1);
    expect(a.center, stopped);
    expect(a.entryWorld, 'world-2');
  });

  test(
    'resizing during centering recomputes the target for the new window',
    () {
      final camera = WorldOverviewCamera(
        revealedWorlds: {'world-1', 'world-2', 'world-3'},
        initialWorld: 'world-1',
      );
      addTearDown(camera.dispose);
      camera.configure(
        const Size(390, 844),
        const Rect.fromLTWH(16, 96, 358, 712),
        const WorldOverview(false),
      );
      camera.focusWorld('world-3');
      camera.advance(.2);
      const usable = Rect.fromLTWH(16, 96, 400, 760);
      const overview = WorldOverview(false);
      camera.configure(const Size(432, 892), usable, overview);
      camera.advance(.6);
      final point = overview.project(overview.destinations.last, camera.image);
      expect(
        (point + const Offset(0, 40) - usable.center).distance,
        lessThan(.01),
      );
      expect(camera.entryWorld, 'world-3');
    },
  );

  test('pinch keeps its map point beneath the fingers and clamps zoom', () {
    final camera = WorldOverviewCamera(
      revealedWorlds: {'world-1', 'world-2', 'world-3'},
      initialWorld: 'world-2',
    );
    addTearDown(camera.dispose);
    camera.configure(
      const Size(390, 844),
      const Rect.fromLTWH(16, 90, 358, 730),
      const WorldOverview(false),
    );
    const focal = Offset(175, 360);
    Offset normalized() => Offset(
      (focal.dx - camera.image.left) / camera.image.width,
      (focal.dy - camera.image.top) / camera.image.height,
    );
    final before = normalized();
    camera.beginGesture(focal);
    camera.updateGesture(focal, 1.3);
    expect((normalized() - before).distance, lessThan(.00001));
    camera.updateGesture(focal, 100);
    expect(camera.zoom, WorldOverviewCamera.maxZoom);
    camera.updateGesture(focal, .001);
    expect(camera.zoom, camera.minZoom);
  });

  test(
    'discovery lifts fog first and brings in the destination afterwards',
    () {
      final camera = WorldOverviewCamera(
        revealedWorlds: {'world-1'},
        initialWorld: 'world-1',
      );
      addTearDown(camera.dispose);
      camera.configure(
        const Size(390, 844),
        const Rect.fromLTWH(16, 90, 358, 730),
        const WorldOverview(false),
      );
      final initial = camera.center;
      camera.discover({'world-1', 'world-2'});
      expect(camera.discovery['world-2'], 0);
      camera.advance(.5);
      final middle = camera.discovery['world-2']!;
      expect(camera.center.dy, lessThan(initial.dy));
      expect(OverviewDiscovery.lift(middle), greaterThan(0));
      expect(OverviewDiscovery.arrival(middle), 0);
      camera.advance(.7);
      final arrival = camera.discovery['world-2']!;
      expect(OverviewDiscovery.lift(arrival), 1);
      expect(OverviewDiscovery.arrival(arrival), greaterThan(0));
      expect(OverviewDiscovery.arrival(arrival), lessThan(1));
      camera.advance(.4);
      expect(camera.revealedWorlds, {'world-1', 'world-2'});
      expect(camera.animating, isFalse);
      camera.discover({'world-1', 'world-2'});
      expect(
        camera.animating,
        isFalse,
        reason: 'Progress changes must not replay discovery',
      );
    },
  );

  test(
    'reduced motion reveals immediately, with drag and zoom still available',
    () {
      final camera = WorldOverviewCamera(
        revealedWorlds: {'world-1'},
        initialWorld: 'world-1',
      )..reducedMotion = true;
      addTearDown(camera.dispose);
      camera.configure(
        const Size(390, 844),
        const Rect.fromLTWH(16, 90, 358, 730),
        const WorldOverview(false),
      );
      camera.discover({'world-1', 'world-2'});
      expect(camera.revealedWorlds, {'world-1', 'world-2'});
      expect(camera.animating, isFalse);
      final position = camera.center;
      camera.pan(const Offset(20, 20));
      expect(camera.center, isNot(position));
      camera.endGesture(const Offset(1000, 1000));
      expect(camera.animating, isFalse);
    },
  );
}
