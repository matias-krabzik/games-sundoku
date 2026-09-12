import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/first_experience_controller.dart';
import 'home_art.dart';
import 'illustrated_action_button.dart';
import 'map_art.dart';
import 'tutorial_block_art.dart';
import 'tutorial_block_controls.dart';
import 'ui_surface_art.dart';

/// The board is supplied by the route so its element survives every lesson.
class TutorialJourney extends StatelessWidget {
  const TutorialJourney({
    super.key,
    required this.flow,
    required this.board,
    required this.header,
    required this.onExit,
  });
  final FirstExperienceController flow;
  final Widget board;
  final Widget header;
  final VoidCallback onExit;

  bool get _playing => flow.step == FirstExperienceStep.playing;
  bool get _celebrating =>
      flow.step == FirstExperienceStep.celebration ||
      flow.step == FirstExperienceStep.complete;

  static String title(FirstExperienceController flow) =>
      flow.lesson?.title ??
      switch (flow.step) {
        FirstExperienceStep.gameIntroduction => [
          'Jugamos juntos',
          'Ahora eliges tú',
          '¡Tú puedes!',
        ][flow.gameIndex],
        FirstExperienceStep.givensIntroduction => 'Listo para jugar',
        FirstExperienceStep.inputIntroduction => 'Así ponemos un número',
        FirstExperienceStep.playing => 'Sudoku ${flow.gameIndex + 1} de 3',
        FirstExperienceStep.celebration => '¡Sudoku completo!',
        FirstExperienceStep.complete => '¡Completaste el nivel 1!',
        _ => 'Tu primer sudoku',
      };

  String get _message => flow.lesson != null
      ? flow.lessonMessage
      : switch (flow.step) {
          FirstExperienceStep.gameIntroduction => [
            'Tu bloque sigue aquí.\nDoku te ayudará a completar el tablero.',
            'Ahora elige tú la casilla.\nSi necesitas ayuda, toca «Pista».',
            '¡Vamos con el tercero!\nPuedes pedir una pista cuando quieras.',
          ][flow.gameIndex],
          FirstExperienceStep.givensIntroduction => 'Las pistas no se cambian.\nToca una casilla vacía y elige un número.',
          FirstExperienceStep.inputIntroduction =>
            'Toca una casilla vacía.\nDespués toca un número para ponerlo.',
          FirstExperienceStep.playing => flow.playMessage,
          FirstExperienceStep.celebration => [
            '¡Resolviste tu primer sudoku!\nGanaste una estrella.',
            '¡Ya tienes dos estrellas!\nVamos por la tercera.',
            '¡Tres sudokus resueltos!\nGanaste las tres estrellas.',
          ][flow.gameIndex],
          FirstExperienceStep.complete =>
            'El nivel 2 ya está abierto.\n¡Doku te espera en el mapa!',
          _ => '',
        };

  String get _action =>
      flow.reviewOnly && flow.storyIndex == flow.storyCount - 1
      ? 'Volver al mapa'
      : flow.lesson?.action ??
            switch (flow.step) {
              FirstExperienceStep.gameIntroduction => 'Ver las pistas',
              FirstExperienceStep.givensIntroduction =>
                flow.session?.lights == 3 ? 'Terminar repaso' : 'Jugar',
              FirstExperienceStep.inputIntroduction => 'Empezar',
              FirstExperienceStep.playing =>
                !flow.readyToPlay && flow.error != null
                    ? 'Reintentar'
                    : flow.confirmingMove
                    ? 'Seguir'
                    : flow.hint != null && !flow.showingAnswer
                    ? 'Ver el número'
                    : 'Pista',
              FirstExperienceStep.celebration => [
                'Vamos al segundo',
                'Vamos al tercero',
                'Ver mi logro',
              ][flow.gameIndex],
              FirstExperienceStep.complete => 'Volver al mapa',
              _ => 'Siguiente',
            };

  Future<void> _advance() async {
    if (flow.step == FirstExperienceStep.complete ||
        (flow.reviewOnly && flow.storyIndex == flow.storyCount - 1)) {
      onExit();
    } else if (_playing) {
      if (!flow.readyToPlay) {
        await flow.resumeGame();
      } else if (flow.confirmingMove) {
        flow.continuePlaying();
      } else {
        await flow.requestHint();
      }
    } else {
      await flow.advance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, bounds) {
        final wide =
            bounds.maxWidth >= 700 && bounds.maxWidth > bounds.maxHeight * 1.2;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: wide ? 950 : 502),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                children: [
                  header,
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, body) {
                        final boardWidth = math.min(
                          wide ? body.maxWidth * .47 : body.maxWidth,
                          430.0,
                        );
                        final boardArea = SizedBox(
                          width: boardWidth,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Keep the real board mounted, even behind the celebration.
                              IgnorePointer(
                                ignoring: _celebrating,
                                child: ExcludeSemantics(
                                  excluding: _celebrating,
                                  child: Opacity(
                                    opacity: _celebrating ? 0 : 1,
                                    child: Row(
                                      children: [
                                        if (_playing) ...[
                                          TutorialEraseButton(
                                            onPressed:
                                                flow.readyToPlay &&
                                                    !flow.confirmingMove &&
                                                    flow.gameCell != null &&
                                                    !flow.fixedIndices.contains(
                                                      flow.gameCell,
                                                    ) &&
                                                    flow.boardValues[flow
                                                            .gameCell!] !=
                                                        null
                                                ? flow.clearGameCell
                                                : null,
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Expanded(
                                          child: AspectRatio(
                                            aspectRatio: 1,
                                            child: board,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (_celebrating)
                                Positioned.fill(
                                  child: TutorialReward(
                                    key: ValueKey('reward-${flow.gameIndex}'),
                                    stars: flow.session?.lights ?? 0,
                                  ),
                                ),
                            ],
                          ),
                        );
                        final information = Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_playing) ...[
                              const SizedBox(height: 4),
                              TutorialNumberTray(
                                available: [
                                  for (var n = 1; n <= 9; n++)
                                    if (flow.boardValues
                                            .where((v) => v == n)
                                            .length <
                                        9)
                                      n,
                                ],
                                onSelected:
                                    flow.readyToPlay &&
                                        !flow.confirmingMove &&
                                        flow.gameCell != null
                                    ? flow.placeGameNumber
                                    : null,
                              ),
                              const SizedBox(height: 8),
                            ] else if (!_celebrating && wide == false)
                              const SizedBox(height: 12),
                            TutorialLessonCard(
                              message: _message,
                              messageKey:
                                  '${flow.step}-${flow.gameCell}-${flow.playMessage}',
                              progress: _playing
                                  ? '${flow.remaining} casillas por completar'
                                  : null,
                            ),
                            if (flow.step ==
                                    FirstExperienceStep.blockIntroduction &&
                                flow.session == null &&
                                !flow.reviewOnly)
                              TextButton(
                                key: const ValueKey('tutorial-choose-order'),
                                onPressed: flow.isBusy ? null : flow.startBlock,
                                child: Text(
                                  'Elegir el orden',
                                  style: homeText(16),
                                ),
                              ),
                            if (flow.step == FirstExperienceStep.complete)
                              TextButton(
                                key: const ValueKey('tutorial-review'),
                                onPressed: flow.isBusy
                                    ? null
                                    : flow.repeatLessons,
                                child: Text(
                                  'Repasar las reglas',
                                  style: homeText(17),
                                ),
                              ),
                            if (flow.error != null)
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    flow.error!,
                                    textAlign: TextAlign.center,
                                    style: homeText(16),
                                  ),
                                ),
                              ),
                          ],
                        );
                        return SingleChildScrollView(
                          key: const ValueKey('intro-scroll'),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: body.maxHeight,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: wide
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        boardArea,
                                        const SizedBox(width: 24),
                                        Expanded(child: information),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [boardArea, information],
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: IllustratedActionButton(
                      key: const ValueKey('tutorial-next'),
                      compact: bounds.maxHeight < 650,
                      showPlayIcon: !_playing,
                      fontSize: 23,
                      label: flow.isBusy ? 'Guardando…' : _action,
                      onPressed: flow.isBusy ? null : _advance,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class TutorialLessonCard extends StatelessWidget {
  const TutorialLessonCard({
    super.key,
    required this.message,
    required this.messageKey,
    this.progress,
  });
  final String message;
  final String messageKey;
  final String? progress;

  @override
  Widget build(BuildContext context) => UiSurfacePanel(
    surface: UiSurface.goldCreamPanel,
    padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          liveRegion: true,
          child: TweenAnimationBuilder<double>(
            key: ValueKey(messageKey),
            tween: Tween(begin: 0, end: 1),
            duration:
                MediaQuery.disableAnimationsOf(context) ||
                    MediaQuery.accessibleNavigationOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 350),
            builder: (_, value, child) => Opacity(opacity: value, child: child),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: homeText(20),
            ),
          ),
        ),
        if (progress != null) ...[
          const SizedBox(height: 8),
          Text(
            progress!,
            textAlign: TextAlign.center,
            style: homeText(15, weight: FontWeight.w600),
          ),
        ],
      ],
    ),
  );
}

class TutorialReward extends StatelessWidget {
  const TutorialReward({super.key, required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$stars de 3 estrellas ganadas',
    image: true,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: const TutorialBlockArt(TutorialGlyph.guide)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration:
                    MediaQuery.disableAnimationsOf(context) ||
                        MediaQuery.accessibleNavigationOf(context)
                    ? Duration.zero
                    : Duration(milliseconds: 450 + i * 180),
                builder: (_, progress, child) => Transform.scale(
                  scale: .6 + .4 * Curves.easeOutBack.transform(progress),
                  child: Opacity(opacity: progress, child: child),
                ),
                child: MapIcon(
                  i < stars ? MapGlyph.goldStar : MapGlyph.emptyStar,
                  size: 64,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}
