import 'package:flutter/material.dart';

import 'settings_art.dart';

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
  const HomeArt(this.surface, {super.key});

  final HomeSurface surface;

  @override
  Widget build(BuildContext context) {
    final (asset, region) = switch (surface) {
      HomeSurface.play => (
        'play-button',
        const Rect.fromLTRB(.115, .160, .88, .850),
      ),
      HomeSurface.status => (
        'status-panel',
        const Rect.fromLTRB(.040, .080, .960, .880),
      ),
      HomeSurface.settings => (
        'header-surfaces',
        const Rect.fromLTRB(.322, .137, .673, .487),
      ),
      HomeSurface.profile => (
        'header-surfaces',
        const Rect.fromLTRB(.089, .584, .911, .846),
      ),
      HomeSurface.progressTrack => (
        'progress',
        const Rect.fromLTRB(.033, .234, .967, .406),
      ),
      HomeSurface.progressFill => (
        'progress',
        const Rect.fromLTRB(.033, .590, .967, .758),
      ),
    };
    final art = SettingsArtRegion(
      asset: 'assets/images/home/$asset.png',
      region: region,
    );
    return surface == HomeSurface.progressTrack ||
            surface == HomeSurface.progressFill
        ? ClipRRect(borderRadius: BorderRadius.circular(999), child: art)
        : art;
  }
}

TextStyle homeText(double size, {FontWeight weight = FontWeight.w800}) =>
    TextStyle(
      fontFamily: 'Baloo2',
      fontSize: size,
      color: homeNavy,
      height: 1.05,
      fontWeight: weight,
    );
