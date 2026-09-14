import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../routes.dart';
import '../data/level_node.dart';
import '../widgets/game_feedback_scope.dart';
import '../widgets/home_art.dart';
import '../widgets/illustrated_action_button.dart';
import '../widgets/juicy_press.dart';
import '../widgets/parallax_background.dart';
import '../widgets/settings_art.dart';

/// Sunny title screen with Doku, illustrated controls, and live game progress.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.availableLevel = 1,
    this.unlockedLevels = 1,
    this.playerName = 'Jugador',
    this.onPlay,
    this.onReady,
    this.hasStarted = false,
  });

  final int availableLevel;
  final int unlockedLevels;
  final String playerName;
  final VoidCallback? onPlay;
  final ValueChanged<BuildContext>? onReady;
  final bool hasStarted;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onReady?.call(context);
    });
  }

  @override
  Widget build(BuildContext context) => TickerMode(
    enabled: ModalRoute.of(context)?.isCurrent ?? true,
    child: Scaffold(
      body: ParallaxBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) {
              final landscape = viewport.maxWidth > viewport.maxHeight * 1.2;
              final height = math.max(300.0, viewport.maxHeight);
              final content = Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: landscape ? 960 : 500),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      landscape ? 14 : (height * .045).clamp(18, 38),
                    ),
                    child: Column(
                      children: [
                        _HomeHeader(playerName: widget.playerName),
                        if (landscape)
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      const _AnimatedLogo(width: 240),
                                      const Expanded(child: _Doku()),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Center(
                                    child: _HomeActions(
                                      onPlay: widget.onPlay,
                                      availableLevel: widget.availableLevel,
                                      unlockedLevels: widget.unlockedLevels,
                                      compact: true,
                                      hasStarted: widget.hasStarted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          SizedBox(height: height < 650 ? 2 : 8),
                          LayoutBuilder(
                            builder: (context, space) => _AnimatedLogo(
                              width: math.min(
                                space.maxWidth * .94,
                                height * .46,
                              ),
                            ),
                          ),
                          const Expanded(child: _Doku()),
                          const SizedBox(height: 8),
                          _HomeActions(
                            onPlay: widget.onPlay,
                            availableLevel: widget.availableLevel,
                            unlockedLevels: widget.unlockedLevels,
                            compact: height < 650,
                            hasStarted: widget.hasStarted,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
              return viewport.maxHeight < 300
                  ? SingleChildScrollView(
                      child: SizedBox(height: height, child: content),
                    )
                  : content;
            },
          ),
        ),
      ),
    ),
  );
}

class _Doku extends StatelessWidget {
  const _Doku();

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/doku-home.png',
    fit: BoxFit.contain,
    alignment: Alignment.bottomCenter,
    semanticLabel: 'Doku saluda alegremente',
  );
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.playerName});
  final String playerName;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Flexible(
        child: SizedBox(
          width: 168,
          height: 54,
          child: JuicyPress(
            key: const ValueKey('home-profile'),
            label:
                'Perfil de ${playerName.trim().isEmpty ? 'Jugador' : playerName}',
            onFeedback: () => GameFeedbackScope.tap(context),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profile),
            builder: (context, depression) => Stack(
              fit: StackFit.expand,
              children: [
                const HomeArt(HomeSurface.profile),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 9, 17, 10),
                  child: Row(
                    children: [
                      const HomeIcon(HomeGlyph.user, size: 27),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          playerName.trim().isEmpty ? 'Jugador' : playerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: homeText(20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: 16),
      SizedBox.square(
        dimension: 54,
        child: JuicyPress(
          key: const ValueKey('home-settings'),
          label: 'Ajustes',
          onFeedback: () => GameFeedbackScope.tap(context),
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
          builder: (context, depression) => const Stack(
            fit: StackFit.expand,
            children: [
              HomeArt(HomeSurface.settings),
              Center(child: SettingsIcon(SettingsGlyph.gear, size: 33)),
            ],
          ),
        ),
      ),
    ],
  );
}

class _HomeActions extends StatelessWidget {
  const _HomeActions({
    required this.availableLevel,
    required this.unlockedLevels,
    required this.compact,
    required this.hasStarted,
    this.onPlay,
  });
  final VoidCallback? onPlay;
  final int availableLevel;
  final int unlockedLevels;
  final bool compact;
  final bool hasStarted;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 380),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IllustratedActionButton(
          key: const ValueKey('home-play'),
          label: 'Jugar',
          compact: compact,
          onPressed:
              onPlay ?? () => Navigator.of(context).pushNamed(AppRoutes.map),
        ),
        if (hasStarted) ...[
          SizedBox(height: compact ? 9 : 12),
          _GameStatusCard(
            key: const ValueKey('home-game-status'),
            availableLevel: availableLevel,
            unlockedLevels: unlockedLevels,
          ),
        ],
      ],
    ),
  );
}

class _GameStatusCard extends StatelessWidget {
  const _GameStatusCard({
    super.key,
    required this.availableLevel,
    required this.unlockedLevels,
  });
  final int availableLevel;
  final int unlockedLevels;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Nivel $availableLevel. Mundo 1. $unlockedLevels de ${kMap1Nodes.length} niveles desbloqueados',
    excludeSemantics: true,
    child: AspectRatio(
      aspectRatio: 3.12,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const HomeArt(HomeSurface.status),
          LayoutBuilder(
            builder: (context, space) {
              final unit = space.maxWidth / 350;
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  23 * unit,
                  17 * unit,
                  23 * unit,
                  16 * unit,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatusLabel(
                              HomeGlyph.sun,
                              'Nivel $availableLevel',
                              unit,
                            ),
                          ),
                          Container(
                            width: 1.2,
                            height: 32 * unit,
                            color: const Color(0xFFE1CCA3),
                          ),
                          SizedBox(width: 13 * unit),
                          Expanded(
                            child: _StatusLabel(
                              HomeGlyph.world,
                              'Mundo 1',
                              unit,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 7 * unit),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20 * unit),
                      child: SizedBox(
                        height: 16 * unit,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const HomeArt(HomeSurface.progressTrack),
                            Padding(
                              padding: EdgeInsets.all(1.6 * unit),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor:
                                      (unlockedLevels / kMap1Nodes.length)
                                          .clamp(0, 1),
                                  heightFactor: 1,
                                  child: const HomeArt(
                                    HomeSurface.progressFill,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 3 * unit),
                    Text(
                      '$unlockedLevels de ${kMap1Nodes.length}',
                      style: homeText(15 * unit),
                      textScaler: TextScaler.noScaling,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel(this.glyph, this.label, this.unit);
  final HomeGlyph glyph;
  final String label;
  final double unit;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      HomeIcon(glyph, size: 37 * unit),
      SizedBox(width: 7 * unit),
      Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(label, style: homeText(22 * unit)),
        ),
      ),
    ],
  );
}

class _AnimatedLogo extends StatefulWidget {
  const _AnimatedLogo({required this.width});

  final double width;

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with TickerProviderStateMixin {
  static bool _hasPlayedEntrance = false;

  late final AnimationController _entranceController;
  late final AnimationController _idleController;
  late final Animation<Offset> _idleOffset;
  late final Animation<double> _idleRotation;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    );

    final math.Random random = math.Random();
    final List<Offset> offsets = [
      Offset.zero,
      for (int i = 0; i < 7; i++)
        Offset(random.nextDouble() * 6 - 3, random.nextDouble() * 4 - 2),
      Offset.zero,
    ];
    final List<double> rotations = [
      0,
      for (int i = 0; i < 7; i++) random.nextDouble() * 0.016 - 0.008,
      0,
    ];

    _idleOffset = _offsetSequence(offsets).animate(_idleController);
    _idleRotation = _doubleSequence(rotations).animate(_idleController);
  }

  TweenSequence<Offset> _offsetSequence(List<Offset> values) {
    return TweenSequence<Offset>([
      for (int i = 0; i < values.length - 1; i++)
        TweenSequenceItem(
          tween: Tween<Offset>(
            begin: values[i],
            end: values[i + 1],
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1,
        ),
    ]);
  }

  TweenSequence<double> _doubleSequence(List<double> values) {
    return TweenSequence<double>([
      for (int i = 0; i < values.length - 1; i++)
        TweenSequenceItem(
          tween: Tween<double>(
            begin: values[i],
            end: values[i + 1],
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1,
        ),
    ]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final bool animationsDisabled = MediaQuery.disableAnimationsOf(context);
    final bool shouldPlayEntrance = !_hasPlayedEntrance;
    _hasPlayedEntrance = true;

    if (animationsDisabled || !shouldPlayEntrance) {
      _entranceController.value = 1;
      if (!animationsDisabled) _idleController.repeat();
      return;
    }

    _entranceController.forward().whenComplete(() {
      if (mounted) _idleController.repeat();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_entranceController, _idleController]),
        child: Image.asset(
          'assets/images/sundoku-logo.png',
          width: widget.width,
          fit: BoxFit.contain,
          semanticLabel: 'SunDoku',
        ),
        builder: (context, child) {
          final double entrance = Curves.easeOutBack.transform(
            _entranceController.value,
          );
          final Offset position =
              Offset(0, -34 * (1 - entrance)) + _idleOffset.value;
          final double scale = 0.72 + 0.28 * entrance;

          return Transform.translate(
            offset: position,
            child: Transform.rotate(
              angle: _idleRotation.value,
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
      ),
    );
  }
}
