import 'package:flutter/material.dart';

import '../models/world_overview_camera.dart';

/// A destination enters only after its covering fog has flown upwards.
class WorldDestinationArrival extends StatelessWidget {
  const WorldDestinationArrival({
    super.key,
    required this.progress,
    required this.child,
  });
  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = OverviewDiscovery.arrival(progress);
    return IgnorePointer(
      ignoring: t < 1,
      child: ExcludeFocus(
        excluding: t < 1,
        child: ExcludeSemantics(
          excluding: t < 1,
          child: Opacity(
            opacity: Curves.easeOut.transform(t),
            child: Transform.translate(
              offset: Offset(0, 22 * (1 - Curves.easeOutCubic.transform(t))),
              child: Transform.scale(
                scale: .84 + .16 * Curves.easeOutBack.transform(t),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
