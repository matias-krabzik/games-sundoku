import 'package:flutter/material.dart';

import '../data/world_catalog.dart';
import '../models/world_map_definition.dart';
import 'settings_art.dart';
import 'ui_surface_art.dart';

/// A small view of the world's existing artwork, framed with the shared tile.
class WorldThumbnail extends StatelessWidget {
  const WorldThumbnail({super.key, required this.worldId, required this.size});

  final String worldId;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (worldId == 'world-2') {
      return SizedBox.square(
        dimension: size,
        child: const SettingsArtRegion(
          asset: 'assets/images/map/world-2-thumbnail.png',
          region: Rect.fromLTRB(.124, .129, .876, .850),
        ),
      );
    }
    final world = adventureWorld(worldId);
    final terrain = world.map.layers
        .firstWhere(
          (layer) => layer.plane == MapLayerPlane.terrain,
          orElse: () => world.map.layers.last,
        )
        .asset;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const UiSurfaceArt(UiSurface.goldTile),
          Padding(
            padding: EdgeInsets.all(size * .085),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size * .14),
              child: ColoredBox(
                color: world.map.backgroundColor,
                child: Image.asset(
                  worldId == 'world-1'
                      ? 'assets/images/home-background.png'
                      : terrain,
                  fit: BoxFit.cover,
                  alignment: worldId == 'world-1'
                      ? const Alignment(0, -.1)
                      : const Alignment(.9, -.1),
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
