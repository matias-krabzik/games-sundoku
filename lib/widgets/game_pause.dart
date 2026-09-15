import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../controllers/first_experience_controller.dart';
import 'home_art.dart';
import 'illustrated_action_button.dart';
import 'juicy_press.dart';
import 'ui_surface_art.dart';

String formatPlayTime(int milliseconds) {
  final seconds = milliseconds ~/ 1000;
  final minutes = seconds ~/ 60;
  return '${minutes.toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class GameTimerControls extends StatefulWidget {
  const GameTimerControls({
    super.key,
    required this.flow,
    this.blocked = false,
  });
  final FirstExperienceController flow;
  final bool blocked;

  @override
  State<GameTimerControls> createState() => _GameTimerControlsState();
}

class _GameTimerControlsState extends State<GameTimerControls> {
  late final Timer _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
    if (mounted && widget.flow.readyToPlay) setState(() {});
  });

  @override
  void initState() {
    super.initState();
    _ticker;
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        formatPlayTime(widget.flow.elapsedMs),
        key: const ValueKey('game-timer'),
        style: homeText(20),
      ),
      const SizedBox(width: 10),
      SizedBox.square(
        dimension: 42,
        child: JuicyPress(
          key: const ValueKey('game-pause'),
          label: 'Pausar partida',
          onPressed: widget.blocked || !widget.flow.readyToPlay
              ? null
              : widget.flow.requestPause,
          builder: (_, _) => const UiSurfacePanel(
            surface: UiSurface.creamTile,
            padding: EdgeInsets.zero,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [_PauseBar(), SizedBox(width: 5), _PauseBar()],
              ),
            ),
          ),
        ),
      ),
    ],
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
