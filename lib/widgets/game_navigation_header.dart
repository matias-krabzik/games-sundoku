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
  });
  final VoidCallback? onBack;
  final VoidCallback? onSettings;
  final Widget? center;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _GameHeaderButton(
        key: const ValueKey('game-back'),
        label: 'Volver al mapa',
        onPressed: onBack,
        icon: const MapIcon(MapGlyph.back, size: 29),
      ),
      if (center != null) Expanded(child: Center(child: center)),
      _GameHeaderButton(
        key: const ValueKey('game-settings'),
        label: 'Configuración',
        onPressed: onSettings,
        icon: const SettingsIcon(SettingsGlyph.gear, size: 33),
      ),
    ],
  );
}

class _GameHeaderButton extends StatelessWidget {
  const _GameHeaderButton({
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
