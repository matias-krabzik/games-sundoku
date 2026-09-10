import 'dart:async';

import 'package:flutter/material.dart';

import 'routes.dart';
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
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.home: (_) => ListenableBuilder(
            listenable: _progress,
            builder: (_, _) => HomeScreen(
              availableLevel: _progress.latestUnlocked,
              unlockedLevels: _progress.unlockedCount,
              playerName: _repository.state.player.nameChosen
                  ? _repository.state.player.name
                  : 'Jugador',
            ),
          ),
          AppRoutes.map: (_) => MapScreen(progress: _progress),
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
