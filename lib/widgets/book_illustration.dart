import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'book_pagination.dart';
import 'book_print_material.dart';
import 'book_resources.dart';

/// The valley and a printed block, composed from existing art and real text.
class BookIllustration extends StatelessWidget {
  const BookIllustration({super.key, this.softEdges = true});
  final bool softEdges;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: LayoutBuilder(
      builder: (context, bounds) {
        final side = math.min(bounds.maxWidth * .48, bounds.maxHeight * .78);
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: _ValleyVignette(softEdges: softEdges)),
            Positioned(
              right: bounds.maxWidth * .04,
              bottom: bounds.maxHeight * .06,
              child: Transform.rotate(
                angle: .09,
                child: _PrintedBlock(size: side),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _ValleyVignette extends StatelessWidget {
  const _ValleyVignette({required this.softEdges});
  final bool softEdges;

  @override
  Widget build(BuildContext context) {
    final landscape = Image(image: bookLandscapeAsset, fit: BoxFit.cover);
    if (!softEdges) return landscape;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.white,
          Colors.white,
          Colors.transparent,
        ],
        stops: [0, .12, .84, 1],
      ).createShader(bounds),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => const LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0, .08, .92, 1],
        ).createShader(bounds),
        child: landscape,
      ),
    );
  }
}

class _PrintedBlock extends StatelessWidget {
  const _PrintedBlock({required this.size});
  final double size;
  static const _givens = {0: 1, 1: 7, 2: 3, 3: 6, 5: 9, 6: 8, 7: 2, 8: 5};

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D8),
        border: Border.all(color: const Color(0xFFC8A568), width: 3),
        boxShadow: const [BoxShadow(color: Color(0x223F2A11), blurRadius: 5)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: LayoutBuilder(
          builder: (context, bounds) {
            final cell = bounds.maxWidth / 3;
            return Stack(
              children: [
                const Positioned.fill(child: CustomPaint(painter: _Grid())),
                for (final entry in _givens.entries)
                  Positioned(
                    left: entry.key % 3 * cell,
                    top: entry.key ~/ 3 * cell,
                    width: cell,
                    height: cell,
                    child: Center(
                      child: BookPrintedInk(
                        child: Text(
                          '${entry.value}',
                          textScaler: TextScaler.noScaling,
                          style: bookText(cell * .65)
                              .copyWith(color: const Color(0xFF695234)),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _Grid extends CustomPainter {
  const _Grid();
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i <= 3; i++) {
      final paint = Paint()
        ..color = const Color(0xFFBFA678)
        ..strokeWidth = i % 3 == 0 ? 1 : .35;
      final x = i * size.width / 3;
      final y = i * size.height / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_Grid oldDelegate) => false;
}
