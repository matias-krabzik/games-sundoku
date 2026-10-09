import 'package:flutter/material.dart';

import 'game_feedback_scope.dart';
import 'game_layout.dart';
import 'home_art.dart';
import 'juicy_press.dart';
import 'map_art.dart';
import 'settings_art.dart';
import 'ui_surface_art.dart';

class GameNavigationHeader extends StatelessWidget {
  const GameNavigationHeader({
    super.key,
    this.onBack,
    this.onSettings,
    this.center,
    this.pauseAction,
    this.sharedPanel = false,
    this.backLabel = 'Volver al mapa',
  });
  final VoidCallback? onBack;
  final VoidCallback? onSettings;
  final Widget? center;
  final Widget? pauseAction;
  final bool sharedPanel;
  final String backLabel;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final back = GameHeaderButton(
        key: const ValueKey('game-back'),
        label: backLabel,
        onPressed: onBack,
        icon: const MapIcon(MapGlyph.back, size: 29),
      );
      final settings = GameHeaderButton(
        key: const ValueKey('game-settings'),
        label: 'Configuración',
        onPressed: onSettings,
        icon: const SettingsIcon(SettingsGlyph.gear, size: 33),
      );
      final actions = pauseAction == null
          ? settings
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [pauseAction!, const SizedBox(width: 8), settings],
            );
      if (sharedPanel && center != null) {
        return SizedBox(
          height: GameLayout.controlSize + GameLayout.mobileHeaderInset * 2,
          child: UiSurfacePanel(
            key: const ValueKey('intro-header'),
            surface: UiSurface.goldCreamPanel,
            padding: const EdgeInsets.all(GameLayout.mobileHeaderInset),
            child: Row(
              children: [
                back,
                const SizedBox(width: 8),
                Expanded(child: center!),
                if (pauseAction != null) ...[
                  const SizedBox(width: 8),
                  pauseAction!,
                ],
                const SizedBox(width: 8),
                settings,
              ],
            ),
          ),
        );
      }
      if (pauseAction == null) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            back,
            if (center != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(child: center),
                ),
              ),
            settings,
          ],
        );
      }
      const sideWidth = 116.0;
      if (center == null) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [back, actions],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: bounds.maxWidth >= sideWidth * 2 + 300
                ? sideWidth
                : GameLayout.controlSize,
            child: Align(alignment: Alignment.centerLeft, child: back),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: center),
            ),
          ),
          SizedBox(
            width: sideWidth,
            child: Align(alignment: Alignment.centerRight, child: actions),
          ),
        ],
      );
    },
  );
}

class GameHeaderButton extends StatelessWidget {
  const GameHeaderButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: GameLayout.controlSize,
    child: JuicyPress(
      label: label,
      onFeedback: () => GameFeedbackScope.tap(context),
      onPressed: onPressed,
      builder: (_, _) => Opacity(
        opacity: onPressed == null ? .5 : 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const HomeArt(HomeSurface.settings),
            Center(child: icon),
          ],
        ),
      ),
    ),
  );
}
