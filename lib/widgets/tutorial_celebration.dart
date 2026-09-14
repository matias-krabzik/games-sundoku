import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'home_art.dart';
import 'illustrated_action_button.dart';
import 'map_art.dart';
import 'tutorial_block_art.dart';
import 'tutorial_story.dart';

const tutorialCelebrationDuration = Duration(milliseconds: 1700);
const tutorialBoardFlightDuration = 850;

double _interval(double progress, int start, int end) =>
    ((progress * tutorialCelebrationDuration.inMilliseconds - start) /
            (end - start))
        .clamp(0.0, 1.0);

class TutorialCelebration extends StatelessWidget {
  const TutorialCelebration({
    super.key,
    required this.animation,
    required this.board,
    required this.header,
    required this.stars,
    required this.message,
    required this.action,
    required this.onAction,
    required this.finalGame,
    this.boardSlotKey,
    this.actionKey,
    this.previousBoards = const [],
    this.departure = const AlwaysStoppedAnimation(0),
  });

  final Animation<double> animation;
  final Widget board;
  final Widget header;
  final int stars;
  final String message;
  final String action;
  final VoidCallback? onAction;
  final bool finalGame;
  final Key? boardSlotKey;
  final Key? actionKey;
  final List<Widget> previousBoards;
  final Animation<double> departure;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final compact = bounds.maxHeight < 650;
      final wide =
          bounds.maxWidth >= 700 && bounds.maxWidth > bounds.maxHeight * 1.2;
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: wide ? 950 : 502),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: AnimatedBuilder(
              animation: Listenable.merge([animation, departure]),
              builder: (context, _) {
                final progress = animation.value;
                final cardOpacity = Curves.easeOut.transform(
                  _interval(progress, 1150, 1500),
                );
                final actionOpacity = _interval(progress, 1500, 1700);
                final hero = Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TutorialBoardFan(
                      animation: animation,
                      board: board,
                      previousBoards: previousBoards,
                      boardSlotKey: boardSlotKey,
                      size: compact ? 126 : 154,
                    ),
                    const SizedBox(height: 8),
                    TutorialReward(
                      stars: stars,
                      animation: animation,
                      compact: compact,
                    ),
                  ],
                );
                final story = Opacity(
                  key: const ValueKey('reward-card-fade'),
                  opacity: cardOpacity,
                  child: IgnorePointer(
                    ignoring: cardOpacity == 0,
                    child: TutorialStory(
                      key: ValueKey('reward-story-$stars'),
                      lines: message.split('\n'),
                      tip: null,
                      autoplay: progress * 1700 >= 1500,
                      skipHint: 'Toca para mostrar todo el mensaje',
                    ),
                  ),
                );
                final leaving = Curves.easeIn.transform(departure.value);
                return Opacity(
                  key: const ValueKey('reward-departure'),
                  opacity: 1 - leaving,
                  child: Transform.translate(
                    offset: Offset(0, 12 * leaving),
                    child: Column(
                      children: [
                        Opacity(
                          opacity: Curves.easeOut.transform(
                            _interval(progress, 0, 350),
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 470),
                            child: header,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, body) => SingleChildScrollView(
                              key: const ValueKey('intro-scroll'),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: body.maxHeight,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: wide
                                      ? Row(
                                          children: [
                                            SizedBox(
                                              width: math.min(
                                                body.maxWidth * .43,
                                                340,
                                              ),
                                              child: hero,
                                            ),
                                            const SizedBox(width: 24),
                                            Expanded(child: story),
                                          ],
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            hero,
                                            const SizedBox(height: 12),
                                            story,
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Opacity(
                          key:
                              actionKey ?? const ValueKey('reward-action-fade'),
                          opacity: actionOpacity,
                          child: IgnorePointer(
                            ignoring: actionOpacity < 1,
                            child: IllustratedActionButton(
                              key: const ValueKey('tutorial-next'),
                              compact: compact,
                              fontSize: 23,
                              label: action,
                              leadingIcon: finalGame
                                  ? const HomeIcon(
                                      HomeGlyph.world,
                                      key: ValueKey('reward-map-icon'),
                                      size: 34,
                                    )
                                  : null,
                              onPressed: actionOpacity < 1 ? null : onAction,
                            ),
                          ),
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
    },
  );
}

class TutorialBoardFan extends StatelessWidget {
  const TutorialBoardFan({
    super.key,
    required this.animation,
    required this.board,
    required this.previousBoards,
    required this.size,
    this.boardSlotKey,
  }) : assert(previousBoards.length <= 2);

  final Animation<double> animation;
  final Widget board;
  final List<Widget> previousBoards;
  final double size;
  final Key? boardSlotKey;

  @override
  Widget build(BuildContext context) {
    final count = previousBoards.length + 1;
    final width =
        size *
        (count == 3
            ? 2.08
            : count == 2
            ? 1.75
            : 1);
    final top =
        size *
        (count == 3
            ? .34
            : count == 2
            ? .24
            : 0);
    final front = SizedBox.square(
      key: boardSlotKey,
      dimension: size,
      child: IgnorePointer(child: board),
    );
    return Semantics(
      label: count == 1 ? 'Sudoku resuelto' : '$count sudokus resueltos',
      child: SizedBox(
        width: width,
        height: top + size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var index = 0; index < previousBoards.length; index++)
              Builder(
                builder: (context) {
                  final right = count == 3 && index == 1;
                  final scale = count == 3 && index == 0 ? .72 : .86;
                  final x = right ? width - size * (scale + .10) : size * .12;
                  final y = size * .15;
                  final child = RepaintBoundary(
                    child: ExcludeSemantics(
                      child: IgnorePointer(child: previousBoards[index]),
                    ),
                  );
                  return AnimatedBuilder(
                    animation: animation,
                    child: child,
                    builder: (context, child) {
                      final reveal = _interval(
                        animation.value,
                        tutorialBoardFlightDuration + index * 100,
                        1200 + index * 100,
                      );
                      final open = Curves.easeOutCubic.transform(reveal);
                      return Positioned(
                        left: x,
                        top: y,
                        width: size * scale,
                        height: size * scale,
                        child: Opacity(
                          key: ValueKey('reward-fan-fade-$index'),
                          opacity: reveal,
                          child: Transform.translate(
                            offset: Offset(
                              (width / 2 - x - size * scale / 2) * (1 - open),
                              16 * (1 - open),
                            ),
                            child: Transform.rotate(
                              key: ValueKey('reward-fan-rotation-$index'),
                              angle: (right ? .20 : -.24) * open,
                              child: child,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            Positioned(
              left: count == 2 ? width - size : (width - size) / 2,
              top: top,
              child: front,
            ),
          ],
        ),
      ),
    );
  }
}

class TutorialReward extends StatelessWidget {
  const TutorialReward({
    super.key,
    required this.stars,
    this.animation = const AlwaysStoppedAnimation(1),
    this.compact = false,
  });

  final int stars;
  final Animation<double> animation;
  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$stars de 3 estrellas ganadas',
    image: true,
    child: AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final entrance = Curves.easeOutCubic.transform(
          _interval(animation.value, 100, 850),
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              key: const ValueKey('reward-doku-fade'),
              opacity: entrance,
              child: Transform.translate(
                key: const ValueKey('reward-doku-motion'),
                offset: Offset(0, 45 * (1 - entrance)),
                child: SizedBox(
                  height: compact ? 126 : 170,
                  child: const TutorialBlockArt(TutorialGlyph.guide),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  Builder(
                    builder: (context) {
                      final star = _interval(
                        animation.value,
                        650 + i * 250,
                        1000 + i * 250,
                      );
                      return Opacity(
                        key: ValueKey('reward-star-$i'),
                        opacity: star,
                        child: Transform.translate(
                          offset: Offset(0, 16 * (1 - star)),
                          child: Transform.scale(
                            scale:
                                .45 + .55 * Curves.easeOutBack.transform(star),
                            child: MapIcon(
                              i < stars
                                  ? MapGlyph.goldStar
                                  : MapGlyph.emptyStar,
                              size: compact ? 46 : 56,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        );
      },
    ),
  );
}
