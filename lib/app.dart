import 'package:flutter/material.dart';

import 'routes.dart';
import 'data/level_progress.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/map_screen.dart';

/// Root of the app. Wires the theme and the top-level route table.
class SunDokuApp extends StatefulWidget {
  const SunDokuApp({super.key});

  @override
  State<SunDokuApp> createState() => _SunDokuAppState();
}

class _SunDokuAppState extends State<SunDokuApp> {
  final LevelProgress _progress = LevelProgress();

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
          ),
        ),
        AppRoutes.settings: (_) => const SettingsScreen(),
        AppRoutes.map: (_) => MapScreen(progress: _progress),
      },
    );
  }
}
