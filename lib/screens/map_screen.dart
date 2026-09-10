import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../data/level_progress.dart';
import '../widgets/map_level_button.dart';
import '../widgets/light_award_overlay.dart';

import '../data/level_node.dart';
import '../widgets/app_toast.dart';
import '../widgets/map_selection_light.dart';

const _navy = Color(0xFF082A62);

/// A horizontally scrollable world with ten touch targets on the painted path.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.progress});

  final LevelProgress? progress;

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
  int? _awardingLevel;
  int _socket = 0;
  int _awardVariant = 0;
  final math.Random _awardRandom = math.Random();

  @override
  void initState() {
    super.initState();
    _progress.addListener(_progressChanged);
  }

  void _progressChanged() {
    if (mounted) setState(() {});
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
        _progress.awardLight(level);
        if (_progress.lightsFor(level) == 3 && level < kMap1Nodes.length) {
          nextLevel = level + 1;
        }
      }
    } on TickerCanceled {
      // Leaving the map cancels the pending light without awarding it.
    } finally {
      if (mounted) {
        setState(() => _awardingLevel = null);
        if (nextLevel != null) _focusLevel(nextLevel);
      }
    }
  }

  final ScrollController _scroll = ScrollController();
  int _activeLevel = 1;
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

  void _focusLevel(int level, {bool select = false}) {
    if (_awardingLevel != null) return;
    final int target = level.clamp(1, kMap1Nodes.length);
    setState(() => _activeLevel = target);
    if (_scroll.hasClients) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _scroll.jumpTo(_offsetFor(target));
      } else {
        _scroll.animateTo(
          _offsetFor(target),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    }
    if (select) {
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
          final double nodeSize = compact ? 56 : 68;

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
                        child: Image.asset(
                          'assets/images/world-1-horizontal.png',
                          fit: BoxFit.fill,
                          excludeFromSemantics: true,
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
                            lights: _progress.lightsFor(node.level),
                            unlocked: _progress.isUnlocked(node.level),
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
                enabled: _progress.isUnlocked(_activeLevel),
                scoreLevels: {
                  for (final node in kMap1Nodes)
                    if (_progress.isUnlocked(node.level)) node.level,
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _RoundButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: 'Volver',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: _RaisedPanel(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: compact ? 8 : 12,
                                  ),
                                  child: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'MUNDO 1',
                                        style: TextStyle(
                                          color: Color(0xFF9D650D),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Valle del Sol',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: _navy,
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (kDebugMode) ...[
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
                                        ? () =>
                                              _progress.resetLevel(_activeLevel)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      _RaisedPanel(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Nivel anterior',
                                icon: const Icon(Icons.chevron_left_rounded),
                                color: _navy,
                                onPressed:
                                    _awardingLevel == null && _activeLevel > 1
                                    ? () => _focusLevel(_activeLevel - 1)
                                    : null,
                              ),
                              SizedBox(
                                width: 160,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Nivel $_activeLevel de ${kMap1Nodes.length}',
                                      style: const TextStyle(
                                        color: _navy,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      _progress.isUnlocked(_activeLevel)
                                          ? '${_progress.lightsFor(_activeLevel)}/3 puntos obtenidos'
                                          : 'Consigue 3 puntos en el nivel ${_activeLevel - 1}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF716344),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Nivel siguiente',
                                icon: const Icon(Icons.chevron_right_rounded),
                                color: _navy,
                                onPressed:
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

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => _RaisedPanel(
    child: IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
      color: _navy,
      iconSize: 28,
      constraints: const BoxConstraints.tightFor(width: 52, height: 52),
    ),
  );
}
