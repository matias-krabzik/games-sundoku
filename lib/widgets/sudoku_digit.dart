import 'package:flutter/material.dart';

import 'home_art.dart';

/// Glossy blue numerals remain real Flutter text at every board size.
class SudokuDigit extends StatelessWidget {
  const SudokuDigit(this.value, {super.key, required this.size});
  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = homeText(size, weight: FontWeight.w900).copyWith(height: 1);
    return ExcludeSemantics(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '$value',
            textScaler: TextScaler.noScaling,
            style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = size * .035
                ..color = const Color(0xFF001B65),
              shadows: [
                Shadow(
                  color: const Color(0x50001763),
                  offset: Offset(0, size * .035),
                  blurRadius: size * .025,
                ),
              ],
            ),
          ),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1261FF),
                Color(0xFF82BAFF),
                Color(0xFF0755F5),
                Color(0xFF0034BD),
                Color(0xFF001B65),
              ],
              stops: [0, .23, .34, .64, 1],
            ).createShader(bounds),
            child: Text(
              '$value',
              textScaler: TextScaler.noScaling,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
