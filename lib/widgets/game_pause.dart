import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../controllers/first_experience_controller.dart';
import '../playables/playables_runtime.dart';
import 'game_navigation_header.dart';
import 'home_art.dart';
import 'illustrated_action_button.dart';
import 'juicy_press.dart';
import 'ui_surface_art.dart';

String formatPlayTime(int milliseconds) {
  final elapsed = Duration(milliseconds: milliseconds);
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  final minutesAndSeconds =
      '${twoDigits(elapsed.inMinutes % 60)}:${twoDigits(elapsed.inSeconds % 60)}';
  if (elapsed.inHours == 0) return minutesAndSeconds;
  final hoursAndTime = '${twoDigits(elapsed.inHours % 24)}:$minutesAndSeconds';
  return elapsed.inDays > 0 ? '${elapsed.inDays}d $hoursAndTime' : hoursAndTime;
}

class GameTimerControls extends StatefulWidget {
  const GameTimerControls({
    super.key,
    required this.flow,
    this.blocked = false,
    this.scale = 1,
    this.showPause = true,
  });
  final FirstExperienceController flow;
  final bool blocked;
  final double scale;
  final bool showPause;

  @override
  State<GameTimerControls> createState() => _GameTimerControlsState();
}

class _GameTimerControlsState extends State<GameTimerControls> {
  final PlayablesRuntime? _playables = PlayablesRuntime.active;
  Timer? _ticker;

  void _syncTicker() {
    if (_playables?.isPaused == true) {
      _ticker?.cancel();
      _ticker = null;
    } else {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && widget.flow.readyToPlay) setState(() {});
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _playables?.addListener(_syncTicker);
    _syncTicker();
  }

  @override
  void dispose() {
    _playables?.removeListener(_syncTicker);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time = Text(
      formatPlayTime(widget.flow.displayTimeMs),
      key: const ValueKey('game-timer'),
      maxLines: 1,
      style: homeText(20 * widget.scale),
    );
    if (!widget.showPause) return time;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        time,
        const SizedBox(width: 10),
        SizedBox.square(
          dimension: (42 * widget.scale).clamp(42, 54),
          child: JuicyPress(
            key: const ValueKey('game-pause'),
            label: widget.flow.isPaused ? 'Reanudar partida' : 'Pausar partida',
            onPressed:
                widget.blocked ||
                    widget.flow.isBusy ||
                    (!widget.flow.readyToPlay && !widget.flow.isPaused)
                ? null
                : widget.flow.isPaused
                ? widget.flow.resumeGame
                : widget.flow.requestPause,
            builder: (_, _) => UiSurfacePanel(
              surface: UiSurface.creamTile,
              padding: EdgeInsets.zero,
              child: Center(
                child: widget.flow.isPaused
                    ? Icon(
                        Icons.play_arrow_rounded,
                        key: const ValueKey('game-play-icon'),
                        color: homeNavy,
                        size: (30 * widget.scale).clamp(30, 40),
                      )
                    : Transform.scale(
                        scale: widget.scale.clamp(1, 54 / 42),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PauseBar(),
                            SizedBox(width: 5),
                            _PauseBar(),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GamePauseButton extends StatelessWidget {
  const GamePauseButton({super.key, required this.flow, this.blocked = false});

  final FirstExperienceController flow;
  final bool blocked;

  @override
  Widget build(BuildContext context) => GameHeaderButton(
    label: flow.isPaused ? 'Reanudar partida' : 'Pausar partida',
    onPressed: blocked || flow.isBusy || (!flow.readyToPlay && !flow.isPaused)
        ? null
        : flow.isPaused
        ? flow.resumeGame
        : flow.requestPause,
    icon: flow.isPaused
        ? const Icon(
            Icons.play_arrow_rounded,
            key: ValueKey('game-play-icon'),
            color: homeNavy,
            size: 34,
          )
        : const Row(
            mainAxisSize: MainAxisSize.min,
            children: [_PauseBar(), SizedBox(width: 5), _PauseBar()],
          ),
  );
}

class _PauseBar extends StatelessWidget {
  const _PauseBar();

  @override
  Widget build(BuildContext context) => Container(
    width: 5,
    height: 17,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(2),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2872BD), homeNavy],
      ),
    ),
  );
}

class PausableGameBoard extends StatelessWidget {
  const PausableGameBoard({super.key, required this.board, required this.flow});
  final Widget board;
  final FirstExperienceController flow;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(bounds.maxWidth * .033),
          child: ImageFiltered(
            key: const ValueKey('game-board-blur'),
            enabled: flow.isPaused,
            imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: IgnorePointer(
              ignoring: flow.isPaused,
              child: ExcludeSemantics(excluding: flow.isPaused, child: board),
            ),
          ),
        ),
        if (flow.isPaused)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: UiSurfacePanel(
                  surface: UiSurface.goldCreamPanel,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'En pausa',
                        style: homeText(26),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        flow.error == null
                            ? 'Tu partida está guardada.'
                            : 'La partida sigue aquí.',
                        style: homeText(17),
                        textAlign: TextAlign.center,
                      ),
                      if (flow.error != null)
                        Text(
                          flow.error!,
                          style: homeText(15),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 16),
                      IllustratedActionButton(
                        key: const ValueKey('game-resume'),
                        label: flow.isBusy ? 'Guardando…' : 'Continuar',
                        fontSize: 21,
                        onPressed: flow.isBusy ? null : flow.resumeGame,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
