import 'package:flutter/material.dart';

import 'settings_art.dart';
import 'ui_surface_art.dart';

const homeNavy = Color(0xFF082A62);

enum HomeGlyph { sun, world, play, user }

class HomeIcon extends StatelessWidget {
  const HomeIcon(this.glyph, {super.key, this.size = 36});

  final HomeGlyph glyph;
  final double size;

  static const _regions = [
    Rect.fromLTRB(.055, .077, .459, .480),
    Rect.fromLTRB(.543, .103, .956, .480),
    Rect.fromLTRB(.098, .560, .440, .937),
    Rect.fromLTRB(.573, .557, .920, .944),
  ];

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: SettingsArtRegion(
      asset: 'assets/images/home/icons.png',
      region: _regions[glyph.index],
    ),
  );
}

enum HomeSurface {
  play,
  status,
  settings,
  profile,
  progressTrack,
  progressFill,
}

class HomeArt extends StatelessWidget {
  const HomeArt(
    this.surface, {
    super.key,
    this.playReferenceSize = const Size(244, 78),
  });

  final HomeSurface surface;
  final Size playReferenceSize;

  @override
  Widget build(BuildContext context) => UiSurfaceArt(switch (surface) {
    HomeSurface.play => UiSurface.goldButton,
    HomeSurface.status => UiSurface.creamPanel,
    HomeSurface.settings => UiSurface.creamRound,
    HomeSurface.profile => UiSurface.creamPill,
    HomeSurface.progressTrack => UiSurface.progressTrack,
    HomeSurface.progressFill => UiSurface.progressFill,
  }, referenceSize: surface == HomeSurface.play ? playReferenceSize : null);
}

TextStyle homeText(double size, {FontWeight weight = FontWeight.w800}) =>
    TextStyle(
      fontFamily: 'Baloo2',
      fontSize: size,
      color: homeNavy,
      height: 1.05,
      fontWeight: weight,
    );
