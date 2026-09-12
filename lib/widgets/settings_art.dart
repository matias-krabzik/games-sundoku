import 'package:flutter/material.dart';

import 'ui_surface_art.dart';

const settingsNavy = Color(0xFF082A62);

/// The atlas contains isolated artwork extracted from the approved mockup.
enum SettingsGlyph {
  gear,
  music,
  sound,
  vibration,
  info,
  check,
  close,
  chevron,
}

class SettingsIcon extends StatelessWidget {
  const SettingsIcon(this.glyph, {super.key, this.size = 36});
  final SettingsGlyph glyph;
  final double size;

  @override
  Widget build(BuildContext context) {
    final column = glyph.index % 4;
    final row = glyph.index ~/ 4;
    return SizedBox.square(
      dimension: size,
      child: SettingsArtRegion(
        asset: 'assets/images/settings/icons.png',
        region: Rect.fromLTWH(
          (column + .08) / 4,
          (row + .08) / 2,
          .84 / 4,
          .84 / 2,
        ),
      ),
    );
  }
}

/// Clips a normalized source rectangle without resampling the saved artwork.
class SettingsArtRegion extends StatelessWidget {
  const SettingsArtRegion({
    super.key,
    required this.asset,
    required this.region,
  });
  final String asset;
  final Rect region;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth / region.width;
        final height = constraints.maxHeight / region.height;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: width,
            maxWidth: width,
            minHeight: height,
            maxHeight: height,
            child: Transform.translate(
              offset: Offset(-region.left * width, -region.top * height),
              child: Image.asset(
                asset,
                width: width,
                height: height,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        );
      },
    ),
  );
}

class SettingsPanelSurface extends StatelessWidget {
  const SettingsPanelSurface({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => UiSurfacePanel(
    padding: const EdgeInsets.all(6),
    child: ClipRRect(borderRadius: BorderRadius.circular(24), child: child),
  );
}

class SettingsGoldSurface extends StatelessWidget {
  const SettingsGoldSurface({
    super.key,
    required this.child,
    this.circular = false,
    this.depression = 0,
  });
  final Widget child;
  final bool circular;
  final double depression;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      UiSurfaceArt(circular ? UiSurface.goldRound : UiSurface.goldButton),
      Center(
        child: Padding(
          padding: circular
              ? const EdgeInsets.all(9)
              : const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: FittedBox(fit: BoxFit.scaleDown, child: child),
        ),
      ),
    ],
  );
}
