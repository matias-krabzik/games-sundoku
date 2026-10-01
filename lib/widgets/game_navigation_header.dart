import 'package:flutter/material.dart';

import 'game_feedback_scope.dart';
import 'game_layout.dart';
import 'home_art.dart';
import 'juicy_press.dart';
import 'map_art.dart';
import 'settings_art.dart';

class GameNavigationHeader extends StatelessWidget {
  const GameNavigationHeader({
    super.key,
    this.onBack,
    this.onSettings,
    this.center,
    this.pauseAction,
    this.backLabel = 'Volver al mapa',
  });
  final VoidCallback? onBack;
  final VoidCallback? onSettings;
  final Widget? center;
  final Widget? pauseAction;
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
      if (pauseAction == null) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            back,
            if (center != null) Expanded(child: Center(child: center)),
            settings,
          ],
        );
      }
      final actions = Row(
        mainAxisSize: MainAxisSize.min,
        children: [pauseAction!, const SizedBox(width: 8), settings],
      );
      const sideWidth = 116.0;
      if (center == null) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [back, actions],
        );
      }
      if (bounds.maxWidth < sideWidth * 2 + 300) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [back, actions],
            ),
            const SizedBox(height: 8),
            Center(child: center),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: sideWidth,
            child: Align(alignment: Alignment.centerLeft, child: back),
          ),
          Expanded(child: Center(child: center)),
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
