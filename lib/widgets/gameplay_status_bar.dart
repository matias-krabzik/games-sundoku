import 'package:flutter/material.dart';

import 'settings_art.dart';

/// Unlimited lives in the introductory games.
class GameplayStatusBar extends StatelessWidget {
  const GameplayStatusBar({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Tooltip(
          message:
              'Vidas infinitas: puedes intentarlo todas las veces que quieras',
          child: Semantics(
            key: const ValueKey('game-unlimited-lives'),
            label: 'Vidas infinitas. No pierdes vidas al equivocarte.',
            image: true,
            excludeSemantics: true,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 19 * .878 / .674,
                  height: 19,
                  child: SettingsArtRegion(
                    asset: 'assets/images/tutorial/lives-icons.png',
                    region: Rect.fromLTRB(.028, .163, .467, .837),
                  ),
                ),
                SizedBox(width: 6),
                SizedBox(
                  width: 15 * .954 / .503,
                  height: 15,
                  child: SettingsArtRegion(
                    asset: 'assets/images/tutorial/lives-icons.png',
                    region: Rect.fromLTRB(.508, .250, .985, .753),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
