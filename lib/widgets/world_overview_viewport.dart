import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../models/world_overview_camera.dart';

/// Moves the painting and its destinations together, beneath the fixed UI.
class WorldOverviewViewport extends StatelessWidget {
  const WorldOverviewViewport({
    super.key,
    required this.camera,
    required this.child,
  });

  final WorldOverviewCamera camera;
  final Widget child;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => camera.stopInertia(),
    onPointerSignal: (event) {
      if (event is PointerScrollEvent) {
        GestureBinding.instance.pointerSignalResolver.register(
          event,
          (_) => camera.scroll(-event.scrollDelta),
        );
      }
    },
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: (details) => camera.beginGesture(details.localFocalPoint),
      onScaleUpdate: (details) =>
          camera.updateGesture(details.localFocalPoint, details.scale),
      onScaleEnd: (details) =>
          camera.endGesture(details.velocity.pixelsPerSecond),
      child: child,
    ),
  );
}
