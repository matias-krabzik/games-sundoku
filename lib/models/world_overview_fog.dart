import 'dart:math' as math;
import 'dart:ui';

enum OverviewFogTexture {
  light('fog-light.png'),
  medium('fog-medium.png'),
  dense('fog-dense.png');

  const OverviewFogTexture(this.file);
  final String file;
  String get asset => 'assets/images/world-selection/$file';
}

/// Independent mist pieces moving to the right at a stable screen scale.
class OverviewFogBand {
  const OverviewFogBand({
    required this.texture,
    required this.y,
    required this.width,
    required this.opacity,
    required this.speed,
    required this.phase,
  });

  final OverviewFogTexture texture;
  final double y;
  final double width;
  final double opacity;
  final double speed;
  final double phase;

  Iterable<Rect> screenPieces(Size viewport, double seconds, double aspect) =>
      pieces(
        Offset.zero & viewport,
        seconds,
        aspect,
        referenceSize: Size(
          viewport.shortestSide * 1.2,
          viewport.shortestSide * .8,
        ),
      );

  Iterable<Rect> pieces(
    Rect region,
    double seconds,
    double aspect, {
    Size? referenceSize,
  }) sync* {
    final reference = referenceSize ?? region.size;
    final pieceWidth = math.max(
      reference.width * width,
      reference.height * 1.7,
    );
    final height = pieceWidth / aspect;
    final spacing = pieceWidth * .72;
    final drift =
        (seconds * speed * reference.width + phase * spacing) % spacing;
    final rows = referenceSize == null
        ? 1
        : (region.height / reference.height).ceil() + 2;
    // The next copy enters before the previous one exits. Wrapping never
    // teleports a visible piece or reverses its direction.
    for (
      var left = region.left + drift - pieceWidth - spacing;
      left < region.right;
      left += spacing
    ) {
      for (var row = 0; row < rows; row++) {
        yield Rect.fromLTWH(
          left,
          region.top +
              reference.height * (y + row - (referenceSize == null ? 0 : 1)) -
              height / 2,
          pieceWidth,
          height,
        );
      }
    }
  }
}

const overviewFogBands = [
  OverviewFogBand(
    texture: OverviewFogTexture.medium,
    y: .04,
    width: 1.4,
    opacity: .66,
    speed: .013,
    phase: .12,
  ),
  OverviewFogBand(
    texture: OverviewFogTexture.dense,
    y: .28,
    width: 1.25,
    opacity: .90,
    speed: .018,
    phase: .61,
  ),
  OverviewFogBand(
    texture: OverviewFogTexture.light,
    y: .43,
    width: 1.6,
    opacity: .46,
    speed: .032,
    phase: .34,
  ),
  OverviewFogBand(
    texture: OverviewFogTexture.dense,
    y: .61,
    width: 1.45,
    opacity: .84,
    speed: .011,
    phase: .84,
  ),
  OverviewFogBand(
    texture: OverviewFogTexture.medium,
    y: .82,
    width: 1.3,
    opacity: .68,
    speed: .025,
    phase: .42,
  ),
  OverviewFogBand(
    texture: OverviewFogTexture.light,
    y: .98,
    width: 1.7,
    opacity: .36,
    speed: .038,
    phase: .75,
  ),
];
