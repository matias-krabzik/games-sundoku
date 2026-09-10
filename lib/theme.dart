import 'package:flutter/material.dart';

/// Palette for the "Sol" world — warm, sunny, high-contrast for young players.
const Color kSunOrange = Color(0xFFFF8A00);
const Color kSunYellow = Color(0xFFFFC93C);
const Color kSunRay = Color(0xFFFFB000);
const Color kSunFace = Color(0xFF5B3A00);
const Color kSkyTop = Color(0xFFFFF6E0);
const Color kSkyBottom = Color(0xFFFFE3AC);

/// Background used by the splash and home screens.
const LinearGradient sunSkyGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [kSkyTop, kSkyBottom],
);

ThemeData buildSunDokuTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: kSunOrange,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kSkyTop,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kSunOrange,
        foregroundColor: Colors.white,
        minimumSize: const Size(240, 60),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
  );
}
