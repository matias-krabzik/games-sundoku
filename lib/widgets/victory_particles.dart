import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Continuous fullscreen confetti while the victory screen is visible.
class VictoryParticles extends StatefulWidget {
  const VictoryParticles({
    super.key,
    required this.entrance,
    required this.grandFinale,
    this.foregroundBounds,
  });

  final Animation<double> entrance;
  final bool grandFinale;
  final Rect? Function()? foregroundBounds;

  @override
  State<VictoryParticles> createState() => _VictoryParticlesState();
}

class _VictoryParticlesState extends State<VictoryParticles>
    with TickerProviderStateMixin {
  late final _burst = AnimationController(vsync: this, value: 1);
  late final _launch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late List<_Particle> _particles;
  late bool _armed;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _configure();
    widget.entrance.addListener(_onEntrance);
  }

  void _configure() {
    _burst.duration = const Duration(seconds: 12);
    _particles = _Particle.create(widget.grandFinale);
    _armed = true;
  }

  void _onEntrance() {
    if (!_armed || _reducedMotion || widget.entrance.value < .5) return;
    _armed = false;
    _burst.repeat();
    _launch.forward(from: 0);
  }

  @override
  void didUpdateWidget(VictoryParticles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entrance != widget.entrance ||
        oldWidget.grandFinale != widget.grandFinale) {
      oldWidget.entrance.removeListener(_onEntrance);
      _launch.stop();
      _burst.stop();
      _burst.value = 1;
      _configure();
      widget.entrance.addListener(_onEntrance);
      _resumeRain();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (_reducedMotion) {
      _armed = false;
      _launch.stop();
      _burst.stop();
      _burst.value = 1;
    } else {
      _resumeRain();
    }
  }

  // A remounted reward resumes its rain without replaying the launch.
  void _resumeRain() {
    if (_reducedMotion || widget.entrance.value < .5 || _burst.isAnimating) {
      return;
    }
    _armed = false;
    _launch.value = 1;
    _burst.repeat();
  }

  @override
  void reassemble() {
    super.reassemble();
    _resumeRain();
  }

  @override
  void dispose() {
    widget.entrance.removeListener(_onEntrance);
    _launch.dispose();
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: _reducedMotion
            ? const SizedBox.expand()
            : CustomPaint(
                painter: _VictoryPainter(
                  progress: _burst,
                  launch: _launch,
                  foregroundBounds: widget.foregroundBounds,
                  particles: _particles,
                  grandFinale: widget.grandFinale,
                ),
                child: const SizedBox.expand(),
              ),
      ),
    ),
  );
}

class _Particle {
  const _Particle({
    required this.origin,
    required this.velocity,
    required this.delay,
    required this.radius,
    required this.rotation,
    required this.spin,
    required this.color,
    required this.star,
  });

  final Offset origin;
  final Offset velocity;
  final double delay;
  final double radius;
  final double rotation;
  final double spin;
  final Color color;
  final bool star;

  static List<_Particle> create(bool finale) {
    final random = math.Random(finale ? 307 : 101);
    const colors = [
      Color(0xFFFFD438),
      Color(0xFFFFF3B9),
      Color(0xFF2C59AD),
      Color(0xFFEF8A72),
      Color(0xFF95B968),
    ];
    return List.generate(finale ? 120 : 32, (index) {
      final side = index.isEven ? -1.0 : 1.0;
      return _Particle(
        // Stratify positions so every part of the screen stays populated.
        origin: Offset(
          ((index % 8) + random.nextDouble()) / 8,
          ((index ~/ 8) + random.nextDouble()) / (finale ? 15 : 4),
        ),
        velocity: Offset(side * (.015 + random.nextDouble() * .025), 1),
        delay: random.nextDouble() * math.pi * 2,
        radius: finale
            ? 3 + random.nextDouble() * 3
            : 2 + random.nextDouble() * 2,
        rotation: random.nextDouble() * math.pi,
        spin: (random.nextDouble() - .5) * (finale ? 8 : 1),
        color: colors[finale ? index % colors.length : index % 2],
        star: !finale || index % 5 == 0,
      );
    });
  }
}

class _VictoryPainter extends CustomPainter {
  _VictoryPainter({
    required this.progress,
    required this.launch,
    this.foregroundBounds,
    required this.particles,
    required this.grandFinale,
  }) : super(repaint: Listenable.merge([progress, launch]));

  final AnimationController progress;
  final Animation<double> launch;
  final Rect? Function()? foregroundBounds;
  final List<_Particle> particles;
  final bool grandFinale;

  @override
  void paint(Canvas canvas, Size size) {
    if (!progress.isAnimating) return;
    final phase = progress.value * math.pi * 2;
    final scale = (size.width / 358).clamp(.7, 1.2);
    final paint = Paint();
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final foreground = foregroundBounds?.call();
    if (foreground != null) {
      canvas.clipPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(Offset.zero & size),
          Path()..addRRect(
            RRect.fromRectAndRadius(
              foreground.inflate(4),
              const Radius.circular(20),
            ),
          ),
        ),
      );
    }
    for (final exploding in [
      if (grandFinale && launch.value < 1) true,
      false,
    ]) {
      for (final particle in particles) {
        var alpha = .85 + .15 * math.sin(phase + particle.delay);
        var x =
            (particle.origin.dx +
                particle.velocity.dx * math.sin(phase + particle.delay)) *
            size.width;
        // Recycle beyond the viewport instead of fading the celebration away.
        var y =
            ((particle.origin.dy + progress.value) % 1) * (size.height + 24) -
            12;
        if (exploding) {
          final t = launch.value * 2.6;
          final side = particle.velocity.dx < 0 ? -1.0 : 1.0;
          x = (.5 + side * (.06 + particle.origin.dx * .34) * t) * size.width;
          y =
              (.98 - (.65 + particle.origin.dy * .30) * t + .28 * t * t) *
              size.height;
          alpha = (1 - ((launch.value - .65) / .35).clamp(0.0, 1.0));
        } else if (grandFinale) {
          alpha *= ((launch.value - .35) / .45).clamp(0.0, 1.0);
        }
        final radius = particle.radius * scale;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(particle.rotation + particle.spin * math.sin(phase));
        if (!particle.star) {
          canvas.scale(
            .45 + .55 * math.cos(phase * 8 + particle.delay).abs(),
            1,
          );
        }
        final shape = Path();
        if (particle.star) {
          final points = grandFinale ? 5 : 4;
          for (var point = 0; point < points * 2; point++) {
            final angle = point * math.pi / points - math.pi / 2;
            final r = point.isEven ? radius : radius * .4;
            final dx = math.cos(angle) * r;
            final dy = math.sin(angle) * r;
            if (point == 0) {
              shape.moveTo(dx, dy);
            } else {
              shape.lineTo(dx, dy);
            }
          }
          shape.close();
        } else {
          shape.addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: radius,
                height: radius * 2,
              ),
              const Radius.circular(1),
            ),
          );
        }
        paint
          ..style = PaintingStyle.fill
          ..color = particle.color.withValues(alpha: alpha);
        canvas.drawPath(shape, paint);
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = .6 * scale
          ..color = const Color(0xFFFFF9DF).withValues(alpha: alpha * .75);
        canvas.drawPath(shape, paint);
        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_VictoryPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      particles != oldDelegate.particles ||
      grandFinale != oldDelegate.grandFinale;
}
