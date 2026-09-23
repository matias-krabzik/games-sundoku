import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../data/level_progress.dart';
import '../widgets/map_level_button.dart';
import '../widgets/map_chrome.dart';
import '../widgets/completed_level_popover.dart';
import '../widgets/light_award_overlay.dart';
import '../widgets/map_parallax_scene.dart';

import '../data/level_node.dart';
import '../widgets/app_toast.dart';
import '../widgets/map_selection_light.dart';
import '../widgets/developer_floating_menu.dart';

/// A horizontally scrollable world with ten touch targets on the painted path.
class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.progress,
    this.showDeveloperControls = kDebugMode,
    this.onOpenIntroduction,
    this.onViewTutorial,
    this.onReplayIntroduction,
    this.onOpenLevel,
  });

  final LevelProgress? progress;
  final bool showDeveloperControls;
  final VoidCallback? onOpenIntroduction;
  final VoidCallback? onViewTutorial;
  final Future<void> Function()? onReplayIntroduction;
  final Future<void> Function(int)? onOpenLevel;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  late final LevelProgress _progress = widget.progress ?? LevelProgress();
  late final AnimationController _award = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  late final Map<int, int> _visibleLights = {
    for (final node in kMap1Nodes) node.level: _progress.lightsFor(node.level),
  };
  bool _replaying = false;
  bool _openingLevel = false;
  bool _checkQueued = false;
  bool _wasCurrent = false;
  bool _entryFocusPending = true;

  int? get _entryLevel =>
      kMap1Nodes.every(
        (node) =>
            _progress.lightsFor(node.level) >= LevelProgress.requiredLights,
      )
      ? null
      : _progress.latestUnlocked;
  int _lightsFor(int level) => _visibleLights[level]!;
  bool _unlocked(int level) =>
      _progress.isUnlocked(level) && (level == 1 || _lightsFor(level - 1) >= 3);

  int? _awardingLevel;
  int _socket = 0;
  int _awardVariant = 0;
  final math.Random _awardRandom = math.Random();

  @override
  void initState() {
    super.initState();
    _visibleLights;
    _activeLevel = _entryLevel ?? _activeLevel;
    _progress.addListener(_progressChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route visibility: rewards must wait until the player returns.
    final current = ModalRoute.of(context)?.isCurrent != false;
    if (current && !_wasCurrent) _entryFocusPending = true;
    _wasCurrent = current;
    _queueRewards();
  }

  void _progressChanged() {
    if (!mounted) return;
    setState(() {
      for (final node in kMap1Nodes) {
        final saved = _progress.lightsFor(node.level);
        if (_preparingWorld ||
            saved < _lightsFor(node.level) ||
            (_awardingLevel != null && !_replaying)) {
          _visibleLights[node.level] = saved;
        }
      }
    });
    _queueRewards();
  }

  void _queueRewards() {
    if (_checkQueued) return;
    _checkQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkQueued = false;
      if (mounted) unawaited(_syncMapEntry());
    });
  }

  Future<void> _syncMapEntry() async {
    await _revealSavedRewards();
    if (!mounted ||
        !_entryFocusPending ||
        _awardingLevel != null ||
        _openingLevel ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    _entryFocusPending = false;
    final level = _entryLevel;
    if (level != null) await _focusLevel(level);
  }

  Future<void> _revealSavedRewards() async {
    if (_awardingLevel != null || ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    final pending = kMap1Nodes
        .where(
          (node) => _progress.lightsFor(node.level) > _lightsFor(node.level),
        )
        .toList();
    if (pending.isEmpty) return;
    int? nextLevel;
    setState(() {
      _replaying = true;
      _awardingLevel = pending.first.level;
    });
    try {
      for (final node in pending) {
        final level = node.level;
        if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
        setState(() {
          _activeLevel = level;
          _awardingLevel = level;
          _award.value = 0;
        });
        if (_scroll.hasClients) {
          if (MediaQuery.disableAnimationsOf(context)) {
            _scroll.jumpTo(_offsetFor(level));
          } else {
            await _scroll.animateTo(
              _offsetFor(level),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
            );
          }
        }
        while (_lightsFor(level) < _progress.lightsFor(level)) {
          if (!mounted) return;
          if (ModalRoute.of(context)?.isCurrent == false) return;
          setState(() {
            _socket = _lightsFor(level);
            _awardVariant = _awardRandom.nextInt(1 << 31);
          });
          if (!MediaQuery.disableAnimationsOf(context)) {
            await _award.forward(from: 0).orCancel;
          }
          if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
          setState(
            () => _visibleLights[level] = math.min(
              _socket + 1,
              _progress.lightsFor(level),
            ),
          );
          if (_lightsFor(level) == 3 && level < kMap1Nodes.length) {
            nextLevel = level + 1;
          }
        }
      }
    } on TickerCanceled {
      // The score is already saved; only its visual presentation is canceled.
    } finally {
      if (mounted) {
        setState(() {
          _replaying = false;
          _awardingLevel = null;
        });
        if (nextLevel != null && ModalRoute.of(context)?.isCurrent != false) {
          _focusLevel(nextLevel);
        }
      }
    }
  }

  final ScrollController _scroll = ScrollController();

  Future<void> _resetWorld() async {
    try {
      await _progress.resetLevel(1);
    } catch (_) {
      if (mounted) {
        showToast(context, 'No se pudo resetear el mundo. Intentá de nuevo.');
      }
    }
  }

  Future<void> _chooseLevelToReset() async {
    if (!mounted) return;
    final level = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('dev-level-picker'),
        title: const Text('Resetear nivel'),
        content: SizedBox(
          width: 260,
          height: 360,
          child: ListView(
            children: [
              for (final node in kMap1Nodes)
                ListTile(
                  key: ValueKey('dev-reset-level-${node.level}'),
                  title: Text('Nivel ${node.level}'),
                  onTap: () => Navigator.of(dialogContext).pop(node.level),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    if (level == null) return;
    try {
      await _progress.resetLevel(level);
    } catch (_) {
      if (mounted) {
        showToast(context, 'No se pudo resetear el nivel. Intentá de nuevo.');
      }
    }
  }

  Future<void> _completeActiveLevel() async {
    try {
      await _progress.completeRandomLevel(_activeLevel);
    } on StateError {
      if (mounted) {
        showToast(context, 'Completá primero el nivel anterior.');
      }
    } catch (_) {
      if (mounted) {
        showToast(context, 'No se pudo completar el nivel. Intentá de nuevo.');
      }
    }
  }

  bool _preparingWorld = false;

  Future<void> _completeWorldExceptLastPuzzle() async {
    if (_preparingWorld) return;
    if (_awardingLevel != null) {
      showToast(
        context,
        'Esperá a que termine la animación e intentá de nuevo.',
      );
      return;
    }
    _preparingWorld = true;
    try {
      await _progress.completeWorldExceptLastPuzzle();
      if (!mounted) return;
      await _focusLevel(kMap1Nodes.last.level);
      if (mounted) {
        showToast(context, 'Mundo listo: falta la ronda 3 del último juego.');
      }
    } catch (_) {
      if (mounted) {
        showToast(context, 'No se pudo preparar el mundo. Intentá de nuevo.');
      }
    } finally {
      _preparingWorld = false;
    }
  }

  int _activeLevel = 1;
  int _focusRequest = 0;
  Size _viewport = Size.zero;
  double _worldWidth = 0;

  @override
  void dispose() {
    _award.dispose();
    _progress.removeListener(_progressChanged);
    if (widget.progress == null) _progress.dispose();
    _scroll.dispose();
    super.dispose();
  }

  double _offsetFor(int level) =>
      (kMap1Nodes[level - 1].x * _worldWidth - _viewport.width / 2).clamp(
        0,
        math.max(0, _worldWidth - _viewport.width),
      );

  Future<void> _focusLevel(int level, {bool select = false}) async {
    if (_awardingLevel != null || _openingLevel) return;
    if (select && ModalRoute.of(context)?.isCurrent == false) return;
    final request = ++_focusRequest;
    final int target = level.clamp(1, kMap1Nodes.length);
    setState(() => _activeLevel = target);
    if (_scroll.hasClients) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _scroll.jumpTo(_offsetFor(target));
      } else {
        final movement = _scroll.animateTo(
          _offsetFor(target),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
        if (select) {
          await movement;
        } else {
          unawaited(movement);
        }
      }
    }
    if (!mounted ||
        request != _focusRequest ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    if (select) {
      if (_progress.isUnlocked(target)) {
        final replayPractice = target == 1 && _progress.lightsFor(target) >= 3;
        final continueGame = await Navigator.of(context).push<bool>(
          LevelSummaryRoute(
            level: target,
            lights: _progress.lightsFor(target),
            session: _progress.sessionFor(target),
            record: _progress.recordFor(target),
          ),
        );
        if (!mounted || continueGame != true) return;
        if (replayPractice && widget.onReplayIntroduction != null) {
          await _replayPractice();
          return;
        }
        await _openSelectedLevel(target);
        return;
      }
      showToast(
        context,
        _progress.isUnlocked(target)
            ? 'Nivel $target'
            : 'Consigue 3 puntos en el nivel ${target - 1}',
      );
    }
  }

  Future<void> _openSelectedLevel(int level) async {
    _openingLevel = true;
    try {
      if (level == 1) {
        widget.onOpenIntroduction?.call();
      } else if (widget.onOpenLevel != null) {
        await widget.onOpenLevel!(level);
      }
    } catch (_) {
      if (mounted) {
        showToast(context, 'No pudimos abrir la partida. Intenta de nuevo.');
      }
    } finally {
      _openingLevel = false;
      if (mounted) _queueRewards();
    }
  }

  Future<void> _replayPractice() async {
    _openingLevel = true;
    try {
      await widget.onReplayIntroduction!();
    } catch (_) {
      if (mounted) {
        showToast(context, 'No pudimos iniciar la práctica. Intenta de nuevo.');
      }
    } finally {
      _openingLevel = false;
      if (mounted) _queueRewards();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF78C8F6),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final Size viewport = constraints.biggest;
                final bool compact = viewport.height < 520;
                final bool largeWindow =
                    viewport.width >= 700 || viewport.height >= 900;
                final double worldHeight = math.max(
                  viewport.height,
                  viewport.width / 3,
                );
                _worldWidth = worldHeight * 3;
                if (viewport != _viewport) {
                  _viewport = viewport;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _scroll.hasClients) {
                      _scroll.jumpTo(_offsetFor(_activeLevel));
                    }
                  });
                }
                final double nodeSize = compact
                    ? 68
                    : (viewport.width * .24).clamp(82, 106);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    MapParallaxScene(
                      scroll: _scroll,
                      worldSize: Size(_worldWidth, worldHeight),
                      protectedWorldRects: [
                        for (final node in kMap1Nodes)
                          Rect.fromLTWH(
                            node.x * _worldWidth - nodeSize / 2,
                            node.y * worldHeight - nodeSize / 2,
                            nodeSize,
                            nodeSize + 22,
                          ).inflate(8),
                      ],
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          SingleChildScrollView(
                            key: const ValueKey('world-scroll'),
                            controller: _scroll,
                            scrollDirection: Axis.horizontal,
                            physics: _awardingLevel == null
                                ? const ClampingScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                            child: SizedBox(
                              width: _worldWidth,
                              height: viewport.height,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  for (final node in kMap1Nodes)
                                    Positioned(
                                      left: node.x * _worldWidth - nodeSize / 2,
                                      top:
                                          node.y * worldHeight +
                                          (viewport.height - worldHeight) / 2 -
                                          nodeSize / 2,
                                      width: nodeSize,
                                      height: nodeSize + 22,
                                      child: MapLevelButton(
                                        level: node.level,
                                        lights: _lightsFor(node.level),
                                        unlocked: _unlocked(node.level),
                                        active: node.level == _activeLevel,
                                        onTap: () => _focusLevel(
                                          node.level,
                                          select: true,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          MapSelectionLight(
                            level: _activeLevel,
                            scoreLevels: {
                              for (final node in kMap1Nodes)
                                if (_unlocked(node.level)) node.level,
                            },
                            worldSize: Size(_worldWidth, worldHeight),
                            nodeSize: nodeSize,
                            scroll: _scroll,
                          ),
                          if (_awardingLevel != null)
                            LightAwardOverlay(
                              animation: _award,
                              scroll: _scroll,
                              variant: _awardVariant,
                              source: Offset(
                                kMap1Nodes[_awardingLevel! - 1].x * _worldWidth,
                                kMap1Nodes[_awardingLevel! - 1].y *
                                        worldHeight +
                                    (viewport.height - worldHeight) / 2,
                              ),
                              destination: Offset(
                                kMap1Nodes[_awardingLevel! - 1].x *
                                        _worldWidth +
                                    mapScoreStarOffset(_socket, nodeSize).dx,
                                kMap1Nodes[_awardingLevel! - 1].y *
                                        worldHeight +
                                    (viewport.height - worldHeight) / 2 +
                                    mapScoreStarOffset(_socket, nodeSize).dy,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          largeWindow ? 32 : 16,
                          compact ? 8 : (largeWindow ? 24 : 16),
                          largeWindow ? 32 : 16,
                          12,
                        ),
                        child: Column(
                          children: [
                            MapWorldHeader(
                              onViewTutorial: widget.onViewTutorial,
                              compact: compact,
                              onBack: () => Navigator.of(context).pop(),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                    if (kDebugMode && widget.showDeveloperControls)
                      DeveloperFloatingMenu(
                        actions: [
                          DeveloperMenuAction(
                            key: const ValueKey(
                              'dev-complete-world-except-last',
                            ),
                            label: 'Completar mundo menos última ronda',
                            icon: Icons.flag_outlined,
                            onPressed: _completeWorldExceptLastPuzzle,
                          ),
                          DeveloperMenuAction(
                            key: const ValueKey('dev-reset-world'),
                            label: 'Resetear mundo',
                            icon: Icons.public_outlined,
                            onPressed: _resetWorld,
                          ),
                          DeveloperMenuAction(
                            key: const ValueKey('dev-reset-specific-level'),
                            label: 'Resetear nivel específico',
                            icon: Icons.restart_alt_rounded,
                            onPressed: _chooseLevelToReset,
                          ),
                          DeveloperMenuAction(
                            key: const ValueKey('dev-complete-random-level'),
                            label: 'Completar nivel $_activeLevel al azar',
                            icon: Icons.casino_outlined,
                            onPressed: _completeActiveLevel,
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
          MapStatusCard(
            compact: MediaQuery.sizeOf(context).height < 520,
            level: _activeLevel,
            points: _progress.worldPoints,
            onPrevious: _awardingLevel == null && _activeLevel > 1
                ? () => _focusLevel(_activeLevel - 1)
                : null,
            onNext: _awardingLevel == null && _activeLevel < kMap1Nodes.length
                ? () => _focusLevel(_activeLevel + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
