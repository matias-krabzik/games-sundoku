import 'dart:async';

import 'package:flutter/material.dart';

import 'routes.dart';
import 'controllers/first_experience_controller.dart';
import 'data/level_progress.dart';
import 'data/repositories/game_repository.dart';
import 'data/services/game_feedback.dart';
import 'data/services/device_game_feedback.dart';
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

/// Root of the app. Wires the theme and the top-level route table.
class SunDokuApp extends StatefulWidget {
  const SunDokuApp({super.key, this.repository, this.feedback});

  final GameRepository? repository;
  final GameFeedback? feedback;

  @override
  State<SunDokuApp> createState() => _SunDokuAppState();
}

class _SunDokuAppState extends State<SunDokuApp> {
  late final GameRepository _repository =
      widget.repository ?? GameRepository.memory();
  late final LevelProgress _progress = LevelProgress(repository: _repository);
  late final GameFeedback _feedback = widget.feedback ?? DeviceGameFeedback();

  late final _musicObserver = MusicRouteObserver(_feedback);

  late final _modalSoundObserver = ModalSoundObserver(
    onOpened: () => unawaited(
      _feedback.modalOpened(sound: _repository.state.settings.sound),
    ),
  );

  bool _openingPlay = false;
  bool _openingQuickPlay = false;
  bool? _departingHomeHasStarted;
  bool _welcomeChecked = false;

  bool get _hasStarted {
    final introduction =
        _repository.state.modules[FirstExperienceController.moduleKey];
    return (introduction is Map && introduction.isNotEmpty) ||
        _repository.state.sessions.isNotEmpty ||
        _levelOneComplete;
  }

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
      progress: _progress,
      onViewTutorial: () =>
          Navigator.of(context).pushNamed(AppRoutes.tutorialReview),
      onOpenIntroduction: () =>
          Navigator.of(context).pushNamed(AppRoutes.firstExperience),
      onReplayIntroduction: () => _replayPractice(context),
      onOpenLevel: (number) async {
        await _repository.startGeneratedLevel(number);
        if (!context.mounted) return;
        await Navigator.of(context).push(
          WorldJourneyRoute(
            settings: const RouteSettings(name: AppRoutes.game),
            reduceMotion: MediaQuery.disableAnimationsOf(context),
            builder: (_) => FirstExperienceScreen(
              repository: _repository,
              levelNumber: number,
            ),
          ),
        );
      },
    ),
  );

  @override
  void dispose() {
    _progress.dispose();
    if (widget.repository == null) unawaited(_repository.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameFeedbackHost(
      repository: _repository,
      output: _feedback,
      child: MaterialApp(
        title: 'SunDoku',
        navigatorObservers: [_musicObserver, _modalSoundObserver],
        debugShowCheckedModeBanner: false,
        theme: buildSunDokuTheme(),
        initialRoute: AppRoutes.splash,
        builder: (context, child) => SunDokuCursor(child: child!),
        routes: {AppRoutes.splash: (_) => const SplashScreen()},
        onGenerateRoute: (settings) => switch (settings.name) {
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
                onReady: (homeContext) => unawaited(_welcome(homeContext)),
                onResetAll: _repository.resetDebugSave,
                hasStarted: _departingHomeHasStarted ?? _hasStarted,
                quickPlayUnlocked: _repository.quickPlayUnlocked,
                quickPlayIsNew: _repository.quickPlayIsNew,
                celebrateQuickPlay: _repository.shouldCelebrateQuickPlay,
                availableLevel: _progress.latestUnlocked,
                unlockedLevels: _progress.unlockedCount,
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
