import 'package:flutter/material.dart';

import 'settings_art.dart';

enum TutorialGlyph { guide, rays, arrow }

/// Decorative drawings are cropped independently and preserve their proportions.
class TutorialBlockArt extends StatelessWidget {
  const TutorialBlockArt(this.glyph, {super.key});
  final TutorialGlyph glyph;

  @override
  Widget build(BuildContext context) {
    final region = switch (glyph) {
      TutorialGlyph.guide => const Rect.fromLTRB(.045, .020, .590, .940),
      TutorialGlyph.rays => const Rect.fromLTRB(.700, .075, .882, .515),
      TutorialGlyph.arrow => const Rect.fromLTRB(.675, .575, .875, .935),
    };
    return ExcludeSemantics(
      child: Center(
        child: AspectRatio(
          aspectRatio: 1536 * region.width / (1024 * region.height),
          child: SettingsArtRegion(
            asset: 'assets/images/tutorial/block-guide-atlas.png',
            region: region,
          ),
        ),
      ),
    );
  }
}
