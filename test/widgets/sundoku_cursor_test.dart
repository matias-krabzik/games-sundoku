import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/app.dart';
import 'package:sundoku/data/services/game_feedback.dart';
import 'package:sundoku/screens/home_screen.dart';
import 'package:sundoku/widgets/sundoku_cursor.dart';

void main() {
  testWidgets(
    'the real app installs the illustrated cursor above its navigator',
    (tester) async {
      await tester.pumpWidget(const SunDokuApp(feedback: GameFeedback()));
      expect(find.byType(SunDokuCursor), findsOneWidget);
      await tester.runAsync(
        () => precacheImage(
          const ResizeImage(AssetImage(SunDokuCursor.asset), width: 128),
          tester.element(find.byType(SunDokuCursor)),
        ),
      );
      await tester.pump();
      final mouse = TestGesture(
        dispatcher: tester.sendEventToBinding,
        kind: PointerDeviceKind.mouse,
        device: 42,
      );
      await mouse.addPointer(location: const Offset(200, 200));
      await tester.pump();
      expect(find.byKey(const ValueKey('sundoku-pointer')), findsOneWidget);
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(42),
        SystemMouseCursors.none,
      );
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.macOS}),
  );

  testWidgets(
    'desktop cursor follows its hotspot and preserves hover, taps and drags',
    (tester) async {
      final capture = GlobalKey();
      var hovered = false;
      var tapped = false;
      var slider = 0.0;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => RepaintBoundary(
            key: capture,
            child: SunDokuCursor(child: child!),
          ),
          home: StatefulBuilder(
            builder: (context, update) => Scaffold(
              body: Column(
                children: [
                  MouseRegion(
                    onHover: (_) => hovered = true,
                    cursor: SystemMouseCursors.click,
                    child: TextButton(
                      key: const ValueKey('target'),
                      onPressed: () => tapped = true,
                      child: const Text('Probar'),
                    ),
                  ),
                  Slider(
                    value: slider,
                    onChanged: (v) => update(() => slider = v),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const ResizeImage(AssetImage(SunDokuCursor.asset), width: 128),
          tester.element(find.byType(SunDokuCursor)),
        ),
      );
      await tester.pump();
      final mouse = TestGesture(
        dispatcher: tester.sendEventToBinding,
        kind: PointerDeviceKind.mouse,
        device: 42,
      );
      final target = tester.getCenter(find.byKey(const ValueKey('target')));
      await mouse.addPointer(location: target);
      await mouse.moveTo(target + const Offset(1, 0));
      await tester.pump();
      final pointer = find.byKey(const ValueKey('sundoku-pointer'));
      expect(
        tester.getTopLeft(pointer) + SunDokuCursor.hotspot,
        target + const Offset(1, 0),
      );
      expect(hovered, true);
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(42),
        SystemMouseCursors.none,
      );
      await mouse.down(target);
      await mouse.up();
      await tester.pump();
      expect(tapped, true);
      final sliderRect = tester.getRect(find.byType(Slider));
      await mouse.moveTo(sliderRect.centerLeft + const Offset(25, 0));
      await mouse.down(sliderRect.centerLeft + const Offset(25, 0));
      await mouse.moveTo(sliderRect.centerRight - const Offset(25, 0));
      await tester.pump();
      expect(slider, greaterThan(.8));
      expect(
        tester.getTopLeft(pointer) + SunDokuCursor.hotspot,
        sliderRect.centerRight - const Offset(25, 0),
      );
      await mouse.up();
      await mouse.removePointer();
      await tester.pump();
      expect(pointer, findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant({TargetPlatform.macOS}),
  );

  testWidgets(
    'selected cursor stays above dialogs and home parallax still follows it',
    (tester) async {
      final boundary = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => RepaintBoundary(
            key: boundary,
            child: SunDokuCursor(child: child!),
          ),
          home: Builder(
            builder: (context) => HomeScreen(
              onPlay: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    const AlertDialog(content: Text('Cursor sobre el modal')),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const ResizeImage(AssetImage(SunDokuCursor.asset), width: 128),
          tester.element(find.byType(SunDokuCursor)),
        ),
      );
      await tester.pump();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      final play = find.byKey(const ValueKey('home-play'));
      await mouse.addPointer(location: tester.getCenter(play));
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final transform = tester.widget<Transform>(
        find.byKey(const ValueKey('parallax-offset')),
      );
      expect(transform.transform.storage[12], isNot(0));
      final path = Platform.environment['CURSOR_CAPTURE_PATH'];
      if (path != null) {
        await tester.runAsync(() async {
          for (final asset in [
            'assets/images/home-background.png',
            'assets/images/doku-home.png',
            'assets/images/sundoku-logo.png',
          ]) {
            await precacheImage(
              AssetImage(asset),
              tester.element(find.byType(HomeScreen)),
            );
          }
        });
        await tester.pump();
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          await File(path).writeAsBytes(bytes!.buffer.asUint8List());
        });
      }
      await tester.tap(play);
      await tester.pump(const Duration(milliseconds: 300));
      await mouse.moveTo(tester.getCenter(find.byType(AlertDialog)));
      await tester.pump();
      expect(find.byKey(const ValueKey('sundoku-pointer')), findsOneWidget);
      expect(find.text('Cursor sobre el modal'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant({TargetPlatform.macOS}),
  );

  testWidgets(
    'mobile keeps the system pointer and draws no cursor overlay',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SunDokuCursor(child: SizedBox.expand())),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(100, 100));
      await tester.pump();
      expect(find.byKey(const ValueKey('sundoku-pointer')), findsNothing);
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );
}
