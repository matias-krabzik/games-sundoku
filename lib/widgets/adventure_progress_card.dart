import 'package:flutter/material.dart';

import '../data/world_catalog.dart';
import 'home_art.dart';

/// The shared floating progress panel used on the home and adventure map.
class AdventureProgressCard extends StatelessWidget {
  const AdventureProgressCard({
    super.key,
    required this.level,
    required this.worldId,
    required this.unlockedLevels,
    this.levelName,
    this.leading,
    this.trailing,
    this.compact = false,
  });

  final int level;
  final String worldId;
  final int unlockedLevels;
  final String? levelName;
  final Widget? leading;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final world = adventureWorld(worldId);
    final onMap = levelName != null;
    return Semantics(
      label:
          'Nivel $level. ${world.name}. $unlockedLevels de ${world.nodes.length} niveles desbloqueados',
      explicitChildNodes: onMap,
      excludeSemantics: !onMap,
      child: onMap
          ? SizedBox(height: compact ? 145 : 168, child: _mapPanel(world))
          : AspectRatio(
              aspectRatio: 3.12,
              child: _panel(context, world.nodes.length, world.name),
            ),
    );
  }

  Widget _mapPanel(AdventureWorld world) => LayoutBuilder(
    builder: (context, _) {
      final small = compact;
      final inset = small ? 18.0 : 25.0;
      final totalLevels = world.nodes.length;
      return Stack(
        fit: StackFit.expand,
        children: [
          const HomeArt(HomeSurface.status),
          Padding(
            padding: EdgeInsets.fromLTRB(
              inset,
              small ? 12 : 16,
              inset,
              small ? 20 : 27,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  height: small ? 58 : 62,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      leading ?? const SizedBox(width: 48),
                      SizedBox(width: small ? 13 : 24),
                      Flexible(
                        child: SizedBox(
                          key: const ValueKey('map-level-summary'),
                          width: small ? 120 : 164,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Nivel $level',
                                  style: homeText(small ? 25 : 30),
                                  textScaler: TextScaler.noScaling,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$unlockedLevels / $totalLevels',
                                  style: homeText(small ? 15 : 17),
                                  textScaler: TextScaler.noScaling,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: small ? 13 : 24),
                      trailing ?? const SizedBox(width: 48),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: small ? 14 : 31),
                  child: _progressBar(
                    key: const ValueKey('map-level-progress'),
                    totalLevels: totalLevels,
                    height: small ? 16 : 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );

  Widget _panel(BuildContext context, int totalLevels, String worldName) =>
      Stack(
        fit: StackFit.expand,
        children: [
          const HomeArt(HomeSurface.status),
          LayoutBuilder(
            builder: (context, space) {
              final onMap = levelName != null;
              final unit = onMap
                  ? (space.maxWidth / 420).clamp(.72, 1.0)
                  : space.maxWidth / 350;
              return Padding(
                padding: onMap
                    ? EdgeInsets.fromLTRB(
                        20 * unit,
                        compact ? 10 : 15,
                        20 * unit,
                        compact ? 10 : 12,
                      )
                    : EdgeInsets.fromLTRB(
                        23 * unit,
                        17 * unit,
                        23 * unit,
                        16 * unit,
                      ),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (leading != null) ...[
                            leading!,
                            SizedBox(width: 3 * unit),
                          ],
                          Expanded(
                            child: _StatusLabel(
                              HomeGlyph.sun,
                              'Nivel $level',
                              iconSize: onMap ? 31 * unit : 37 * unit,
                              fontSize: onMap ? 19 * unit : 22 * unit,
                              gap: onMap ? 4 * unit : 7 * unit,
                            ),
                          ),
                          Container(
                            width: 1.2,
                            height: (onMap ? 29 : 32) * unit,
                            color: const Color(0xFFE1CCA3),
                          ),
                          SizedBox(width: (onMap ? 6 : 13) * unit),
                          Expanded(
                            child: _StatusLabel(
                              HomeGlyph.world,
                              worldName,
                              iconSize: onMap ? 31 * unit : 37 * unit,
                              fontSize: onMap ? 19 * unit : 22 * unit,
                              gap: onMap ? 4 * unit : 7 * unit,
                            ),
                          ),
                          if (trailing != null) ...[
                            SizedBox(width: 3 * unit),
                            trailing!,
                          ],
                        ],
                      ),
                    ),
                    if (levelName != null) ...[
                      SizedBox(height: compact ? 1 : 3),
                      SizedBox(
                        height: compact ? 18 : 23,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            levelName!,
                            key: const ValueKey('map-level-name'),
                            textAlign: TextAlign.center,
                            style: homeText(compact ? 17 : 21),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: onMap ? (compact ? 2 : 4) : 7 * unit),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: (onMap ? 24 : 20) * unit,
                      ),
                      child: _progressBar(
                        totalLevels: totalLevels,
                        height: onMap ? (compact ? 10 : 13) : 16 * unit,
                      ),
                    ),
                    SizedBox(height: onMap ? 2 : 3 * unit),
                    Text(
                      '$unlockedLevels de $totalLevels',
                      style: homeText(onMap ? (compact ? 12 : 14) : 15 * unit),
                      textScaler: TextScaler.noScaling,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      );

  Widget _progressBar({
    Key? key,
    required int totalLevels,
    required double height,
  }) => SizedBox(
    key: key,
    height: height,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const HomeArt(HomeSurface.progressTrack),
        Padding(
          padding: EdgeInsets.all(height * .1),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (unlockedLevels / totalLevels).clamp(0.0, 1.0),
              heightFactor: 1,
              child: const HomeArt(HomeSurface.progressFill),
            ),
          ),
        ),
      ],
    ),
  );
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel(
    this.glyph,
    this.label, {
    required this.iconSize,
    required this.fontSize,
    required this.gap,
  });

  final HomeGlyph glyph;
  final String label;
  final double iconSize;
  final double fontSize;
  final double gap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      HomeIcon(glyph, size: iconSize),
      SizedBox(width: gap),
      Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(label, style: homeText(fontSize)),
        ),
      ),
    ],
  );
}
