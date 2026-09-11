import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../data/level_progress.dart';
import '../screens/map_screen.dart';
import '../theme.dart';

@Preview(name: 'Mapa · teléfono', group: 'SunDoku', size: Size(390, 844))
@Preview(name: 'Mapa · compacto', group: 'SunDoku', size: Size(320, 568))
@Preview(name: 'Mapa · horizontal', group: 'SunDoku', size: Size(844, 390))
Widget mapPreview() => const _MapPreview();

class _MapPreview extends StatefulWidget {
  const _MapPreview();

  @override
  State<_MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<_MapPreview> {
  final _progress = LevelProgress();

  @override
  void initState() {
    super.initState();
    unawaited(_progress.recordResult(1, 3));
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildSunDokuTheme(),
    home: MapScreen(progress: _progress, showDeveloperControls: false),
  );
}
