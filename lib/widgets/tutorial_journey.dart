import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/first_experience_controller.dart';
import '../domain/models/game_session.dart';
import '../domain/tutorial/tutorial_solution_tour.dart';
import 'home_art.dart';
import 'game_layout.dart';
import 'game_pause.dart';
import 'gameplay_status_bar.dart';
import 'illustrated_action_button.dart';
import 'sudoku_board.dart';
import 'sudoku_help.dart';
import 'sudoku_time_summary.dart';
import 'tutorial_celebration.dart';
import 'tutorial_story.dart';
import 'tutorial_block_controls.dart';
import 'ui_surface_art.dart';
import 'world_completion_recap.dart';

export 'tutorial_celebration.dart' show TutorialReward;

/// The board is supplied by the route so its element survives every lesson.
class TutorialJourney extends StatelessWidget {
  static const _maxBoardWidth = GameLayout.maxBoardSize;

  const TutorialJourney({
    super.key,
    required this.flow,
    required this.board,
    required this.header,
    this.navigation,
    required this.onExit,
    this.navigationBlocked = false,
    this.onLessonFinished,
    this.solutionTour = const AlwaysStoppedAnimation(1),
    this.finishingBoard = false,
    this.rewardAnimation = const AlwaysStoppedAnimation(1),
    this.rewardBoardSlotKey,
    this.rewardActionKey,
    this.onNextGame,
    this.onNextLevel,
    this.nextLevelNumber,
    this.departure = const AlwaysStoppedAnimation(0),
    this.gameEntrance = const AlwaysStoppedAnimation(1),
    this.gameBoardSlotKey,
  });
  final FirstExperienceController flow;
  final Widget board;
  final Widget header;
  final Widget? navigation;
  final VoidCallback onExit;
  final bool navigationBlocked;
  final VoidCallback? onLessonFinished;
  final Animation<double> solutionTour;
  final bool finishingBoard;
  final Animation<double> rewardAnimation;
  final Key? rewardBoardSlotKey;
  final Key? rewardActionKey;
  final Future<void> Function()? onNextGame;
  final VoidCallback? onNextLevel;
  final int? nextLevelNumber;
  final Animation<double> departure;
  final Animation<double> gameEntrance;
  final Key? gameBoardSlotKey;

  bool get _playing =>
      flow.step == FirstExperienceStep.playing || finishingBoard;
  bool get _celebrating =>
      !finishingBoard &&
      (flow.step == FirstExperienceStep.celebration ||
          flow.step == FirstExperienceStep.complete);

  static String title(FirstExperienceController flow) => flow.isQuickPlay
      ? flow.step == FirstExperienceStep.complete
            ? '¡Sudoku resuelto!'
            : flow.quickPlayDifficulty!.label
      : flow.lesson?.title ??
            switch (flow.step) {
              FirstExperienceStep.gameIntroduction => [
                'Jugamos juntos',
                'Ahora eliges tú',
                '¡Tú puedes!',
              ][flow.gameIndex],
              FirstExperienceStep.solvedExample => '¡Mira cómo encaja todo!',
              FirstExperienceStep.givensIntroduction => '¡Ahora te toca a ti!',
              FirstExperienceStep.inputIntroduction => 'Así ponemos un número',
              FirstExperienceStep.playing => 'Ronda ${flow.gameIndex + 1} de 3',
              FirstExperienceStep.celebration =>
                flow.gameIndex == 0
                    ? flow.isFirstSudokuVictory
                          ? '¡Lo lograste!'
                          : '¡Una estrella para ti!'
                    : '¡Ya tienes dos estrellas!',
              FirstExperienceStep.complete =>
                flow.isLastLevel
                    ? '¡Lo completaste todo!'
                    : '¡Juego ${flow.levelNumber} completado!',
              _ => 'Tu primer sudoku',
            };

  String get _message {
    if (_celebrating) {
      if (flow.isQuickPlay) {
        return '¡Cada número en su lugar! ¿Vamos con otro desafío?';
      }
      if (flow.step == FirstExperienceStep.complete) {
        return flow.isLastLevel
            ? '${worldCongratulations(flow.repository.state.player)} Completaste todos los juegos del Valle del Sol. ¡Vamos a recordar lo que aprendiste!'
            : '¡Conseguiste las tres estrellas! El siguiente juego ya está desbloqueado.';
      }
      if (flow.gameIndex == 0) {
        return flow.isFirstSudokuVictory
            ? 'Resolviste tu primer sudoku y ganaste una estrella. ¡Vamos por el siguiente!'
            : 'Cada número encontró su lugar. ¡Ya completaste la primera ronda!';
      }
      return '¡Otro sudoku resuelto! Solo falta uno para completar este juego.';
    }
    return flow.lesson != null
        ? flow.lessonMessage
        : switch (flow.step) {
            FirstExperienceStep.gameIntroduction => [
              'Tu bloque sigue aquí.\nCompleta las casillas vacías.',
              'Elige una casilla vacía\ny coloca el número que falta.',
              '¡Vamos con el tercero!\nCompleta el tablero sin repetir números.',
            ][flow.gameIndex],
            FirstExperienceStep.givensIntroduction => 'Ahora quitamos algunos números del tablero resuelto.\nLos que quedan son tus pistas: no se pueden cambiar.\n¡Descubre los que faltan! Recuerda mirar su fila, su columna y su bloque.',
            FirstExperienceStep.inputIntroduction =>
              'Toca una casilla vacía.\nDespués toca un número para ponerlo.',
            FirstExperienceStep.playing => flow.playMessage,
            _ => '',
          };
  }

  String get _action =>
      flow.reviewOnly && flow.storyIndex == flow.storyCount - 1
      ? 'Volver al mapa'
      : flow.lesson?.action ??
            switch (flow.step) {
              FirstExperienceStep.gameIntroduction => 'Ver las pistas',
              FirstExperienceStep.givensIntroduction =>
                flow.session?.lights == 3 ? 'Terminar repaso' : 'Jugar',
              FirstExperienceStep.inputIntroduction => 'Empezar',
              FirstExperienceStep.playing => 'Reintentar',
              FirstExperienceStep.celebration => [
                'Vamos al segundo',
                'Vamos al tercero',
                'Ver mi logro',
              ][flow.gameIndex],
              FirstExperienceStep.complete =>
                flow.isQuickPlay ? 'Volver al inicio' : 'Volver al mapa',
              _ => 'Siguiente',
            };

  Future<void> _advance() async {
    if (navigationBlocked) return;
    if (flow.step == FirstExperienceStep.complete ||
        (flow.reviewOnly && flow.storyIndex == flow.storyCount - 1)) {
      onExit();
    } else if (_playing) {
      await flow.resumeGame();
    } else if (flow.step == FirstExperienceStep.celebration &&
        onNextGame != null) {
      await onNextGame!();
    } else {
      await flow.advance();
    }
  }

  Widget _gameUi(Widget child, String name, double begin) => !_playing
      ? child
      : AnimatedBuilder(
          animation: gameEntrance,
          child: child,
          builder: (context, child) {
            final progress = Curves.easeOutCubic.transform(
              ((gameEntrance.value - begin) / (1 - begin)).clamp(0.0, 1.0),
            );
            return IgnorePointer(
              ignoring: progress < 1,
              child: Opacity(
                key: ValueKey('next-game-$name'),
                opacity: progress,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - progress)),
                  child: child,
                ),
              ),
            );
          },
        );

  @override
  Widget build(BuildContext context) {
    if (_celebrating) {
      return TutorialCelebration(
        title: title(flow),
        starCount: flow.roundCount,
        exitLabel: flow.isLastLevel && flow.step == FirstExperienceStep.complete
            ? 'Ver lo aprendido'
            : flow.isQuickPlay
            ? 'Volver al inicio'
            : 'Volver al mapa',
        animation: rewardAnimation,
        departure: departure,
        board: board,
        previousBoards: [
          for (final puzzle in flow.session!.puzzles.take(flow.gameIndex))
            if (puzzle.status == PlayStatus.completed)
              SudokuBoard(
                key: ValueKey('reward-board-${puzzle.puzzleId}'),
                cells: puzzle.cells.map((cell) => cell.value).toList(),
                fixedIndices: {
                  for (var index = 0; index < 81; index++)
                    if (flow.repository.state.puzzles[puzzle.puzzleId]!.isFixed(
                      index,
                    ))
                      index,
                },
              ),
        ],
        boardSlotKey: rewardBoardSlotKey,
        actionKey: rewardActionKey,
        header: header,
        stars: flow.session?.lights ?? 0,
        message: _message,
        summary: flow.step == FirstExperienceStep.complete
            ? AnimatedBuilder(
                animation: rewardAnimation,
                builder: (context, _) => SudokuTimeSummary(
                  message: _message,
                  autoplayMessage: rewardAnimation.value * 1700 >= 1500,
                  quickPlayDifficulty: flow.quickPlayDifficulty?.label,
                  elapsedMs: [
                    for (final puzzle in flow.session!.puzzles)
                      puzzle.elapsedMs,
                  ],
                  levelNumber: flow.levelNumber,
                  points: [
                    for (final puzzle in flow.session!.puzzles) puzzle.points,
                  ],
                ),
              )
            : null,
        action: _action,
        nextLevelNumber: nextLevelNumber,
        onNextLevel: flow.isBusy || navigationBlocked ? null : onNextLevel,
        finalGame: flow.step == FirstExperienceStep.complete,
        onAction: flow.isBusy || navigationBlocked
            ? null
            : flow.isLastLevel && flow.step == FirstExperienceStep.complete
            ? () async {
                final finished = await showWorldCompletionRecap(
                  context,
                  flow.repository.state.player,
                );
                if (context.mounted && finished == true) onExit();
              }
            : _advance,
      );
    }
    final help = flow.helpTip;
    return LayoutBuilder(
      builder: (context, bounds) {
        final desktopPlay =
            _playing &&
            GameLayout.isDesktop &&
            bounds.maxWidth >= GameLayout.desktopPlayWidth + 32;
        final wide =
            desktopPlay ||
            (!_playing &&
                bounds.maxWidth >= 700 &&
                bounds.maxWidth > bounds.maxHeight * 1.2);
        final largeWindow = bounds.maxWidth >= 700 || bounds.maxHeight >= 900;
        final statusWidth = desktopPlay
            ? _maxBoardWidth
            : GameLayout.mobileBoardSize(MediaQuery.sizeOf(context).width);
        final statusScale = (statusWidth / 360).clamp(1.0, 1.8);
        return Column(
          children: [
            if (navigation != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  largeWindow ? 32 : 16,
                  largeWindow ? 16 : 10,
                  largeWindow ? 32 : 16,
                  0,
                ),
                child: _gameUi(navigation!, 'navigation', .60),
              ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: desktopPlay
                        ? GameLayout.desktopPlayWidth + 32
                        : wide
                        ? 950
                        : (_playing ? double.infinity : 502),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Column(
                      children: [
                        _gameUi(
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: desktopPlay
                                  ? _maxBoardWidth
                                  : double.infinity,
                            ),
                            child: header,
                          ),
                          'header',
                          .60,
                        ),
                        const SizedBox(height: 8),
                        if (_playing) ...[
                          _gameUi(
                            SizedBox(
                              width: statusWidth,
                              child: GameplayStatusBar(
                                scale: statusScale,
                                points: flow.points,
                                trailing: GameTimerControls(
                                  flow: flow,
                                  scale: statusScale,
                                  blocked: navigationBlocked,
                                ),
                              ),
                            ),
                            'status',
                            .70,
                          ),
                          const SizedBox(height: 4),
                        ],
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, body) {
                              final boardWidth = desktopPlay
                                  ? _maxBoardWidth
                                  : _playing
                                  ? GameLayout.mobileBoardSize(
                                      MediaQuery.sizeOf(context).width,
                                    )
                                  : math.min(
                                      wide
                                          ? body.maxWidth * .47
                                          : body.maxWidth,
                                      _maxBoardWidth,
                                    );
                              final boardCellSize = GameLayout.boardCellSize(
                                boardWidth,
                              );
                              final keypadGap = body.maxWidth < 340 ? 2.0 : 4.0;
                              final controlsWidth = desktopPlay
                                  ? GameLayout.numberGridWidth
                                  : boardCellSize * 9 + keypadGap * 8;
                              final boardArea = SizedBox.square(
                                key: gameBoardSlotKey,
                                dimension: boardWidth,
                                child: PausableGameBoard(
                                  board: board,
                                  flow: flow,
                                ),
                              );
                              final information = Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_playing) ...[
                                    if (!desktopPlay)
                                      const SizedBox(height: 20),
                                    TutorialNumberTray(
                                      horizontal: !desktopPlay,
                                      showGuide: !desktopPlay,
                                      buttonExtent: boardCellSize,
                                      available: flow.availableGameNumbers,
                                      onSelected:
                                          !navigationBlocked &&
                                              flow.readyToPlay &&
                                              flow.gameCell != null &&
                                              !flow.fixedIndices.contains(
                                                flow.gameCell,
                                              )
                                          ? flow.placeGameNumber
                                          : null,
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Center(
                                        child: SizedBox(
                                          width: controlsWidth,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              TutorialEraseButton(
                                                dimension: boardCellSize,
                                                iconSize: boardCellSize * .55,
                                                surface: UiSurface.creamTile,
                                                onPressed:
                                                    !navigationBlocked &&
                                                        flow.readyToPlay &&
                                                        flow.gameCell != null &&
                                                        !flow.fixedIndices
                                                            .contains(
                                                              flow.gameCell,
                                                            ) &&
                                                        flow.boardValues[flow
                                                                .gameCell!] !=
                                                            null
                                                    ? flow.clearGameCell
                                                    : null,
                                              ),
                                              SudokuHelpButton(
                                                key: const ValueKey(
                                                  'game-help',
                                                ),
                                                active: help != null,
                                                dimension: boardCellSize,
                                                onPressed:
                                                    !navigationBlocked &&
                                                        flow.canShowHelp
                                                    ? (help == null
                                                          ? flow.showHelp
                                                          : flow.dismissHelp)
                                                    : null,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else if (!_celebrating && wide == false)
                                    const SizedBox(height: 12),
                                  if (flow.step ==
                                      FirstExperienceStep.solvedExample)
                                    AnimatedBuilder(
                                      animation: solutionTour,
                                      builder: (context, _) {
                                        final tour = TutorialSolutionTour(
                                          solutionTour.value,
                                        );
                                        return TutorialLessonCard(
                                          message: tour.message,
                                          messageKey:
                                              'solution-tour-${tour.phase}',
                                          onFinished: tour.finished
                                              ? onLessonFinished
                                              : null,
                                        );
                                      },
                                    )
                                  else if (!_playing)
                                    TutorialLessonCard(
                                      onFinished: onLessonFinished,
                                      message: _message,
                                      messageKey:
                                          '${flow.step}-${flow.gameCell}-${flow.playMessage}',
                                    ),
                                  if (_playing && !desktopPlay) ...[
                                    if (help != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: SudokuHelpCard(
                                          key: const ValueKey('game-help-card'),
                                          tip: help,
                                        ),
                                      ),
                                    if (help == null &&
                                        flow.playMessage.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        flow.playMessage,
                                        style: homeText(16),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: desktopPlay
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                key: const ValueKey(
                                                  'desktop-play-group',
                                                ),
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  boardArea,
                                                  const SizedBox(
                                                    width: GameLayout
                                                        .desktopBoardGap,
                                                  ),
                                                  SizedBox(
                                                    width: GameLayout
                                                        .numberGridWidth,
                                                    child: _gameUi(
                                                      information,
                                                      'controls',
                                                      .77,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (help != null ||
                                                  flow.playMessage.isNotEmpty)
                                                ConstrainedBox(
                                                  constraints:
                                                      const BoxConstraints(
                                                        maxWidth:
                                                            _maxBoardWidth,
                                                      ),
                                                  child: _gameUi(
                                                    Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        if (help != null)
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  top: 12,
                                                                ),
                                                            child: SudokuHelpCard(
                                                              key:
                                                                  const ValueKey(
                                                                    'game-help-card',
                                                                  ),
                                                              tip: help,
                                                            ),
                                                          )
                                                        else ...[
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          Text(
                                                            flow.playMessage,
                                                            style: homeText(16),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    'help',
                                                    .77,
                                                  ),
                                                ),
                                            ],
                                          )
                                        : wide
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              boardArea,
                                              const SizedBox(width: 24),
                                              Expanded(
                                                child: _gameUi(
                                                  information,
                                                  'controls',
                                                  .77,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            mainAxisAlignment: _playing
                                                ? MainAxisAlignment.spaceEvenly
                                                : MainAxisAlignment.center,
                                            children: [
                                              boardArea,
                                              _gameUi(
                                                information,
                                                'controls',
                                                .77,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (!_playing ||
                            (flow.error != null && !flow.readyToPlay))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: IllustratedActionButton(
                              key: const ValueKey('tutorial-next'),
                              compact: bounds.maxHeight < 650,
                              showPlayIcon: !_playing,
                              fontSize: 23,
                              label: flow.isBusy ? 'Guardando…' : _action,
                              onPressed: flow.isBusy || navigationBlocked
                                  ? null
                                  : _advance,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
    this.onFinished,
  });
  final String message;
  final String messageKey;
  final String? progress;
  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) => TutorialStory(
    key: ValueKey(messageKey),
    lines: [message, ?progress],
    tip: null,
    interactive: false,
    textStyle: homeText(20).copyWith(height: 1.3),
    onFinished: onFinished,
  );
}
