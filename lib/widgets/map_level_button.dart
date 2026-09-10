import 'dart:math' as math;

import 'package:flutter/material.dart';

const List<double> kMapScoreStarSizes = <double>[30, 38, 46];

/// Score-point center relative to the center of a level marker.
Offset mapScoreStarOffset(int socket, double nodeSize) {
  assert(socket >= 0 && socket < 3);
  return switch (socket) {
    0 => Offset(-nodeSize / 2 + 7, -nodeSize / 2 - 4),
    1 => Offset(0, -nodeSize / 2 - 16),
    _ => Offset(nodeSize / 2 - 3, -nodeSize / 2 - 4),
  };
}

double mapScoreStarSize(int socket) => kMapScoreStarSizes[socket];

/// A dormant stone that warms up as its three light sockets are filled.
class MapLevelButton extends StatelessWidget {
  const MapLevelButton({
    super.key,
    required this.level,
    required this.active,
    required this.lights,
    required this.unlocked,
    required this.onTap,
  });

  final int level;
  final bool active;
  final int lights;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Nivel $level',
      value: unlocked
          ? 'Disponible, $lights de 3 puntos'
          : 'Bloqueado, consigue 3 puntos en el nivel ${level - 1}',
      button: true,
      selected: active,
      child: Column(
        children: [
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: unlocked ? 1 : 0, end: unlocked ? 1 : 0),
              duration: reduced
                  ? Duration.zero
                  : const Duration(milliseconds: 1100),
              curve: Curves.easeInOutCubic,
              builder: (context, power, _) => Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  if (unlocked && power > 0 && power < 1)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: _IgnitionPainter(power)),
                      ),
                    ),
                  if (unlocked) ...[
                    Positioned(
                      left: -29,
                      right: -29,
                      top: -67,
                      height: 128,
                      child: IgnorePointer(
                        child: Opacity(
                          key: ValueKey('level-$level-star-crest'),
                          opacity: 0.82 + power * 0.18,
                          child: Image.asset(
                            'assets/images/level-star-ribbon-thick.png',
                            fit: BoxFit.contain,
                            cacheWidth: 504,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -8,
                      top: -19,
                      child: _ScoreStar(
                        level: level,
                        socket: 0,
                        earned: lights >= 1,
                        reduced: reduced,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: -35,
                      child: Center(
                        child: _ScoreStar(
                          level: level,
                          socket: 1,
                          earned: lights >= 2,
                          reduced: reduced,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -20,
                      top: -27,
                      child: _ScoreStar(
                        level: level,
                        socket: 2,
                        earned: lights >= 3,
                        reduced: reduced,
                      ),
                    ),
                  ],
                  Transform.scale(
                    scale:
                        (active ? 1.10 : 1) + math.sin(power * math.pi) * 0.14,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(
                              const Color(0xFF9AACA9),
                              const Color(0xFFFFF59A),
                              power,
                            )!,
                            Color.lerp(
                              const Color(0xFF43565C),
                              const Color(0xFFFFC21A),
                              power,
                            )!,
                          ],
                        ),
                        border: Border.all(
                          width: 3.5,
                          color: Color.lerp(
                            active
                                ? const Color(0xFFDAE7DF)
                                : const Color(0xFF9CADAD),
                            const Color(0xFFFFB20F),
                            power,
                          )!,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF082A62)
                                .withValues(alpha: active ? 0.72 : 0.58),
                            offset: const Offset(0, 7),
                            blurRadius: active ? 16 : 13,
                            spreadRadius: active ? 2 : 1,
                          ),
                          const BoxShadow(
                            color: Color(0x80504017),
                            offset: Offset(0, 10),
                            blurRadius: 10,
                          ),
                          BoxShadow(
                            color: Color.lerp(
                              const Color(0xFF34454C),
                              const Color(0xFFCE8D23),
                              power,
                            )!,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Color.lerp(
                              const Color(0xFFB7C3C0),
                              const Color(0xFFFFF4A8),
                              power,
                            )!,
                            width: 1.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: onTap,
                            child: Center(
                              child: Image.asset(
                                'assets/images/level-number-$level.png',
                                key: ValueKey('level-$level-label'),
                                width: level == 10 ? 38 : 29,
                                height: 36,
                                fit: BoxFit.contain,
                                cacheWidth: level == 10 ? 152 : 116,
                                excludeFromSemantics: true,
                                opacity: AlwaysStoppedAnimation<double>(
                                  0.62 + power * 0.38,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 1 - power,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF34454C),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 14,
                            color: Color(0xFFE6EDE6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

class _ScoreStar extends StatelessWidget {
  const _ScoreStar({
    required this.level,
    required this.socket,
    required this.earned,
    required this.reduced,
  });

  final int level;
  final int socket;
  final bool earned;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final double size = mapScoreStarSize(socket);
    final double angle = switch (socket) {
      0 => -0.12,
      1 => 0.04,
      _ => 0.11,
    };
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        key: ValueKey('level-$level-score-${socket + 1}'),
        tween: Tween(begin: earned ? 1 : 0, end: earned ? 1 : 0),
        duration: reduced ? Duration.zero : const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
        builder: (context, value, _) {
          final double progress = value.clamp(0, 1);
          return Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scale: 1 + math.sin(progress * math.pi) * 0.24,
              child: SizedBox.square(
                dimension: size,
                child: CustomPaint(painter: _ScoreStarPainter(progress)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScoreStarPainter extends CustomPainter {
  const _ScoreStarPainter(this.progress);

  final double progress;

  Path _star(Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide * 0.46;
    final inner = outer * 0.47;
    final vertices = <Offset>[];
    for (int point = 0; point < 10; point++) {
      final radius = point.isEven ? outer : inner;
      final angle = -math.pi / 2 + point * math.pi / 5;
      vertices.add(center + Offset(math.cos(angle), math.sin(angle)) * radius);
    }

    final path = Path();
    for (int point = 0; point < vertices.length; point++) {
      final previous = vertices[(point - 1) % vertices.length];
      final current = vertices[point];
      final next = vertices[(point + 1) % vertices.length];
      final rounding = point.isEven ? 0.24 : 0.16;
      final entry = Offset.lerp(current, previous, rounding)!;
      final exit = Offset.lerp(current, next, rounding)!;
      if (point == 0) {
        path.moveTo(entry.dx, entry.dy);
      } else {
        path.lineTo(entry.dx, entry.dy);
      }
      path.quadraticBezierTo(current.dx, current.dy, exit.dx, exit.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _star(size);
    final bounds = Offset.zero & size;
    canvas.save();
    canvas.translate(0, size.shortestSide * 0.055);
    canvas.drawPath(
      path,
      Paint()
        ..color = Color.lerp(
          const Color(0xFF817E72),
          const Color(0xFFC46B00),
          progress,
        )!,
    );
    canvas.restore();
    canvas.drawShadow(
      path,
      Color.lerp(const Color(0xFF061A3A), const Color(0xFFFFA000), progress)!,
      3 + progress * 5,
      true,
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(
              const Color(0xFFE3E0D3),
              const Color(0xFFFFFFD0),
              progress,
            )!,
            Color.lerp(
              const Color(0xFFCDCABE),
              const Color(0xFFFFD52B),
              progress,
            )!,
            Color.lerp(
              const Color(0xFFB6B3A7),
              const Color(0xFFFF9F00),
              progress,
            )!,
          ],
          stops: const [0, 0.58, 1],
        ).createShader(bounds),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 1.7 + size.shortestSide * 0.025
        ..color = Color.lerp(
          const Color(0xFF969387),
          const Color(0xFFFFB30E),
          progress,
        )!,
    );
    canvas.drawCircle(
      size.center(Offset.zero) +
          Offset(-size.width * 0.10, -size.height * 0.13),
      size.shortestSide * 0.055,
      Paint()..color = Colors.white.withValues(alpha: progress * 0.9),
    );
  }

  @override
  bool shouldRepaint(_ScoreStarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _IgnitionPainter extends CustomPainter {
  const _IgnitionPainter(this.power);
  final double power;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * (0.4 + power * 1.4);
    final strength = math.sin(power * math.pi);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFFADD).withValues(alpha: strength * 0.6),
            const Color(0xFFFFCF48).withValues(alpha: strength * 0.35),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius * 0.8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * (1 - power)
        ..color = const Color(0xFFFFF3B6).withValues(alpha: strength * 0.8),
    );
  }

  @override
  bool shouldRepaint(_IgnitionPainter oldDelegate) =>
      oldDelegate.power != power;
}
