import 'screens/challenge_tutorial_screen.dart';
import 'screens/world_selection_screen.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import 'routes.dart';
import 'controllers/first_experience_controller.dart';
import 'data/level_progress.dart';
import 'widgets/book_resources.dart';
import 'widgets/solara_book.dart';
import 'screens/notes_tutorial_screen.dart';
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
  bool _welcomeChecked = false;
  bool _openingBook = false;
  late final _bookResources = BookResources();

  bool get _hasStarted {
    final introduction =
        _repository.state.modules[FirstExperienceController.moduleKey];
    return (introduction is Map && introduction.isNotEmpty) ||
        _repository.state.sessions.isNotEmpty ||
        _levelOneComplete;
  }

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
    _openingPlay = true;
    try {
      final route = _worldSelectionRoute(
        context,
        const RouteSettings(name: AppRoutes.worlds),
      );
      unawaited(Navigator.of(context).push(route));
      await route.entered;
    } finally {
      _openingPlay = false;
    }
  }

  WorldJourneyRoute _worldSelectionRoute(
    BuildContext context,
    RouteSettings settings, {
    ValueChanged<String>? onChosen,
  }) => WorldJourneyRoute(
    settings: settings,
    reduceMotion:
        MediaQuery.maybeOf(context)?.disableAnimations ??
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations,
    builder: (context) => WorldSelectionScreen(
      repository: _repository,
      navigation: _worldNavigation,
      onSelectWorld: (worldId) async {
        if (!_worldNavigation.isUnlocked(worldId)) return;
        if (onChosen != null) {
          onChosen(worldId);
          Navigator.of(context).pop();
        } else {
          await _enterSelectedWorld(context, worldId);
        }
      },
    ),
  );

  Future<void> _chooseWorldFromMap(BuildContext context) async {
    String? selected;
    await Navigator.of(context).push(
      _worldSelectionRoute(
        context,
        const RouteSettings(name: AppRoutes.worlds),
        onChosen: (worldId) => selected = worldId,
      ),
    );
    if (selected != null && context.mounted) {
      try {
        await _switchWorld(context, selected!);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No pudimos abrir este destino. Intenta de nuevo.'),
            ),
          );
        }
      }
    }
  }

  Future<void> _enterSelectedWorld(BuildContext context, String worldId) async {
    if (_openingPlay || !_worldNavigation.isUnlocked(worldId)) return;
    _openingPlay = true;
    try {
      await _worldNavigation.enterWorld(worldId);
      if (!context.mounted) return;
      final navigator = Navigator.of(context);
      final route = _mapRoute(
        context,
        const RouteSettings(name: AppRoutes.map),
        worldId: worldId,
      );
      unawaited(navigator.push(route));
      await route.entered;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos abrir este destino. Intenta de nuevo.'),
          ),
        );
      }
    } finally {
      _openingPlay = false;
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
      onChooseWorld: () => unawaited(_chooseWorldFromMap(context)),
      onHome: () => Navigator.of(context).popUntil(
        (route) => route.settings.name == AppRoutes.home || route.isFirst,
      ),
      onNextWorld: worldId == 'world-1'
          ? () => _switchWorld(context, 'world-2')
          : worldId == 'world-2'
          ? () => _switchWorld(context, 'world-3')
          : null,
      onReturn: () => showNotesUnlock(context, _repository),
      onViewTutorial: () => unawaited(_openTutorialBook(context)),
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
              if (context.mounted) await _openNotesLesson(context);
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
      await _openNotesLesson(context);
      return;
    }
    if (worldId == 'world-3' && _repository.needsChallengeTutorial(number)) {
      await _openChallengeLesson(context, number);
      return;
    }
    final session = await _repository.startGeneratedLevel(
      number,
      worldId: worldId,
    );
    await _repository.acknowledgeIntermediateWin(session.id);
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

  Future<void> _openNotesLesson(BuildContext context) async {
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
  Future<void> _openChallengeLesson(BuildContext context, int level) async {
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

  Future<void> _warmTutorialBook(BuildContext context) async {
    try {
      await _bookResources.prepare(context);
    } catch (_) {
      // Opening the book retries a failed background load and reports it.
    }
  }

  Future<void> _openTutorialBook(BuildContext context) async {
    if (_openingBook) return;
    _openingBook = true;
    final sourceRoute = ModalRoute.of(context);
    try {
      await _bookResources.prepare(context);
      if (!mounted || !context.mounted || sourceRoute?.isCurrent == false) {
        return;
      }
      await showDialog<void>(
        context: context,
        routeSettings: const RouteSettings(name: AppRoutes.tutorialBook),
        barrierColor: const Color(0x990B1524),
        builder: (bookContext) => SolaraBook(
          key: const ValueKey('tutorial-book'),
          onClose: () => Navigator.of(bookContext).pop(),
          onOpenSummary: () async {
            await Navigator.of(bookContext).pushNamed(AppRoutes.tutorialReview);
          },
        ),
      );
    } catch (_) {
      if (mounted && context.mounted && sourceRoute?.isCurrent != false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos cargar el libro. Intenta de nuevo.'),
          ),
        );
      }
    } finally {
      _openingBook = false;
    }
  }

  @override
  void dispose() {
    _bookResources.dispose();
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
                  unawaited(_warmTutorialBook(homeContext));
                  widget.onHomeReady?.call();
                  unawaited(_welcome(homeContext));
                },
                onResetAll: _repository.resetDebugSave,
                quickPlayUnlocked: _repository.quickPlayUnlocked,
                quickPlayIsNew: _repository.quickPlayIsNew,
                celebrateQuickPlay: _repository.shouldCelebrateQuickPlay,
                playerName: _repository.state.player.nameChosen
                    ? _repository.state.player.name
                    : 'Jugador',
              ),
            ),
          ),
          AppRoutes.worlds => _worldSelectionRoute(context, settings),
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
