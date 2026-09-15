import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../data/level_progress.dart';
import '../widgets/map_level_button.dart';
import '../widgets/map_chrome.dart';
import '../widgets/completed_level_popover.dart';
import '../widgets/light_award_overlay.dart';
import '../widgets/parallax_background.dart';

import '../data/level_node.dart';
import '../widgets/app_toast.dart';
import '../widgets/map_selection_light.dart';

const _navy = Color(0xFF082A62);

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
        if (saved < _lightsFor(node.level) ||
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

  Future<void> _giveLights({required bool complete}) async {
    if (_awardingLevel != null ||
        !_progress.isUnlocked(_activeLevel) ||
        _progress.lightsFor(_activeLevel) == 3) {
      return;
    }
    final level = _activeLevel;
    setState(() => _awardingLevel = level);
    int? nextLevel;
    final count = complete ? 3 - _progress.lightsFor(level) : 1;
    try {
      for (int i = 0; i < count; i++) {
        if (!mounted) return;
        setState(() {
          _socket = _progress.lightsFor(level);
          _awardVariant = _awardRandom.nextInt(1 << 31);
        });
        if (!MediaQuery.disableAnimationsOf(context)) {
          await _award.forward(from: 0).orCancel;
        }
        if (!mounted) return;
        await _progress.awardLight(level);
        if (!mounted) return;
        if (_progress.lightsFor(level) == 3 && level < kMap1Nodes.length) {
          nextLevel = level + 1;
        }
      }
    } on TickerCanceled {
      // Leaving the map cancels the pending light without awarding it.
    } catch (_) {
      if (mounted) {
        showToast(context, 'No se pudo guardar el progreso. Intentá de nuevo.');
      }
    } finally {
      if (mounted) {
        setState(() => _awardingLevel = null);
        if (nextLevel != null) _focusLevel(nextLevel);
      }
    }
  }

  final ScrollController _scroll = ScrollController();

  Future<void> _resetLevel() async {
    try {
      await _progress.resetLevel(_activeLevel);
    } catch (_) {
      if (mounted) {
        showToast(context, 'No se pudo guardar el progreso. Intentá de nuevo.');
      }
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
      if (target > 1 && _progress.isUnlocked(target)) {
        if (_progress.lightsFor(target) >= 3) {
          showToast(context, '¡Ya completaste el nivel $target!');
          return;
        }
        if (widget.onOpenLevel != null) {
          _openingLevel = true;
          try {
            await widget.onOpenLevel!(target);
          } catch (_) {
            if (mounted) {
              showToast(
                context,
                'No pudimos abrir la partida. Intenta de nuevo.',
              );
            }
          } finally {
            _openingLevel = false;
            if (mounted) _queueRewards();
          }
          return;
        }
      }
      if (target == 1 &&
          _lightsFor(target) == 3 &&
          widget.onReplayIntroduction != null) {
        final worldHeight = _worldWidth / 3;
        final nodeSize = _viewport.height < 520
            ? 68.0
            : (_viewport.width * .24).clamp(82.0, 106.0);
        final node = kMap1Nodes[target - 1];
        final replay = await Navigator.of(context).push<bool>(
          CompletedLevelRoute(
            anchor: Offset(
              node.x * _worldWidth - _scroll.offset,
              node.y * worldHeight +
                  (_viewport.height - worldHeight) / 2 -
                  nodeSize * .9 -
                  8,
            ),
          ),
        );
        if (!mounted || replay != true) return;
        try {
          await widget.onReplayIntroduction!();
        } catch (_) {
          if (mounted) {
            showToast(
              context,
              'No pudimos iniciar la partida. Inténtalo de nuevo.',
            );
          }
        }
        return;
      }
      if (target == 1 &&
          _progress.isUnlocked(target) &&
          widget.onOpenIntroduction != null) {
        widget.onOpenIntroduction!();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF78C8F6),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final Size viewport = constraints.biggest;
          final bool compact = viewport.height < 520;
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
                      Positioned(
                        left: 0,
                        top: (viewport.height - worldHeight) / 2,
                        width: _worldWidth,
                        height: worldHeight,
                        child: ParallaxBackground(
                          backgroundAsset:
                              'assets/images/world-1-horizontal.png',
                          maxX: 8.0,
                          maxY: 6.0,
                          backgroundFit: BoxFit.fill,
                          backgroundAlignment: Alignment.topCenter,
                          mobileSensorEnabled: false,
                          scaleBase: 1.04,
                          child: const SizedBox.expand(),
                        ),
                      ),
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
                            onTap: () => _focusLevel(node.level, select: true),
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
                    kMap1Nodes[_awardingLevel! - 1].y * worldHeight +
                        (viewport.height - worldHeight) / 2,
                  ),
                  destination: Offset(
                    kMap1Nodes[_awardingLevel! - 1].x * _worldWidth +
                        mapScoreStarOffset(_socket, nodeSize).dx,
                    kMap1Nodes[_awardingLevel! - 1].y * worldHeight +
                        (viewport.height - worldHeight) / 2 +
                        mapScoreStarOffset(_socket, nodeSize).dy,
                  ),
                ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, compact ? 8 : 16, 16, 12),
                  child: Column(
                    children: [
                      MapWorldHeader(
                        onViewTutorial: widget.onViewTutorial,
                        compact: compact,
                        onBack: () => Navigator.of(context).pop(),
                      ),
                      if (kDebugMode && widget.showDeveloperControls) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _RaisedPanel(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'DEV',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: _navy,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Simular 1 punto',
                                    icon: const Icon(
                                      Icons.add_circle_outline_rounded,
                                    ),
                                    onPressed:
                                        _awardingLevel == null &&
                                            _progress.isUnlocked(
                                              _activeLevel,
                                            ) &&
                                            _progress.lightsFor(_activeLevel) <
                                                3
                                        ? () => _giveLights(complete: false)
                                        : null,
                                  ),
                                  IconButton(
                                    tooltip:
                                        'Simular 3 puntos y abrir siguiente',
                                    icon: const Icon(Icons.lock_open_rounded),
                                    onPressed:
                                        _awardingLevel == null &&
                                            _progress.isUnlocked(
                                              _activeLevel,
                                            ) &&
                                            _progress.lightsFor(_activeLevel) <
                                                3
                                        ? () => _giveLights(complete: true)
                                        : null,
                                  ),
                                  IconButton(
                                    tooltip: 'Reiniciar nivel',
                                    icon: const Icon(Icons.replay_rounded),
                                    onPressed:
                                        _awardingLevel == null &&
                                            _progress.lightsFor(_activeLevel) >
                                                0
                                        ? _resetLevel
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      MapStatusCard(
                        compact: viewport.height < 650,
                        level: _activeLevel,
                        totalLevels: kMap1Nodes.length,
                        points: _lightsFor(_activeLevel),
                        unlocked: _unlocked(_activeLevel),
                        onPrevious: _awardingLevel == null && _activeLevel > 1
                            ? () => _focusLevel(_activeLevel - 1)
                            : null,
                        onNext:
                            _awardingLevel == null &&
                                _activeLevel < kMap1Nodes.length
                            ? () => _focusLevel(_activeLevel + 1)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RaisedPanel extends StatelessWidget {
  const _RaisedPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFBE9), Color(0xFFFFE0A0)],
      ),
      border: Border.all(color: const Color(0xFFFFF3BB), width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40513F13),
          blurRadius: 12,
          offset: Offset(0, 8),
        ),
        BoxShadow(color: Color(0xFFD99A32), offset: Offset(0, 4)),
      ],
    ),
    child: child,
  );
}
