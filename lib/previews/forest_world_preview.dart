import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../data/level_progress.dart';
import '../data/repositories/game_repository.dart';
import '../screens/map_screen.dart';
import '../screens/notes_tutorial_screen.dart';
import '../theme.dart';

@Preview(name: 'Bosque · mapa', group: 'SunDoku', size: Size(1024, 768))
@Preview(name: 'Bosque · mapa móvil', group: 'SunDoku', size: Size(390, 844))
Widget forestMapPreview() => const _ForestPreview();

@Preview(name: 'Bosque · lápiz', group: 'SunDoku', size: Size(390, 844))
@Preview(
  name: 'Bosque · lápiz horizontal',
  group: 'SunDoku',
  size: Size(844, 390),
)
Widget forestLessonPreview() => const _ForestPreview(lesson: true);

class _ForestPreview extends StatefulWidget {
  const _ForestPreview({this.lesson = false});
  final bool lesson;
  @override
  State<_ForestPreview> createState() => _ForestPreviewState();
}

class _ForestPreviewState extends State<_ForestPreview> {
  final repository = GameRepository.memory();
  late final progress = LevelProgress(
    repository: repository,
    worldId: 'world-2',
  );
  late final prepared = repository.prepareDebugForest();
  @override
  void dispose() {
    progress.dispose();
    unawaited(repository.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: buildSunDokuTheme(),
    home: FutureBuilder(
      future: prepared,
      builder: (context, snapshot) =>
          snapshot.connectionState != ConnectionState.done
          ? const Center(child: CircularProgressIndicator())
          : widget.lesson
          ? NotesTutorialScreen(
              repository: repository,
              replay: true,
              onFinished: () async {},
            )
          : MapScreen(progress: progress, showDeveloperControls: false),
    ),
  );
}
