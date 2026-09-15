import 'dart:async';

import 'package:flutter/material.dart';

import 'routes.dart';
import 'controllers/first_experience_controller.dart';
import 'data/level_progress.dart';
import 'data/repositories/game_repository.dart';
import 'data/services/game_feedback.dart';
import 'data/services/device_game_feedback.dart';
import 'widgets/game_feedback_scope.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/map_screen.dart';
import 'screens/first_experience_screen.dart';
import 'widgets/sundoku_cursor.dart';

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

  bool _openingPlay = false;
  bool _welcomeChecked = false;

  bool get _hasStarted {
    final introduction =
        _repository.state.modules[FirstExperienceController.moduleKey];
    return (introduction is Map && introduction.isNotEmpty) ||
        _repository.state.sessions.isNotEmpty ||
        _progress.latestUnlocked > 1;
  }

  Future<void> _welcome(BuildContext context) async {
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
      unawaited(navigator.pushNamed(AppRoutes.map));
      if (firstVisit) {
        unawaited(navigator.pushNamed(AppRoutes.firstExperience));
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
        debugShowCheckedModeBanner: false,
        theme: buildSunDokuTheme(),
        initialRoute: AppRoutes.splash,
        builder: (context, child) => SunDokuCursor(child: child!),
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.home: (_) => ListenableBuilder(
            listenable: _progress,
            builder: (context, _) => HomeScreen(
              onPlay: () => _play(context),
              onReady: (homeContext) => unawaited(_welcome(homeContext)),
              hasStarted: _hasStarted,
              availableLevel: _progress.latestUnlocked,
              unlockedLevels: _progress.unlockedCount,
              playerName: _repository.state.player.nameChosen
                  ? _repository.state.player.name
                  : 'Jugador',
            ),
          ),
          AppRoutes.map: (context) => MapScreen(
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
                MaterialPageRoute<void>(
                  builder: (_) => FirstExperienceScreen(
                    repository: _repository,
                    levelNumber: number,
                  ),
                ),
              );
            },
          ),
          AppRoutes.tutorialReview: (_) =>
              FirstExperienceScreen(repository: _repository, reviewOnly: true),
          AppRoutes.firstExperience: (_) =>
              FirstExperienceScreen(repository: _repository),
        },
        onGenerateRoute: (settings) => switch (settings.name) {
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
