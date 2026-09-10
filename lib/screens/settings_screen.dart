import 'package:flutter/material.dart';

/// Placeholder settings. Values are in-memory for now — persist them
/// (e.g. shared_preferences) once a settings service exists.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sound = true;
  bool _music = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Efectos de sonido'),
            value: _sound,
            onChanged: (v) => setState(() => _sound = v),
          ),
          SwitchListTile(
            title: const Text('Música'),
            value: _music,
            onChanged: (v) => setState(() => _music = v),
          ),
          const Divider(),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'SunDoku',
            applicationVersion: '1.0.0',
          ),
        ],
      ),
    );
  }
}
