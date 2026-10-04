import 'screens/challenge_tutorial_screen.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import 'routes.dart';
import 'controllers/first_experience_controller.dart';
import 'data/level_progress.dart';
import 'screens/notes_tutorial_screen.dart';
import 'widgets/home_art.dart';
import 'widgets/settings_art.dart';
import 'widgets/illustrated_action_button.dart';
import 'data/repositories/game_repository.dart';
import 'data/services/game_feedback.dart';
import 'data/services/device_game_feedback.dart';
import 'data/services/world_navigation_service.dart';
import 'data/services/mock_world_navigation_service.dart';
import 'widgets/game_feedback_scope.dart';
import 'widgets/music_route_observer.dart';
import 'widgets/modal_sound_observer.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/quick_play_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/map_screen.dart';
import 'screens/first_experience_screen.dart';
import 'widgets/sundoku_cursor.dart';
import 'widgets/world_journey_route.dart';
import 'widgets/developer_floating_menu.dart';
import 'playables/playables_runtime.dart';
import 'playables/playables_pause_gate.dart';

/// Root of the app. Wires the theme and the top-level route table.
class SunDokuApp extends StatefulWidget {
  const SunDokuApp({
    super.key,
    this.repository,
    this.feedback,
    this.worldNavigation,
    this.playables,
    this.onHomeReady,
  });

  final GameRepository? repository;
  final GameFeedback? feedback;
  final WorldNavigationService? worldNavigation;
  final PlayablesRuntime? playables;
  final VoidCallback? onHomeReady;

  @override
  State<SunDokuApp> createState() => _SunDokuAppState();
}

class _SunDokuAppState extends State<SunDokuApp> {
  late final GameRepository _repository =
      widget.repository ?? GameRepository.memory();
  late final LevelProgress _progress = LevelProgress(repository: _repository);
  late final LevelProgress _forestProgress = LevelProgress(
    repository: _repository,
    worldId: 'world-2',
  );
  late final LevelProgress _riverProgress = LevelProgress(
    repository: _repository,
    worldId: 'world-3',
  );
  late final GameFeedback _feedback = widget.feedback ?? DeviceGameFeedback();
  late final WorldNavigationService _worldNavigation =
      widget.worldNavigation ?? MockWorldNavigationService(_repository);

  late final _musicObserver = MusicRouteObserver(_feedback);

  late final _modalSoundObserver = ModalSoundObserver(
    onOpened: () => unawaited(
      _feedback.modalOpened(
        sound: widget.playables == null && _repository.state.settings.sound,
      ),
    ),
  );

  bool _openingPlay = false;
  bool _openingQuickPlay = false;
  bool _switchingWorld = false;
  bool? _departingHomeHasStarted;
  bool _welcomeChecked = false;

  bool get _hasStarted {
    final introduction =
        _repository.state.modules[FirstExperienceController.moduleKey];
    return (introduction is Map && introduction.isNotEmpty) ||
        _repository.state.sessions.isNotEmpty ||
        _levelOneComplete;
  }

  LevelProgress get _adventureProgress =>
      _progressFor(_repository.lastAdventureWorld);

  LevelProgress _progressFor(String worldId) => switch (worldId) {
    'world-2' => _forestProgress,
    'world-3' => _riverProgress,
    _ => _progress,
  };

  bool get _levelOneComplete =>
      _progress.lightsFor(1) >= LevelProgress.requiredLights;

  Future<void> _openQuickPlay(BuildContext context) async {
    if (!_repository.quickPlayUnlocked || _openingQuickPlay) return;
    _openingQuickPlay = true;
    try {
      await _repository.markQuickPlayOpened();
      if (!context.mounted) return;
      unawaited(Navigator.of(context).pushNamed(AppRoutes.quickPlay));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos abrir la partida. Intenta de nuevo.'),
          ),
        );
      }
    } finally {
      _openingQuickPlay = false;
    }
  }

  Future<void> _quickPlayCelebrated(BuildContext context) async {
    try {
      await _repository.markQuickPlayCelebrated();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos guardar esta visita.')),
        );
      }
    }
  }

  Future<void> _welcome(BuildContext context) async {
    final route = ModalRoute.of(context);
    if (route is WorldJourneyRoute) {
      final arrived = await route.entered;
      if (!arrived || !context.mounted) return;
    }
    if (_welcomeChecked) return;
    _welcomeChecked = true;
    final welcome = _repository.state.modules['homeWelcome'];
    if (welcome is Map && welcome['namePromptShown'] == true) return;
    final shouldAsk = !_repository.state.player.nameChosen && !_hasStarted;
    try {
      await _repository.saveModule('homeWelcome', {'namePromptShown': true});
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos guardar esta visita.')),
      );
    }
    if (shouldAsk &&
        context.mounted &&
        (ModalRoute.of(context)?.isCurrent ?? false)) {
      await Navigator.of(context).pushNamed(AppRoutes.profile);
    }
  }

  Future<void> _play(BuildContext context) async {
    if (_openingPlay) return;
    _departingHomeHasStarted = _hasStarted;
    _openingPlay = true;
    try {
      final saved =
          _repository.state.modules[FirstExperienceController.moduleKey];
      final firstVisit = saved is! Map || saved.isEmpty;
      if (firstVisit) {
        await _repository.saveModule(FirstExperienceController.moduleKey, {
          'homeIntroductionShown': true,
        });
      }
      if (!context.mounted) return;
      final navigator = Navigator.of(context);
      final route = _mapRoute(
        context,
        const RouteSettings(name: AppRoutes.map),
        showClouds: !firstVisit,
        worldId: _repository.lastAdventureWorld,
      );
      unawaited(navigator.push(route));
      if (firstVisit) {
        // Install both routes in the same frame: the tutorial owns the visible
        // journey, while the map is ready underneath for the return navigation.
        final tutorial = WorldJourneyRoute(
          settings: const RouteSettings(name: AppRoutes.firstExperience),
          reduceMotion: MediaQuery.disableAnimationsOf(context),
          builder: (_) => FirstExperienceScreen(repository: _repository),
        );
        unawaited(navigator.push(tutorial));
        await tutorial.entered;
      } else {
        await route.entered;
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos guardar. Vuelve a tocar Jugar.'),
          ),
        );
      }
    } finally {
      _openingPlay = false;
      if (mounted) {
        setState(() => _departingHomeHasStarted = null);
      }
    }
  }

  Future<void> _replayPractice(BuildContext context) async {
    final flow = FirstExperienceController(_repository);
    try {
      await flow.restartGames();
    } finally {
      flow.dispose();
    }
    if (context.mounted) {
      await Navigator.of(context).pushNamed(AppRoutes.firstExperience);
    }
  }

  WorldJourneyRoute _mapRoute(
    BuildContext context,
    RouteSettings settings, {
    bool showClouds = true,
    String worldId = 'world-1',
  }) => WorldJourneyRoute(
    settings: settings,
    showClouds: showClouds,
    reduceMotion:
        MediaQuery.maybeOf(context)?.disableAnimations ??
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations,
    builder: (context) => MapScreen(
      key: ValueKey(worldId),
      progress: _progressFor(worldId),
      worldNavigation: _worldNavigation,
      onSelectWorld: (selected) => unawaited(_switchWorld(context, selected)),
      onNextWorld: worldId == 'world-1'
          ? () => _switchWorld(context, 'world-2')
          : worldId == 'world-2'
          ? () => _switchWorld(context, 'world-3')
          : null,
      onReady: worldId == 'world-2'
          ? () => _forestReady(context)
          : worldId == 'world-3'
          ? () => _riverReady(context)
          : null,
      onReturn: () => showNotesUnlock(context, _repository),
      onViewTutorial: () => unawaited(_agenda(context)),
      onOpenIntroduction: worldId == 'world-1'
          ? () => Navigator.of(context).pushNamed(AppRoutes.firstExperience)
          : null,
      onReplayIntroduction: worldId == 'world-1'
          ? () => _replayPractice(context)
          : null,
      onOpenLevel: (number) => _openAdventureGame(context, worldId, number),
      developerActions: [
        if (worldId == 'world-1')
          DeveloperMenuAction(
            key: const ValueKey('dev-prepare-forest'),
            label: 'Preparar entrada al bosque',
            icon: Icons.forest,
            onPressed: () async {
              await _repository.prepareDebugForest();
              if (context.mounted) await _switchWorld(context, 'world-2');
            },
          ),
        if (worldId == 'world-2')
          DeveloperMenuAction(
            key: const ValueKey('dev-notes-lesson'),
            label: 'Repetir entrada con lápiz',
            icon: Icons.edit_note,
            onPressed: () async {
              await _repository.resetDebugNotesTutorial();
              if (context.mounted) await _forestReady(context);
            },
          ),
      ],
    ),
  );

  bool _openingForestLesson = false;
  Future<void> _openAdventureGame(
    BuildContext context,
    String worldId,
    int number, {
    bool replace = false,
  }) async {
    if (worldId == 'world-2' && !_repository.notesTutorialCompleted) {
      await _forestReady(context);
      return;
    }
    await _repository.startGeneratedLevel(number, worldId: worldId);
    if (!context.mounted) return;
    final route = WorldJourneyRoute(
      settings: const RouteSettings(name: AppRoutes.game),
      reduceMotion: MediaQuery.disableAnimationsOf(context),
      builder: (_) => FirstExperienceScreen(
        repository: _repository,
        worldId: worldId,
        levelNumber: number,
      ),
    );
    if (replace) {
      unawaited(Navigator.of(context).pushReplacement(route));
    } else {
      await Navigator.of(context).push(route);
      if (context.mounted) await showNotesUnlock(context, _repository);
    }
  }

  Future<void> _forestReady(BuildContext context) async {
    if (!_repository.forestUnlocked || _openingForestLesson) return;
    await _repository.visitWorld('world-2');
    if (!context.mounted) return;
    if (_repository.notesTutorialCompleted) {
      await showNotesUnlock(context, _repository);
      return;
    }
    _openingForestLesson = true;
    try {
      await Navigator.of(context).push(
        WorldJourneyRoute(
          settings: const RouteSettings(name: AppRoutes.tutorialReview),
          reduceMotion: MediaQuery.disableAnimationsOf(context),
          builder: (lessonContext) => NotesTutorialScreen(
            repository: _repository,
            onFinished: () async {
              if (_repository.notesUnlocked) {
                Navigator.of(lessonContext).pop();
                return;
              }
              await _openAdventureGame(
                lessonContext,
                'world-2',
                1,
                replace: true,
              );
            },
          ),
        ),
      );
      if (context.mounted && ModalRoute.of(context)?.isCurrent == true) {
        await showNotesUnlock(context, _repository);
      }
    } finally {
      _openingForestLesson = false;
    }
  }

  bool _openingRiverLesson = false;
  Future<void> _riverReady(BuildContext context) async {
    final level = _riverProgress.latestUnlocked;
    if (_openingRiverLesson || !_repository.needsChallengeTutorial(level)) {
      return;
    }
    _openingRiverLesson = true;
    try {
      await Navigator.of(context).push(
        WorldJourneyRoute(
          settings: const RouteSettings(name: AppRoutes.challengeIntroduction),
          reduceMotion: MediaQuery.disableAnimationsOf(context),
          builder: (lessonContext) => ChallengeTutorialScreen(
            repository: _repository,
            onFinished: () => _openAdventureGame(
              lessonContext,
              'world-3',
              level,
              replace: true,
            ),
          ),
        ),
      );
    } finally {
      _openingRiverLesson = false;
    }
  }

  Future<void> _switchWorld(BuildContext context, String worldId) async {
    if (_switchingWorld) return;
    _switchingWorld = true;
    try {
      await _worldNavigation.enterWorld(worldId);
      if (!context.mounted) return;
      unawaited(
        Navigator.of(context).pushReplacement(
          _mapRoute(
            context,
            const RouteSettings(name: AppRoutes.map),
            worldId: worldId,
          ),
        ),
      );
    } finally {
      _switchingWorld = false;
    }
  }

  Future<void> _agenda(BuildContext context) async {
    if (!_repository.forestUnlocked) {
      await Navigator.of(context).pushNamed(AppRoutes.tutorialReview);
      return;
    }
    final lesson = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SettingsPanelSurface(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Tu cuaderno', style: homeText(28)),
                          const SizedBox(height: 16),
                          IllustratedActionButton(
                            label: 'Las reglas',
                            fontSize: 22,
                            compact: true,
                            onPressed: () => Navigator.pop(context, 'rules'),
                          ),
                          const SizedBox(height: 12),
                          IllustratedActionButton(
                            label: 'Las anotaciones',
                            fontSize: 22,
                            compact: true,
                            onPressed: () => Navigator.pop(context, 'notes'),
                          ),
                          if (_repository.isWorldUnlocked('world-3')) ...[
                            const SizedBox(height: 12),
                            IllustratedActionButton(
                              label: 'Los desafíos',
                              fontSize: 22,
                              compact: true,
                              onPressed: () =>
                                  Navigator.pop(context, 'challenges'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (lesson == null || !context.mounted) return;
    if (lesson == 'challenges') {
      await Navigator.of(context).push(
        WorldJourneyRoute(
          settings: const RouteSettings(name: AppRoutes.challengeIntroduction),
          reduceMotion: MediaQuery.disableAnimationsOf(context),
          builder: (context) => ChallengeTutorialScreen(
            repository: _repository,
            replay: true,
            onFinished: () async {
              Navigator.of(context).pop();
            },
          ),
        ),
      );
      return;
    }
    if (lesson == 'rules') {
      await Navigator.of(context).pushNamed(AppRoutes.tutorialReview);
      return;
    }
    await Navigator.of(context).push(
      WorldJourneyRoute(
        settings: const RouteSettings(name: AppRoutes.tutorialReview),
        reduceMotion: MediaQuery.disableAnimationsOf(context),
        builder: (context) => NotesTutorialScreen(
          repository: _repository,
          replay: true,
          onFinished: () async {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _progress.dispose();
    _forestProgress.dispose();
    _riverProgress.dispose();
    if (widget.repository == null) unawaited(_repository.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameFeedbackHost(
      repository: _repository,
      output: _feedback,
      playables: widget.playables,
      child: MaterialApp(
        title: 'SunDoku',
        navigatorObservers: [_musicObserver, _modalSoundObserver],
        debugShowCheckedModeBanner: false,
        theme: buildSunDokuTheme(),
        initialRoute: widget.playables == null
            ? AppRoutes.splash
            : AppRoutes.home,
        builder: (context, child) {
          final runtime = widget.playables;
          return runtime == null
              ? SunDokuCursor(child: child!)
              : PlayablesPauseGate(runtime: runtime, child: child!);
        },
        routes: {
          if (widget.playables == null)
            AppRoutes.splash: (_) => const SplashScreen(),
        },
        onGenerateRoute: (settings) => switch (settings.name) {
          AppRoutes.challengeIntroduction => _mapRoute(
            context,
            settings,
            worldId: _repository.isWorldUnlocked('world-3')
                ? 'world-3'
                : 'world-1',
          ),
          AppRoutes.tutorialReview => WorldJourneyRoute(
            settings: settings,
            reduceMotion: WidgetsBinding
                .instance
                .platformDispatcher
                .accessibilityFeatures
                .disableAnimations,
            builder: (_) => FirstExperienceScreen(
              repository: _repository,
              reviewOnly: true,
            ),
          ),
          AppRoutes.home => WorldJourneyRoute(
            settings: settings,
            reduceMotion: WidgetsBinding
                .instance
                .platformDispatcher
                .accessibilityFeatures
                .disableAnimations,
            builder: (_) => ListenableBuilder(
              listenable: _progress,
              builder: (context, _) => HomeScreen(
                onPlay: () => _play(context),
                onQuickPlay: () => unawaited(_openQuickPlay(context)),
                onQuickPlayCelebrated: () =>
                    unawaited(_quickPlayCelebrated(context)),
                onReady: (homeContext) {
                  widget.onHomeReady?.call();
                  unawaited(_welcome(homeContext));
                },
                onResetAll: _repository.resetDebugSave,
                hasStarted: _departingHomeHasStarted ?? _hasStarted,
                quickPlayUnlocked: _repository.quickPlayUnlocked,
                quickPlayIsNew: _repository.quickPlayIsNew,
                celebrateQuickPlay: _repository.shouldCelebrateQuickPlay,
                worldId: _repository.lastAdventureWorld,
                availableLevel: _adventureProgress.latestUnlocked,
                unlockedLevels: _adventureProgress.unlockedCount,
                playerName: _repository.state.player.nameChosen
                    ? _repository.state.player.name
                    : 'Jugador',
              ),
            ),
          ),
          AppRoutes.map => _mapRoute(context, settings),
          AppRoutes.quickPlay when _repository.quickPlayUnlocked =>
            WorldJourneyRoute(
              settings: settings,
              reduceMotion: WidgetsBinding
                  .instance
                  .platformDispatcher
                  .accessibilityFeatures
                  .disableAnimations,
              builder: (_) => QuickPlayScreen(repository: _repository),
            ),
          AppRoutes.firstExperience => WorldJourneyRoute(
            settings: settings,
            reduceMotion: WidgetsBinding
                .instance
                .platformDispatcher
                .accessibilityFeatures
                .disableAnimations,
            builder: (_) => FirstExperienceScreen(repository: _repository),
          ),
          AppRoutes.settings => SettingsRoute(
            repository: _repository,
            settings: settings,
          ),
          AppRoutes.profile => ProfileRoute(
            repository: _repository,
            settings: settings,
          ),
          _ => null,
        },
      ),
    );
  }
}
