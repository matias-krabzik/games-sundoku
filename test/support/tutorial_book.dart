import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundoku/data/tutorial_book.dart';
import 'package:sundoku/widgets/solara_book.dart';

String bookPageCounter(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('book-page-number'))).data!;

int bookPageCount(WidgetTester tester) =>
    int.parse(bookPageCounter(tester).split('/').last.trim());

int currentBookSection(WidgetTester tester) {
  final paper = tester.getRect(find.byKey(const ValueKey('book-pages')));
  final book = tester.widget<SolaraBook>(find.byType(SolaraBook));
  for (var section = 1; section <= book.sections.length; section++) {
    for (final element
        in find.byKey(ValueKey('book-section-$section')).evaluate()) {
      final box = element.renderObject! as RenderBox;
      if (paper.contains(box.localToGlobal(box.size.center(Offset.zero))))
        return section;
    }
  }
  throw StateError('No visible book section');
}

Future<void> openBookSummary(
  WidgetTester tester, {
  BookLesson lesson = BookLesson.rules,
}) async {
  final limit = bookPageCount(tester);
  final summary = find.byKey(const ValueKey('book-summary')).hitTestable();
  final book = tester.widget<SolaraBook>(find.byType(SolaraBook));
  bool ready() =>
      summary.evaluate().isNotEmpty &&
      book.sections[currentBookSection(tester) - 1].lesson == lesson;
  for (var turn = 0; turn < limit && !ready(); turn++) {
    await tester.tap(find.byKey(const ValueKey('book-next')));
    await tester.pump();
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  expect(ready(), isTrue);
  expect(summary, findsOneWidget);
}
