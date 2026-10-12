import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'book_resources.dart';

/// Shares a single decoded paper texture between the sheet and its live text.
class BookPrintMaterial extends StatefulWidget {
  const BookPrintMaterial({super.key, required this.child});
  final Widget child;

  @override
  State<BookPrintMaterial> createState() => _BookPrintMaterialState();
}

class _BookPrintMaterialState extends State<BookPrintMaterial> {
  ImageStream? _stream;
  ImageInfo? _frame;
  late final _listener = ImageStreamListener((frame, synchronous) {
    void update() {
      _frame?.dispose();
      _frame = frame;
    }

    if (synchronous) {
      update();
    } else {
      setState(update);
    }
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = bookPaperAsset.resolve(createLocalImageConfiguration(context));
    if (_stream?.key == next.key) return;
    _stream?.removeListener(_listener);
    _stream = next..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _frame?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _PaperTexture(image: _frame?.image, child: widget.child);
}

class _PaperTexture extends InheritedWidget {
  const _PaperTexture({required this.image, required super.child});
  final ui.Image? image;

  static ui.Image? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PaperTexture>()?.image;

  @override
  bool updateShouldNotify(_PaperTexture oldWidget) => image != oldWidget.image;
}

ui.ImageShader _grainShader(ui.Image image) => ui.ImageShader(
  image,
  TileMode.repeated,
  TileMode.repeated,
  Float64List.fromList([.42, 0, 0, 0, 0, .42, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
  filterQuality: FilterQuality.low,
);

/// A quiet fiber layer feathered inside the book's existing illustrated page.
class BookPaperGrain extends StatelessWidget {
  const BookPaperGrain({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _PaperGrainPainter(_PaperTexture.of(context)),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

class _PaperGrainPainter extends CustomPainter {
  const _PaperGrainPainter(this.image);
  final ui.Image? image;

  @override
  void paint(Canvas canvas, Size size) {
    final texture = image;
    if (texture == null || size.isEmpty) return;
    final bounds = Offset.zero & size;
    final shader = _grainShader(texture);
    canvas.saveLayer(
      bounds,
      Paint()
        ..blendMode = BlendMode.multiply
        ..color = Colors.white.withValues(alpha: .22),
    );
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = shader
        ..colorFilter = const ColorFilter.matrix([
          2.2,
          0,
          0,
          0,
          -306,
          0,
          2.2,
          0,
          0,
          -306,
          0,
          0,
          2.2,
          0,
          -306,
          0,
          0,
          0,
          1,
          0,
        ]),
    );
    for (final vertical in [false, true]) {
      canvas.drawRect(
        bounds,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = LinearGradient(
            begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
            end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
            colors: const [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: const [0, .04, .96, 1],
          ).createShader(bounds),
      );
    }
    canvas.restore();
    shader.dispose();
  }

  @override
  bool shouldRepaint(_PaperGrainPainter oldDelegate) =>
      image != oldDelegate.image;
}

/// Preserves Flutter Text semantics while varying the density of its ink.
class BookPrintedInk extends StatelessWidget {
  const BookPrintedInk({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final texture = _PaperTexture.of(context);
    if (texture == null) return child;
    return ShaderMask(
      blendMode: BlendMode.modulate,
      shaderCallback: (_) => _grainShader(texture),
      child: child,
    );
  }
}
