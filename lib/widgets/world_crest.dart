import 'package:flutter/widgets.dart';

import 'settings_art.dart';

/// The same world totem is used on destinations and their frontier notices.
class WorldCrest extends StatelessWidget {
  const WorldCrest({super.key, required this.worldId});

  final String worldId;

  @override
  Widget build(BuildContext context) {
    final crest = switch (worldId) {
      'world-1' => ('sun', const Rect.fromLTRB(.049, .09, .952, .925)),
      'world-2' => ('mountain', const Rect.fromLTRB(.10, .107, .906, .933)),
      _ => ('water', const Rect.fromLTRB(.025, .208, .976, .875)),
    };
    return AspectRatio(
      aspectRatio: worldId == 'world-2' ? 1.95 : 2.17,
      child: SettingsArtRegion(
        asset: 'assets/images/world-selection/aventura-crest-${crest.$1}.png',
        region: crest.$2,
      ),
    );
  }
}
