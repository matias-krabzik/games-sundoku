import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../playables/playables_runtime.dart';

import '../routes.dart';
import '../widgets/adventure_progress_card.dart';
import '../widgets/game_feedback_scope.dart';
import '../widgets/home_art.dart';
import '../widgets/illustrated_action_button.dart';
import '../widgets/juicy_press.dart';
import '../widgets/parallax_background.dart';
import '../widgets/quick_play_unlock_cue.dart';
import '../widgets/settings_art.dart';
import '../widgets/developer_floating_menu.dart';

/// Sunny title screen with Doku, illustrated controls, and live game progress.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.availableLevel = 1,
    this.worldId = 'world-1',
    this.unlockedLevels = 1,
    this.playerName = 'Jugador',
    this.onPlay,
    this.onQuickPlay,
    this.onReady,
    this.hasStarted = false,
    this.quickPlayUnlocked = false,
    this.quickPlayIsNew = false,
    this.celebrateQuickPlay = false,
    this.onQuickPlayCelebrated,
    this.showDeveloperControls = kDebugMode,
    this.onResetAll,
  });

  final int availableLevel;
  final String worldId;
  final int unlockedLevels;
  final String playerName;
  final VoidCallback? onPlay;
  final VoidCallback? onQuickPlay;
  final ValueChanged<BuildContext>? onReady;
  final bool hasStarted;
  final bool quickPlayUnlocked;
  final bool quickPlayIsNew;
  final bool celebrateQuickPlay;
  final VoidCallback? onQuickPlayCelebrated;
  final bool showDeveloperControls;
  final Future<void> Function()? onResetAll;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (PlayablesRuntime.active != null) {
        // gameReady follows the first fully painted, usable menu.
        await Future.wait([
          for (final asset in [
            'assets/images/home-background.png',
            'assets/images/sundoku-logo.png',
            'assets/images/doku-home.png',
            'assets/images/home/header-surfaces.png',
            'assets/images/home/icons.png',
            'assets/images/settings/icons.png',
            'assets/images/home/play-button.png',
            'assets/images/home/adventure-map.png',
            if (widget.quickPlayUnlocked)
              'assets/images/home/quick-play-bolt.png',
          ])
            precacheImage(AssetImage(asset), context),
        ]);
      }
      if (mounted) widget.onReady?.call(context);
    });
  }

  @override
  Widget build(BuildContext context) => TickerMode(
    enabled: ModalRoute.of(context)?.isCurrent ?? true,
    child: Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ParallaxBackground(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, viewport) {
                  final landscape =
                      viewport.maxWidth > viewport.maxHeight * 1.2;
                  final height = math.max(300.0, viewport.maxHeight);
                  final largeWindow =
                      viewport.maxWidth >= 700 || viewport.maxHeight >= 900;
                  final content = Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          largeWindow ? 32 : 16,
                          largeWindow ? 24 : 8,
                          largeWindow ? 32 : 16,
                          largeWindow ? 18 : 0,
                        ),
                        child: _HomeHeader(playerName: widget.playerName),
                      ),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: landscape
                                  ? 960
                                  : (largeWindow ? 650 : 500),
                            ),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                landscape ? 14 : (height * .045).clamp(18, 38),
                              ),
                              child: _HomeContentViewport(
                                minimumHeight:
                                    landscape || !widget.quickPlayUnlocked
                                    ? 0
                                    : (widget.quickPlayIsNew ? 340 : 300) +
                                          MediaQuery.textScalerOf(
                                            context,
                                          ).scale(
                                            widget.quickPlayIsNew ? 120 : 100,
                                          ),
                                child: Column(
                                  children: [
                                    if (landscape)
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: LayoutBuilder(
                                                builder: (context, space) =>
                                                    Column(
                                                      children: [
                                                        Expanded(
                                                          child: Center(
                                                            child: _AnimatedLogo(
                                                              key:
                                                                  const ValueKey(
                                                                    'home-logo',
                                                                  ),
                                                              width: math.min(
                                                                space.maxWidth *
                                                                    .96,
                                                                480,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const Expanded(
                                                          child: _Doku(),
                                                        ),
                                                      ],
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 18),
                                            Expanded(
                                              child: Center(
                                                child: SingleChildScrollView(
                                                  child: _HomeActions(
                                                    worldId: widget.worldId,
                                                    onQuickPlay:
                                                        widget.onQuickPlay,
                                                    onPlay: widget.onPlay,
                                                    availableLevel:
                                                        widget.availableLevel,
                                                    unlockedLevels:
                                                        widget.unlockedLevels,
                                                    compact: true,
                                                    quickPlayIsNew:
                                                        widget.quickPlayIsNew,
                                                    celebrateQuickPlay: widget
                                                        .celebrateQuickPlay,
                                                    onQuickPlayCelebrated: widget
                                                        .onQuickPlayCelebrated,
                                                    hasStarted:
                                                        widget.hasStarted,
                                                    quickPlayUnlocked: widget
                                                        .quickPlayUnlocked,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else ...[
                                      if (largeWindow)
                                        Expanded(
                                          child: Center(
                                            child: LayoutBuilder(
                                              builder: (_, _) => OverflowBox(
                                                maxWidth:
                                                    viewport.maxWidth - 32,
                                                alignment: Alignment.center,
                                                child: _AnimatedLogo(
                                                  key: const ValueKey(
                                                    'home-logo',
                                                  ),
                                                  width: math.min(
                                                    viewport.maxWidth * .9,
                                                    720,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (!largeWindow) ...[
                                        SizedBox(height: height < 650 ? 2 : 8),
                                        LayoutBuilder(
                                          builder: (context, space) =>
                                              _AnimatedLogo(
                                                key: const ValueKey(
                                                  'home-logo',
                                                ),
                                                width: math.min(
                                                  space.maxWidth * .94,
                                                  height * .46,
                                                ),
                                              ),
                                        ),
                                      ],
                                      const Expanded(child: _Doku()),
                                      const SizedBox(height: 8),
                                      _HomeActions(
                                        worldId: widget.worldId,
                                        onQuickPlay: widget.onQuickPlay,
                                        onPlay: widget.onPlay,
                                        availableLevel: widget.availableLevel,
                                        unlockedLevels: widget.unlockedLevels,
                                        compact: height < 650,
                                        quickPlayIsNew: widget.quickPlayIsNew,
                                        celebrateQuickPlay:
                                            widget.celebrateQuickPlay,
                                        onQuickPlayCelebrated:
                                            widget.onQuickPlayCelebrated,
                                        hasStarted: widget.hasStarted,
                                        quickPlayUnlocked:
                                            widget.quickPlayUnlocked,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
          if (widget.showDeveloperControls && widget.onResetAll != null)
            DeveloperFloatingMenu(
              actions: [
                DeveloperMenuAction(
                  key: const ValueKey('dev-reset-all'),
                  label: 'Resetear todo',
                  icon: Icons.delete_sweep_outlined,
                  onPressed: widget.onResetAll!,
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

class _HomeContentViewport extends StatelessWidget {
  const _HomeContentViewport({
    required this.minimumHeight,
    required this.child,
  });
  final double minimumHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, space) {
      if (space.maxHeight >= minimumHeight) return child;
      return SingleChildScrollView(
        child: SizedBox(height: minimumHeight, child: child),
      );
    },
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
    required this.worldId,
    required this.unlockedLevels,
    required this.compact,
    required this.quickPlayIsNew,
    required this.celebrateQuickPlay,
    this.onQuickPlayCelebrated,
    required this.hasStarted,
    required this.quickPlayUnlocked,
    this.onPlay,
    this.onQuickPlay,
  });
  final VoidCallback? onPlay;
  final VoidCallback? onQuickPlay;
  final int availableLevel;
  final String worldId;
  final int unlockedLevels;
  final bool compact;
  final bool quickPlayIsNew;
  final bool celebrateQuickPlay;
  final VoidCallback? onQuickPlayCelebrated;
  final bool hasStarted;
  final bool quickPlayUnlocked;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 380),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (quickPlayUnlocked) ...[
          QuickPlayUnlockCue(
            isNew: quickPlayIsNew,
            celebrate: celebrateQuickPlay,
            onCelebrated: onQuickPlayCelebrated,
            child: _quickPlayButton(),
          ),
          SizedBox(height: compact ? 12 : 16),
        ],
        _adventureButton(context),
        if (hasStarted) ...[
          SizedBox(height: compact ? 9 : 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: AdventureProgressCard(
              key: const ValueKey('home-game-status'),
              level: availableLevel,
              worldId: worldId,
              unlockedLevels: unlockedLevels,
            ),
          ),
        ],
      ],
    ),
  );

  Widget _adventureButton(BuildContext context) => IllustratedActionButton(
    key: const ValueKey('home-play'),
    label: 'Aventura',
    compact: compact,
    leadingIcon: const HomeIcon(HomeGlyph.map, size: 34),
    secondary: quickPlayUnlocked,
    fontSize: quickPlayUnlocked ? 28 : 34,
    onPressed: onPlay ?? () => Navigator.of(context).pushNamed(AppRoutes.map),
  );

  Widget _quickPlayButton() => IllustratedActionButton(
    key: const ValueKey('home-quick-play'),
    label: 'Partida rápida',
    compact: compact,
    leadingIcon: const HomeIcon(HomeGlyph.bolt, size: 34),
    onPressed: onQuickPlay ?? () {},
  );
}

class _AnimatedLogo extends StatefulWidget {
  const _AnimatedLogo({super.key, required this.width});

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
