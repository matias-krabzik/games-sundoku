import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../routes.dart';
import '../data/world_catalog.dart';
import '../data/services/world_navigation_service.dart';
import 'adventure_progress_card.dart';
import 'game_feedback_scope.dart';
import 'home_art.dart';
import 'juicy_press.dart';
import 'map_art.dart';
import 'settings_art.dart';
import 'ui_surface_art.dart';
import 'world_thumbnail.dart';

class MapWorldHeader extends StatelessWidget {
  const MapWorldHeader({
    super.key,
    required this.onBack,
    this.onViewTutorial,
    this.onChooseWorld,
    this.compact = false,
    this.groupActions = false,
  });

  final VoidCallback onBack;
  final VoidCallback? onViewTutorial;
  final VoidCallback? onChooseWorld;
  final bool compact;
  final bool groupActions;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _MapRoundButton(
        key: const ValueKey('map-back'),
        label: 'Volver al inicio',
        icon: Icons.home_rounded,
        size: compact ? 50 : 54,
        onPressed: onBack,
      ),
      if (onViewTutorial != null) ...[
        const SizedBox(width: 8),
        _MapRoundButton(
          key: const ValueKey('map-tutorial'),
          label: 'Ver el tutorial',
          icon: Icons.menu_book_rounded,
          size: compact ? 50 : 54,
          onPressed: onViewTutorial,
        ),
      ],
      if (onChooseWorld != null) ...[
        const SizedBox(width: 8),
        _MapRoundButton(
          label: 'Elegir mundo',
          icon: Icons.public_rounded,
          size: compact ? 50 : 54,
          onPressed: onChooseWorld,
        ),
      ],
      if (groupActions) const SizedBox(width: 8) else const Spacer(),
      _MapRoundButton(
        key: const ValueKey('map-settings'),
        label: 'Ajustes',
        artwork: SettingsIcon(SettingsGlyph.gear, size: compact ? 30 : 33),
        size: compact ? 50 : 54,
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
      ),
      if (groupActions) const Spacer(),
    ],
  );
}

/// Floating map progress panel. Stars remain on their level markers.
class MapStatusCard extends StatelessWidget {
  const MapStatusCard({
    super.key,
    required this.level,
    this.worldId = 'world-1',
    required this.unlockedLevels,
    this.worldNavigation,
    this.onSelectWorld,
    required this.onPrevious,
    required this.onNext,
    this.compact = false,
  });

  final int level;
  final String worldId;
  final int unlockedLevels;
  final WorldNavigationService? worldNavigation;
  final ValueChanged<String>? onSelectWorld;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final navigation = worldNavigation;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 400 : 477),
      child: AdventureProgressCard(
        level: level,
        worldId: worldId,
        unlockedLevels: unlockedLevels,
        levelName: adventureWorld(worldId).names[level - 1],
        compact: compact,
        onChooseWorld: navigation != null && onSelectWorld != null
            ? () => _chooseWorld(context, navigation)
            : null,
        leading: _MapRoundButton(
          key: const ValueKey('map-previous'),
          label: 'Nivel anterior',
          glyph: MapGlyph.chevron,
          mirrored: true,
          gold: onPrevious != null,
          progressStyle: true,
          size: 48,
          onPressed: onPrevious,
        ),
        trailing: _MapRoundButton(
          key: const ValueKey('map-next'),
          label: 'Nivel siguiente',
          glyph: MapGlyph.chevron,
          gold: onNext != null,
          progressStyle: true,
          size: 48,
          onPressed: onNext,
        ),
      ),
    );
  }

  Future<void> _chooseWorld(
    BuildContext context,
    WorldNavigationService navigation,
  ) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 410),
          child: UiSurfacePanel(
            surface: UiSurface.creamPanel,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Elige un mundo', style: homeText(25)),
                const SizedBox(height: 14),
                for (final world in navigation.worlds) ...[
                  SizedBox(
                    height: 58,
                    child: JuicyPress(
                      key: ValueKey('map-world-option-${world.number}'),
                      label: world.id == worldId
                          ? 'Mundo ${world.number}: ${world.name}, actual'
                          : 'Mundo ${world.number}: ${world.name}',
                      onFeedback: () => GameFeedbackScope.tap(dialogContext),
                      onPressed: navigation.isUnlocked(world.id)
                          ? () => Navigator.of(dialogContext).pop(world.id)
                          : null,
                      builder: (context, _) => Opacity(
                        opacity: navigation.isUnlocked(world.id) ? 1 : .55,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            UiSurfaceArt(
                              world.id == worldId
                                  ? UiSurface.goldButton
                                  : UiSurface.creamPill,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              child: Row(
                                children: [
                                  WorldThumbnail(worldId: world.id, size: 36),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Mundo ${world.number}',
                                          style: homeText(17),
                                        ),
                                        Text(
                                          world.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: homeText(12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!navigation.isUnlocked(world.id))
                                    const Icon(
                                      Icons.lock_rounded,
                                      size: 21,
                                      color: homeNavy,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (context.mounted && selected != null && selected != worldId) {
      onSelectWorld?.call(selected);
    }
  }
}

class _MapRoundButton extends StatelessWidget {
  const _MapRoundButton({
    super.key,
    required this.label,
    this.glyph,
    this.icon,
    this.artwork,
    required this.size,
    required this.onPressed,
    this.gold = false,
    this.progressStyle = false,
    this.mirrored = false,
  });

  final String label;
  final MapGlyph? glyph;
  final IconData? icon;
  final Widget? artwork;
  final double size;
  final VoidCallback? onPressed;
  final bool gold;
  final bool progressStyle;
  final bool mirrored;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: math.max(48, size),
    child: JuicyPress(
      label: label,
      onFeedback: () => GameFeedbackScope.tap(context),
      onPressed: onPressed,
      builder: (context, depression) => Center(
        child: SizedBox.square(
          dimension: size,
          child: Opacity(
            opacity: onPressed == null ? .42 : 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                progressStyle && gold
                    ? const UiSurfaceArt(UiSurface.mapProgressRound)
                    : MapRoundSurface(gold: gold),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Transform.flip(
                      flipX: mirrored,
                      child:
                          artwork ??
                          (icon != null
                              ? Icon(
                                  icon,
                                  size: size * .5,
                                  color: homeNavy,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0xFFFFFFFF),
                                      offset: Offset(0, -1),
                                    ),
                                    Shadow(
                                      color: Color(0x555C3900),
                                      offset: Offset(0, 2),
                                      blurRadius: 1,
                                    ),
                                  ],
                                )
                              : MapIcon(glyph!, size: size * .45)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
