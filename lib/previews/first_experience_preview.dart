import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../controllers/first_experience_controller.dart';
import '../data/level_catalog.dart';
import '../data/repositories/game_repository.dart';
import '../domain/tutorial/tutorial_sudokus.dart';
import '../screens/first_experience_screen.dart';
import '../theme.dart';

@Preview(name: 'Bienvenida · teléfono', group: 'SunDoku', size: Size(390, 844))
@Preview(name: 'Bienvenida · compacto', group: 'SunDoku', size: Size(320, 568))
@Preview(
  name: 'Bienvenida · horizontal',
  group: 'SunDoku',
  size: Size(844, 390),
)
Widget firstExperiencePreview() => const _FirstExperiencePreview();

@Preview(name: 'Bloque · 8 de 9', group: 'SunDoku', size: Size(390, 844))
@Preview(name: 'Bloque · compacto', group: 'SunDoku', size: Size(320, 568))
Widget firstBlockPreview() =>
    const _FirstExperiencePreview(step: FirstExperienceStep.block);

@Preview(name: 'Bloque · explicación', group: 'SunDoku', size: Size(390, 844))
@Preview(name: 'Explicación · compacto', group: 'SunDoku', size: Size(320, 568))
Widget firstBlockIntroductionPreview() =>
    const _FirstExperiencePreview(step: FirstExperienceStep.blockIntroduction);

@Preview(name: 'Regla · fila', group: 'SunDoku', size: Size(390, 844))
@Preview(
  name: 'Regla · texto grande',
  group: 'SunDoku',
  size: Size(320, 568),
  textScaleFactor: 2,
)
Widget firstRowPreview() =>
    const _FirstExperiencePreview(step: FirstExperienceStep.rowRule);

@Preview(name: 'Sudoku · guiado', group: 'SunDoku', size: Size(390, 844))
@Preview(name: 'Sudoku · horizontal', group: 'SunDoku', size: Size(844, 390))
Widget firstGamePreview() =>
    const _FirstExperiencePreview(step: FirstExperienceStep.playing);

class _FirstExperiencePreview extends StatefulWidget {
  const _FirstExperiencePreview({this.step = FirstExperienceStep.welcome});
  final FirstExperienceStep step;

  @override
  State<_FirstExperiencePreview> createState() =>
      _FirstExperiencePreviewState();
}

class _FirstExperiencePreviewState extends State<_FirstExperiencePreview> {
  final _repository = GameRepository.memory();
  late final _ready = _prepare();

  Future<void> _prepare() async {
    if (widget.step == FirstExperienceStep.welcome) return;
    const center = [8, 3, 5, 4, 1, 6, 9, 2, 7];
    final module = {
      'step': widget.step.name,
      'cells': widget.step == FirstExperienceStep.block
          ? [8, 3, 5, 4, 1, 6, 9, 2, null]
          : widget.step.index >= FirstExperienceStep.expansion.index
          ? center
          : List<int?>.filled(9, null),
    };
    if (widget.step == FirstExperienceStep.playing) {
      await _repository.startOrResumeLevel(
        mapLevelId(1),
        definitions: TutorialSudokus.create(center),
        moduleKey: FirstExperienceController.moduleKey,
        moduleData: module,
      );
    } else {
      await _repository.saveModule(FirstExperienceController.moduleKey, module);
    }
  }

  @override
  void dispose() {
    unawaited(_repository.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildSunDokuTheme(),
    home: FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) =>
          snapshot.connectionState != ConnectionState.done
          ? const SizedBox()
          : FirstExperienceScreen(
              repository: _repository,
              showDeveloperControls: false,
            ),
    ),
  );
}
