import 'package:flutter/material.dart';

import 'game_layout.dart';
import 'settings_art.dart';
import 'score_feedback.dart';
import 'ui_surface_art.dart';
import 'challenge_lives.dart';

/// Shared game HUD, with optional lives and target for adventure challenges.
class GameplayStatusBar extends StatelessWidget {
  const GameplayStatusBar({
    super.key,
    this.trailing,
    this.points = 0,
    this.scale = 1,
    this.illustrated = false,
    this.height,
    this.initialLives,
    this.remainingLives,
    this.targetPoints,
  });
  final double scale;
  final int points;
  final Widget? trailing;
  final bool illustrated;
  final double? height;
  final int? initialLives;
  final int? remainingLives;
  final int? targetPoints;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: initialLives != null
                  ? ChallengeLives(
                      key: const ValueKey('game-limited-lives'),
                      remaining: remainingLives ?? initialLives!,
                      total: initialLives!,
                      size: 22 * scale,
                    )
                  : Semantics(
                      key: const ValueKey('game-unlimited-lives'),
                      label:
                          'Vidas infinitas. No pierdes vidas al equivocarte.',
                      image: true,
                      excludeSemantics: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 19 * .878 / .674 * scale,
                            height: 19 * scale,
                            child: const SettingsArtRegion(
                              asset: 'assets/images/tutorial/lives-icons.png',
                              region: Rect.fromLTRB(.028, .163, .467, .837),
                            ),
                          ),
                          SizedBox(width: 6 * scale),
                          SizedBox(
                            width: 15 * .954 / .503 * scale,
                            height: 15 * scale,
                            child: const SettingsArtRegion(
                              asset: 'assets/images/tutorial/lives-icons.png',
                              region: Rect.fromLTRB(.508, .250, .985, .753),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: GameScoreCounter(
                points: points,
                fontSize: 20 * scale,
                targetPoints: targetPoints,
              ),
            ),
          ),
        ),
        if (trailing != null)
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(fit: BoxFit.scaleDown, child: trailing!),
            ),
          ),
      ],
    );
    if (illustrated) {
      final panelHeight =
          height ??
          GameLayout.playStatusHeight(
            compact: false,
            textHeight: MediaQuery.textScalerOf(context).scale(20 * scale),
            large: scale > 1,
          );
      final extraPadding = scale > 1 ? GameLayout.largePlayStatusPadding : 0.0;
      final padding = EdgeInsets.symmetric(
        horizontal: 20 + extraPadding,
        vertical: extraPadding,
      );
      return UiSurfacePanel(
        key: const ValueKey('game-status-panel'),
        surface: UiSurface.creamPanel,
        constraints: BoxConstraints(minHeight: panelHeight),
        padding: padding,
        child: SizedBox(
          height: panelHeight - padding.vertical,
          child: Center(child: content),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: content,
    );
  }
}
