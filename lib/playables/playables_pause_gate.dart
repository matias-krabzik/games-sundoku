import 'package:flutter/material.dart';

import 'playables_runtime.dart';

class PlayablesPauseGate extends StatelessWidget {
  const PlayablesPauseGate({
    super.key,
    required this.runtime,
    required this.child,
  });

  final PlayablesRuntime runtime;
  final Widget child;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: runtime,
    builder: (context, _) => Stack(
      fit: StackFit.expand,
      children: [
        TickerMode(
          enabled: !runtime.isPaused,
          child: IgnorePointer(ignoring: runtime.isPaused, child: child),
        ),
        if (runtime.isPaused)
          const ColoredBox(
            color: Color(0xCC122B49),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Text(
                  'En pausa',
                  style: TextStyle(color: Colors.white, fontSize: 28),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
