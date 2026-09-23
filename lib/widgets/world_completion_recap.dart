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

Future<bool?> showWorldCompletionRecap(
  BuildContext context,
  PlayerProfile player,
) => showDialog<bool>(
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
                SafeArea(
                  top: false,
                  child: IllustratedActionButton(
                    key: const ValueKey('world-recap-done'),
                    label: 'Ir al inicio',
                    compact: true,
                    fontSize: 22,
                    showPlayIcon: false,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
