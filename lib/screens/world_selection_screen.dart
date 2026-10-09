import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../models/world_overview_camera.dart';
import '../playables/playables_runtime.dart';
import '../widgets/world_destination_arrival.dart';
import '../widgets/world_destination_action.dart';
import '../widgets/world_overview_viewport.dart';

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
import '../widgets/developer_floating_menu.dart';
import '../widgets/app_toast.dart';
import '../data/world_catalog.dart';

class WorldSelectionScreen extends StatefulWidget {
  const WorldSelectionScreen({
    super.key,
    required this.repository,
    required this.navigation,
    required this.onSelectWorld,
    this.showDeveloperControls = kDebugMode,
  });
  final GameRepository repository;
  final WorldNavigationService navigation;
  final Future<void> Function(String worldId) onSelectWorld;
  final bool showDeveloperControls;

  @override
  State<WorldSelectionScreen> createState() => _WorldSelectionScreenState();
}

class _WorldSelectionScreenState extends State<WorldSelectionScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _discoveryKey = 'navigation/worldOverview';
  late WorldOverviewCamera _camera;
  late final Ticker _ticker = createTicker(_tick);
  late final PlayablesRuntime? _runtime = PlayablesRuntime.active;
  Duration? _lastFrame;
  bool _visible = false;
  bool _rememberScheduled = false;
  bool _remembering = false;

  Set<String> get _unlocked => {
    for (final world in widget.navigation.worlds)
      if (widget.navigation.isUnlocked(world.id)) world.id,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runtime?.addListener(_syncTicker);
    _createCamera();
  }

  void _createCamera() {
    final saved = widget.repository.state.modules[_discoveryKey];
    final ids = saved is Map ? saved['revealedWorlds'] : null;
    // Existing saves start with their already available destinations revealed.
    final seen = ids is List
        ? ids.whereType<String>().toSet().intersection(_unlocked)
        : _unlocked;
    seen.add('world-1');
    _camera = WorldOverviewCamera(
      revealedWorlds: seen,
      initialWorld: widget.repository.lastAdventureWorld,
    )..discover(_unlocked);
    _camera.addListener(_cameraChanged);
    widget.repository.addListener(_progressChanged);
    _scheduleRemember();
  }

  @override
  void didUpdateWidget(WorldSelectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      oldWidget.repository.removeListener(_progressChanged);
      _camera.dispose();
      _createCamera();
      _camera.reducedMotion =
          MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context);
      _syncTicker();
    }
  }

  void _progressChanged() => _camera.discover(_unlocked);

  void _cameraChanged() {
    _syncTicker();
    _scheduleRemember();
  }

  void _scheduleRemember() {
    if (_rememberScheduled || _remembering) return;
    _rememberScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rememberScheduled = false;
      if (mounted) unawaited(_rememberRevealed());
    });
  }

  Future<void> _rememberRevealed() async {
    final repository = widget.repository;
    final seen = _camera.revealedWorlds;
    final saved = repository.state.modules[_discoveryKey];
    final ids = saved is Map ? saved['revealedWorlds'] : null;
    if (ids is List && setEquals(ids.whereType<String>().toSet(), seen)) return;
    _remembering = true;
    try {
      await repository.saveModule(_discoveryKey, {
        'revealedWorlds': seen.toList(),
      });
    } catch (_) {
      // Discovery is cosmetic; a failed save must not prevent map navigation.
    } finally {
      _remembering = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible =
        TickerMode.valuesOf(context).enabled &&
        ModalRoute.of(context)?.isCurrent != false;
    _camera.reducedMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (_camera.reducedMotion) _camera.finishAnimations();
    _syncTicker();
    _scheduleRemember();
  }

  void _syncTicker() {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final mobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final foreground =
        lifecycle == null ||
        lifecycle == AppLifecycleState.resumed ||
        (!mobile && lifecycle == AppLifecycleState.inactive);
    final active =
        _visible &&
        foreground &&
        _runtime?.isPaused != true &&
        !_camera.reducedMotion &&
        _camera.animating;
    if (active && !_ticker.isActive) {
      _lastFrame = null;
      _ticker.start();
    } else if (!active && _ticker.isActive) {
      _ticker.stop();
      _lastFrame = null;
    }
  }

  void _tick(Duration elapsed) {
    final dt = _lastFrame == null
        ? 0.0
        : ((elapsed - _lastFrame!).inMicroseconds / 1e6).clamp(0.0, .05);
    _lastFrame = elapsed;
    _camera.advance(dt);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _syncTicker();

  @override
  void dispose() {
    widget.repository.removeListener(_progressChanged);
    _runtime?.removeListener(_syncTicker);
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _camera.dispose();
    super.dispose();
  }

  bool _opening = false;
  bool _completing = false;

  Future<void> _completeNextWorld() async {
    if (_completing || _opening || _camera.discovery.values.any((p) => p < 1)) {
      return;
    }
    setState(() => _completing = true);
    try {
      final worldId = await widget.repository.completeNextDebugWorld();
      if (!mounted) return;
      showToast(
        context,
        worldId == null
            ? 'Todos los destinos están completos.'
            : '${adventureWorld(worldId).name} completado.',
      );
    } catch (_) {
      if (mounted) {
        showToast(
          context,
          'No se pudo completar el destino. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Future<void> _enter(String worldId) async {
    if (_opening ||
        _completing ||
        !widget.navigation.isUnlocked(worldId) ||
        (_camera.discovery[worldId] ?? 1) < 1 ||
        _camera.entryWorld != worldId) {
      return;
    }
    setState(() => _opening = true);
    try {
      await widget.onSelectWorld(worldId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos abrir este destino. Intenta de nuevo.'),
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
        final compact = size.shortestSide < 600;
        final short = size.height - safe.vertical < 430;
        final actionHeight = short
            ? 54.0
            : compact
            ? 70.0
            : 78.0;
        final actionGap = short ? 8.0 : 12.0;
        // Each target ends at the middle of the visible gap, so a near miss
        // can select or enter a destination without triggering the other.
        final destinationHitPadding = EdgeInsets.fromLTRB(
          20,
          18,
          20,
          actionGap / 2,
        );
        final actionHitPadding = EdgeInsets.fromLTRB(18, actionGap / 2, 18, 16);
        final usable = Rect.fromLTRB(
          safe.left + 16,
          safe.top + (compact ? 72 : 90),
          size.width - safe.right - 16,
          size.height - safe.bottom - 16,
        );
        final labelWidth = math.min(
          math.min(compact ? 350.0 : 440.0, usable.width),
          (usable.height - actionGap - actionHeight) /
              WorldDestinationGeometry.heightFactor,
        );
        final destinationHeight =
            labelWidth * WorldDestinationGeometry.heightFactor;
        final anchor = labelWidth * WorldDestinationGeometry.anchorFactor;
        _camera.configure(
          size,
          usable,
          overview,
          anchorOffset:
              (destinationHeight + actionGap + actionHeight) / 2 - anchor,
        );
        return ListenableBuilder(
          listenable: Listenable.merge([widget.repository, _camera]),
          builder: (context, _) {
            final image = _camera.image;
            final worlds = widget.navigation.worlds;
            final centered = _camera.entryWorld;
            final points = [
              for (final anchor in overview.destinations)
                overview.project(anchor, image),
            ];
            final rects = [
              for (final point in points)
                Rect.fromLTWH(
                  point.dx - labelWidth / 2,
                  point.dy - anchor,
                  labelWidth,
                  destinationHeight,
                ),
            ];
            return Stack(
              fit: StackFit.expand,
              children: [
                WorldOverviewViewport(
                  camera: _camera,
                  child: WorldOverviewScene(
                    key: const ValueKey('world-overview-scene'),
                    overview: overview,
                    cameraImage: image,
                    discovery: _camera.discovery,
                    lockedWorlds: {
                      for (final world in worlds)
                        if (!widget.navigation.isUnlocked(world.id)) world.id,
                    },
                    protectedRects: [
                      for (var i = 0; i < worlds.length; i++)
                        if (widget.navigation.isUnlocked(worlds[i].id))
                          rects[i],
                    ],
                    child: FocusTraversalGroup(
                      policy: OrderedTraversalPolicy(),
                      child: Stack(
                        children: [
                          for (var i = 0; i < worlds.length; i++)
                            if (widget.navigation.isUnlocked(worlds[i].id))
                              Positioned.fromRect(
                                rect: destinationHitPadding.inflateRect(
                                  rects[i],
                                ),
                                child: FocusTraversalOrder(
                                  order: NumericFocusOrder(i.toDouble()),
                                  child: WorldDestinationArrival(
                                    progress:
                                        _camera.discovery[worlds[i].id] ?? 1,
                                    child: WorldDestination(
                                      key: ValueKey(
                                        'world-point-${worlds[i].id}',
                                      ),
                                      world: worlds[i],
                                      hitPadding: destinationHitPadding,
                                      unlocked: true,
                                      highlighted:
                                          _camera.focusedWorld == worlds[i].id,
                                      completedLevels: worlds[i].nodes
                                          .where(
                                            (node) =>
                                                (widget
                                                        .repository
                                                        .state
                                                        .progress[mapLevelId(
                                                          node.level,
                                                          worldId: worlds[i].id,
                                                        )]
                                                        ?.bestLights ??
                                                    0) >=
                                                3,
                                          )
                                          .length,
                                      stars: worlds[i].nodes.fold(
                                        0,
                                        (total, node) =>
                                            total +
                                            (widget
                                                    .repository
                                                    .state
                                                    .progress[mapLevelId(
                                                      node.level,
                                                      worldId: worlds[i].id,
                                                    )]
                                                    ?.bestLights ??
                                                0),
                                      ),
                                      onPressed: _opening || _completing
                                          ? null
                                          : () async => _camera.focusWorld(
                                              worlds[i].id,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                          if (centered != null)
                            Positioned(
                              left:
                                  rects[worlds.indexWhere(
                                        (w) => w.id == centered,
                                      )]
                                      .left -
                                  actionHitPadding.left,
                              top:
                                  rects[worlds.indexWhere(
                                        (w) => w.id == centered,
                                      )]
                                      .bottom +
                                  actionGap -
                                  actionHitPadding.top,
                              width: labelWidth + actionHitPadding.horizontal,
                              height: actionHeight + actionHitPadding.vertical,
                              child: WorldDestinationAction(
                                key: ValueKey('world-action-$centered'),
                                worldId: centered,
                                compact: compact,
                                hitPadding: actionHitPadding,
                                onPressed: _opening || _completing
                                    ? null
                                    : () => _enter(centered),
                              ),
                            ),
                        ],
                      ),
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
                                horizontal: compact ? 22 : 30,
                                vertical: compact ? 12 : 15,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Reino de Solara',
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
                if (kDebugMode && widget.showDeveloperControls)
                  DeveloperFloatingMenu(
                    actions: [
                      if (!_completing)
                        DeveloperMenuAction(
                          key: const ValueKey('dev-complete-next-world'),
                          label:
                              widget.navigation.worlds.every(
                                (world) =>
                                    widget.repository.worldCompleted(world.id),
                              )
                              ? 'Todos los destinos completos'
                              : 'Completar ${widget.navigation.worlds.firstWhere((world) => !widget.repository.worldCompleted(world.id)).name}',
                          icon: Icons.flag_outlined,
                          onPressed: _completeNextWorld,
                        ),
                    ],
                  ),
              ],
            );
          },
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
