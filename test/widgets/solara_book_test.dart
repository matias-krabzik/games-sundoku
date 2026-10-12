import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/theme.dart';
import 'package:sundoku/widgets/solara_book.dart';

import '../support/tutorial_book.dart';

Future<void> snapshot(WidgetTester tester, GlobalKey key, String name) async {
  final dir = Platform.environment['BOOK_CAPTURE_DIR'];
  if (dir == null) return;
  final context = key.currentContext!;
  final images = tester
      .widgetList<Image>(find.byType(Image))
      .map((image) => image.image)
      .toSet();
  await tester.runAsync(() async {
    for (final provider in images) {
      await precacheImage(provider, context);
    }
  });
  await tester.pump();
  await tester.runAsync(() async {
    final image = await (context.findRenderObject()! as RenderRepaintBoundary)
        .toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(dir).create(recursive: true);
    await File('$dir/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    for (final (family, asset) in [
      ('Baloo2', 'assets/fonts/Baloo2-Variable.ttf'),
      ('LibreBaskerville', 'assets/fonts/LibreBaskerville-Variable.ttf'),
      ('EBGaramond', 'assets/fonts/EBGaramond-Variable.ttf'),
      ('IMFellEnglish', 'assets/fonts/IMFellEnglish-Regular.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(834, 1210),
    const Size(1210, 834),
    const Size(844, 390),
    const Size(568, 320),
    const Size(320, 320),
    const Size(1440, 900),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('book sheets fit $size at text $scale', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final capture = GlobalKey();
        var opened = 0;
        var closed = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildSunDokuTheme(),
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                disableAnimations: true,
                textScaler: TextScaler.linear(scale),
                padding: const EdgeInsets.only(top: 24, bottom: 20),
              ),
              child: RepaintBoundary(
                key: capture,
                child: ColoredBox(
                  color: const Color(0xFF263848),
                  child: SolaraBook(
                    onOpenSummary: () async => opened++,
                    onClose: () => closed = true,
                  ),
                ),
              ),
            ),
          ),
        );
        final total = bookPageCount(tester);
        for (var page = 0; page < total; page++) {
          expect(bookPageCounter(tester), '${page + 1} / $total');
          final summary = find
              .byKey(const ValueKey('book-summary'))
              .hitTestable();
          final previous = find.byKey(const ValueKey('book-previous'));
          final next = find.byKey(const ValueKey('book-next'));
          for (final target in [
            if (summary.evaluate().isNotEmpty) summary,
            previous,
            next,
            find.byKey(const ValueKey('book-exit')),
          ]) {
            final rect = tester.getRect(target);
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(size.width));
            expect(rect.top, greaterThanOrEqualTo(24));
            expect(rect.bottom, lessThanOrEqualTo(size.height - 20));
          }
          if (summary.evaluate().isNotEmpty) {
            await tester.tap(summary);
            await tester.pump();
          }
          await snapshot(
            tester,
            capture,
            'page-${page + 1}-${size.width.toInt()}x${size.height.toInt()}-text-$scale',
          );
          if (page < total - 1) {
            await tester.tap(next);
            await tester.pump();
          }
          expect(tester.takeException(), isNull);
        }
        expect(opened, 1);
        await tester.tap(find.byKey(const ValueKey('book-exit')));
        expect(closed, isTrue);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets(
    'swipe and keyboard turn pages; resizing preserves the reading section',
    (tester) async {
      final capture = GlobalKey();
      Future<void> show(Size size) => tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox.fromSize(
              size: size,
              child: SolaraBook(
                key: capture,
                onOpenSummary: () async {},
                onClose: () {},
              ),
            ),
          ),
        ),
      );
      await show(const Size(390, 600));
      final total = bookPageCount(tester);
      await tester.drag(
        find.byKey(const ValueKey('book-pages')),
        const Offset(-280, 0),
      );
      await tester.pumpAndSettle();
      expect(bookPageCounter(tester), '2 / $total');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(bookPageCounter(tester), '3 / $total');
      final section = currentBookSection(tester);
      await show(const Size(600, 390));
      await tester.pumpAndSettle();
      expect(currentBookSection(tester), section);
      final pageBefore = int.parse(
        bookPageCounter(tester).split('/').first.trim(),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(
        int.parse(bookPageCounter(tester).split('/').first.trim()),
        pageBefore - 1,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
