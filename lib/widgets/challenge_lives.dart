import 'package:flutter/material.dart';

import 'settings_art.dart';

/// Individual hearts shared by the lesson and live challenge HUD.
class ChallengeLives extends StatelessWidget {
  const ChallengeLives({
    super.key,
    required this.remaining,
    required this.total,
    this.size = 22,
  });

  final int remaining;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$remaining de $total vidas',
    image: true,
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          Opacity(
            key: ValueKey('challenge-heart-$i'),
            opacity: i < remaining ? 1 : .22,
            child: SizedBox(
              width: size,
              height: size,
              child: const SettingsArtRegion(
                asset: 'assets/images/tutorial/lives-icons.png',
                region: Rect.fromLTRB(.028, .163, .467, .837),
              ),
            ),
          ),
      ],
    ),
  );
}
