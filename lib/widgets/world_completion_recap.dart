import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/models/player_profile.dart';
import 'home_art.dart';
import 'illustrated_action_button.dart';
import 'settings_art.dart';
import 'tutorial_story.dart';

String worldCongratulations(PlayerProfile player) =>
    player.nameChosen && player.name.trim().isNotEmpty
    ? '¡Felicitaciones, ${player.name.trim()}!'
    : '¡Felicitaciones!';

enum WorldCompletionDestination { map, home }

Future<WorldCompletionDestination?> showWorldCompletionRecap(
  BuildContext context,
  PlayerProfile player,
) => showDialog<WorldCompletionDestination>(
  context: context,
  barrierDismissible: false,
  builder: (context) => Dialog(
    key: const ValueKey('world-completion-recap'),
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(16),
    child: LayoutBuilder(
      builder: (context, bounds) => SizedBox(
        width: bounds.maxWidth.clamp(0.0, 620.0),
        height: bounds.maxHeight.clamp(0.0, 760.0),
        child: SettingsPanelSurface(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          '¡Mundo completado!',
                          textAlign: TextAlign.center,
                          style: homeText(27),
                        ),
                        const SizedBox(height: 16),
                        TutorialStory(
                          key: const ValueKey('world-recap-story'),
                          showPanel: false,
                          padding: const EdgeInsets.all(8),
                          textStyle: homeText(
                            19,
                            weight: FontWeight.w500,
                          ).copyWith(height: 1.3),
                          skipHint: 'Toca para mostrar todo el repaso',
                          lines: [
                            [
                              worldCongratulations(player),
                              'Completaste el Valle del Sol. ¡Mira todo lo que aprendiste!',
                              'En cada fila, de lado a lado, van los números del 1 al 9 sin repetir.',
                              'En cada columna, de arriba abajo, también van del 1 al 9 sin repetir.',
                              'En cada bloque de 3×3, los nueve números aparecen una sola vez.',
                              'Los números que ya estaban en el tablero son tus pistas. ¡No se cambian!',
                              'Antes de colocar un número, mira su fila, su columna y su bloque.',
                            ].join('\n\n'),
                          ],
                          tip: '¡Desbloqueaste Partida rápida!\n\nAhora puedes elegir la dificultad y jugar nuevos sudokus para seguir practicando.\n\n¡Encontrarás tu próximo desafío en el inicio!',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SafeArea(top: false, child: const _RecapActions()),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);

class _RecapActions extends StatelessWidget {
  const _RecapActions();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final label = TextPainter(
        text: TextSpan(text: 'Volver al mapa', style: homeText(22)),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final naturalWidth = math.max(224.0, label.width.ceilToDouble() + 99);
      final height = math.max(70.0, label.height + 27);
      label.dispose();
      final width = bounds.maxWidth >= naturalWidth * 2 + 12
          ? (bounds.maxWidth - 12) / 2
          : bounds.maxWidth;
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          SizedBox(
            width: width,
            height: height,
            child: IllustratedActionButton(
              key: const ValueKey('world-recap-map'),
              label: 'Volver al mapa',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              compact: true,
              fontSize: 22,
              leadingIcon: const HomeIcon(HomeGlyph.map, size: 34),
              onPressed: () =>
                  Navigator.of(context).pop(WorldCompletionDestination.map),
            ),
          ),
          SizedBox(
            width: width,
            height: height,
            child: IllustratedActionButton(
              key: const ValueKey('world-recap-done'),
              label: 'Ir al inicio',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              compact: true,
              secondary: true,
              // Match the gold artwork's transparent outer margins.
              artPadding: const EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 4,
              ),
              fontSize: 22,
              leadingIcon: const SizedBox.square(
                dimension: 34,
                child: Center(
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(homeNavy, BlendMode.srcIn),
                    child: HomeIcon(HomeGlyph.sun, size: 26),
                  ),
                ),
              ),
              onPressed: () =>
                  Navigator.of(context).pop(WorldCompletionDestination.home),
            ),
          ),
        ],
      );
    },
  );
}
