import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Stretches a pill horizontally without subdividing its vertical gradient.
class HorizontalSliceArt extends StatefulWidget {
  const HorizontalSliceArt({
    super.key,
    required this.asset,
    required this.region,
    required this.centerSlice,
    required this.referenceSize,
  });

  final String asset;
  final Rect region;
  final Rect centerSlice;
  final Size referenceSize;

  @override
  State<HorizontalSliceArt> createState() => _HorizontalSliceArtState();
}

class _HorizontalSliceArtState extends State<HorizontalSliceArt> {
  ImageStream? _stream;
  ImageInfo? _frame;
  late final _listener = ImageStreamListener((frame, _) {
    setState(() {
      _frame?.dispose();
      _frame = frame;
    });
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant HorizontalSliceArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) _resolveImage();
  }

  void _resolveImage() {
    final next = AssetImage(widget.asset)
        .resolve(createLocalImageConfiguration(context));
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
  Widget build(BuildContext context) => CustomPaint(
    painter: _HorizontalSlicePainter(
      _frame?.image,
      widget.region,
      widget.centerSlice,
      widget.referenceSize,
    ),
    child: const SizedBox.expand(),
  );
}

class _HorizontalSlicePainter extends CustomPainter {
  const _HorizontalSlicePainter(
    this.image,
    this.region,
    this.centerSlice,
    this.referenceSize,
  );

  final ui.Image? image;
  final Rect region;
  final Rect centerSlice;
  final Size referenceSize;

  @override
  void paint(Canvas canvas, Size size) {
    final texture = image;
    if (texture == null || size.isEmpty) return;
    final source = Rect.fromLTRB(
      (region.left * texture.width).roundToDouble(),
      (region.top * texture.height).roundToDouble(),
      (region.right * texture.width).roundToDouble(),
      (region.bottom * texture.height).roundToDouble(),
    );
    final splitLeft = (centerSlice.left * texture.width).roundToDouble();
    final splitRight = (centerSlice.right * texture.width).roundToDouble();
    final scale = referenceSize.width / source.width;
    final naturalLeft = (splitLeft - source.left) * scale;
    final naturalRight = (source.right - splitRight) * scale;
    final capScale = math.min(1.0, size.width / (naturalLeft + naturalRight));
    final left = naturalLeft * capScale;
    final right = size.width - naturalRight * capScale;
    final paint = Paint()
      ..filterQuality = FilterQuality.low
      ..isAntiAlias = false;

    // Overlap adjacent strips so fractional GPU coordinates never expose the
    // track underneath. Narrow fills shrink their caps horizontally only.
    final overlap = math.min(.5, size.width / 4);
    final sourceOverlap = overlap / (scale * capScale);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (right > left) {
      canvas.drawImageRect(
        texture,
        Rect.fromLTRB(splitLeft, source.top, splitRight, source.bottom),
        Rect.fromLTRB(left - overlap, 0, right + overlap, size.height),
        paint,
      );
    }
    canvas.drawImageRect(
      texture,
      Rect.fromLTRB(
        source.left,
        source.top,
        splitLeft + sourceOverlap,
        source.bottom,
      ),
      Rect.fromLTRB(0, 0, left + overlap, size.height),
      paint,
    );
    canvas.drawImageRect(
      texture,
      Rect.fromLTRB(
        splitRight - sourceOverlap,
        source.top,
        source.right,
        source.bottom,
      ),
      Rect.fromLTRB(right - overlap, 0, size.width, size.height),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HorizontalSlicePainter oldDelegate) =>
      image != oldDelegate.image ||
      region != oldDelegate.region ||
      centerSlice != oldDelegate.centerSlice ||
      referenceSize != oldDelegate.referenceSize;
}
