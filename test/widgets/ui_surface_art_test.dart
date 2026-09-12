import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/widgets/ui_surface_art.dart';

Future<Uint8List> _pixels(
  WidgetTester tester,
  UiSurface surface,
  Size size,
) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: key,
          child: SizedBox.fromSize(size: size, child: UiSurfaceArt(surface)),
        ),
      ),
    ),
  );
  await tester.runAsync(
    () => precacheImage(AssetImage(surface.spec.asset), key.currentContext!),
  );
  await tester.pump();
  return (await tester.runAsync(() async {
    final image =
        await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  }))!;
}

void main() {
  testWidgets(
    'cards grow in two axes without enlarging the illustrated corners',
    (tester) async {
      for (final surface in [
        UiSurface.creamPanel,
        UiSurface.goldCreamPanel,
        UiSurface.goldTile,
        UiSurface.creamTile,
        UiSurface.creamPill,
        UiSurface.goldButton,
      ]) {
        const small = Size(300, 90);
        const large = Size(380, 250);
        final before = await _pixels(tester, surface, small);
        final after = await _pixels(tester, surface, large);
        // Compare the actual rendered top corners, including alpha, rather than
        // checking that the widget happens to use a centerSlice property.
        for (final right in [false, true]) {
          final spec = surface.spec;
          final cornerWidth =
              spec.referenceSize.width *
              (right
                  ? spec.region.right - spec.centerSlice.right
                  : spec.centerSlice.left - spec.region.left) /
              spec.region.width;
          final cornerHeight =
              spec.referenceSize.height *
              (spec.centerSlice.top - spec.region.top) /
              spec.region.height;
          // Stay inside the fixed cap, away from the resampled center seam.
          final pixelsWide = math.min(40, (cornerWidth * 2).floor() - 2);
          final pixelsHigh = math.min(22, (cornerHeight * 2).floor() - 2);
          for (var y = 0; y < pixelsHigh; y++) {
            for (var x = 0; x < pixelsWide; x++) {
              final bx = right ? small.width.toInt() * 2 - 1 - x : x;
              final ax = right ? large.width.toInt() * 2 - 1 - x : x;
              for (var channel = 0; channel < 4; channel++) {
                final b =
                    before[(y * small.width.toInt() * 2 + bx) * 4 + channel];
                final a =
                    after[(y * large.width.toInt() * 2 + ax) * 4 + channel];
                expect(
                  (a - b).abs(),
                  lessThanOrEqualTo(2),
                  reason: '$surface corner at $x,$y',
                );
              }
            }
          }
        }
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'empty and tiny progress fills paint safely with loaded artwork',
    (tester) async {
      for (final surface in [UiSurface.progressTrack, UiSurface.progressFill]) {
        for (final width in [0.0, .1, 1.0, 4.0, 8.0, 160.0]) {
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: SizedBox(
                  width: width,
                  height: 8,
                  child: UiSurfaceArt(surface),
                ),
              ),
            ),
          );
          await tester.runAsync(
            () => precacheImage(
              AssetImage(surface.spec.asset),
              tester.element(find.byType(UiSurfaceArt)),
            ),
          );
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: '$surface at width $width',
          );
        }
      }
    },
  );

  testWidgets(
    'round button skins keep transparent corners at all control sizes',
    (tester) async {
      for (final surface in [UiSurface.creamRound, UiSurface.goldRound]) {
        for (final side in [29.0, 46.0, 54.0, 58.0]) {
          final pixels = await _pixels(tester, surface, Size.square(side));
          final extent = side.toInt() * 2;
          for (final index in [
            0,
            extent - 1,
            extent * (extent - 1),
            extent * extent - 1,
          ]) {
            expect(pixels[index * 4 + 3], lessThanOrEqualTo(3));
          }
          expect(
            pixels[((extent ~/ 2) * extent + extent ~/ 2) * 4 + 3],
            greaterThan(240),
          );
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
}
