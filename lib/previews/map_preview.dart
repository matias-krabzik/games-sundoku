import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../data/level_progress.dart';
import '../data/repositories/game_repository.dart';
import '../screens/map_screen.dart';
import '../theme.dart';

@Preview(name: 'Mapa · teléfono', group: 'SunDoku', size: Size(390, 844))
@Preview(name: 'Mapa · compacto', group: 'SunDoku', size: Size(320, 568))
@Preview(name: 'Mapa · horizontal', group: 'SunDoku', size: Size(844, 390))
Widget mapPreview() => const _MapPreview();

@Preview(
  name: 'Mapa compartido · 21 niveles',
  group: 'SunDoku',
  size: Size(390, 844),
)
@Preview(
  name: 'Mapa compartido · 21 horizontal',
  group: 'SunDoku',
  size: Size(844, 390),
)
Widget expandedMapPreview() => const _MapPreview(worldId: 'world-2');

class _MapPreview extends StatefulWidget {
  const _MapPreview({this.worldId = 'world-1'});
  final String worldId;

  @override
  State<_MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<_MapPreview> {
  final _repository = GameRepository.memory();
  late final _progress = LevelProgress(
    repository: _repository,
    worldId: widget.worldId,
  );
  late final _prepared = widget.worldId == 'world-1'
      ? _progress.recordResult(1, 3)
      : _repository.prepareDebugForest();

  @override
  void initState() {
    super.initState();
    unawaited(_prepared);
  }

  @override
  void dispose() {
    _progress.dispose();
    unawaited(_repository.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildSunDokuTheme(),
    home: FutureBuilder<void>(
      future: _prepared,
      builder: (context, snapshot) =>
          snapshot.connectionState != ConnectionState.done
          ? const Center(child: CircularProgressIndicator())
          : MapScreen(progress: _progress, showDeveloperControls: false),
    ),
  );
}
