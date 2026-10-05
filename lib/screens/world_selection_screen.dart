import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/level_catalog.dart';
import '../data/repositories/game_repository.dart';
import '../data/services/world_navigation_service.dart';
import '../routes.dart';
import '../widgets/game_feedback_scope.dart';
import '../widgets/home_art.dart';
import '../widgets/juicy_press.dart';
import '../widgets/map_art.dart';
import '../widgets/settings_art.dart';
import '../widgets/ui_surface_art.dart';
import '../data/world_overview.dart';
import '../widgets/world_overview_scene.dart';
import '../widgets/world_destination.dart';

class WorldSelectionScreen extends StatefulWidget {
  const WorldSelectionScreen({
    super.key,
    required this.repository,
    required this.navigation,
    required this.onSelectWorld,
  });
  final GameRepository repository;
  final WorldNavigationService navigation;
  final Future<void> Function(String worldId) onSelectWorld;

  @override
  State<WorldSelectionScreen> createState() => _WorldSelectionScreenState();
}

class _WorldSelectionScreenState extends State<WorldSelectionScreen> {
  bool _opening = false;
  Future<void> _enter(String worldId) async {
    if (_opening || !widget.navigation.isUnlocked(worldId)) return;
    setState(() => _opening = true);
    try {
      await widget.onSelectWorld(worldId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos abrir el mundo. Intenta de nuevo.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, bounds) {
        final size = bounds.biggest;
        final safe = MediaQuery.paddingOf(context);
        final landscape = size.width > size.height * 1.12;
        final overview = WorldOverview(landscape);
        final image = overview.imageRect(size);
        final compact = size.shortestSide < 600;
        final diameter = (size.shortestSide * .15).clamp(54.0, 116.0);
        final labelWidth = compact
            ? (landscape ? 150.0 : math.min(158.0, size.width * .40))
            : 222.0;
        final labelHeight = compact ? (landscape ? 58.0 : 70.0) : 86.0;
        final top = safe.top + (compact ? 58 : 82);
        final rects = <Rect>[];
        final points = <Offset>[];
        for (final anchor in overview.destinations) {
          final projected = overview.project(anchor, image);
          final point = Offset(
            projected.dx.clamp(
              safe.left + diameter * .60 + 8,
              size.width - safe.right - diameter * .60 - 8,
            ),
            projected.dy.clamp(
              top + diameter / 2 + 5,
              math.max(
                top + diameter / 2 + 5,
                size.height - safe.bottom - labelHeight - diameter / 2 - 18,
              ),
            ),
          );
          points.add(point);
          rects.add(
            Rect.fromLTWH(
              (point.dx - labelWidth / 2).clamp(
                safe.left + 8,
                size.width - safe.right - labelWidth - 8,
              ),
              point.dy - diameter / 2,
              labelWidth,
              diameter + 6 + labelHeight,
            ),
          );
        }
        return WorldOverviewScene(
          key: const ValueKey('world-overview-scene'),
          overview: overview,
          protectedRects: rects,
          child: Stack(
            children: [
              ListenableBuilder(
                listenable: widget.repository,
                builder: (context, _) => FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: Stack(
                    children: [
                      for (var i = 0; i < widget.navigation.worlds.length; i++)
                        Positioned.fromRect(
                          rect: rects[i],
                          child: FocusTraversalOrder(
                            order: NumericFocusOrder(i.toDouble()),
                            child: WorldDestination(
                              key: ValueKey(
                                'world-point-${widget.navigation.worlds[i].id}',
                              ),
                              world: widget.navigation.worlds[i],
                              unlocked: widget.navigation.isUnlocked(
                                widget.navigation.worlds[i].id,
                              ),
                              highlighted:
                                  widget.repository.lastAdventureWorld ==
                                  widget.navigation.worlds[i].id,
                              completedLevels: widget.navigation.worlds[i].nodes
                                  .where(
                                    (node) =>
                                        (widget
                                                .repository
                                                .state
                                                .progress[mapLevelId(
                                                  node.level,
                                                  worldId: widget
                                                      .navigation
                                                      .worlds[i]
                                                      .id,
                                                )]
                                                ?.bestLights ??
                                            0) >=
                                        3,
                                  )
                                  .length,
                              stars: widget.navigation.worlds[i].nodes.fold(
                                0,
                                (total, node) =>
                                    total +
                                    (widget
                                            .repository
                                            .state
                                            .progress[mapLevelId(
                                              node.level,
                                              worldId: widget
                                                  .navigation
                                                  .worlds[i]
                                                  .id,
                                            )]
                                            ?.bestLights ??
                                        0),
                              ),
                              diameter: diameter,
                              markerLeft:
                                  points[i].dx - rects[i].left - diameter / 2,
                              onPressed: _opening
                                  ? null
                                  : () =>
                                        _enter(widget.navigation.worlds[i].id),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: safe.top + 8,
                left: safe.left + 16,
                right: safe.right + 16,
                child: Row(
                  children: [
                    _HeaderButton(
                      key: const ValueKey('worlds-back'),
                      label: 'Volver',
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const MapIcon(MapGlyph.back, size: 28),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: 340,
                            minHeight: compact ? 54 : 64,
                            maxHeight: compact ? 54 : 64,
                          ),
                          child: UiSurfacePanel(
                            surface: UiSurface.goldCreamPanel,
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 12 : 26,
                              vertical: 15,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Elige tu mundo',
                                maxLines: 1,
                                style: homeText(compact ? 23 : 32),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _HeaderButton(
                      key: const ValueKey('worlds-settings'),
                      label: 'Ajustes',
                      onPressed: () =>
                          Navigator.of(context).pushNamed(AppRoutes.settings),
                      child: const SettingsIcon(SettingsGlyph.gear, size: 32),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    super.key,
    required this.label,
    required this.child,
    required this.onPressed,
  });
  final String label;
  final Widget child;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 50,
    child: JuicyPress(
      label: label,
      onPressed: onPressed,
      onFeedback: () => GameFeedbackScope.tap(context),
      builder: (context, _) => Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(child: UiSurfaceArt(UiSurface.creamRound)),
          child,
        ],
      ),
    ),
  );
}
