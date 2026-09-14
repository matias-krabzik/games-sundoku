import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/first_experience_controller.dart';
import '../domain/models/game_session.dart';
import 'home_art.dart';
import 'game_layout.dart';
import 'gameplay_status_bar.dart';
import 'illustrated_action_button.dart';
import 'sudoku_board.dart';
import 'sudoku_help.dart';
import 'tutorial_celebration.dart';
import 'tutorial_block_controls.dart';
import 'ui_surface_art.dart';

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
    this.finishingBoard = false,
    this.rewardAnimation = const AlwaysStoppedAnimation(1),
    this.rewardBoardSlotKey,
    this.rewardActionKey,
    this.onNextGame,
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
  final bool finishingBoard;
  final Animation<double> rewardAnimation;
  final Key? rewardBoardSlotKey;
  final Key? rewardActionKey;
  final Future<void> Function()? onNextGame;
  final Animation<double> departure;
  final Animation<double> gameEntrance;
  final Key? gameBoardSlotKey;

  bool get _playing =>
      flow.step == FirstExperienceStep.playing || finishingBoard;
  bool get _celebrating =>
      !finishingBoard &&
      (flow.step == FirstExperienceStep.celebration ||
          flow.step == FirstExperienceStep.complete);

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
            'Tu bloque sigue aquí.\nCompleta las casillas vacías.',
            'Elige una casilla vacía\ny coloca el número que falta.',
            '¡Vamos con el tercero!\nCompleta el tablero sin repetir números.',
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
              FirstExperienceStep.playing => 'Reintentar',
              FirstExperienceStep.celebration => [
                'Vamos al segundo',
                'Vamos al tercero',
                'Ver mi logro',
              ][flow.gameIndex],
              FirstExperienceStep.complete => 'Ir al mapa',
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
        action: _action,
        finalGame: flow.step == FirstExperienceStep.complete,
        onAction: flow.isBusy || navigationBlocked ? null : _advance,
      );
    }
    final help = flow.helpTip;
    return LayoutBuilder(
      builder: (context, bounds) {
        final wide =
            !_playing &&
            bounds.maxWidth >= 700 &&
            bounds.maxWidth > bounds.maxHeight * 1.2;
        return Column(
          children: [
            if (navigation != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _gameUi(navigation!, 'navigation', .60),
              ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: wide
                        ? 950
                        : (_playing ? _maxBoardWidth + 32 : 502),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Column(
                      children: [
                        _gameUi(header, 'header', .60),
                        const SizedBox(height: 8),
                        if (_playing) ...[
                          _gameUi(const GameplayStatusBar(), 'status', .70),
                          const SizedBox(height: 4),
                        ],
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, body) {
                              final boardWidth = math.min(
                                wide ? body.maxWidth * .47 : body.maxWidth,
                                _maxBoardWidth,
                              );
                              final boardArea = SizedBox.square(
                                key: gameBoardSlotKey,
                                dimension: boardWidth,
                                child: board,
                              );
                              final information = Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_playing) ...[
                                    const SizedBox(height: 20),
                                    TutorialNumberTray(
                                      horizontal: true,
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
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          TutorialEraseButton(
                                            iconSize: 28,
                                            surface: UiSurface.creamTile,
                                            onPressed:
                                                !navigationBlocked &&
                                                    flow.readyToPlay &&
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
                                          SudokuHelpButton(
                                            key: const ValueKey('game-help'),
                                            active: help != null,
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
                                  ] else if (!_celebrating && wide == false)
                                    const SizedBox(height: 12),
                                  if (!_playing)
                                    TutorialLessonCard(
                                      message: _message,
                                      messageKey:
                                          '${flow.step}-${flow.gameCell}-${flow.playMessage}',
                                    ),
                                  if (_playing) ...[
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
                                  if (flow.step ==
                                          FirstExperienceStep
                                              .blockIntroduction &&
                                      flow.session == null &&
                                      !flow.reviewOnly)
                                    TextButton(
                                      key: const ValueKey(
                                        'tutorial-choose-order',
                                      ),
                                      onPressed: flow.isBusy
                                          ? null
                                          : flow.startBlock,
                                      child: Text(
                                        'Elegir el orden',
                                        style: homeText(16),
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
                                            mainAxisAlignment: _playing
                                                ? MainAxisAlignment.start
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
