import 'package:flutter/material.dart';

import 'settings_art.dart';
import 'ui_surface_art.dart';

enum MapGlyph { back, chevron, lock, goldStar, emptyStar }

/// Isolated source regions from the approved map artwork, preserving real alpha.
class MapIcon extends StatelessWidget {
  const MapIcon(this.glyph, {super.key, this.size = 32});

  final MapGlyph glyph;
  final double size;

  @override
  Widget build(BuildContext context) {
    final region = switch (glyph) {
      MapGlyph.goldStar => const Rect.fromLTRB(.018, .119, .325, .419),
      MapGlyph.emptyStar => const Rect.fromLTRB(.357, .119, .661, .419),
      MapGlyph.back => const Rect.fromLTRB(.686, .14, .985, .419),
      MapGlyph.chevron => const Rect.fromLTRB(.089, .607, .286, .900),
      MapGlyph.lock => const Rect.fromLTRB(.410, .635, .590, .876),
    };
    final aspect = region.width / region.height;
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: SizedBox(
          width: aspect <= 1 ? size * aspect : size,
          height: aspect <= 1 ? size : size / aspect,
          child: SettingsArtRegion(
            asset: 'assets/images/map/icons.png',
            region: region,
          ),
        ),
      ),
    );
  }
}

class MapRoundSurface extends StatelessWidget {
  const MapRoundSurface({super.key, this.gold = false});
  final bool gold;

  @override
  Widget build(BuildContext context) =>
      UiSurfaceArt(gold ? UiSurface.goldRound : UiSurface.creamRound);
}

class MapMarkerArt extends StatelessWidget {
  const MapMarkerArt({super.key, required this.gold});
  final bool gold;

  @override
  Widget build(BuildContext context) => SettingsArtRegion(
    asset: 'assets/images/map/marker-${gold ? 'gold' : 'ivory'}.png',
    region: gold
        ? const Rect.fromLTRB(.092, .075, .908, .906)
        : const Rect.fromLTRB(.041, .025, .957, .958),
  );
}
