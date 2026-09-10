import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../data/repositories/game_repository.dart';
import '../screens/settings_screen.dart';
import '../theme.dart';

@Preview(
  name: 'Configuración · teléfono',
  group: 'SunDoku',
  size: Size(390, 844),
)
@Preview(
  name: 'Configuración · compacto',
  group: 'SunDoku',
  size: Size(320, 568),
)
Widget settingsPreview() => const _SettingsPreview();

class _SettingsPreview extends StatefulWidget {
  const _SettingsPreview();

  @override
  State<_SettingsPreview> createState() => _SettingsPreviewState();
}

class _SettingsPreviewState extends State<_SettingsPreview> {
  final _repository = GameRepository.memory();

  @override
  void dispose() {
    _repository.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildSunDokuTheme(),
    home: Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/home-background.png', fit: BoxFit.cover),
          const ColoredBox(color: Color(0x65082045)),
          SettingsScreen(repository: _repository),
        ],
      ),
    ),
  );
}
