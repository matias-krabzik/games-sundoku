import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/world_catalog.dart';
import 'game_feedback_scope.dart';
import 'home_art.dart';
import 'juicy_press.dart';
import 'ui_surface_art.dart';
import 'world_crest.dart';

/// A map annotation that appears as the undiscovered frontier comes into view.
class WorldFrontierNotice extends StatelessWidget {
  const WorldFrontierNotice({
    super.key,
    required this.world,
    required this.completedLevels,
    required this.frontier,
    required this.usable,
    required this.landscape,
    this.enabled = true,
    this.onPressed,
  });

  final AdventureWorld? world;
  final int completedLevels;
  final Offset? frontier;
  final Rect usable;
  final bool landscape;
  final bool enabled;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final world = this.world;
    final frontier = this.frontier;
    Widget? card;
    if (enabled &&
        world != null &&
        frontier != null &&
        !usable.isEmpty &&
        (landscape
            ? frontier.dx <= usable.right - 64 && frontier.dx >= usable.left
            : frontier.dy >= usable.top + 64 && frontier.dy <= usable.bottom)) {
      final short = usable.height < 300;
      final width = math.min(
        usable.width,
        short
            ? 600.0
            : usable.width < 600
            ? 342.0
            : 480.0,
      );
      final enlarged = MediaQuery.textScalerOf(context).scale(18) > 25;
      card = CustomSingleChildLayout(
        key: ValueKey(world.id),
        delegate: _FrontierPosition(
          frontier: frontier,
          usable: usable,
          landscape: landscape,
          width: width,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: width,
            child: Semantics(
              container: true,
              liveRegion: true,
              child: JuicyPress(
                key: const ValueKey('world-frontier-action'),
                label:
                    'Completa todos los niveles de ${world.name}. '
                    '${completedLevels.clamp(0, world.levelCount)} de '
                    '${world.levelCount} niveles completados. '
                    'Centrar ${world.name}',
                onPressed: onPressed,
                onFeedback: () => GameFeedbackScope.tap(context),
                builder: (context, _) => _FrontierCard(
                  world: world,
                  completedLevels: completedLevels,
                  short: short,
                  concise: short || enlarged,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return IgnorePointer(
      ignoring: card == null,
      child: ExcludeSemantics(
        excluding: card == null,
        child: ExcludeFocus(
          excluding: card == null,
          child: AnimatedSwitcher(
            duration: reduced
                ? Duration.zero
                : const Duration(milliseconds: 240),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: card,
          ),
        ),
      ),
    );
  }
}

class _FrontierCard extends StatelessWidget {
  const _FrontierCard({
    required this.world,
    required this.completedLevels,
    required this.short,
    required this.concise,
  });

  final AdventureWorld world;
  final int completedLevels;
  final bool short;
  final bool concise;

  @override
  Widget build(BuildContext context) {
    final completed = completedLevels.clamp(0, world.levelCount);
    final totem = SizedBox(
      width: short ? 100 : 146,
      height: short ? 60 : 78,
      child: Center(
        child: WorldCrest(
          key: ValueKey('frontier-totem-${world.id}'),
          worldId: world.id,
        ),
      ),
    );
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Despeja la niebla',
          textAlign: TextAlign.center,
          style: homeText(short ? 21 : 25),
        ),
        SizedBox(height: short ? 6 : 9),
        Text(
          'Completa todos los niveles de ${world.name}'
          '${concise ? '.' : ' para descubrir el próximo mundo.'}',
          textAlign: TextAlign.center,
          style: homeText(
            short ? 16 : 18,
            weight: FontWeight.w600,
          ).copyWith(height: 1.18),
        ),
        SizedBox(height: short ? 10 : 16),
        Semantics(
          label: '$completed de ${world.levelCount} niveles completados',
          child: ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: short ? 10 : 13,
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: UiSurfaceArt(UiSurface.progressTrack),
                      ),
                      if (completed > 0)
                        FractionallySizedBox(
                          widthFactor: completed / world.levelCount,
                          heightFactor: 1,
                          child: const UiSurfaceArt(UiSurface.progressFill),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '$completed de ${world.levelCount} niveles completados',
                  textAlign: TextAlign.center,
                  style: homeText(short ? 13 : 15, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    if (short) {
      return UiSurfacePanel(
        key: const ValueKey('world-frontier-card'),
        surface: UiSurface.goldCreamPanel,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Row(
          children: [
            totem,
            const SizedBox(width: 16),
            Expanded(child: content),
          ],
        ),
      );
    }
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 35),
          child: UiSurfacePanel(
            key: const ValueKey('world-frontier-card'),
            surface: UiSurface.goldCreamPanel,
            padding: const EdgeInsets.fromLTRB(26, 48, 26, 22),
            child: content,
          ),
        ),
        totem,
      ],
    );
  }
}

class _FrontierPosition extends SingleChildLayoutDelegate {
  const _FrontierPosition({
    required this.frontier,
    required this.usable,
    required this.landscape,
    required this.width,
  });

  final Offset frontier;
  final Rect usable;
  final bool landscape;
  final double width;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(maxWidth: width, maxHeight: usable.height);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final left = landscape
        ? frontier.dx - childSize.width * .55
        : usable.center.dx - childSize.width / 2;
    final top = landscape
        ? usable.center.dy - childSize.height / 2
        : frontier.dy - childSize.height * .55;
    return Offset(
      left.clamp(usable.left, usable.right - childSize.width),
      top.clamp(usable.top, usable.bottom - childSize.height),
    );
  }

  @override
  bool shouldRelayout(_FrontierPosition oldDelegate) =>
      frontier != oldDelegate.frontier ||
      usable != oldDelegate.usable ||
      landscape != oldDelegate.landscape ||
      width != oldDelegate.width;
}
