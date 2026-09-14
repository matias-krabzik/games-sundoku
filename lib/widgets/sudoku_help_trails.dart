import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/help/sudoku_help_motion.dart';

/// Finite, non-interactive connections using the board's own cell geometry.
class SudokuHelpTrails extends StatefulWidget {
  const SudokuHelpTrails({
    super.key,
    required this.traces,
    required this.centers,
    required this.cellExtent,
    this.arrivalIndex,
  });

  final List<SudokuHelpTrace> traces;
  final List<Offset> centers;
  final double cellExtent;
  final int? arrivalIndex;

  @override
  State<SudokuHelpTrails> createState() => _SudokuHelpTrailsState();
}

class _SudokuHelpTrailsState extends State<SudokuHelpTrails>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(vsync: this, value: 1);
  bool _reduced = false;
  String _signature(SudokuHelpTrails widget) =>
      '${widget.arrivalIndex}:${helpMotionSignature(widget.traces)}';

  void _start() {
    _animation.stop();
    _animation.duration = Duration(
      milliseconds: helpMotionMilliseconds(widget.traces),
    );
    if (_reduced || (widget.traces.isEmpty && widget.arrivalIndex == null)) {
      _animation.value = 1;
    } else {
      _animation.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (_animation.duration == null || reduced != _reduced) {
      _reduced = reduced;
      _start();
    }
  }

  @override
  void didUpdateWidget(SudokuHelpTrails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signature(oldWidget) != _signature(widget)) _start();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          key: const ValueKey('help-trails-paint'),
          painter: SudokuHelpTrailPainter(
            progress: _animation,
            traces: widget.traces,
            centers: widget.centers,
            cellExtent: widget.cellExtent,
            arrivalIndex: widget.arrivalIndex,
          ),
        ),
      ),
    ),
  );
}

class SudokuHelpTrailPainter extends CustomPainter {
  SudokuHelpTrailPainter({
    required this.progress,
    required this.traces,
    required this.centers,
    required this.cellExtent,
    this.arrivalIndex,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final List<SudokuHelpTrace> traces;
  final List<Offset> centers;
  final double cellExtent;
  final int? arrivalIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress.value <= 0 || progress.value >= 1) return;
    final milliseconds = progress.value * helpMotionMilliseconds(traces);
    final width = (cellExtent * .045).clamp(1.3, 2.4);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var index = 0; index < traces.length; index++) {
      if (traces[index].isBlockHop) continue;
      final age = milliseconds - 180 - index * 380;
      if (age <= 0 || age >= 650) continue;
      final route = traces[index].cells;
      if (route.length < 2) continue;
      final path = Path()
        ..moveTo(centers[route.first].dx, centers[route.first].dy);
      for (final cell in route.skip(1)) {
        path.lineTo(centers[cell].dx, centers[cell].dy);
      }
      final alpha =
          (age / 80).clamp(0.0, 1.0) *
          (1 - ((age - 380) / 270).clamp(0.0, 1.0));
      final drawn = Curves.easeInOutCubic.transform(
        (age / 380).clamp(0.0, 1.0),
      );
      for (final metric in path.computeMetrics()) {
        final length = metric.length * drawn;
        final segment = metric.extractPath(0, length);
        canvas.drawPath(
          segment,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = width + 2
            ..color = const Color(0xFF9B6A16).withValues(alpha: alpha * .65),
        );
        canvas.drawPath(
          segment,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = width
            ..color = const Color(0xFFFFED9B).withValues(alpha: alpha),
        );
        final head = metric.getTangentForOffset(length)?.position;
        if (head != null) {
          canvas.drawCircle(
            head,
            width * 1.8,
            Paint()..color = const Color(0xFFFFC631).withValues(alpha: alpha),
          );
          canvas.drawCircle(
            head,
            width * .8,
            Paint()..color = Colors.white.withValues(alpha: alpha),
          );
        }
      }
    }
    final arrival = traces.isNotEmpty && traces.last.isBlockHop
        ? null
        : arrivalIndex;
    final pulse = ((milliseconds - 180 - traces.length * 380 - 200) / 500)
        .clamp(0.0, 1.0);
    if (arrival != null && pulse > 0 && pulse < 1) {
      final rect = Rect.fromCenter(
        center: centers[arrival],
        width: cellExtent * (.83 + .1 * pulse),
        height: cellExtent * (.83 + .1 * pulse),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cellExtent * .13)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 1.8
          ..color = const Color(0xFFFFD32A)
              .withValues(alpha: math.sin(pulse * math.pi)),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SudokuHelpTrailPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      traces != oldDelegate.traces ||
      centers != oldDelegate.centers ||
      cellExtent != oldDelegate.cellExtent ||
      arrivalIndex != oldDelegate.arrivalIndex;
}
