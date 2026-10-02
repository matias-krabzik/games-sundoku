import 'dart:math' as math;
import 'dart:ui';

/// The existing leaf touch physics, shared by every ambient particle.
abstract final class MapRadialPuff {
  static const radius = 220.0;
  static const duration = 2.0;

  static Offset impulseAt(
    Offset position,
    Offset center, {
    Offset fallback = const Offset(0, -1),
  }) {
    final delta = position - center;
    final distance = delta.distance;
    if (distance >= radius) return Offset.zero;
    final away = distance < 1 ? fallback : delta / distance;
    return away * (115 * (1 - distance / radius));
  }

  static Offset gustAt(Offset position, Offset center, double age) {
    final delta = position - center;
    final distance = delta.distance;
    final reach = (1 - distance / radius).clamp(0.0, 1.0);
    final strength =
        reach * math.pow((1 - age / duration).clamp(0.0, 1.0), 2) * 95;
    final away = distance < 1 ? const Offset(0, -1) : delta / distance;
    return away * strength;
  }

  static Offset decay(Offset impulse, double dt) =>
      impulse * math.exp(-dt * 3.5);
}
