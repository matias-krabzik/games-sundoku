import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/tutorial_book.dart';

const bookInk = Color(0xFF293D4A);

TextStyle bookText(double size, {FontWeight weight = FontWeight.w400}) =>
    TextStyle(
      fontFamily: 'EBGaramond',
      fontSize: size,
      color: bookInk,
      height: 1.5,
      fontWeight: weight,
    );

class BookTypography {
  const BookTypography({required this.large});
  final bool large;

  TextStyle styleFor(BookBlockKind kind) => switch (kind) {
    BookBlockKind.coverTitle => bookText(
      large ? 44 : 34,
    ).copyWith(fontFamily: 'IMFellEnglish', height: 1.12),
    BookBlockKind.title => bookText(
      large ? 30 : 23,
    ).copyWith(fontFamily: 'IMFellEnglish', height: 1.25),
    BookBlockKind.eyebrow => bookText(
      large ? 13 : 10,
      weight: FontWeight.w700,
    ).copyWith(letterSpacing: 1.5, color: const Color(0xFF937236)),
    _ => bookText(large ? 22 : 18),
  };
}

class BookLeafPart {
  const BookLeafPart({
    required this.kind,
    required this.text,
    required this.height,
    required this.gap,
    required this.style,
  });
  final BookBlockKind kind;
  final String text;
  final double height;
  final double gap;
  final TextStyle style;
}

class BookLeaf {
  const BookLeaf({
    required this.section,
    required this.block,
    required this.offset,
    required this.parts,
  });
  final int section;
  final int block;
  final int offset;
  final List<BookLeafPart> parts;
}

double bookTextHeight(
  String text,
  TextStyle style,
  double width,
  TextScaler scaler,
  TextDirection direction,
) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textScaler: scaler,
    textDirection: direction,
  )..layout(maxWidth: math.max(1, width));
  final result = painter.height;
  painter.dispose();
  return result;
}

/// Keeps the editorial sheets intact and adds continuation leaves only as needed.
/// Each heading is printed once; resizing anchors to the current text position.
List<BookLeaf> paginateBook({
  List<BookSection> sections = bookSections,
  required double width,
  required double height,
  required bool large,
  required TextScaler scaler,
  required TextDirection direction,
}) {
  final leaves = <BookLeaf>[];
  final typography = BookTypography(large: large);
  double measure(String text, TextStyle style) =>
      bookTextHeight(text, style, width, scaler, direction);

  for (var section = 0; section < sections.length; section++) {
    final blocks = sections[section].blocks;
    var block = 0;
    var offset = 0;
    while (block < blocks.length) {
      final startBlock = block;
      final startOffset = offset;
      final parts = <BookLeafPart>[];
      var free = height;
      while (block < blocks.length) {
        final content = blocks[block];
        final gap = parts.isEmpty ? 0.0 : 14.0;
        var style = typography.styleFor(content.kind);
        final picture =
            content.kind == BookBlockKind.illustration ||
            content.kind == BookBlockKind.summary;
        if (picture) {
          final summary = content.kind == BookBlockKind.summary;
          final preferred = summary
              ? math.min(width, large ? 260.0 : 220.0)
              : math.min(width * .7, large ? 210.0 : 160.0);
          final minimum = math.min(summary ? 128.0 : 96.0, height);
          if (parts.isNotEmpty && free - gap < minimum) break;
          final extent = math.min(preferred, math.max(1.0, free - gap));
          parts.add(
            BookLeafPart(
              kind: content.kind,
              text: '',
              height: extent,
              gap: gap,
              style: style,
            ),
          );
          free -= extent + gap;
          block++;
          offset = 0;
          continue;
        }

        final lineHeight = measure('Ag', style);
        if (lineHeight > height) {
          style = style.copyWith(
            fontSize: style.fontSize! * height / lineHeight,
          );
        }
        final remaining = content.text.substring(offset);
        final wholeHeight = measure(remaining, style);
        if (parts.isNotEmpty &&
            wholeHeight > free - gap &&
            wholeHeight <= height) {
          break;
        }
        var low = 0;
        var high = remaining.length;
        while (low < high) {
          final middle = (low + high + 1) ~/ 2;
          if (measure(remaining.substring(0, middle).trimRight(), style) <=
              free - gap) {
            low = middle;
          } else {
            high = middle - 1;
          }
        }
        if (low == 0) break;
        if (low < remaining.length) {
          final boundary = remaining.lastIndexOf(' ', low);
          if (boundary > 0) low = boundary;
        }
        final text = remaining.substring(0, low).trimRight();
        final textHeight = measure(text, style);
        parts.add(
          BookLeafPart(
            kind: content.kind,
            text: text,
            height: textHeight,
            gap: gap,
            style: style,
          ),
        );
        free -= textHeight + gap;
        offset += low;
        while (offset < content.text.length && content.text[offset] == ' ') {
          offset++;
        }
        if (offset == content.text.length) {
          block++;
          offset = 0;
        } else {
          break;
        }
      }
      if (parts.isEmpty) break;
      leaves.add(
        BookLeaf(
          section: section,
          block: startBlock,
          offset: startOffset,
          parts: parts,
        ),
      );
    }
  }
  return leaves;
}
