import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(38),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0, .09, .4, .84, 1],
        colors: [
          Color(0xFFFFF6AF),
          Color(0xFFFFD52D),
          Color(0xFFFFCB20),
          Color(0xFFFFB615),
          Color(0xFFF5980A),
        ],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x6007203D),
          blurRadius: 32,
          offset: Offset(0, 15),
        ),
        BoxShadow(color: Color(0xFFF0A012), offset: Offset(0, 3)),
      ],
      border: Border.all(color: const Color(0xFFFFE99B), width: 1.5),
    ),
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(31),
          border: Border.all(color: const Color(0xFFFFFFF4), width: 2),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFCF4), Color(0xFFFFF8E8), Color(0xFFFFEBCB)],
          ),
          boxShadow: const [BoxShadow(color: Color(0x55CC8309), blurRadius: 3)],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(29), child: child),
      ),
    ),
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
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(circular ? 100 : 36),
      boxShadow: [
        BoxShadow(
          color: const Color(0x42A66514),
          blurRadius: 6 - depression * 3,
          offset: Offset(0, 5 - depression * 4),
        ),
      ],
    ),
    child: circular
        ? Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFA3),
                  Color(0xFFFFD834),
                  Color(0xFFFFB609),
                ],
              ),
              border: Border.all(color: const Color(0xFFFFE582), width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0xFFF4A10E), offset: Offset(0, 2)),
              ],
            ),
            child: Padding(padding: const EdgeInsets.all(9), child: child),
          )
        : Stack(
            fit: StackFit.expand,
            children: [
              const SettingsArtRegion(
                asset: 'assets/images/settings/done-button.png',
                region: Rect.fromLTRB(.04, .205, .96, .755),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: FittedBox(fit: BoxFit.scaleDown, child: child),
                ),
              ),
            ],
          ),
  );
}
