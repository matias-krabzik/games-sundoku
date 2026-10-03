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
import 'sudoku_notes.dart';
import 'sudoku_time_summary.dart';
import 'tutorial_celebration.dart';
import 'tutorial_story.dart';
import 'tutorial_lesson_card.dart';
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
    this.onWorldCompleted,
    this.navigationBlocked = false,
    this.onLessonFinished,
    this.storyController,
    this.onRevealAnimation,
    this.skipAction,
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
  final VoidCallback? onWorldCompleted;
  final bool navigationBlocked;
  final VoidCallback? onLessonFinished;
  final TutorialStoryController? storyController;
  final bool Function()? onRevealAnimation;
  final Widget? skipAction;
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
      flow.step == FirstExperienceStep.playing ||
      flow.challengeOverlay ||
      finishingBoard;
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
            ? '${worldCongratulations(flow.repository.state.player)} Completaste ${flow.world.name}. ¡Vamos a recordar lo que aprendiste!'
            : flow.worldId == 'world-2' && flow.levelNumber == 1
            ? '¡Anotaciones desbloqueadas! El lápiz ya es tuyo. Puedes usarlo en cualquier juego y en Partida rápida. ¡Tus notas te ayudarán a pensar!'
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
    if (onRevealAnimation?.call() == true) return;
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
                final destination = await showWorldCompletionRecap(
                  context,
                  flow.repository.state.player,
                  worldId: flow.worldId,
                );
                if (!context.mounted) return;
                switch (destination) {
                  case WorldCompletionDestination.map:
                    onExit();
                  case WorldCompletionDestination.home:
                    (onWorldCompleted ?? onExit)();
                  case null:
                    break;
                }
              }
            : _advance,
      );
    }
    final help = flow.helpTip;
    return LayoutBuilder(
      builder: (context, bounds) {
        final desktopPlay =
            _playing && GameLayout.useLargePlayLayout(bounds.biggest);
        final compactLandscape =
            _playing && GameLayout.useCompactLandscape(bounds.biggest);
        final wide =
            desktopPlay ||
            (!_playing &&
                bounds.maxWidth >= 700 &&
                bounds.maxWidth > bounds.maxHeight * 1.2);
        final largeWindow = bounds.maxWidth >= 700 || bounds.maxHeight >= 900;
        final statusWidth = desktopPlay
            ? _maxBoardWidth
            : compactLandscape
            ? math.min(_maxBoardWidth, bounds.maxWidth * .8)
            : GameLayout.mobileBoardSize(MediaQuery.sizeOf(context).width);
        final statusScale = desktopPlay || compactLandscape
            ? 1.0
            : (statusWidth / 360).clamp(1.0, 1.8);
        return Column(
          children: [
            if (navigation != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  desktopPlay
                      ? 16
                      : largeWindow
                      ? 32
                      : 16,
                  compactLandscape
                      ? 8
                      : largeWindow
                      ? 16
                      : 10,
                  desktopPlay
                      ? 16
                      : largeWindow
                      ? 32
                      : 16,
                  0,
                ),
                child: _gameUi(navigation!, 'navigation', .60),
              ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: desktopPlay
                        ? GameLayout.maxPlayBoardSize + 32
                        : wide
                        ? 950
                        : (_playing
                              ? double.infinity
                              : GameLayout.maxTutorialTextWidth + 32),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      compactLandscape ? 6 : 10,
                      16,
                      compactLandscape ? 6 : 10,
                    ),
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
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, body) {
                              final sideInformation =
                                  _playing &&
                                  body.maxWidth >= 480 &&
                                  body.maxHeight < 400;
                              final notesReading =
                                  flow.notesAvailable &&
                                  flow.gameCell != null &&
                                  flow.boardValues[flow.gameCell!] == null;
                              final textScaler = MediaQuery.textScalerOf(
                                context,
                              );
                              final notesLabel = SudokuNotesReading(
                                notes: flow.selectedNotes,
                                active: flow.notesMode,
                              );
                              double messageHeight(
                                String message,
                                double width, {
                                double fontSize = 16,
                              }) {
                                final painter = TextPainter(
                                  text: TextSpan(
                                    text: message,
                                    style: DefaultTextStyle.of(context).style
                                        .merge(homeText(fontSize)),
                                  ),
                                  textDirection: Directionality.of(context),
                                  textScaler: textScaler,
                                )..layout(maxWidth: math.max(1, width));
                                final height = painter.height;
                                painter.dispose();
                                return height;
                              }

                              final statusHeight = desktopPlay
                                  ? math.max(76.0, textScaler.scale(20) + 36)
                                  : math.max(
                                          (42 * statusScale)
                                              .clamp(42, 54)
                                              .toDouble(),
                                          textScaler.scale(20 * statusScale) *
                                              1.5,
                                        ) +
                                        8;
                              var extraHeight = statusHeight + 12;

                              if (_playing && !sideInformation) {
                                if (help != null) {
                                  extraHeight +=
                                      math.max(
                                        56,
                                        messageHeight(
                                          help.message,
                                          body.maxWidth - 48,
                                          fontSize: 18,
                                        ),
                                      ) +
                                      52;
                                } else if (flow.playMessage.isNotEmpty) {
                                  extraHeight +=
                                      messageHeight(
                                        flow.playMessage,
                                        body.maxWidth,
                                      ) +
                                      12;
                                }
                                if (notesReading) {
                                  extraHeight +=
                                      messageHeight(
                                        notesLabel.message,
                                        body.maxWidth - 24,
                                      ) +
                                      16;
                                }
                                if (flow.error != null) {
                                  extraHeight +=
                                      messageHeight(
                                        flow.error!,
                                        body.maxWidth - 16,
                                      ) +
                                      16;
                                }
                              }
                              final boardWidth = _playing
                                  ? GameLayout.playBoardSize(
                                      viewport: bounds.biggest,
                                      body: body.biggest,
                                      extraHeight: extraHeight,
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
                              final controlsWidth =
                                  boardCellSize * 9 + keypadGap * 8;
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
                                    SizedBox(
                                      width: controlsWidth,
                                      child: TutorialNumberTray(
                                        horizontal: true,
                                        showGuide: !desktopPlay,
                                        buttonExtent: boardCellSize,
                                        available: flow.availableGameNumbers,
                                        notesMode: flow.notesMode,
                                        selectedNotes: flow.selectedNotes,
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
                                                dimension: math.min(
                                                  boardCellSize,
                                                  52,
                                                ),
                                                iconSize: boardCellSize * .55,
                                                surface: UiSurface.creamTile,
                                                onPressed:
                                                    !navigationBlocked &&
                                                        flow.canClearGameCell
                                                    ? flow.clearGameCell
                                                    : null,
                                              ),
                                              if (flow.notesAvailable)
                                                SudokuNotesButton(
                                                  key: const ValueKey(
                                                    'game-notes',
                                                  ),
                                                  active: flow.notesMode,
                                                  dimension: boardCellSize,
                                                  sound: flow
                                                      .repository
                                                      .state
                                                      .settings
                                                      .sound,
                                                  onPressed:
                                                      !navigationBlocked &&
                                                          flow.readyToPlay
                                                      ? flow.toggleNotesMode
                                                      : null,
                                                ),
                                              SudokuHelpButton(
                                                disabledReason:
                                                    flow.hintsAllowed ? null : 'Este desafío es sin pistas',
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
                                    if (notesReading && !sideInformation)
                                      notesLabel,
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
                                          controller: storyController,
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
                                      controller: storyController,
                                      message: _message,
                                      messageKey:
                                          '${flow.step}-${flow.gameCell}-${flow.playMessage}',
                                    ),
                                  if (_playing &&
                                      !desktopPlay &&
                                      !sideInformation) ...[
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
                                  if (flow.error != null &&
                                      (!_playing || !sideInformation))
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
                              if (_playing) {
                                final playGroup = Column(
                                  key: desktopPlay
                                      ? const ValueKey('desktop-play-group')
                                      : null,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      key: const ValueKey('game-status-slot'),
                                      height: statusHeight,
                                      child: Center(
                                        child: _gameUi(
                                          SizedBox(
                                            width: statusWidth,
                                            child: GameplayStatusBar(
                                              scale: statusScale,
                                              points: flow.points,
                                              initialLives: flow
                                                  .challengeRules
                                                  ?.initialLives,
                                              remainingLives: flow
                                                  .challengeRules
                                                  ?.remainingLives(
                                                    flow
                                                        .puzzleProgress!
                                                        .mistakes,
                                                  ),
                                              targetPoints: flow
                                                  .challengeRules
                                                  ?.targetPoints,
                                              illustrated: desktopPlay,
                                              trailing: GameTimerControls(
                                                flow: flow,
                                                scale: statusScale,
                                                blocked: navigationBlocked,
                                                showPause: !desktopPlay,
                                              ),
                                            ),
                                          ),
                                          'status',
                                          .70,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    boardArea,
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: body.maxWidth,
                                      child: _gameUi(
                                        information,
                                        'controls',
                                        .77,
                                      ),
                                    ),
                                    if (desktopPlay &&
                                        (help != null ||
                                            flow.playMessage.isNotEmpty))
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: body.maxWidth,
                                        ),
                                        child: _gameUi(
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 12,
                                            ),
                                            child: help != null
                                                ? SudokuHelpCard(
                                                    key: const ValueKey(
                                                      'game-help-card',
                                                    ),
                                                    tip: help,
                                                  )
                                                : Text(
                                                    flow.playMessage,
                                                    style: homeText(16),
                                                    textAlign: TextAlign.center,
                                                  ),
                                          ),
                                          'help',
                                          .77,
                                        ),
                                      ),
                                  ],
                                );
                                final sideWidth = math.min(
                                  280.0,
                                  (body.maxWidth - boardWidth) / 2 - 20,
                                );
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: playGroup,
                                      ),
                                    ),
                                    if (sideInformation &&
                                        (help != null ||
                                            flow.playMessage.isNotEmpty ||
                                            notesReading ||
                                            flow.error != null))
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: SizedBox(
                                          width: sideWidth,
                                          height: body.maxHeight,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: SizedBox(
                                              width: sideWidth,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (help != null)
                                                    SudokuHelpCard(
                                                      key: const ValueKey(
                                                        'game-help-card',
                                                      ),
                                                      tip: help,
                                                    )
                                                  else if (flow
                                                      .playMessage
                                                      .isNotEmpty)
                                                    Text(
                                                      flow.playMessage,
                                                      style: homeText(16),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  if (notesReading)
                                                    SudokuNotesReading(
                                                      notes: flow.selectedNotes,
                                                      active: flow.notesMode,
                                                    ),
                                                  if (flow.error != null)
                                                    Text(
                                                      flow.error!,
                                                      style: homeText(16),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              }
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
                                    child: wide
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
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IllustratedActionButton(
                                  key: const ValueKey('tutorial-next'),
                                  compact: bounds.maxHeight < 650,
                                  showPlayIcon: !_playing,
                                  fontSize: 23,
                                  label: flow.isBusy ? 'Guardando…' : _action,
                                  onPressed:
                                      flow.isBusy ||
                                          (navigationBlocked &&
                                              onRevealAnimation == null)
                                      ? null
                                      : _advance,
                                ),
                                if (skipAction != null) ...[
                                  const SizedBox(height: 6),
                                  skipAction!,
                                ],
                              ],
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
