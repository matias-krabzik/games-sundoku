import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/widgets/victory_particles.dart';

Future<({int visible, int positions})> pixels(
  WidgetTester tester,
  GlobalKey boundaryKey,
) async => (await tester.runAsync(() async {
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
      .buffer
      .asUint8List();
  image.dispose();
  var visible = 0;
  var positions = 0;
  for (var offset = 3; offset < bytes.length; offset += 4) {
    if (bytes[offset] > 0) {
      visible++;
      positions += offset;
    }
  }
  return (visible: visible, positions: positions);
}))!;

void main() {
  testWidgets(
    'continuous particles differ in intensity, move, and never intercept taps',
    (tester) async {
      final counts = <int>[];
      for (final finale in [false, true]) {
        final entrance = AnimationController(vsync: tester, value: 0);
        final boundary = GlobalKey();
        var taps = 0;
        Widget scene() => Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: Center(
              child: RepaintBoundary(
                key: boundary,
                child: SizedBox(
                  width: 358,
                  height: 430,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => taps++,
                    child: VictoryParticles(
                      entrance: entrance,
                      grandFinale: finale,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpWidget(scene());
        expect((await pixels(tester, boundary)).visible, 0);
        entrance.value = .49;
        await tester.pump(const Duration(milliseconds: 100));
        expect((await pixels(tester, boundary)).visible, 0);
        entrance.value = .5;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));
        final first = await pixels(tester, boundary);
        expect(first.visible, greaterThan(0));
        counts.add(first.visible);
        await tester.tapAt(tester.getCenter(find.byType(VictoryParticles)));
        expect(taps, 1);
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          (await pixels(tester, boundary)).positions,
          isNot(first.positions),
        );
        // Finishing the entrance and rebuilding keep the celebration alive.
        entrance.value = 1;
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpWidget(scene());
        await tester.pump(const Duration(milliseconds: 500));
        expect((await pixels(tester, boundary)).visible, greaterThan(0));
        await tester.pump(const Duration(seconds: 25));
        expect((await pixels(tester, boundary)).visible, greaterThan(0));
        await tester.pumpWidget(const SizedBox());
        entrance.dispose();
      }
      expect(counts.last, greaterThan(counts.first * 3));
    },
  );

  testWidgets('restored rewards resume rain while reduced motion disables it', (
    tester,
  ) async {
    for (final reduced in [false, true]) {
      final entrance = AnimationController(
        vsync: tester,
        value: reduced ? 0 : 1,
      );
      final boundary = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: Center(
              child: RepaintBoundary(
                key: boundary,
                child: SizedBox(
                  width: 358,
                  height: 430,
                  child: VictoryParticles(
                    entrance: entrance,
                    grandFinale: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      entrance.value = 1;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(
        (await pixels(tester, boundary)).visible,
        reduced ? 0 : greaterThan(0),
      );
      await tester.pumpWidget(const SizedBox());
      entrance.dispose();
    }
  });
}
