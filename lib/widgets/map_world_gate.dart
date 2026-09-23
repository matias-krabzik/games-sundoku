import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_feedback_scope.dart';
import 'juicy_press.dart';

/// Sun center in the unpadded 2172 × 724 map artwork.
const mapWorldGateAnchor = Offset(1982 / 2172, 179 / 724);

/// Scales with the arch while retaining a 48 px minimum touch target.
double mapWorldGateArtworkSize(double worldHeight) => 104 * worldHeight / 724;
double mapWorldGateTouchSize(double worldHeight) =>
    math.max(48, mapWorldGateArtworkSize(worldHeight));

/// The original arch emblem, illuminated after all of the world's rounds.
/// Navigation stays disabled until a next-world destination is supplied.
class MapWorldGate extends StatelessWidget {
  const MapWorldGate({
    super.key,
    required this.unlocked,
    required this.artworkSize,
    this.onPressed,
  });

  final bool unlocked;
  final double artworkSize;
  final FutureOr<void> Function()? onPressed;

  static const asset = 'assets/images/map/gate-sun.png';
  static const _muted = ColorFilter.matrix([
    .2126,
    .7152,
    .0722,
    0,
    0,
    .2126,
    .7152,
    .0722,
    0,
    0,
    .2126,
    .7152,
    .0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  Widget build(BuildContext context) {
    final artwork = Image.asset(
      asset,
      width: artworkSize,
      height: artworkSize,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
    return Semantics(
      value: unlocked
          ? 'Mundo 1 completado'
          : 'Completa todas las rondas del mundo 1',
      child: JuicyPress(
        label: 'Próximo mundo',
        onPressed: unlocked ? onPressed : null,
        onFeedback: () => GameFeedbackScope.tap(context),
        builder: (context, depression) => SizedBox.square(
          dimension: math.max(48, artworkSize),
          child: Center(
            child: SizedBox.square(
              dimension: artworkSize,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (unlocked)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFD967).withValues(alpha: .65),
                            const Color(0xFFFFD967).withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  unlocked
                      ? artwork
                      : ColorFiltered(colorFilter: _muted, child: artwork),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
