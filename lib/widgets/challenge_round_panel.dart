import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/first_experience_controller.dart';
import '../domain/scoring/adventure_challenge.dart';
import 'game_pause.dart';
import 'home_art.dart';
import 'illustrated_action_button.dart';
import 'map_art.dart';
import 'score_feedback.dart';
import 'ui_surface_art.dart';

/// Static presentation of an already saved result, also used before first play.
/// Awards and attempt transitions belong to the repository, never this widget.
class ChallengeRoundPanel extends StatelessWidget {
  const ChallengeRoundPanel({
    super.key,
    required this.flow,
    required this.onExit,
  });
  final FirstExperienceController flow;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final board = flow.puzzleProgress!;
    final rules = board.attempt!.rules;
    final result = board.attempt!.result;
    final ready = result == null;
    final won = result?.outcome == ChallengeOutcome.won;
    final title = ready
        ? 'Tu próximo desafío'
        : switch (result.outcome) {
            ChallengeOutcome.won => '¡Estrella conseguida!',
            ChallengeOutcome.outOfTime => 'Se acabó el tiempo',
            ChallengeOutcome.outOfLives => 'Te quedaste sin vidas',
            ChallengeOutcome.belowTarget => 'Faltaron algunos puntos',
            _ => 'Inténtalo otra vez',
          };
    final message = ready
        ? 'Completa el sudoku a tiempo y alcanza la meta con vidas disponibles.'
        : switch (result.outcome) {
            ChallengeOutcome.won =>
              'Completaste el sudoku y alcanzaste la meta.',
            ChallengeOutcome.belowTarget =>
              'Te faltaron ${formatScore(rules.targetPoints - board.points)} puntos para esta estrella.',
            ChallengeOutcome.hintsNotAllowed => 'Este desafío es sin pistas.',
            ChallengeOutcome.mistakesNotAllowed =>
              'Este desafío requiere terminar sin errores.',
            _ => 'Puedes volver a intentar esta ronda. Tus estrellas anteriores se conservan.',
          };
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: title,
      child: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Center(
          child: LayoutBuilder(
            builder: (context, bounds) {
              final compact = bounds.maxHeight < 500;
              return SizedBox(
                width: math.min(540, bounds.maxWidth),
                height: math.min(520, bounds.maxHeight),
                child: UiSurfacePanel(
                  key: ValueKey(ready ? 'challenge-ready' : 'challenge-result'),
                  surface: UiSurface.goldCreamPanel,
                  padding: EdgeInsets.all(compact ? 16 : 26),
                  child: Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, contentBounds) => SingleChildScrollView(
                            key: const ValueKey('challenge-panel-scroll'),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: contentBounds.maxHeight,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Nivel ${flow.levelNumber} · Ronda ${flow.gameIndex + 1} de 3',
                                    style: homeText(17),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    title,
                                    key: const ValueKey(
                                      'challenge-result-title',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: homeText(compact ? 24 : 30),
                                  ),
                                  const SizedBox(height: 12),
                                  Semantics(
                                    label:
                                        '${flow.session!.lights} de 3 estrellas ganadas',
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        for (var i = 0; i < 3; i++)
                                          MapIcon(
                                            i < flow.session!.lights
                                                ? MapGlyph.goldStar
                                                : MapGlyph.emptyStar,
                                            size: compact ? 40 : 56,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    message,
                                    style: homeText(19),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    ready
                                        ? 'Meta: ${formatScore(rules.targetPoints)} puntos'
                                        : '${formatScore(board.points)} / ${formatScore(rules.targetPoints)} puntos',
                                    key: const ValueKey(
                                      'challenge-panel-points',
                                    ),
                                    style: homeText(24),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    ready
                                        ? '${rules.initialLives} ${rules.initialLives == 1 ? 'vida' : 'vidas'} · ${formatPlayTime(rules.timeLimitMs)}'
                                        : '${rules.remainingLives(board.mistakes)}/${rules.initialLives} vidas · ${formatPlayTime(board.elapsedMs)} jugados',
                                    style: homeText(19),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (!rules.allowsHints) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      'Sin errores ni pistas',
                                      style: homeText(19),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                  if (flow.error != null) ...[
                                    const SizedBox(height: 12),
                                    Semantics(
                                      liveRegion: true,
                                      child: Text(
                                        flow.error!,
                                        style: homeText(17),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      IllustratedActionButton(
                        key: const ValueKey('challenge-primary'),
                        label: flow.isBusy
                            ? 'Guardando…'
                            : ready
                            ? 'Jugar'
                            : won
                            ? 'Continuar'
                            : 'Reintentar',
                        compact: compact,
                        fontSize: compact ? 20 : 24,
                        onPressed: flow.isBusy
                            ? null
                            : ready
                            ? flow.resumeGame
                            : won
                            ? () => flow.advance()
                            : flow.retryChallenge,
                      ),
                      TextButton(
                        onPressed: flow.isBusy ? null : onExit,
                        child: Text('Volver al mapa', style: homeText(17)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
