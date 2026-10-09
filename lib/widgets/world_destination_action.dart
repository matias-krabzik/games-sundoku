import 'package:flutter/material.dart';

import 'illustrated_action_button.dart';

/// The only entry action, appearing after the selected destination settles.
class WorldDestinationAction extends StatelessWidget {
  const WorldDestinationAction({
    super.key,
    required this.worldId,
    required this.compact,
    required this.onPressed,
  });

  final String worldId;
  final bool compact;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      child: IllustratedActionButton(
        key: ValueKey('world-enter-$worldId'),
        label: 'Ir al destino',
        compact: compact,
        fontSize: compact ? 24 : 30,
        onPressed: onPressed,
      ),
      builder: (context, progress, child) => IgnorePointer(
        ignoring: progress < 1 || onPressed == null,
        child: ExcludeFocus(
          excluding: progress < 1,
          child: ExcludeSemantics(
            excluding: progress < 1,
            child: Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - progress)),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
